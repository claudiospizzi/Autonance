
function Get-AutonanceErrorMessage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Component,

        [Parameter(Mandatory = $false)]
        [System.String]
        $ErrorId
    )

    $values = Import-PowerShellDataFile -Path "$Script:ModulePath\Strings\$Component.psd1"

    $errorMessage = $values[$result.ReturnValue]
    if ([String]::IsNullOrEmpty($errorMessage))
    {
        $errorMessage = 'Unknown'
    }

    Write-Output $errorMessage
}
