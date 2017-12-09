
function Invoke-AutonanceContainer
{
    [CmdletBinding()]
    param
    (
        # Autonance container to execute.
        [Parameter(Mandatory = $true)]
        [PSTypeName('Autonance.Container')]
        $Container
    )

    $repeat      = $Container.Repeat
    $repeatCount = 1

    do
    {
        # Block info
        if ($repeat)
        {
            Write-Autonance '' -Type Info
            Write-Autonance "$($Container.Type) $($Container.Name) (Repeat: $repeatCount)" -Type Container
        }
        else
        {
            Write-Autonance '' -Type Info
            Write-Autonance "$($Container.Type) $($Container.Name)" -Type Container
        }

        # It's a container, so increment the level
        $Script:AutonanceLevel++

        # Get all items to execute
        $items = & $Container.ScriptBlock

        # Invoke all
        foreach ($item in $items)
        {
            # Inherit the credentials to all sub items
            if ($null -eq $item.Credential -and $null -ne $Container.Credential)
            {
                $item.Credential = $Container.Credential
            }

            if ($item.PSTypeNames -contains 'Autonance.Task')
            {
                Invoke-AutonanceTask -Task $item
            }
            elseif ($item.PSTypeNames -contains 'Autonance.Container')
            {
                Invoke-AutonanceContainer -Container $item
            }
            else
            {
                Write-Warning "Unexpected Autonance task or container object: [$($item.GetType().FullName)] $item"
            }
        }

        # Check repeat
        if ($repeat)
        {
            if ($Container.RepeatCount -ne 0)
            {
                if ($repeatCount -ge $Container.RepeatCount)
                {
                    $repeat = $false
                }
            }

            if ($null -ne $Container.RepeatCondition)
            {
                $repeatCondition = & $Container.RepeatCondition

                if (!$repeatCondition)
                {
                    $repeat = $false
                }
            }

            if ($Container.RepeatInquire)
            {
                # Prepare the choices
                $repeatInquireChoices = New-Object -TypeName 'Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]'
                $repeatInquireChoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Repeat', 'Repeat all child tasks'))
                $repeatInquireChoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Continue', 'Continue with next task'))

                # Query the desired choice from the user
                do
                {
                    $repeatInquireResult = $Host.UI.PromptForChoice('Repeat', "Do you want to repeat $($Container.Type) $($Container.Name)?", $repeatInquireChoices, -1)
                }
                while ($repeatInquireResult -eq -1)

                # Check the result and quit the execution, if necessary
                if ($repeatInquireResult -eq 1)
                {
                    $repeat = $false
                }
            }
        }

        # Increment repeat count
        $repeatCount++

        # Container has finished, decrement the level
        $Script:AutonanceLevel--
    }
    while ($repeat)
}
