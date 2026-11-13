Set-StrictMode -Version 2.0

# Diretórios onde a varredura nunca entra (árvores enormes ou de sistema).
$script:SkipDirs = @(
  'node_modules', '.venv', 'venv', 'target', '.git',
  '$RECYCLE.BIN', 'System Volume Information'
)

function Invoke-Git {
  # Roda git num repo sem lançar erro; devolve saída e código.
  param([string]$Path, [string[]]$GitArgs)
  # No PowerShell 5.1, stderr de comando nativo vira erro fatal se o chamador usa 'Stop'.
  $ErrorActionPreference = 'Continue'
  $out =& git -c safe.directory=* -C $Path @GitArgs 2>$null
  [pscustomobject]@{ Output = @($out); ExitCode = $LASTEXITCODE }
}

function Find-GitRepos {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string[]]$Roots,
    [int]$MaxDepth = 5
  )
  $found = New-Object System.Collections.Generic.List[string]
  $stack = New-Object System.Collections.Stack

  foreach ($root in $Roots) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    $full = (Resolve-Path -LiteralPath $root).ProviderPath
    $stack.Push(@($full, 0))
  }

  while ($stack.Count -gt 0) {
    $item = $stack.Pop()
    $dir = $item[0]; $depth = $item[1]

    if (Test-Path -LiteralPath (Join-Path $dir '.git')) {
      $found.Add($dir)
      continue   # não procura repos aninhados
    }
    if ($depth -ge $MaxDepth) { continue }

    $children = Get-ChildItem -LiteralPath $dir -Directory -Force -ErrorAction SilentlyContinue
    foreach ($c in $children) {
      if ($script:SkipDirs -contains $c.Name) { continue }
      # Junções e links simbólicos (ex.: "Application Data") geram loops.
      if ($c.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      $stack.Push(@($c.FullName, ($depth + 1)))
    }
  }
  $found | Sort-Object
}

function Get-GitRepoStatus {
  [CmdletBinding()]
  param([Parameter(Mandatory, Position = 0)][string]$Path)

  $branch = (Invoke-Git $Path @('rev-parse', '--abbrev-ref', 'HEAD')).Output | Select-Object -First 1
  if (-not $branch -or $branch -eq 'HEAD') { $branch = '(detached)' }

  $porcelain = (Invoke-Git $Path @('status', '--porcelain')).Output | Where-Object { $_ }
  $uncommitted = @($porcelain).Count

  $remotes = (Invoke-Git $Path @('remote')).Output | Where-Object { $_ }
  $hasRemote = @($remotes).Count -gt 0

  $ahead = Invoke-Git $Path @('rev-list', '--count', '@{u}..HEAD')
  if ($ahead.ExitCode -eq 0 -and $ahead.Output.Count -gt 0) {
    $unpushed = [int]$ahead.Output[0]; $noUpstream = $false
  } else {
    $unpushed = $null; $noUpstream = $true
  }

  [pscustomobject]@{
    Path        = $Path
    Branch      = $branch
    Uncommitted = $uncommitted
    Unpushed    = $unpushed
    NoUpstream  = $noUpstream
    HasRemote   = $hasRemote
    Pending     = ($uncommitted -gt 0 -or $noUpstream -or $unpushed -gt 0 -or $branch -eq '(detached)')
  }
}

function Get-DriveLayout {
  [CmdletBinding()]
  param()
  $c = Get-Partition -DriveLetter C -ErrorAction SilentlyContinue | Select-Object -First 1
  $d = Get-Partition -DriveLetter D -ErrorAction SilentlyContinue | Select-Object -First 1
  $cDisk = if ($c) { Get-Disk -Number $c.DiskNumber -ErrorAction SilentlyContinue } else { $null }
  $dDisk = if ($d) { Get-Disk -Number $d.DiskNumber -ErrorAction SilentlyContinue } else { $null }

  $separate = $null
  if ($c -and $d) { $separate = [bool]($c.DiskNumber -ne $d.DiskNumber) }

  [pscustomobject]@{
    DExists         = [bool]$d
    DIsSeparateDisk = $separate
    CDiskModel      = if ($cDisk) { $cDisk.FriendlyName } else { $null }
    DDiskModel      = if ($dDisk) { $dDisk.FriendlyName } else { $null }
    CDiskSizeGB     = if ($cDisk) { [math]::Round($cDisk.Size / 1GB, 1) } else { $null }
    DDiskSizeGB     = if ($dDisk) { [math]::Round($dDisk.Size / 1GB, 1) } else { $null }
    CDiskBusType    = if ($cDisk) { [string]$cDisk.BusType } else { $null }
  }
}

