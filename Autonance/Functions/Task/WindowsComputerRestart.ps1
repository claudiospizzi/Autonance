<#
    .SYNOPSIS
        Autonance DSL task to restart a Windows computer.

    .DESCRIPTION
        The WindowsComputerRestart task is part of the Autonance domain-specific
        language (DSL). The task will restart the specified Windows computer
        using WinRM. A user account can be specified with the Credential
        parameter.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function WindowsComputerRestart
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

        # Specifies the number of retries between computer state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Count = 120,

        # Specifies the interval between computer state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Delay = 5
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'WindowsComputerRestart task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'WindowsComputerRestart' -Name $ComputerName -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

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

            # Specifies the number of retries between computer state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Count = 120,

            # Specifies the interval between computer state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Delay = 5
        )

        try
        {
            ## Part 1 - Before Reboot

            $session = New-AutonanceSession -ComputerName $ComputerName -Credential $Credential -SessionType CIM -ErrorAction Stop

            # Get the operating system object
            $operatingSystem = Get-CimInstance -CimSession $session -ClassName 'Win32_OperatingSystem' -ErrorAction Stop

            # To verify the reboot, store the last boot up time
            $oldBootUpTime = $operatingSystem.LastBootUpTime

            Write-Autonance -Message "Last boot up time is $oldBootUpTime"


            ## Part 2 - Execute Reboot

            Write-Autonance -Message "Restart computer $ComputerName now ..."

            # Now, reboot the system
            $result = $operatingSystem | Invoke-CimMethod -Name 'Reboot' -ErrorAction Stop

            # Check method error code
            if ($result.ReturnValue -ne 0)
            {
                $errorMessage = Get-AutonanceErrorMessage -Component 'Win32OperatingSystem_Wbem' -ErrorId $result.ReturnValue

                throw "Failed to restart $ComputerName with error code $($result.ReturnValue): $errorMessage"
            }

            # Close old session (or try it...)
            Remove-AutonanceSession -Session $session -Silent

            # Reset variables
            $session         = $null
            $operatingSystem = $null

            # Wait until the computer has restarted is running
            Wait-AutonanceTask -Activity "$ComputerName is restarting..." -Count $Count -Delay $Delay -Condition {

                # Prepare credentials for remote connection
                $credentialSplat = @{}
                if ($null -ne $Credential)
                {
                    $credentialSplat['Credential'] = $Credential
                }

                # Test the connection and try to get the operating system object
                $innerOperatingSystem = Invoke-Command -ComputerName $ComputerName @credentialSplat -ScriptBlock { Get-CimInstance -ClassName 'Win32_OperatingSystem' } -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

                # Return boolean value if the condition has passed
                $null -ne $innerOperatingSystem -and $oldBootUpTime -lt $innerOperatingSystem.LastBootUpTime
            }


            ## Part 3 - Verify Reboot

            $session = New-AutonanceSession -ComputerName $ComputerName -Credential $Credential -SessionType CIM -ErrorAction Stop

            # Get the operating system object
            $operatingSystem = Get-CimInstance -CimSession $session -ClassName 'Win32_OperatingSystem' -ErrorAction Stop

            # To verify the reboot, store the new boot up time
            $newBootUpTime = $operatingSystem.LastBootUpTime

            Write-Autonance -Message "New boot up time is $newBootUpTime"

            # Verify if the reboot was successful
            if ($oldBootUpTime -eq $newBootUpTime)
            {
                throw "Failed to restart computer $ComputerName!"
            }
        }
        catch
        {
            throw $_
        }
        finally
        {
            Remove-AutonanceSession -Session $session

            # Ensure, that the next task has a short delay
            Start-Sleep -Seconds 5
        }
    }
}
