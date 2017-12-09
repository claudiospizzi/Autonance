
function Write-Autonance
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Container', 'Task', 'Action', 'Info')]
        [System.String]
        $Type = 'Action'
    )

    if (!$Script:AutonanceSilent)
    {
        $messageLines = $Message.Split("`n")

        if ($Script:AutonanceBlock)
        {
            $colorSplat = @{}

            switch ($Type)
            {
                'Container'
                {
                    $prefixFirst = '  ' * $Script:AutonanceLevel
                    $prefixOther = '  ' * $Script:AutonanceLevel

                    $colorSplat['ForegroundColor'] = 'Magenta'
                }
                'Task'
                {
                    $prefixFirst = '  ' * $Script:AutonanceLevel
                    $prefixOther = '  ' * $Script:AutonanceLevel

                    $colorSplat['ForegroundColor'] = 'Magenta'
                }
                'Action'
                {
                    $prefixFirst = '  ' * $Script:AutonanceLevel + '  - '
                    $prefixOther = '  ' * $Script:AutonanceLevel + '    '

                    $colorSplat['ForegroundColor'] = 'Cyan'
                }
                'Info'
                {
                    $prefixFirst = '  ' * $Script:AutonanceLevel
                    $prefixOther = '  ' * $Script:AutonanceLevel
                }
            }

            $messageLines = "$prefixFirst$($messageLines -join "`n$prefixOther")".Split("`n")

            if ($Type -eq 'Info')
            {
                $messageLines | Write-Host
            }
            else
            {
                for ($i = 0; $i -lt $messageLines.Count; $i++)
                {
                    if ($null -eq $Script:AutonanceTimestamp)
                    {
                        $Script:AutonanceTimestamp = Get-Date

                        $timestamp = '{0:dd.MM.yyyy HH:mm:ss}   00:00:00' -f $Script:AutonanceTimestamp
                    }
                    else
                    {
                        $timestamp = ((Get-Date) - $Script:AutonanceTimestamp).ToString('hh\:mm\:ss')
                    }

                    $timestampWidth = $Host.UI.RawUI.WindowSize.Width - $messageLines[$i].Length - 4

                    if ($i -eq 0 -and $timestampWidth -ge $timestamp.Length)
                    {
                        Write-Host -Object $messageLines[$i] @colorSplat -NoNewline
                        Write-Host -Object ("   {0,$timestampWidth}" -f $timestamp) -ForegroundColor 'DarkGray'
                    }
                    else
                    {
                        Write-Host -Object $messageLines[$i] @colorSplat
                    }
                }
            }
        }
        else
        {
            foreach ($messageLine in $messageLines)
            {
                Write-Verbose $messageLine
            }
        }
    }
}
