[![PowerShell Gallery - Autonance](https://img.shields.io/badge/PowerShell_Gallery-Autonance-0072C6.svg)](https://www.powershellgallery.com/packages/Autonance)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/Autonance.svg)](https://github.com/claudiospizzi/Autonance/releases)
[![AppVeyor - master](https://img.shields.io/appveyor/ci/claudiospizzi/Autonance/master.svg)](https://ci.appveyor.com/project/claudiospizzi/Autonance/branch/master)

# Autonance PowerShell Module

PowerShell module for automatic supervised maintenance with Autonance DSL.

## Introduction

PowerShell module to automate recurring maintenance activities like installing
Windows Updates. Autonance is optimized to perform task on distributed systems
like a hosted business applications which consists of multiple servers with
complex dependencies.

Thanks to the Autonance domain-specific language, the maintenance can be written
as a readable playbook, easy to understand and track.

## Features

### Containers

The following containers are the root elements of the Autonance domain-specific
language and can be used to group the tasks.

* **Maintenance**  
  Autonance DSL maintenance container. The top-most container.

* **TaskGroup**  
  Container to group maintenance tasks.

### Tasks

The following tasks are part of the Autonance domain-specific language and can
be used to perform maintenance.

* **SleepTask**  
  Wait for the specified amount of time.

* **ConfirmTask**  
  Get a user confirmation to continue or stop the maintenance script.

* **LocalScript**  
  Invoke a script script block on the local computer.

* **RemoteScript**  
  Invoke a script script block on the remote computer.

* **WindowsServiceStart**  
  Ensure a Windows service is started.

* **WindowsServiceStop**
  Ensure a Windows service is stopped.

* **WindowsServiceConfig**  
  Ensure a Windows has a valid startup type configuration.

* **WindowsUpdateInstall**  
  Install windows updates on the target computer.

* **WindowsComputerRestart**  
  Restart the target Windows computer.

* **WindowsComputerShutdown**  
  Shutdown the target Windows computer.

* **WindowsComputerWait**  
  Wait until the target Windows computer is online

* **SqlServerAvailabilityGroupFailover**  
  Failover the SQL Availability Group to the target SQL Instance.

### Extensions

* **Get-AutonanceExtension**  
  Get all registered tasks in the Autonance extension system.

* **Register-AutonanceExtension**  
  Register a new task in the Autonance extension system.

* **Unregister-AutonanceExtension**  
  Unregister an existing task from the Autonance extension system.

* **Write-AutonanceMessage**  
  Use this function to write Autonance messages in an extension task.

## Examples

### Example 1: Single Server Maintenance

Shutdown a Windows server for manual hardware maintenance. Before shutting down,
stop all required services. After shutdown, wait until the server is online.
This demo will use the default credentials.

```powershell
Maintenance 'LON-SRV01 Maintenance' {

    # Stop and disable the application service
    WindowsServiceStop 'LON-SRV01' 'MyApplication'
    WindowsServiceConfig 'LON-SRV01' 'MyApplication' -StartupType 'Disabled'

    # Confirm before the computer reboot
    ConfirmTask 'Confirm' 'Shutdown server LON-SRV01?'

    # Stop the target computer
    WindowsComputerShutdown 'LON-SRV01'

    # At this point, perform the manual hardware maintenance...

    # Wait until the target computer is available
    WindowsComputerWait 'LON-SRV01'

    # Set the service to automatic startup and start it
    WindowsServiceConfig 'LON-SRV01' 'MyApplication' -StartupType 'Automatic'
    WindowsServiceStop 'LON-SRV01' 'MyApplication'

    # Log the maintenance success
    LocalScript {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Add-Content -Path 'C:\Windows\Temp\maintenance.log' -Value "$timestamp   LON-SRV01 maintenance successful"
    }
}
```

### Example 2: SQL Server AlwaysOn Availability Group Maintenance

The following demo shows how to perform a Windows Update installation on a SQL
Server Availability Group cluster. The Availability Group is always switched
away from the system which will be updated.

```powershell
Maintenance 'AvgGroup01 Maintenance' -Credential (Get-Credential 'ADATUM\Admin') {

    TaskGroup 'Patch Server LON-SQL01' {

        # Failover the SQL Instance to LON-SQL02
        SqlServerAvailabilityGroupFailover 'LON-SQL02' 'LON-SQL02\MSSQLSERVER' 'AvgGroup01'

        # Install Windows Updates
        WindowsUpdateInstall 'LON-SQL01'

        # Restart Computer
        WindowsComputerRestart 'LON-SQL01'
    }

    SleepTask 10

    TaskGroup 'Patch Server LON-SQL02' {

        # Failover the SQL Instance to LON-SQL01
        SqlServerAvailabilityGroupFailover 'LON-SQL01' 'LON-SQL01\MSSQLSERVER' 'AvgGroup01'

        # Install Windows Updates
        WindowsUpdateInstall 'LON-SQL02'

        # Restart Computer
        WindowsComputerRestart 'LON-SQL02'
    }
}
```

### Example 3: Extension System

Register an Autonance extension task to update the WSUS report.

```powershell
Register-AutonanceExtension -Name 'WsusReport' -ScriptBlock {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,
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

Maintenance 'Extension Demo' {

    # Install Windows Updates
    WindowsUpdateInstall 'LON-SRV02'

    # Restart Computer
    WindowsComputerRestart 'LON-SRV02'

    # Update WSUS Report
    WsusReport 'LON-SRV02'
}
```

## Versions

Please find all versions in the [GitHub Releases] section and the release notes
in the [CHANGELOG.md] file.

## Installation

Use the following command to install the module from the [PowerShell Gallery],
if the PackageManagement and PowerShellGet modules are available:

```powershell
# Download and install the module
Install-Module -Name 'Autonance'
```

Alternatively, download the latest release from GitHub and install the module
manually on your local system:

1. Download the latest release from GitHub as a ZIP file: [GitHub Releases]
2. Extract the module and install it: [Installing a PowerShell Module]

## Requirements

The following minimum requirements are necessary to use this module, or in other
words are used to test this module:

* Windows PowerShell 5.1
* Windows Server 2012 R2 / Windows 10

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer] and [psake] PowerShell Modules

[PowerShell Gallery]: https://www.powershellgallery.com/packages/Autonance
[GitHub Releases]: https://github.com/claudiospizzi/Autonance/releases
[Installing a PowerShell Module]: https://msdn.microsoft.com/en-us/library/dd878350

[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell
[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[psake]: https://www.powershellgallery.com/packages/psake
