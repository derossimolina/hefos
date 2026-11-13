Set-StrictMode -Version 2.0

# Diretórios onde a varredura nunca entra (árvores enormes ou de sistema).
$script:SkipDirs = @(
  'node_modules', '.venv', 'venv', 'target', '.git',
  '$RECYCLE.BIN', 'System Volume Information'
)

function Invoke-Git {
  # Roda git num repo sem lançar erro; devolve saída e código.
  param([string]$Path, [string[]]$GitArgs)
  $out = & git -c safe.directory=* -C $Path @GitArgs 2>$null
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

Export-ModuleMember -Function Find-GitRepos, Get-GitRepoStatus
