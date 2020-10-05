
function New-AutonanceTask
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        # The task type, e.g. LocalScript, WindowsComputerReboot, etc.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # The task name, which will be shown after the task type.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Name,

        # The credentials, which will be used for the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        # The script block, which contains the task definition.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # The task arguments to pass for the task execution.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $Arguments
    )

    # Create and return the task object
    [PSCustomObject] [Ordered] @{
        PSTypeName  = 'Autonance.Task'
        Type        = $Type
        Name        = $Name
        Credential  = $Credential
        ScriptBlock = $ScriptBlock
        Arguments   = $Arguments
    }
}
