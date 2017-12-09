
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Maintenance' {

    Context 'Script Block Mock' {

        Mock 'Get-Help' -Verifiable { }

        Mock 'Write-Autonance' -ModuleName $moduleName -ParameterFilter { $Message -eq "" -and $Type -eq 'Info' } -Verifiable { }
        Mock 'Write-Autonance' -ModuleName $moduleName -ParameterFilter { $Message -eq "`n" -and $Type -eq 'Info' } -Verifiable { }
        Mock 'Write-Autonance' -ModuleName $moduleName -ParameterFilter { $Message -eq "Maintenance Outer" -and $Type -eq 'Container' } -Verifiable { }
        Mock 'Write-Autonance' -ModuleName $moduleName -ParameterFilter { $Message -like "Autonance Version *.*.*`nCopyright (c) 2017 by Claudio Spizzi. Licensed under MIT license." -and $Type -eq 'Info' } -Verifiable { }

        It 'should show header and output' {

            # Act
            Maintenance 'Outer' { }

            # Assert
            Assert-MockCalled 'Write-Autonance' -ModuleName $moduleName -Times 4 -Exactly
        }

        It 'should execute the script block' {

            # Act
            Maintenance 'Outer' { Get-Help }

            # Assert
            Assert-MockCalled 'Get-Help' -Times 1 -Exactly
        }
    }

    Context 'Default' {

        It 'should not allow nested Maintenance containers' {

            # Act & Assert
            { Maintenance 'Outer' -NoHeader -NoOutput { Maintenance 'Inner' { } } } | Should Throw
        }
    }
}
