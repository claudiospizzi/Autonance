
function Remove-AutonanceSession
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Object]
        $Session,

        [Parameter(Mandatory = $false)]
        [switch]
        $Silent
    )

    # Remove existing session
    if ($null -ne $Session)
    {
        if ($Session -is [System.Management.Automation.Runspaces.PSSession])
        {
            if (-not $Silent.IsPresent)
            {
                Write-Autonance -Message "Close WinRM connection to $ComputerName"
            }

            if ($PSCmdlet.ShouldProcess($Session, 'Close WinRM session'))
            {
                $Session | Remove-PSSession -ErrorAction SilentlyContinue
            }
        }

        if ($session -is [Microsoft.Management.Infrastructure.CimSession])
        {
            if (-not $Silent.IsPresent)
            {
                Write-Autonance -Message "Close CIM connection to $ComputerName"
            }

            if ($PSCmdlet.ShouldProcess($Session, 'Close COM session'))
            {
                $Session | Remove-CimSession -ErrorAction SilentlyContinue
            }
        }
    }
}
