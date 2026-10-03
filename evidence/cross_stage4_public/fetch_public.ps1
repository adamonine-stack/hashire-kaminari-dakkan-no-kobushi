param([string]$ReleaseCommit)
$ErrorActionPreference='Stop'
$taskOutput=Join-Path $PSScriptRoot 'verification.json'
$taskBase='https://adamonine-stack.github.io/hashire-kaminari-dakkan-no-kobushi/'
$taskHtml=(Invoke-WebRequest ($taskBase+'?verify='+$ReleaseCommit)).Content
$taskMatch=[regex]::Match($taskHtml,'const GODOT_CONFIG\s*=\s*(\{[^\r\n]+\});')
if(-not $taskMatch.Success){throw 'Godot config missing'}
$taskConfig=$taskMatch.Groups[1].Value | ConvertFrom-Json
if($taskConfig.executable -ne ('game-'+$ReleaseCommit.Substring(0,12))){throw ('Old runtime: '+$taskConfig.executable)}
$taskAssets=@()
foreach($extension in @('.js','.wasm','.pck','.audio.worklet.js','.audio.position.worklet.js')){
 $taskName=$taskConfig.executable+$extension
 $taskResponse=Invoke-WebRequest -Method Head -Uri ($taskBase+$taskName)
 $taskAssets+=@{asset=$taskName;status=[int]$taskResponse.StatusCode}
}
Invoke-WebRequest ($taskBase+$taskConfig.executable+'.pck') -OutFile (Join-Path $PSScriptRoot 'public.pck')
$taskPack=Get-Item (Join-Path $PSScriptRoot 'public.pck')
if($taskPack.Length -ne $taskConfig.fileSizes.($taskConfig.executable+'.pck')){throw 'PCK size mismatch'}
@{release_commit=$ReleaseCommit;pr=170;pages_run=37125923169;public_url=$taskBase;godot_config=$taskConfig;pack_bytes=$taskPack.Length;pack_sha256=(Get-FileHash $taskPack.FullName -Algorithm SHA256).Hash.ToLower();assets=$taskAssets;browser_canvas='Unverified: browser inventory empty; iab unavailable'} | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $taskOutput
Write-Output ('PUBLIC_RUNTIME_OK '+$taskConfig.executable+' bytes='+$taskPack.Length)
