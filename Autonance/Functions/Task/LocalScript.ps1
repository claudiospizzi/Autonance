<#
    .SYNOPSIS
    Autonance DSL task to invoke a local script block.

    .DESCRIPTION
    The LocalScript task is part of the Autonance domain-specific language
    (DSL). The task will invoke the script block on the local computer. The
    script can use some of the built-in PowerShell functions to return objects
    or control the maintenance:
    - Throw an terminating error to stop the whole maintenance script
    - Show status information with Write-Autonance

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function LocalScript
{
    [CmdletBinding()]
    param
    (
        # Specifies a user account that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # The script block to invoke.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'LocalScript task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'LocalScript' -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # Specifies a user account that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # The script block to invoke.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.Management.Automation.ScriptBlock]
            $ScriptBlock
        )

        $ErrorActionPreference = 'Stop'

        if ($null -eq $Credential)
        {
            Write-Autonance -Message 'Invoke the local script block now...'

            & $ScriptBlock
        }
        else
        {
            try
            {
                Write-Autonance -Message "Push the impersonation context as $($Credential.UserName)"

                Push-ImpersonationContext -Credential $Credential -ErrorAction Stop

                Write-Autonance -Message 'Invoke the local script block now...'

                & $ScriptBlock
            }
            finally
            {
                Write-Autonance -Message 'Pop the impersonation context'

                Pop-ImpersonationContext -ErrorAction SilentlyContinue
            }
        }
    }
}
