param([string]$GodotBinary = '', [string[]]$TestNames = @())
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
if (-not $GodotBinary) { $GodotBinary = Join-Path (Split-Path $taskRoot -Parent) '.godot_check/Godot_v4.7-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $GodotBinary)) { throw "Godot executable missing: $GodotBinary" }
$tests = @('special_reversal_check','special_ai_situation_check','special_grapple_guard_check','stage9_two_hit_qa','stage9_cleanup_qa','cross_muei_check','crusher_reversal_presentation_check','rei_reversal_presentation_check','combat_pose_flow_check','st_action_fix_regression','stage5_6_motion_atlas','stage7_8_motion_atlas','stage5_shadow_boxer_regression','dev052_visual_check','dev053_stage1_smoke','dev056_enemy_air_attack_smoke','dev061_enemy_pressure_smoke','dev062_guard_counterplay_smoke','dev063_special_gauge_balance_smoke','dev064_archetype_balance_smoke','dev065_double_tap_mobility_smoke','dev066_character_backstep_ai_smoke','akky_motion_atlas','gou_motion_atlas','seiya_motion_atlas','stage1_regression','stage2_regression','stage3_regression','stage4_regression','japanese_font_smoke','opening_flow_smoke','stage8_ending_check','true_seiya_combat_check','dark_seiya_combat_check')
if ($TestNames.Count) { $tests = @($tests | Where-Object { $_ -in $TestNames }) }
$outDir = Join-Path $taskRoot 'evidence/handoff_checks'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$results = @()
$originalAppData = $env:APPDATA
try {
    foreach ($testName in $tests) {
        $env:APPDATA = Join-Path $outDir "runtime/$testName"
        $logPath = Join-Path $outDir "$testName.log"
        if ($testName -in @('stage9_two_hit_qa','stage9_cleanup_qa')) {
            & $GodotBinary --headless --fixed-fps 60 --quit-after 60000 --path (Join-Path $taskRoot 'godot') "res://tests/$testName.tscn" *> $logPath
        } else {
            & $GodotBinary --headless --fixed-fps 60 --quit-after 60000 --path (Join-Path $taskRoot 'godot') --script "res://tests/$testName.gd" *> $logPath
        }
        $code = $LASTEXITCODE
        $logText = Get-Content -LiteralPath $logPath -Raw
        $warningLines = @($logText -split "`n" | Where-Object { $_ -match '^WARNING:' })
        $errorLines = @($logText -split "`n" | Where-Object { $_ -match 'SCRIPT ERROR:|^ERROR:' })
        $completed = $logText -match '_OK|failures=\[\]|failures=0'
        $functionalPassed = $code -eq 0 -and $errorLines.Count -eq 0 -and $completed
        $passed = $functionalPassed -and $warningLines.Count -eq 0
        $results += [pscustomobject]@{ test=$testName; exit=$code; passed=$passed; functionalPassed=$functionalPassed; warnings=$warningLines; errors=$errorLines; completed=$completed; log=$logPath }
        Write-Output "TEST $testName EXIT=$code PASS=$passed"
    }
} finally { $env:APPDATA = $originalAppData }
if ($TestNames.Count -and (Test-Path (Join-Path $outDir 'test-results.json'))) {
    $oldResults = @(Get-Content (Join-Path $outDir 'test-results.json') -Raw | ConvertFrom-Json)
    $results = @($oldResults | Where-Object { $_.test -notin $tests }) + $results
}
# Normalize older result entries from their saved logs after a selective run.
foreach ($entry in $results) {
    $savedText = Get-Content -LiteralPath $entry.log -Raw
    $savedErrors = @($savedText -split "`n" | Where-Object { $_ -match 'SCRIPT ERROR:|^ERROR:' })
    $savedWarnings = @($savedText -split "`n" | Where-Object { $_ -match '^WARNING:' })
    $functional = $entry.exit -eq 0 -and $savedErrors.Count -eq 0 -and $entry.completed
    $entry | Add-Member -Force -NotePropertyName errors -NotePropertyValue $savedErrors
    $entry | Add-Member -Force -NotePropertyName warnings -NotePropertyValue $savedWarnings
    $entry | Add-Member -Force -NotePropertyName functionalPassed -NotePropertyValue $functional
    $entry | Add-Member -Force -NotePropertyName passed -NotePropertyValue ($functional -and $savedWarnings.Count -eq 0)
}
$results | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $outDir 'test-results.json')
if (@($results | Where-Object { -not $_.passed }).Count) { exit 1 }
