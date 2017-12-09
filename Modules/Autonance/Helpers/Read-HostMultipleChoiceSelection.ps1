
function Read-HostMultipleChoiceSelection
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Caption,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $ChoiceObject,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ChoiceLabel
    )

    if ($ChoiceObject.Count -ne $ChoiceLabel.Count)
    {
        throw 'ChoiceObject and ChoiceLabel item count do not match.'
    }

    Write-Host ''
    Write-Host $Caption
    Write-Host $Message

    for ($i = 0; $i -lt $ChoiceLabel.Count; $i++)
    {
        Write-Host ('[{0:00}] {1}' -f ($i + 1), $ChoiceLabel[$i])
    }

    Write-Host '(input comma-separated choices or * for all)'

    do
    {
        $rawInputs = Read-Host -Prompt 'Choice'
    }
    while ([String]::IsNullOrWhiteSpace($rawInputs))

    if ($rawInputs -eq '*')
    {
        Write-Output $ChoiceObject
    }
    else
    {
        foreach ($rawInput in $rawInputs.Split(','))
        {
            try
            {
                $rawNumber = [Int32]::Parse($rawInput)

                $rawNumber--

                if ($rawNumber -ge 0 -and $rawNumber -lt $ChoiceLabel.Count)
                {
                    Write-Output $ChoiceObject[$rawNumber]
                }
                else
                {
                    throw
                }
            }
            catch
            {
                Write-Warning "Unable to parse input '$rawInput'"
            }
        }
    }
}
