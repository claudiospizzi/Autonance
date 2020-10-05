
function New-AutonanceContainer
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        # The container type, e.g. Maintenance, TaskGroup, etc.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # The container name, which will be shown after the container type.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Name = '',

        # The credentials, which will be used for all container tasks.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential = $null,

        # The script block, which contains the container tasks definitions.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # The processing mode of the container. Currently only sequential mode
        # is supported.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Sequential')]
        [System.String]
        $Mode = 'Sequential',

        # Specifies, if the container tasks should be repeated.
        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $Repeat = $false,

        # If the container tasks will be repeated, define the number of repeat
        # loops. Use 0 for an infinite loop.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $RepeatCount = 0,

        # If the container tasks will be repeated, define the repeat condition.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ScriptBlock]
        $RepeatCondition = $null,

        # If the container tasks will be repeated, define if the user gets an
        # inquire for every loop.
        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $RepeatInquire = $false
    )

    # Create and return the container object
    [PSCustomObject] [Ordered] @{
        PSTypeName      = 'Autonance.Container'
        Type            = $Type
        Name            = $Name
        Credential      = $Credential
        ScriptBlock     = $ScriptBlock
        Mode            = $Mode
        Repeat          = $Repeat
        RepeatCount     = $RepeatCount
        RepeatCondition = $RepeatCondition
        RepeatInquire   = $RepeatInquire
    }
}
