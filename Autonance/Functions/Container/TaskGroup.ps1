<#
    .SYNOPSIS
        Autonance DSL container to group maintenance tasks.

    .DESCRIPTION
        The TaskGroup container is part of the Autonance domain-specific
        language (DSL) and is used to group maintenance tasks. Optionally, the
        tasks within the group can be repeated in a loop. The loop can have
        multiple stop options or will run infinite as long as no exception
        occurs.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function TaskGroup
{
    [CmdletBinding(DefaultParameterSetName = 'Simple')]
    param
    (
        # Task group name.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Name,

        # Script block containing the grouped tasks.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # Optionally parameters to use for all maintenance tasks.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = $null,

        # Option to repeat all tasks in the group.
        [Parameter(Mandatory = $false, ParameterSetName = 'Repeat')]
        [switch]
        $Repeat,

        # Number of times to repeat the group. Use 0 for an infinite loop.
        [Parameter(Mandatory = $false, ParameterSetName = 'Repeat')]
        [System.Int32]
        $RepeatCount = 0,

        # Script block to control the repeat loop. Return $true to continue with
        # the loop. Return $false to stop the loop and continue with the next
        # maintenance task.
        [Parameter(Mandatory = $false, ParameterSetName = 'Repeat')]
        [System.Management.Automation.ScriptBlock]
        $RepeatCondition = $null,

        # Option to show a user prompt after each loop, to inquire, if the loop
        # should continue or stop.
        [Parameter(Mandatory = $false, ParameterSetName = 'Repeat')]
        [switch]
        $RepeatInquire
    )

    # Create and return the task group container object
    $containerSplat = @{
        Type            = 'TaskGroup'
        Name            = $Name
        Credential      = $Credential
        ScriptBlock     = $ScriptBlock
        Repeat          = $Repeat.IsPresent
        RepeatCount     = $RepeatCount
        RepeatCondition = $RepeatCondition
        RepeatInquire   = $RepeatInquire.IsPresent
    }
    New-AutonanceContainer @containerSplat
}
