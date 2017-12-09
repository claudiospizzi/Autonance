
# Import the module
Remove-Module -Name 'Autonance' -ErrorAction SilentlyContinue -Force -Verbose:$false
Import-Module -Name "$PSScriptRoot\..\Autonance.psd1" -Force -Verbose:$false

# Global definition
$sqlServer01 = 'DB01.contoso.com'
$sqlServer02 = 'DB02.contoso.com'
$sqlInstance01 = 'DB01\INSTANCE01'
$sqlInstance02 = 'DB02\INSTANCE01'
$sqlAvgGroup = 'AVGGROUP01'
$credential = Get-VaultEntryCredential -TargetName 'CONTOSO\Administrator'

# Demo with credential
Maintenance 'SQL' -Credential $credential {

    # Ensure the availability group is hosted on the second server
    SqlServerAvailabilityGroupFailover $sqlServer02 $sqlInstance02 $sqlAvgGroup

    # Patch and reboot the first server
    WindowsUpdateInstall $sqlServer01
    WindowsComputerRestart $sqlServer01

    # Manual confirmation
    ConfirmTask 'Confirm' "Do you want to failover $sqlAvgGroup back to $sqlServer01"

    # Failover back to the first server
    SqlServerAvailabilityGroupFailover $sqlServer01 $sqlInstance01 $sqlAvgGroup
}
