<#
    .SYNOPSIS
        Write an Autonance task message.

    .DESCRIPTION
        This function must be used in a Autonance extension task to show the
        current status messages in a nice formatted output. The Autonance module
        will take care about the indent and message color.

    .EXAMPLE
        PS C:\> Register-AutonanceExtension -Name 'ShowMessage' -ScriptBlock { Write-AutonanceMessage -Message 'Hello, World!' }
        Uses the Write-AutonanceMessage function to show a nice formatted output
        message within a custom Autonance task.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function Write-AutonanceMessage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Message
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'Write-AutonanceMessage function not encapsulated in a Autonance task'
    }

    Write-Autonance -Message $Message
}
