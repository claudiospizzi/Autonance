<#
    .SYNOPSIS
    Get the registered Autonance extensions.

    .DESCRIPTION
    This command wil return all registered autonance extensions in the current
    PowerShell session.

    .EXAMPLE
    PS C:\> Get-AutonanceExtension
    Returns all registered autonance extensions.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function Get-AutonanceExtension
{
    [CmdletBinding()]
    param
    (
        # Name of the extension to return
        [Parameter(Mandatory = $false)]
        [System.String]
        $Name
    )

    foreach ($key in $Script:AutonanceExtension.Keys)
    {
        if ($null -eq $Name -or $key -like $Name)
        {
            $Script:AutonanceExtension[$key]
        }
    }
}
