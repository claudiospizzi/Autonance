<#
    .SYNOPSIS
        Autonance DSL task to invoke a remote script block.

    .DESCRIPTION
        The RemoteScript task is part of the Autonance domain-specific language
        (DSL). The task will invoke the script block on the specified Windows
        computer using WinRM. A user account can be specified with the
        Credential parameter. The script can use some of the built-in PowerShell
        functions to return objects or control the maintenance:
        - Throw an terminating error to stop the whole maintenance script
        - Show status information with Write-Autonance

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function RemoteScript
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

        # The script block to invoke.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'RemoteScript task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'RemoteScript' -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

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

            # The script block to invoke.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.Management.Automation.ScriptBlock]
            $ScriptBlock
        )

        try
        {
            $session = New-AutonanceSession -ComputerName $ComputerName -Credential $Credential -SessionType WinRM -ErrorAction Stop

            Write-Autonance -Message "Invoke the remote script block now..."

            Invoke-Command -Session $session -ScriptBlock $ScriptBlock -ErrorAction Stop
        }
        catch
        {
            throw $_
        }
        finally
        {
            Remove-AutonanceSession -Session $session
        }
    }
}
