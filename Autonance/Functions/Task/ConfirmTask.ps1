<#
    .SYNOPSIS
        Autonance DSL task to get a user confirmation.

    .DESCRIPTION
        The ConfirmTask task is part of the Autonance domain-specific language
        (DSL). The task uses the $Host.UI.PromptForChoice() built-in method to
        display a host specific confirm prompt.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function ConfirmTask
{
    [CmdletBinding()]
    param
    (
        # Message title for the confirm box.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Caption,

        # Message body for the confirm box.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $Query
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'ConfirmTask task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'ConfirmTask' -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # Message title for the confirm box.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $Caption,

            # Message body for the confirm box.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.String]
            $Query
        )

        # Prepare the choices
        $choices = New-Object -TypeName 'Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]'
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes', 'Continue the maintenance'))
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No', 'Stop the maintenance'))

        # Query the desired choice from the user
        do
        {
            $result = $Host.UI.PromptForChoice($Caption, $Query, $choices, -1)
        }
        while ($result -eq -1)

        # Check the result and quit the execution, if necessary
        if ($result -ne 0)
        {
            throw "User has canceled the maintenance!"
        }
    }
}
