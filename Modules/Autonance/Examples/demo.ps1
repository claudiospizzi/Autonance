
# Import the module
Remove-Module -Name 'Autonance' -ErrorAction SilentlyContinue -Force -Verbose:$false
Import-Module -Name "$PSScriptRoot\..\Autonance.psd1" -Force -Verbose:$false

$computerName = '192.168.144.13'
$credential   = Get-Credential 'LAB-SRV01\Administrator'

# $computerName = 'autonancewin.westeurope.cloudapp.azure.com'
# $credential = Get-VaultEntryCredential -TargetName 'AUTONANCEWIN\autonance'

# Register an extension
Register-AutonanceExtension -Name 'WindowsUpdateReport' -ScriptBlock {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    if ($null -eq $Credential)
    {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock { wuauclt.exe /ReportNow }
    }
    else
    {
        Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock { wuauclt.exe /ReportNow }
    }
}

# Demo with credential
Maintenance 'Demo with credential' -Credential $credential {

    LocalScript {
        "$(Get-Date)   Start Maintenance" | Out-File -FilePath 'C:\Windows\Temp\maintenance.log' -Append
    }

    RemoteScript $computerName {
        "$(Get-Date)   Start Maintenance" | Out-File -FilePath 'C:\Windows\Temp\maintenance.log' -Append
    }

    WindowsServiceStart $computerName 'BITS'
    WindowsServiceStart $computerName 'BITS'

    WindowsServiceStop $computerName 'BITS'
    WindowsServiceStop $computerName 'BITS'

    SleepTask 1

    WindowsServiceConfig $computerName 'BITS' -StartupType 'Disabled'
    WindowsServiceConfig $computerName 'BITS' -StartupType 'Manual'
    WindowsServiceConfig $computerName 'BITS' -StartupType 'Automatic'

    ConfirmTask 'Confirm' "Do you want to continue with computer $computerName?"

    WindowsUpdateInstall $computerName

    # Restart the computer
    WindowsComputerRestart $computerName

    # Shutdown the computer and manually startup
    WindowsComputerShutdown $computerName
    WindowsComputerWait $computerName

    WindowsUpdateReport $computerName
}
