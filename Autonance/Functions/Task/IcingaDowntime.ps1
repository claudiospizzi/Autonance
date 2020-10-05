<#
    .SYNOPSIS
    Autonance DSL task to set an Icinga service downtime.

    .DESCRIPTION
    The IcingaDowntime task is part of the Autonance domain-specific language
    (DSL). The task will set a downtime in an Icinga monitoring instance for
    the specific service.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function IcingaDowntimeService
{
    [CmdletBinding()]
    param
    (
        # The hostname of the icinga instance.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ComputerName,

        # The target service name for the downtime.
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $ServiceName,

        # The target service name for the downtime.
        [Parameter(Mandatory = $false, Position = 2)]
        [System.TimeSpan]
        $Duration = '01:00:00',

        # Specifies a icinga user that has permission to perform the task.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # Optionally, specify the port
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $IcingaPort = 5665
    )

    if (!$Script:AutonanceBlock)
    {
        throw 'IcingaDowntime task not encapsulated in a Maintenance container'
    }

    New-AutonanceTask -Type 'IcingaDowntime' -Name "$ComputerName $ServiceName" -Credential $Credential -Arguments $PSBoundParameters -ScriptBlock {

        [CmdletBinding()]
        param
        (
            # The hostname of the icinga instance.
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $ComputerName,

            # The target service name for the downtime.
            [Parameter(Mandatory = $true, Position = 1)]
            [System.String]
            $ServiceName,

            # The target service name for the downtime.
            [Parameter(Mandatory = $false, Position = 2)]
            [System.TimeSpan]
            $Duration = '01:00:00',

            # Specifies a icinga user that has permission to perform the task.
            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,

            # Optionally, specify the port
            [Parameter(Mandatory = $false)]
            [System.Int32]
            $IcingaPort = 5665
        )

        Write-Autonance -Message "Connected to VMware Server $viServer"

        # $ curl -k -s -u root:icinga -H 'Accept: application/json' -X POST
        # 'https://localhost:5665/v1/actions/schedule-downtime?type=Service&filter=service.name==%22ping4%22'
        # -d '{ "start_time": 1446388806, "end_time": 1446389806, "duration": 1000, "author": "icingaadmin", "comment": "IPv4 network maintenance", "pretty": true }'


        # try
        # {
        # }
        # catch
        # {
        #     throw $_
        # }
    }
}
