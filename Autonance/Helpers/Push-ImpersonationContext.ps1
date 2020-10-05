
function Push-ImpersonationContext
{
    [CmdletBinding()]
    param
    (
        # Specifies a user account to impersonate.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # The logon type.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Interactive', 'Network', 'Batch', 'Service', 'Unlock', 'NetworkClearText', 'NewCredentials')]
        $LogonType = 'Interactive',

        # The logon provider.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'WinNT40', 'WinNT50')]
        $LogonProvider = 'Default'
    )

    Initialize-ImpersonationContext

    # Handle for the logon token
    $tokenHandle = [IntPtr]::Zero

    # Now logon the user account on the local system
    $logonResult = [Win32.AdvApi32]::LogonUser($Credential.GetNetworkCredential().UserName,
                                               $Credential.GetNetworkCredential().Domain,
                                               $Credential.GetNetworkCredential().Password,
                                               ([Win32.Logon32Type] $LogonType),
                                               ([Win32.Logon32Provider] $LogonProvider),
                                               [ref] $tokenHandle)

    # Error handling, if the logon fails
    if (-not $logonResult)
    {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

        throw "Failed to call LogonUser() throwing Win32 exception with error code: $errorCode"
    }

    # Now, impersonate the new user account
    $newImpersonationContext = [System.Security.Principal.WindowsIdentity]::Impersonate($tokenHandle)
    $Script:ImpersonationContext.Push($newImpersonationContext)

    # Finally, close the handle to the token
    [Win32.Kernel32]::CloseHandle($tokenHandle) | Out-Null
}
