<#
    .SYNOPSIS
    Autonance DSL task to upgrade the VMware Tools.

    .DESCRIPTION
    The VMwareToolsUpgrade task is part of the Autonance domain-specific
    language (DSL). The task will use the PowerCLI cmdlet to connect to a
    vSphere Server and upgrade the VMware Tools on the target VM.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function VMwareToolsUpgrade
{
    [CmdletBinding()]
    param
    (
        # The target VMware server to connect.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $VMwareServer,

        # The protocol to connect to the VMware server, default is https.
        [Parameter(Mandatory = $false)]
        [ValidateSet('http', 'https')]
        [System.String]
        $VMwareProtocol = 'https',

        # The port to connect to the VMware server, default is 443.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $VMWarePort = 443,

        # Specifies a user account that has permission on the VMware server.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # The target VM to upgrade the VMware Tools.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $VMName
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'VMwareToolsUpgrade task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'VMwareToolsUpgrade' -Name "$VMwareServer\$VMName" -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # The target VMware server to connect.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $VMwareServer,

            # The protocol to connect to the VMware server, default is https.
            [Parameter(Mandatory = $false)]
            [ValidateSet('http', 'https')]
            [System.String]
            $VMwareProtocol = 'https',

            # The port to connect to the VMware server, default is 443.
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $VMWarePort = 443,

            # Specifies a user account that has permission on the VMware server.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # The target VM to upgrade the VMware Tools.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.String]
            $VMName
        )

        $ErrorActionPreference = 'Stop'

        try
        {
            ## Part 1 - Connect VMware Server

            if ($null -eq $Credential)
            {
                $viServer = Connect-VIServer -Server $VMwareServer -Port $VMWarePort
            }
            else
            {
                $viServer = Connect-VIServer -Server $VMwareServer -Port $VMWarePort -Credential $Credential
            }

            Write-Autonance -Message "Connected to VMware Server $viServer"


            ## Part 2 - Check the VMware Tools

            # Load VM and it's view
            $vm = VMware.VimAutomation.Core\Get-VM -Server $viServer -Name $VMName
            $vmView = $vm | VMware.VimAutomation.Core\Get-View

            # Get the current VMware Tools status
            $vmToolsVersion = $vmView.Guest.ToolsVersion
            $vmToolsStatus  = $vmView.Summary.Guest.ToolsVersionStatus2

            Write-Autonance -Message "VMware Tools Version is $vmToolsVersion"
            Write-Autonance -Message "VMware Tools Status is $vmToolsStatus"


            ## Part 3a - Exit task because no action can be performed

            if ($vmToolsStatus -eq 'guestToolsCurrent')
            {
                Write-Autonance -Message 'VMware Tools is current, no upgrade required'
                return
            }

            if ('guestToolsNeedUpgrade', 'guestToolsSupportedOld', 'guestToolsTooOld' -notcontains $vmToolsStatus)
            {
                throw "VMware Tools status for VM $vm is not supported: $vmToolsStatus"
            }


            ## Part 3b - Upgrade VMware Tools

            Write-Autonance -Message 'VMware Tools is not current, invoke upgrade...'

            # Upgrade the VMware Tools
            Update-Tools -Server $viServer -VM $vm -NoReboot

            Write-Autonance -Message 'VMware Tools upgrade completed'

            # Reload VM and it's view
            $vm = VMware.VimAutomation.Core\Get-VM -Server $viServer -Name $VMName
            $vmView = $vm | VMware.VimAutomation.Core\Get-View

            # Get the updated VMware Tools status
            $vmToolsVersion = $vmView.Guest.ToolsVersion
            $vmToolsStatus  = $vmView.Summary.Guest.ToolsVersionStatus2

            Write-Autonance -Message "VMware Tools Version is $vmToolsVersion"
            Write-Autonance -Message "VMware Tools Status is $vmToolsStatus"

            if ($vmToolsStatus -eq 'guestToolsCurrent')
            {
                Write-Autonance -Message 'VMware Tools is current, ugprade successful'
            }
            else
            {
                throw "VMware Tools upgrade failed!"
            }
        }
        catch
        {
            throw $_
        }
        finally
        {
            if ($null -ne $viServer)
            {
                Disconnect-VIServer -Server $viServer -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }
}
