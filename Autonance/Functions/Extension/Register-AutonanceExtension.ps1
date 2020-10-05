<#
    .SYNOPSIS
    Register an Autonance extension.

    .DESCRIPTION
    This function will register a new Autonance extension, by creating a global
    function with the specified extension name. The function can be called like
    all other DSL tasks in the Maintenance block.
    The script block can contain a parameter block, to specify the parameters
    provided to the cmdlet. If a parameter $Credential is used, the credentials
    will automatically be passed to the sub task, if specified. The function
    Write-AutonanceMessage can be used to return status messages. The Autonance
    module will take care of the formatting.

    .EXAMPLE
    PS C:\>
    Register-AutonanceExtension -Name 'WsusReport' -ScriptBlock {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true, Position = 0)]
            [System.String]
            $ComputerName,

            [Parameter(Mandatory = $false)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,
        )

        if ($null -eq $Credential)
        {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock { wuauclt.exe /ReportNow }
        }
        else
        {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock { wuauclt.exe /ReportNow }
        }
    }

    Register an Autonance extension to invoke the report now command for WSUS.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/Autonance
#>

function Register-AutonanceExtension
{
    [CmdletBinding()]
    param
    (
        # Extension function name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        # Script block to execute for the extension.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    # Register the Autonance extension in the current scope
    $Script:AutonanceExtension[$Name] = [PSCustomObject] [Ordered] @{
        PSTypeName  = 'Autonance.Extension'
        Name        = $Name
        ScriptBlock = $ScriptBlock
    }

    # Create the helper script block which will be invoked for the extension. It
    # return the extension as a Autonance task item.
    $extensionScriptBlock = {

        $name      = (Get-PSCallStack)[0].InvocationInfo.MyCommand.Name
        $extension = Get-AutonanceExtension -Name $name

        # Create and return the task object without using New-AutonanceTask
        # function, because this will be executed outside of the module scope
        # and there is the helper function New-AutonanceTask not available.
        [PSCustomObject] [Ordered] @{
            PSTypeName  = 'Autonance.Task'
            Type        = $extension.Name
            Name        = ''
            Credential  = $Credential
            ScriptBlock = $extension.ScriptBlock
            Arguments   = $PSBoundParameters
        }
    }

    # Concatenate the original parameters and the helper script block
    $extensionParameter   = [String] $ScriptBlock.Ast.ParamBlock
    $extensionBody        = [String] $extensionScriptBlock
    $extensionScriptBlock = [ScriptBlock]::Create($extensionParameter + $extensionBody)

    # Register the global function
    Set-Item -Path "Function:\Global:$Name" -Value $extensionScriptBlock -Force | Out-Null
}
