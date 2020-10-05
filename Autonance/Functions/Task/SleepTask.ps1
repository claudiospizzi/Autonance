<#
    .SYNOPSIS
        Autonance DSL task to wait for the specified amount of time.

    .DESCRIPTION
        The SleepTask task is part of the Autonance domain-specific language
        (DSL). The task uses the Start-Sleep built-in command to wait for the
        specified amount of time.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function SleepTask
{
    [CmdletBinding()]
    param
    (
        # Duration in seconds to wait.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Int32]
        $Second
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'SleepTask task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'SleepTask' -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # Duration in seconds to wait.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.Int32]
            $Second
        )

        Write-Autonance -Message "Wait for $Second second(s)"

        # Now wait
        Start-Sleep -Seconds $Second
    }
}
