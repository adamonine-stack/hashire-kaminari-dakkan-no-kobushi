$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$exe = Join-Path (Split-Path $taskRoot -Parent) '.godot_check/Godot_v4.7-stable_win64_console.exe'
$tests = @('st_action_fix_regression','stage5_6_motion_atlas','stage7_8_motion_atlas','stage5_shadow_boxer_regression','dev052_visual_check','dev053_stage1_smoke','dev056_enemy_air_attack_smoke','dev061_enemy_pressure_smoke','dev062_guard_counterplay_smoke','dev063_special_gauge_balance_smoke','dev064_archetype_balance_smoke','dev065_double_tap_mobility_smoke','dev066_character_backstep_ai_smoke','akky_motion_atlas','gou_motion_atlas','seiya_motion_atlas','stage1_regression','stage2_regression','stage3_regression','stage4_regression','japanese_font_smoke','opening_flow_smoke')
$tests += @('stage8_ending_check','true_seiya_combat_check','dark_seiya_combat_check')
$results = @()
foreach ($testName in $tests) {
    $env:APPDATA = Join-Path $taskRoot "evidence/runtime/$testName"
    $logPath = Join-Path $taskRoot "evidence/$testName.log"
    & $exe --headless --fixed-fps 60 --quit-after 60000 --path (Join-Path $taskRoot 'godot') --script "res://tests/$testName.gd" *> $logPath
    $code = $LASTEXITCODE
    $logText = Get-Content -LiteralPath $logPath -Raw
    $errorLines = @($logText -split "`n" | Where-Object { $_ -match 'SCRIPT ERROR:|^ERROR:' })
    $completed = $logText -match '_OK|failures=\[\]|failures=0'
    $passed = $code -eq 0 -and $errorLines.Count -eq 0 -and $completed
    $results += [pscustomobject]@{ test=$testName; exit=$code; passed=$passed; errors=$errorLines; completed=$completed; log=$logPath }
    Write-Output "TEST $testName EXIT=$code PASS=$passed"
}
$results | ConvertTo-Json | Set-Content (Join-Path $taskRoot 'evidence/test-results.json')
