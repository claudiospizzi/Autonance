
function Pop-ImpersonationContext
{
    [CmdletBinding()]
    param ()

    Initialize-ImpersonationContext

    if ($Script:ImpersonationContext.Count -gt 0)
    {
        # Get the latest impersonation context
        $popImpersonationContext = $Script:ImpersonationContext.Pop()

        # Undo the impersonation
        $popImpersonationContext.Undo()
    }
}
