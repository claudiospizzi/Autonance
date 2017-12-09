
function Wait-AutonanceTask
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Activity,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ScriptBlock]
        $Condition,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Count,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Delay
    )

    for ($i = 1; $i -le $Count; $i++)
    {
        Write-Progress -Activity $Activity -Status "$i / $Count" -PercentComplete ($i / $Count * 100) -Verbose

        # Record the timestamp before the condition query
        $timestamp = Get-Date

        # Evaluate the condition and exit the loop, if the result is true
        $result = & $Condition
        if ($result)
        {
            Write-Progress -Activity $Activity -Completed

            return
        }

        # Calculate the remaining sleep duration
        $duration = (Get-Date) - $timestamp
        $leftover = $Delay - $duration.TotalSeconds

        # Sleep if required
        if ($leftover -gt 0)
        {
            Start-Sleep -Seconds $leftover
        }
    }

    Write-Progress -Activity $Activity -Completed

    throw "Timeout: $Activity"
}
