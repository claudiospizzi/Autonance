<#
    .SYNOPSIS
    Autonance DSL task to install Windows updates.

    .DESCRIPTION
    The WindowsUpdateInstall task is part of the Autonance domain-specific
    language (DSL). The task will install all pending Windows updates on the
    target Windows computer by using WinRM and the 'Microsoft.Update.Session'
    COM object. A user account can be specified with the Credential parameter.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function WindowsUpdateInstall
{
    [CmdletBinding()]
    param
    (
        # This task restarts the specified Windows computer.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        # Specifies a user account that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # If specified, all available updates will be installed without a query.
        [Parameter(Mandatory = $false)]
        [switch]
        $All
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'WindowsUpdateInstall task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'WindowsUpdateInstall' -Name $ComputerName -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # This task restarts the specified Windows computer.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $ComputerName,

            # Specifies a user account that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # If specified, all available updates will be installed without a query.
            [Parameter(Mandatory = $false)]
            [switch]
            $All
        )

        try
        {
            $guid   = New-Guid | Select-Object -ExpandProperty 'Guid'
            $script = Get-Content -Path "$Script:ModulePath\Scripts\WindowsUpdate.ps1"

            $session = New-AutonanceSession -ComputerName $ComputerName -Credential $Credential -SessionType WinRM -ErrorAction Stop


            ## Part 1: Search for pending updates

            Write-Autonance -Message 'Search for pending updates ...'

            $pendingUpdates = Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {

                $updateSession  = New-Object -ComObject 'Microsoft.Update.Session'
                $updateSearcher = $updateSession.CreateUpdateSearcher()
                $searchResult   = $updateSearcher.Search("IsInstalled=0 and Type='Software'")

                foreach ($update in $searchResult.Updates)
                {
                    [PSCustomObject] @{
                        KBArticle = 'KB' + $update.KBArticleIDs[0]
                        Identity  = $update.Identity.UpdateID
                        Title     = $update.Title
                    }
                }
            }

            if ($pendingUpdates.Count -eq 0)
            {
                Write-Autonance -Message 'No pending updates found'
                return
            }

            Write-Autonance -Message ("{0} pending update(s) found" -f $pendingUpdates.Count)


            ## Part 2: Select updates

            if ($All.IsPresent)
            {
                Write-Autonance -Message 'All pending update(s) were preselected to install'

                $selectedUpdates = $pendingUpdates
            }
            else
            {
                Write-Autonance -Message 'Query the user for update(s) to install'

                $readHostMultipleChoiceSelection = @{
                    Caption      = 'Choose Updates'
                    Message      = 'Please select the updates to install from the following list.'
                    ChoiceObject = $pendingUpdates
                    ChoiceLabel  = $pendingUpdates.Title
                }
                $selectedUpdates = @(Read-HostMultipleChoiceSelection @readHostMultipleChoiceSelection)

                if ($selectedUpdates.Count -eq 0)
                {
                    Write-Autonance -Message 'No updates selected by the user'
                    return
                }

                Write-Autonance -Message ("{0} pending update(s) were selected to install" -f $selectedUpdates.Count)
            }


            ## Part 3: Install the updates with a one-time scheduled task

            Write-Autonance -Message 'Invoke a remote scheduled task to install the update(s)'

            # Create and start the scheduled task
            Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {

                $using:script | Set-Content -Path "C:\Windows\Temp\WindowsUpdate-$using:guid.ps1" -Encoding UTF8

                $updateList = $using:selectedUpdates.Identity -join ','

                try
                {
                    # Use the new scheduled tasks cmdlets
                    $newScheduledTask = @{
                        Action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Windows\Temp\WindowsUpdate-$using:guid.ps1`" -Id `"$using:guid`" -Update `"$updateList`"" -ErrorAction Stop
                        Trigger   = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(-1) -ErrorAction Stop
                        Principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest -ErrorAction Stop
                        Settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -ErrorAction Stop
                    }
                    New-ScheduledTask @newScheduledTask -ErrorAction Stop | Register-ScheduledTask -TaskName "WindowsUpdate-$using:guid" -ErrorAction Stop | Start-ScheduledTask -ErrorAction Stop
                }
                catch
                {
                    # Craete a temporary batch file
                    "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:\Windows\Temp\WindowsUpdate-$using:guid.ps1`" -Id `"$using:guid`" -Update `"$updateList`"" | Out-File "C:\Windows\Temp\WindowsUpdate-$using:guid.cmd" -Encoding Ascii

                    # The scheduled tasks cmdlets are missing, use schtasks.exe
                    (SCHTASKS.EXE /CREATE /RU "NT Authority\System" /SC ONCE /ST 23:59 /TN "WindowsUpdate-$using:guid" /TR "`"C:\Windows\Temp\WindowsUpdate-$using:guid.cmd`"" /RL HIGHEST /F) | Out-Null
                    (SCHTASKS.EXE /RUN /TN "WindowsUpdate-$using:guid") | Out-Null
                }
            }

            # Wait for every step until it is completed
            foreach ($step in @('Search', 'Download', 'Install'))
            {
                $status = Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {

                    $step = $using:step
                    $path = "C:\Windows\Temp\WindowsUpdate-$using:guid.xml"

                    do
                    {
                        Start-Sleep -Seconds 1

                        if (Test-Path -Path $path)
                        {
                            $status = Import-Clixml -Path $path
                        }
                    }
                    while ($null -eq $status -or $status.$step.Status -eq $false)

                    Write-Output $status.$step
                }

                Write-Autonance -Message $status.Message

                if (-not $status.Result)
                {
                    throw $status.Message
                }
            }
        }
        catch
        {
            throw $_
        }
        finally
        {
            # Try to cleanup the scheduled task and the script file
            if ($null -ne $session)
            {
                Invoke-Command -Session $session -ErrorAction SilentlyContinue -ScriptBlock {

                    Unregister-ScheduledTask -TaskName "WindowsUpdate-$using:guid" -Confirm:$false -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\Temp\WindowsUpdate-$using:guid.cmd" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\Temp\WindowsUpdate-$using:guid.ps1" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\Temp\WindowsUpdate-$using:guid.xml" -Force -ErrorAction SilentlyContinue
                }
            }

            Remove-AutonanceSession -Session $session

            # Ensure, that the next task has a short delay
            Start-Sleep -Seconds 3
        }
    }
}
