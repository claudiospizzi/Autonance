<#
    .SYNOPSIS
    Autonance DSL task to configure a Windows service.

    .DESCRIPTION
    The WindowsServiceConfig task is part of the Autonance domain-specific
    language (DSL). The task will configure the specified Windows service on a
    remote computer by using CIM to connect to the remote computer. A user
    account can be specified with the Credential parameter.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function WindowsServiceConfig
{
    [CmdletBinding()]
    param
    (
        # This task configures a Windows service on the specified computer.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        # Specifies the service name for the service to be configured.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $ServiceName,

        # Specifies a user account that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # If specified, the target startup type will be set.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Automatic', 'Manual', 'Disabled')]
        [System.String]
        $StartupType
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'WindowsServiceConfig task not encapsulated in a Maintenance container'
    }

    # Define a nice task name
    $name = "$ComputerName\$ServiceName"
    if ($PSBoundParameters.ContainsKey('StartupType'))
    {
        $name += ", StartupType=$StartupType"
    }

    New-AutonanceTask -Type 'WindowsServiceConfig' -Name $name -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # This task configures a Windows service on the specified computer.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $ComputerName,

            # Specifies the service name for the service to be configured.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.String]
            $ServiceName,

            # Specifies a user account that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # If specified, the target startup type will be set.
            [Parameter(Mandatory = $false)]
            [ValidateSet('Automatic', 'Manual', 'Disabled')]
            [System.String]
            $StartupType
        )

        try
        {
            $session = New-AutonanceSession -ComputerName $ComputerName -Credential $Credential -SessionType CIM -ErrorAction Stop

            # Get service and throw an exception, if the service does not exist
            $service = Get-CimInstance -CimSession $session -ClassName 'Win32_Service' -Filter "Name = '$ServiceName'" -ErrorAction Stop
            if ($null -eq $service)
            {
                throw "$ServiceName service does not exist!"
            }

            if ($PSBoundParameters.ContainsKey('StartupType'))
            {
                # Do nothing, if the services startup type is correct
                if ($service.StartMode.Replace('Auto', 'Automatic') -eq $StartupType)
                {
                    Write-Autonance -Message "$ServiceName service startup type is already set to $StartupType"
                }
                else
                {
                    Write-Autonance -Message "$ServiceName service startup type is $($service.StartMode.Replace('Auto', 'Automatic'))"
                    Write-Autonance -Message "Set $ServiceName service startup type to $StartupType"

                    # Reconfigure service
                    $result = $service | Invoke-CimMethod -Name 'ChangeStartMode' -Arguments @{ StartMode = $StartupType } -ErrorAction Stop

                    # Check method error code
                    if ($result.ReturnValue -ne 0)
                    {
                        throw "Failed to set $ServiceName service startup type with error code $($result.ReturnValue)!"
                    }

                    # Check if the service startup type is correct
                    $service = Get-CimInstance -CimSession $session -ClassName 'Win32_Service' -Filter "Name = '$ServiceName'" -ErrorAction Stop
                    if ($service.StartMode.Replace('Auto', 'Automatic') -ne $StartupType)
                    {
                        throw "Failed to set $ServiceName service startup type, current is $($service.StartMode.Replace('Auto', 'Automatic'))!"
                    }

                    Write-Autonance -Message "$ServiceName service startup type changed successfully"
                }
            }
        }
        catch
        {
            throw $_
        }
        finally
        {
            Remove-AutonanceSession -Session $session
        }
    }
}
