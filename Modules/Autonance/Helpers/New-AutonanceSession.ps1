
function New-AutonanceSession
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [ValidateSet('WinRM', 'CIM')]
        [System.String]
        $SessionType,

        [Parameter(Mandatory = $false)]
        [switch]
        $Silent
    )

    # Session splat
    $sessionSplat = @{}
    if ($null -ne $Credential)
    {
        $sessionSplat['Credential'] = $Credential
        $messageSuffix = " as $($Credential.UserName)"
    }

    if (-not $Silent.IsPresent)
    {
        Write-Autonance -Message "Open $SessionType connection to $ComputerName$messageSuffix"
    }

    # Create a new session
    switch ($SessionType)
    {
        'WinRM'
        {
            if ($PSCmdlet.ShouldProcess($ComputerName, 'Open WinRM session'))
            {
                New-PSSession -ComputerName $ComputerName @sessionSplat -ErrorAction Stop
            }
        }
        'CIM'
        {
            if ($PSCmdlet.ShouldProcess($ComputerName, 'Open CIM session'))
            {
                New-CimSession -ComputerName $ComputerName @sessionSplat -ErrorAction Stop
            }
        }
    }
}