function Get-SensitiveItems {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable]$Paths)
  foreach ($name in ($Paths.Keys | Sort-Object)) {
    $p = $Paths[$name]
    $exists = Test-Path -LiteralPath $p
    $bytes = 0
    if ($exists) {
      $item = Get-Item -LiteralPath $p -Force
      if ($item.PSIsContainer) {
        $sum = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        if ($sum) { $bytes = $sum }
      } else {
        $bytes = $item.Length
      }
    }
    [pscustomobject]@{
      Name   = $name
      Path   = $p
      Exists = [bool]$exists
      SizeMB = [math]::Round($bytes / 1MB, 2)
    }
  }
}

function Format-InventoryReport {
  [CmdletBinding()]
  param(
    [object[]]$Repos = @(),
    [Parameter(Mandatory)][object]$Drives,
    [object[]]$Items = @()
  )
  $pending = @($Repos | Where-Object { $_.Pending })
  $ok      = @($Repos | Where-Object { -not $_.Pending })
  $tick = [char]96
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('# Inventário do Windows — HefOS etapa 0')
  $lines.Add('')
  $lines.Add("Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm').")
  $lines.Add('')

  $lines.Add('## Repositórios pendentes')
  $lines.Add('')
  if ($pending.Count -eq 0) {
    $lines.Add('Nenhum.')
  } else {
    $lines.Add('| Repositório | Branch | Não commitados | Sem push | Remote |')
    $lines.Add('|---|---|---|---|---|')
    foreach ($r in $pending) {
      $push = if ($r.NoUpstream) { 'sem upstream' } else { [string]$r.Unpushed }
      $rem  = if ($r.HasRemote) { 'sim' } else { 'não' }
      $lines.Add("| $tick$($r.Path)$tick | $($r.Branch) | $($r.Uncommitted) | $push | $rem |")
    }
  }
  $lines.Add('')

  $lines.Add('## Repositórios ok')
  $lines.Add('')
  $lines.Add("$($ok.Count) repositório(s) limpos e sincronizados.")
  $lines.Add('')

  $lines.Add('## Discos')
  $lines.Add('')
  $lines.Add("- C: $($Drives.CDiskModel) ($($Drives.CDiskSizeGB) GB)")
  if (-not $Drives.DExists) {
    $lines.Add('- D: não existe')
  } else {
    if ($Drives.DIsSeparateDisk -eq $true) { $kind = 'disco físico separado' }
    elseif ($Drives.DIsSeparateDisk -eq $false) { $kind = 'partição no mesmo disco do C: (será apagada no Dia D!)' }
    else { $kind = 'indeterminado' }
    $lines.Add("- D: $($Drives.DDiskModel) ($($Drives.DDiskSizeGB) GB) — $kind")
  }
  if (($Drives.PSObject.Properties.Name -contains 'CDiskBusType') -and $Drives.CDiskBusType -eq 'RAID') {
    $lines.Add('- **Atenção:** o controlador está em modo RAID (Intel RST). Mude para AHCI na BIOS antes do Dia D (ver runbook).')
  }
  $lines.Add('')

  $lines.Add('## Itens para backup manual')
  $lines.Add('')
  if (@($Items).Count -eq 0) {
    $lines.Add('Nenhum item verificado.')
  } else {
    $lines.Add('| Item | Caminho | Existe | Tamanho (MB) |')
    $lines.Add('|---|---|---|---|')
    foreach ($i in $Items) {
      $e = if ($i.Exists) { 'sim' } else { 'não encontrado' }
      $lines.Add("| $($i.Name) | $tick$($i.Path)$tick | $e | $($i.SizeMB) |")
    }
  }
  $lines.Add('')
  $lines.Add("PENDENTES: $($pending.Count)")
  $lines -join "`n"
}

Export-ModuleMember -Function Find-GitRepos, Get-GitRepoStatus, Get-DriveLayout, Get-SensitiveItems, Format-InventoryReport
