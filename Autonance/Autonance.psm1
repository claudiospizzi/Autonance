<# ----------------- DEBUGGING ONLY -- REMOVED DURING BUILD ----------------- #>

# Get and dot source all helper functions (internal)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Helpers' -Directory |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -File -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all external functions (public)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Functions' -Directory |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -File -Recurse |
            ForEach-Object { . $_.FullName }

<# -------------------------------------------------------------------------- #>

# Initialize context variables
$Script:AutonanceBlock     = $false
$Script:AutonanceLevel     = 0
$Script:AutonanceSilent    = $false
$Script:AutonanceExtension = @{}
$Script:AutonanceTimestamp = $null

$Script:ModulePath = $PSScriptRoot
