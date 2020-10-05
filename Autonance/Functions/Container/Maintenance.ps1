<#
    .SYNOPSIS
        Autonance DSL maintenance container.

    .DESCRIPTION
        The Maintenance container is part of the Autonance domain-specific
        language (DSL) and is used to define a maintenance container block. The
        maintenance container block is always the topmost block and contains all
        sub containers and maintenance tasks.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function Maintenance
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    param
    (
        # Name of the maintenance.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Name,

        # Script block containing the maintenance tasks.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # Optionally parameters to use for all maintenance tasks.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = $null,

        # Hide autonance header.
        [Parameter(Mandatory = $false)]
        [switch]
        $NoHeader,

        # Hide autonance output.
        [Parameter(Mandatory = $false)]
        [switch]
        $NoOutput
    )

    try
    {
        # Ensure that the Maintenance block is not nested
        if ($Script:AutonanceBlock)
        {
            throw 'Maintenance container is not the topmost block'
        }

        # Initialize context variables
        $Script:AutonanceBlock  = $true
        $Script:AutonanceLevel  = 0
        $Script:AutonanceSilent = $NoOutput.IsPresent

        # Headline with module info
        if (!$NoHeader.IsPresent)
        {
            Write-Autonance -Message (Get-Module -Name 'Autonance' | ForEach-Object { "{0} Version {1}`n{2}" -f $_.Name, $_.Version, $_.Copyright }) -Type 'Info'
        }

        # Create the maintenance container object
        $containerSplat = @{
            Type            = 'Maintenance'
            Name            = $Name
            Credential      = $Credential
            ScriptBlock     = $ScriptBlock
        }
        $container = New-AutonanceContainer @containerSplat

        # Invoke the root maintenance container
        Invoke-AutonanceContainer -Container $container

        # End blank lines
        Write-Autonance -Message "`n" -Type 'Info'
    }
    finally
    {
        # Reset context variable
        $Script:AutonanceBlock     = $false
        $Script:AutonanceTimestamp = $null
    }
}
