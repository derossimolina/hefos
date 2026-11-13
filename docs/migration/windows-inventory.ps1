<#
.SYNOPSIS
  Inventário da etapa 0 do HefOS: repositórios git pendentes, discos e itens sensíveis.
.DESCRIPTION
  Códigos de saída: 0 sem pendências, 1 com pendências, 2 erro de pré-requisito.
  Funciona no Windows PowerShell 5.1 e no PowerShell 7.
#>
[CmdletBinding()]
param(
  [string[]]$Roots = @('D:\', $HOME),
  [string]$OutFile = (Join-Path (Get-Location) 'inventory-report.md'),
  [int]$MaxDepth = 5,
  [switch]$SkipSensitive
)

$ErrorActionPreference = 'Stop'
try {
  Import-Module (Join-Path $PSScriptRoot 'Inventory.psm1') -Force

  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'ERRO: git não encontrado no PATH. Instale o Git for Windows e rode de novo.'
    exit 2
  }
  $existing = @($Roots | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) })
  if ($existing.Count -eq 0) {
    Write-Host "ERRO: Nenhuma raiz existe: $($Roots -join ', ')"
    exit 2
  }

  Write-Host "Procurando repositórios em: $($existing -join ', ') ..."
  $repos = @(Find-GitRepos -Roots $existing -MaxDepth $MaxDepth | ForEach-Object { Get-GitRepoStatus $_ })
  $drives = Get-DriveLayout

  $items = @()
  if (-not $SkipSensitive) {
    Write-Host 'Medindo itens sensíveis (pode demorar nos perfis de navegador) ...'
    $items = @(Get-SensitiveItems -Paths @{
      ssh       = Join-Path $HOME '.ssh'
      aws       = Join-Path $HOME '.aws'
      claude    = Join-Path $HOME '.claude'
      gitconfig = Join-Path $HOME '.gitconfig'
      obsidian  = 'D:\new_obsidian'
      chrome    = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
      brave     = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
    })
  }

  $report = Format-InventoryReport -Repos $repos -Drives $drives -Items $items
  [IO.File]::WriteAllText($OutFile, $report, (New-Object System.Text.UTF8Encoding $false))

  $pending = @($repos | Where-Object { $_.Pending }).Count
  Write-Host "Repositórios: $($repos.Count) encontrados, $pending pendentes."
  Write-Host "Relatório: $OutFile"
  if ($pending -gt 0) { exit 1 } else { exit 0 }
}
catch {
  Write-Host "ERRO: $($_.Exception.Message)"
  exit 2
}
