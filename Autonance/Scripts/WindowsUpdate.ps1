[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [System.String]
    $Id,

    [Parameter(Mandatory = $true)]
    [System.String]
    $Update
)

$ErrorActionPreference = 'Stop'

# Enum definition
$operationResultCode = @(
    'Not Started'
    'In Progress'
    'Succeeded'
    'Succeeded With Errors'
    'Failed'
    'Aborted'
)

# Parse input update GUID's
$updates = $Update.Split(',')

# Status object
$status = [PSCustomObject] @{
    Search   = [PSCustomObject] @{
        Status   = $false
        Result   = $null
        Message  = ''
    }
    Download = [PSCustomObject] @{
        Status   = $false
        Result   = $null
        Message  = ''
    }
    Install  = [PSCustomObject] @{
        Status   = $false
        Result   = $null
        Message  = ''
    }
}

# Export current status
$status | Export-Clixml -Path "C:\Windows\Temp\WindowsUpdate-$Id.xml" -Force


## Part 1: Search Update

Start-Sleep -Seconds 2

try
{
    $updateSession  = New-Object -ComObject 'Microsoft.Update.Session'
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult   = $updateSearcher.Search("IsInstalled=0 and Type='Software'")

    $updateDownload = New-Object -ComObject 'Microsoft.Update.UpdateColl'

    foreach ($currentUpdate in $searchResult.Updates)
    {
        if ($updates -contains $currentUpdate.Identity.UpdateID)
        {
            $updateDownload.Add($currentUpdate)
        }
    }

    if ($updateDownload.Count -eq 0)
    {
        throw 'No updates selected!'
    }

    $status.Search.Status  = $true
    $status.Search.Result  = $true
    $status.Search.Message = '{0} update(s) selected, download now...' -f $updateDownload.Count
}
catch
{
    $status.Search.Status  = $true
    $status.Search.Result  = $false
    $status.Search.Message = [String] $_

    exit
}
finally
{
    $status | Export-Clixml -Path "C:\Windows\Temp\WindowsUpdate-$Id.xml" -Force
}


## Part 2: Download Updates

Start-Sleep -Seconds 2

try
{
    $updateDownloader = $updateSession.CreateUpdateDownloader()
    $updateDownloader.Updates = $updateDownload
    $downloadResult = $updateDownloader.Download()

    if ($downloadResult.ResultCode -ne 2)
    {
        throw ('Download not succeeded with status {0}' -f $operationResultCode[$downloadResult.ResultCode])
    }

    $updateInstall = New-Object -ComObject 'Microsoft.Update.UpdateColl'

    foreach ($currentUpdate in $searchResult.Updates)
    {
        if ($updates -contains $currentUpdate.Identity.UpdateID -and $currentUpdate.IsDownloaded)
        {
            $updateInstall.Add($currentUpdate) | Out-Null
        }
    }

    if ($updateInstall.Count -eq 0)
    {
        throw 'No updates downloaded!'
    }

    $status.Download.Status  = $true
    $status.Download.Result  = $true
    $status.Download.Message = '{0} update(s) downloaded, install now...' -f $updateInstall.Count
}
catch
{
    $status.Download.Status  = $true
    $status.Download.Result  = $false
    $status.Download.Message = [String] $_

    exit
}
finally
{
    $status | Export-Clixml -Path "C:\Windows\Temp\WindowsUpdate-$Id.xml" -Force
}


## Part 3: Install Updates

Start-Sleep -Seconds 2

try
{
    $updateInstaller = $updateSession.CreateUpdateInstaller()
    $updateInstaller.Updates = $updateInstall
    $installResult = $updateInstaller.Install()

    if ($installResult.ResultCode -ne 2)
    {
        throw ('Install not succeeded with status {0}' -f $operationResultCode[$downloadResult.ResultCode])
    }

    $status.Install.Status  = $true
    $status.Install.Result  = $true
    $status.Install.Message = '{0} update(s) installed, reboot {1} required' -f $updateInstall.Count, $(if ($installResult.RebootRequired) { 'is' } else { 'is not' })
}
catch
{
    $status.Install.Status  = $true
    $status.Install.Result  = $false
    $status.Install.Message = [String] $_

    exit
}
finally
{
    $status | Export-Clixml -Path "C:\Windows\Temp\WindowsUpdate-$Id.xml" -Force
}
