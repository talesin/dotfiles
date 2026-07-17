param(
    [string]$InputLine   = '',
    [int]   $CursorPos   = -1,
    [string]$WorkingDir  = ''
)

if ($CursorPos -lt 0) { $CursorPos = $InputLine.Length }
if ($WorkingDir -and (Test-Path $WorkingDir -PathType Container)) {
    Set-Location $WorkingDir
}

$result = [System.Management.Automation.CommandCompletion]::CompleteInput(
    $InputLine, $CursorPos, $null
)

foreach ($c in $result.CompletionMatches) {
    Write-Output $c.CompletionText
}
