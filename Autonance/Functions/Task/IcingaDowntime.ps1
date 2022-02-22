<#
    .SYNOPSIS
        Autonance DSL task to set an Icinga service downtime.

    .DESCRIPTION
        The IcingaDowntime task is part of the Autonance domain-specific
        language (DSL). The task will set a downtime in an Icinga monitoring
        instance for the specific service.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/Autonance
#>
function IcingaDowntime
{
    [CmdletBinding()]
    param
    (
        # The hostname of the icinga instance.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $IcingaServer,

        # Optionally, specify the port
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $IcingaPort = 5665,

        # Specifies a icinga user that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # The target host name for the downtime.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $HostName,

        # The target service name for the downtime.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ServiceName,

        # Downtime duration.
        [Parameter(Mandatory = $false)]
        [System.TimeSpan]
        $Duration = '01:00:00',

        # Downtime comment.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Comment = "Downtime by $Env:Username on $Env:ComputerName at $((Get-Date).ToString('s')) using Autonance"
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'IcingaDowntime task not encapsulated in a Maintenance container'
    }

    # Build a nice task name
    $taskName = '{0} {1}' -f $IcingaServer, $HostName
    if (-not [System.String]::IsNullOrEmpty($ServiceName))
    {
        $taskName = '{0}!{1}' -f $taskName, $ServiceName
    }

    New-AutonanceTask -Type 'IcingaDowntime' -Name $taskName -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # The hostname of the icinga instance.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $IcingaServer,

            # Optionally, specify the port
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $IcingaPort = 5665,

            # Specifies a icinga user that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # The target host name for the downtime.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.String]
            $HostName,

            # The target service name for the downtime.
            [Parameter(Mandatory = $false)]
            [System.String]
            $ServiceName,

            # Downtime duration.
            [Parameter(Mandatory = $false)]
            [System.TimeSpan]
            $Duration = '01:00:00',

            # Downtime comment.
            [Parameter(Mandatory = $false)]
            [System.String]
            $Comment = "Downtime by $Env:Username on $Env:ComputerName at $((Get-Date).ToString('s')) using Autonance"
        )

        Write-Autonance -Message "Connected to Icinga Server $IcingaServer`:$IcingaPort"

        Connect-IcingaServer -Uri "https://$IcingaServer`:$IcingaPort" -Credential $Credential

        if ([System.String]::IsNullOrEmpty($ServiceName))
        {
            Write-Autonance -Message "Set downtime on host $HostName for $Duration"

            Get-IcingaHost -ComputerName $HostName | Set-IcingaDowntime -Duration $Duration -Comment $Comment | Out-Null
        }
        else
        {
            Write-Autonance -Message "Set downtime on service $HostName!$ServiceName for $Duration"

            Get-IcingaHost -ComputerName $HostName -ServiceName $ServiceName | Set-IcingaDowntime -Duration $Duration -Comment $Comment | Out-Null
        }
    }
}
