<#
    .SYNOPSIS
        Unregister an Autonance extension.

    .DESCRIPTION
        This function removes a registered Autonance extension from the current
        session.

    .EXAMPLE
        PS C:\> Unregister-AutonanceExtension -Name 'WsusReport'
        Unregister the Autonance extension calles WsusReport.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function Unregister-AutonanceExtension
{
    [CmdletBinding()]
    param
    (
        # Extension function name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    if ($Script:AutonanceExtension.ContainsKey($Name))
    {
        # Remove the module extension
        $Script:AutonanceExtension.Remove($Name)

        # Remove the global function
        Remove-Item -Path "Function:\$Name" -Force
    }
}
