
function Invoke-AutonanceTask
{
    [CmdletBinding()]
    param
    (
        # Autonance task to execute.
        [Parameter(Mandatory = $true)]
        [PSTypeName('Autonance.Task')]
        $Task
    )

    $retry      = $false
    $retryCount = 0

    do
    {
        # Block info
        if ($retryCount -eq 0)
        {
            Write-Autonance '' -Type Info
            Write-Autonance "$($Task.Type) $($Task.Name)" -Type Task
        }
        else
        {
            Write-Autonance '' -Type Info
            Write-Autonance "$($Task.Type) $($Task.Name) (Retry: $retryCount)" -Type Task
        }

        try
        {
            $taskArguments   = $task.Arguments
            $taskScriptBlock = $task.ScriptBlock

            # If the task supports custom credentials and the credentials were
            # not explicit specified, set them with the parent task credentials.
            if ($taskScriptBlock.Ast.ParamBlock.Parameters.Name.VariablePath.UserPath -contains 'Credential')
            {
                if ($null -eq $taskArguments.Credential -and $null -ne $Task.Credential)
                {
                    $taskArguments.Credential = $Task.Credential
                }
            }

            & $taskScriptBlock @taskArguments -ErrorAction 'Stop'

            $retry = $false
        }
        catch
        {
            Write-Error $_

            # Prepare the retry choices in case of the exception
            $retryChoices = New-Object -TypeName 'Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]'
            $retryChoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Retry', 'Retry this task'))
            $retryChoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Continue', 'Continue with next task'))
            $retryChoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Stop', 'Stop the maintenance'))

            # Query the desired choice from the user
            do
            {
                $retryResult = $Host.UI.PromptForChoice('Repeat', "Do you want to retry $($Task.Type) $($Task.Name)?", $retryChoices, -1)
            }
            while ($retryResult -eq -1)

            switch ($retryResult)
            {
                0 { $retry = $true }
                1 { $retry = $false }
                2 { throw 'Maintenance stopped by user!' }
            }
        }

        $retryCount++
    }
    while ($retry)
}
