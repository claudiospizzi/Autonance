<#
    .SYNOPSIS
    Autonance DSL task to failover an SQL Server Availability Group.

    .DESCRIPTION
    Use this task to failover the specified SQL Server Availability Group to the
    specified computer and instance. It will use the SQLPS module on the remote
    system.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function SqlServerAvailabilityGroupFailover
{
    [CmdletBinding()]
    param
    (
        # This is the target Windows computer for the planned failover.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        # Target SQL instance for the planned planned.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $SqlInstance,

        # The availability group name to perform a planned manual failover.
        [Parameter(Mandatory = $true, Position = 2)]
        [System.String]
        $AvailabilityGroup,

        # Specifies a user account that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # Specifies the number of retries between availability group state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Count = 60,

        # Specifies the interval between availability group state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Delay = 2
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'SqlServerAvailabilityGroupFailover task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'SqlServerAvailabilityGroupFailover' -Name "$ComputerName $SqlInstance $AvailabilityGroup" -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # This is the target Windows computer for the planned failover.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $ComputerName,

            # Target SQL instance for the planned planned.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.String]
            $SqlInstance,

            # The availability group name to perform a planned manual failover.
            [Parameter(Mandatory = $true, Position = 2)]
            [System.String]
            $AvailabilityGroup,

            # Specifies a user account that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # Specifies the number of retries between availability group state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Count = 60,

            # Specifies the interval between availability group state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Delay = 2
        )

        $SqlInstancePath = $SqlInstance

        # Default MSSQLSERVER instance, only specified as server name
        if (-not $SqlInstance.Contains('\'))
        {
            $SqlInstancePath = "$SqlInstance\DEFAULT"
        }

        try
        {
            ## Part 1 - Connect to the SQL Server and load the SQLPS module

            $session = New-AutonanceSession -ComputerName $ComputerName -Credential $Credential -SessionType WinRM -ErrorAction Stop

            # Load the SQL PowerShell module but suppress warnings because of
            # uncommon cmdlet verbs.
            Invoke-Command -Session $session -ScriptBlock { Import-Module -Name 'SQLPS' -WarningAction 'SilentlyContinue' } -ErrorAction Stop


            ## Part 2 - Check the current role and state

            $replicas = Invoke-Command -Session $session -ScriptBlock { Get-ChildItem -Path "SQLSERVER:\Sql\$using:SqlInstancePath\AvailabilityGroups\$using:AvailabilityGroup\AvailabilityReplicas" | Select-Object * } -ErrorAction Stop
            $replica  = $replicas.Where({$_.Name -eq $SqlInstance})[0]


            ## Part 3 - Planned manual failover

            if ($replica.Role -ne 'Primary')
            {
                ## Part 3a - Check replicate state

                Write-Autonance -Message "Replica role is $($replica.Role.ToString().ToLower())"
                Write-Autonance -Message "Replica state is $($replica.RollupRecoveryState.ToString().ToLower()) and $($replica.RollupSynchronizationState.ToString().ToLower())"

                if ($replica.RollupRecoveryState.ToString() -ne 'Online' -or $replica.RollupSynchronizationState.ToString() -ne 'Synchronized')
                {
                    throw 'Replicate is not ready for planned manual failover!'
                }


                ## Part 3b - Invoke failover

                Write-Autonance -Message "Failover $AvailabilityGroup to $SqlInstance ..."

                Invoke-Command -Session $session -ScriptBlock { Switch-SqlAvailabilityGroup -Path "SQLSERVER:\Sql\$using:SqlInstancePath\AvailabilityGroups\$using:AvailabilityGroup" } -ErrorAction Stop

                Wait-AutonanceTask -Activity "$SqlInstance replication is restoring ..." -Count $Count -Delay $Delay -Condition {

                    $replicas = Invoke-Command -Session $session -ScriptBlock { Get-ChildItem -Path "SQLSERVER:\Sql\$using:SqlInstancePath\AvailabilityGroups\$using:AvailabilityGroup\AvailabilityReplicas" | ForEach-Object { $_.Refresh(); $_ } } -ErrorAction Stop

                    $condition = $true

                    # Check all replica states
                    foreach ($replica in $replicas)
                    {
                        # Test for primary replica
                        if ($replica.Name -eq $SqlInstance)
                        {
                            $condition = $condition -and $replica.Role -eq 'Primary'
                            $condition = $condition -and $replica.RollupRecoveryState -eq 'Online'
                        }

                        # Test for any replica
                        $condition = $condition -and $replica.RollupSynchronizationState -eq 'Synchronized'
                    }

                    $condition
                }
            }


            ## Part 4 - Verify

            $replicas = Invoke-Command -Session $session -ScriptBlock { Get-ChildItem -Path "SQLSERVER:\Sql\$using:SqlInstancePath\AvailabilityGroups\$using:AvailabilityGroup\AvailabilityReplicas" } -ErrorAction Stop
            $replica  = $replicas.Where({$_.Name -eq $SqlInstance})[0]

            Write-Autonance -Message "Replica role is $($replica.Role.ToString().ToLower())"
            Write-Autonance -Message "Replica state is $($replica.RollupRecoveryState.ToString().ToLower()) and $($replica.RollupSynchronizationState.ToString().ToLower())"

            if ($replica.Role -ne 'Primary')
            {
                throw 'Replica role is not primary'
            }

            if ($replica.RollupRecoveryState -ne 'Online')
            {
                throw 'Replica recovery state is not online'
            }

            if ($replica.RollupSynchronizationState -ne 'Synchronized')
            {
                throw 'Replica synchronization state is not synchronized'
            }
        }
        catch
        {
            throw $_
        }
        finally
        {
            Remove-AutonanceSession -Session $session

            # Ensure, that the next task has a short delay
            Start-Sleep -Seconds 3
        }
    }
}
