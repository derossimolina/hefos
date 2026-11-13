<#
.SYNOPSIS
  Etapa 0 do HefOS: copia para o disco externo tudo o que precisa sobreviver ao Dia D.
.DESCRIPTION
  Copia, com robocopy (pode ser interrompido e retomado: na segunda vez só copia o que mudou):
    - D:\ inteiro (exceto lixeira e pastas de sistema)          -> <Dest>\hefos-backup\D
    - ~\Downloads e ~\OneDrive                                  -> <Dest>\hefos-backup\C-home
    - ~\.ssh, ~\.aws, ~\.claude, ~\.gitconfig (itens sensíveis) -> <Dest>\hefos-backup\sensiveis
  Por padrão pula pastas que se recriam (node_modules, .venv, venv, __pycache__, target, .next, dist).

  Códigos de saída: 0 tudo copiado (e conferido, com -Verify), 1 falha ou diferença, 2 pré-requisito.
.EXAMPLE
  powershell -NoProfile -File docs/migration/backup-to-external.ps1 -Dest F:\ -DryRun
  powershell -NoProfile -File docs/migration/backup-to-external.ps1 -Dest F:\ -Verify
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Dest,
  [switch]$DryRun,             # só simula (robocopy /L): nada é copiado
  [switch]$Verify,             # depois da cópia, confere se ainda falta algum arquivo
  [switch]$IncludeRegenerable  # copia também node_modules, .venv etc.
)

function Fail([string]$msg) { Write-Host "ERRO: $msg"; exit 2 }

function Get-DiskNumber([string]$path) {
  $letter = ([IO.Path]::GetPathRoot((Resolve-Path -LiteralPath $path).ProviderPath)).Substring(0, 1)
  $p = Get-Partition -DriveLetter $letter -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($p) { $p.DiskNumber } else { $null }
}

# ---------- Pré-requisitos ----------
if (-not (Test-Path -LiteralPath $Dest -PathType Container)) { Fail "o destino '$Dest' não existe. Conecte o disco externo e confira a letra." }

$destDisk = Get-DiskNumber $Dest
foreach ($src in @('C:\', 'D:\')) {
  if (-not (Test-Path -LiteralPath $src)) { continue }
  if ($null -ne $destDisk -and $destDisk -eq (Get-DiskNumber $src)) {
    Fail "o destino '$Dest' está no mesmo disco físico do $src. Use um disco externo."
  }
}

$root = Join-Path $Dest 'hefos-backup'
$regen = @('node_modules', '.venv', 'venv', '__pycache__', 'target', '.next', 'dist')
$alwaysSkip = @('$RECYCLE.BIN', 'System Volume Information', 'Cofre Pessoal', 'Personal Vault', 'OneDriveTemp')

# ---------- Espaço livre ----------
$needGB = 0
if (Test-Path 'D:\') { $needGB += (Get-PSDrive D).Used / 1GB }
$needGB += 10   # Downloads, OneDrive e itens sensíveis (~7 GB) com folga
$destDrive = Get-PSDrive -Name ([IO.Path]::GetPathRoot((Resolve-Path -LiteralPath $Dest).ProviderPath).Substring(0, 1))
$freeGB = $destDrive.Free / 1GB
Write-Host ("Destino: {0}  livre: {1:N0} GB  necessário (estimativa máxima): {2:N0} GB" -f $root, $freeGB, $needGB)
if (-not $DryRun -and $freeGB -lt $needGB) {
  Write-Host 'AVISO: pode faltar espaço. As pastas regeneráveis já são puladas; se ainda faltar, libere espaço no destino.'
}

# ---------- Tarefas ----------
$jobs = @(
  @{ Name = 'D';         Src = 'D:\';                     Dst = Join-Path $root 'D' },
  @{ Name = 'downloads'; Src = (Join-Path $HOME 'Downloads'); Dst = Join-Path $root 'C-home\Downloads' },
  @{ Name = 'onedrive';  Src = (Join-Path $HOME 'OneDrive');  Dst = Join-Path $root 'C-home\OneDrive' },
  @{ Name = 'ssh';       Src = (Join-Path $HOME '.ssh');      Dst = Join-Path $root 'sensiveis\.ssh' },
  @{ Name = 'aws';       Src = (Join-Path $HOME '.aws');      Dst = Join-Path $root 'sensiveis\.aws' },
  @{ Name = 'claude';    Src = (Join-Path $HOME '.claude');   Dst = Join-Path $root 'sensiveis\.claude' },
  @{ Name = 'gitconfig'; Src = $HOME;                         Dst = Join-Path $root 'sensiveis'; File = '.gitconfig' }
)

$logDir = Join-Path $root 'logs'
if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

function Invoke-Robo([hashtable]$job, [switch]$ListOnly) {
  $xd = $alwaysSkip
  if (-not $IncludeRegenerable) { $xd = $xd + $regen }
  $ra = @($job.Src, $job.Dst)
  if ($job.File) { $ra += $job.File } else { $ra += '/E' }
  # /FFT: tolerância de 2 s nos horários (discos exFAT/FAT); /XJ: não segue junções
  $ra += @('/COPY:DAT', '/DCOPY:T', '/R:1', '/W:1', '/XJ', '/FFT', '/MT:8', '/NP', '/NFL', '/NDL', '/XD') + $xd
  if ($ListOnly) { $ra += '/L' }
  else { $ra += "/LOG+:$(Join-Path $logDir "$($job.Name).log")"; $ra += '/TEE' }
  & robocopy @ra | Out-Host
  $LASTEXITCODE
}

$failed = @()
foreach ($job in $jobs) {
  if (-not (Test-Path -LiteralPath $job.Src)) { Write-Host "-- $($job.Name): origem não existe, pulando."; continue }
  Write-Host "== $($job.Name): $($job.Src) -> $($job.Dst)"
  $code = Invoke-Robo $job -ListOnly:$DryRun
  if ($code -ge 8) { $failed += "$($job.Name) (robocopy $code)" }
}

if ($Verify -and -not $DryRun) {
  Write-Host '== Conferência: procurando arquivos que ainda faltam no destino ...'
  foreach ($job in $jobs) {
    if (-not (Test-Path -LiteralPath $job.Src)) { continue }
    $code = Invoke-Robo $job -ListOnly
    # bit 1 = ainda há arquivos para copiar; >= 8 = erro
    if ($code -ge 8 -or ($code -band 1)) { $failed += "$($job.Name) (conferência: faltam arquivos)" }
  }
}

Write-Host ''
if ($DryRun) { Write-Host 'Simulação concluída. Nada foi copiado.' }
if ($failed.Count -gt 0) {
  Write-Host "FALHAS: $($failed -join '; ')"
  if (-not $DryRun) { Write-Host "Logs em $logDir. Rode de novo: o robocopy retoma de onde parou." }
  exit 1
}
Write-Host 'OK: nenhuma falha.'
exit 0
