<#
    .SYNOPSIS
        Autonance DSL task to start a Windows service.

    .DESCRIPTION
        The WindowsServiceStart task is part of the Autonance domain-specific
        language (DSL). The task will start the specified Windows service on a
        remote computer by using CIM to connect to the remote computer. A user
        account can be specified with the Credential parameter.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function WindowsServiceStart
{
    [CmdletBinding()]
    param
    (
        # This task starts a Windows service on the specified computer.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        # Specifies the service name for the service to be started.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $ServiceName,

        # Specifies a user account that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # Specifies the number of retries between service state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Count = 30,

        # Specifies the interval between service state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Delay = 2
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'WindowsServiceStart task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'WindowsServiceStart' -Name "$ComputerName\$ServiceName" -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # This task starts a Windows service on the specified computer.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $ComputerName,

            # Specifies the service name for the service to be started.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.String]
            $ServiceName,

            # Specifies a user account that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # Specifies the number of retries between service state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Count = 30,

            # Specifies the interval between service state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Delay = 2
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

            # Do nothing, if the services is already running
            if ($service.State -eq 'Running')
            {
                Write-Autonance -Message "$ServiceName service is already running"
            }
            else
            {
                Write-Autonance -Message "$ServiceName service is not running"
                Write-Autonance -Message "Start $ServiceName service now"

                # Start service
                $result = $service | Invoke-CimMethod -Name 'StartService' -ErrorAction Stop

                # Check method error code
                if ($result.ReturnValue -ne 0)
                {
                    $errorMessage = Get-AutonanceErrorMessage -Component 'Win32Service_StartService' -ErrorId $result.ReturnValue

                    throw "Failed to start $ServiceName service with error code $($result.ReturnValue): $errorMessage!"
                }

                # Wait until the services is running
                Wait-AutonanceTask -Activity "$ServiceName service is starting..." -Count $Count -Delay $Delay -Condition {
                    $service = Get-CimInstance -CimSession $session -ClassName 'Win32_Service' -Filter "Name = '$ServiceName'" -ErrorAction Stop
                    $service.State -ne 'Start Pending'
                }

                # Check if the service is now running
                $service = Get-CimInstance -CimSession $session -ClassName 'Win32_Service' -Filter "Name = '$ServiceName'" -ErrorAction Stop
                if ($service.State -ne 'Running')
                {
                    throw "Failed to start $ServiceName service, current state is $($service.State)!"
                }

                Write-Autonance -Message "$ServiceName service started successfully"
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
