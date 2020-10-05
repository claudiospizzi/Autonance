
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Maintenance' {

    Context 'Script Block Mock' {

        Mock 'Get-Help' -Verifiable { }

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
