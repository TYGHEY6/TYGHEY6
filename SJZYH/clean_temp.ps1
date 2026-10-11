$ErrorActionPreference = 'SilentlyContinue'
$targets = @(
  @{ Name = 'UserTemp';  Path = "$env:TEMP" },
  @{ Name = 'ThumbCache'; Path = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" },
  @{ Name = 'ShaderCache'; Path = "$env:LOCALAPPDATA\D3DSCache" }
)
$before = 0
foreach ($t in $targets) { if (Test-Path $t.Path) { $before += (Get-ChildItem $t.Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } }
Get-ChildItem "$env:TEMP" -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter 'thumbcache_*' -Force | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\D3DSCache" -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$after = 0
foreach ($t in $targets) { if (Test-Path $t.Path) { $after += (Get-ChildItem $t.Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } }
Write-Output ("Before: {0:N1} MB -> After: {1:N1} MB, Freed: {2:N1} MB" -f ($before/1MB), ($after/1MB), (($before-$after)/1MB))
ipconfig /flushdns | Out-Null
Write-Output 'DNS cache flushed'
