<#
    .SYNOPSIS
        Autonance DSL task to shutdown a Windows computer.

    .DESCRIPTION
        The WindowsComputerShutdown task is part of the Autonance
        domain-specific language (DSL). The task will shutdown the specified
        Windows computer. A user account can be specified with the Credential
        parameter.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function WindowsComputerShutdown
{
    [CmdletBinding()]
    param
    (
        # This task stops the specified Windows computer.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        # Specifies a user account that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # Specifies the number of retries between computer state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Count = 720,

        # Specifies the interval between computer state tests.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $Delay = 5
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'WindowsComputerShutdown task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'WindowsComputerShutdown' -Name $ComputerName -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # This task stops the specified Windows computer.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $ComputerName,

            # Specifies a user account that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # Specifies the number of retries between computer state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Count = 720,

            # Specifies the interval between computer state tests.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $Delay = 5
        )

        ## Part 1 - Before Shutdown

        $session = New-AutonanceSession -ComputerName $ComputerName -Credential $Credential -SessionType CIM -ErrorAction Stop

        # Get the operating system object
        $operatingSystem = Get-CimInstance -CimSession $session -ClassName 'Win32_OperatingSystem' -ErrorAction Stop

        Write-Autonance -Message "Last boot up time is $($operatingSystem.LastBootUpTime)"


        ## Part 2 - Execute Shutdown

        Write-Autonance -Message "Shutdown computer $ComputerName now ..."

        # Now, reboot the system
        $result = $operatingSystem | Invoke-CimMethod -Name 'Shutdown' -ErrorAction Stop

        # Check method error code
        if ($result.ReturnValue -ne 0)
        {
            $errorMessage = Get-AutonanceErrorMessage -Component 'Win32OperatingSystem_Wbem' -ErrorId $result.ReturnValue

            throw "Failed to shutdown $ComputerName with error code $($result.ReturnValue): $errorMessage"
        }

        # Close old session (or try it...)
        Remove-AutonanceSession -Session $session -Silent


        ## Part 3 - Wait for Shutdown

        # Wait until the computer has or is disconnected
        Wait-AutonanceTask -Activity "Wait for computer $ComputerName disconnect..." -Count $Count -Delay $Delay -Condition {

            try
            {
                # Prepare credentials for remote connection
                $credentialSplat = @{}
                if ($null -ne $Credential)
                {
                    $credentialSplat['Credential'] = $Credential
                }

                # Test the connection and try to get the computer name
                Invoke-Command -ComputerName $ComputerName @credentialSplat -ScriptBlock { } -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null

                return $false
            }
            catch
            {
                return $true
            }
        }
    }
}
