<#
    .SYNOPSIS
        Autonance DSL task to wait for a Windows computer.

    .DESCRIPTION
        The WindowsComputerWait task is part of the Autonance domain-specific
        language (DSL). The task will wait until the specified Windows computer
        is reachable using WinRM. A user account can be specified with the
        Credential parameter.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function WindowsComputerWait
{
    [CmdletBinding()]
    param
    (
        # This task waits for the specified Windows computer.
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
        throw 'WindowsComputerWait task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'WindowsComputerWait' -Name $ComputerName -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # This task waits for the specified Windows computer.
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

        Write-Autonance -Message "Wait for computer $ComputerName..."

        # Wait until the computer is reachable
        Wait-AutonanceTask -Activity "Wait for computer $ComputerName..." -Count $Count -Delay $Delay -Condition {

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

                return $true
            }
            catch
            {
                return $false
            }
        }
    }
}
