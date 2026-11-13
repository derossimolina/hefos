BeforeAll {
  Import-Module "$PSScriptRoot/../../docs/migration/Inventory.psm1" -Force

  function New-Repo([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    git -C $Path init -q -b main 2>$null
    git -C $Path -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
    (Resolve-Path -LiteralPath $Path).ProviderPath
  }

  function New-RepoWithRemote([string]$Path) {
    $bare = "$Path.remote.git"
    git init -q --bare $bare 2>$null
    $repo = New-Repo $Path
    git -C $repo remote add origin $bare
    git -C $repo push -q -u origin main 2>$null
    $repo
  }
}

Describe 'Find-GitRepos' {
  BeforeAll {
    $root = Join-Path $TestDrive 'scan'
    $repoComAcento     = New-Repo (Join-Path $root 'J de Rossi Molina/projeto ção')
    $repoEmNodeModules = New-Repo (Join-Path $root 'app/node_modules/pkg')
    $repoEmAppData     = New-Repo (Join-Path $root 'AppData/Local/cache')
    $repoPai           = New-Repo (Join-Path $root 'pai')
    $aninhado          = New-Repo (Join-Path $root 'pai/sub/filho')
    $found = @(Find-GitRepos -Roots $root)
  }
  It 'encontra repo em caminho com espaços e acentos' {
    $found | Should -Contain $repoComAcento
  }
  It 'não desce em node_modules' {
    $found | Should -Not -Contain $repoEmNodeModules
  }
  It 'não desce em AppData' {
    $found | Should -Not -Contain $repoEmAppData
  }
  It 'não lista repo aninhado dentro de outro repo' {
    $found | Should -Contain $repoPai
    $found | Should -Not -Contain $aninhado
  }
  It 'respeita MaxDepth' {
    @(Find-GitRepos -Roots $root -MaxDepth 1) | Should -Not -Contain $repoComAcento
  }
}

Describe 'Get-GitRepoStatus' {
  BeforeAll {
    $base = Join-Path $TestDrive 'status'
    $repoSincronizado = New-RepoWithRemote (Join-Path $base 'sync')

    $repoSujo = New-RepoWithRemote (Join-Path $base 'sujo')
    Set-Content -LiteralPath (Join-Path $repoSujo 'a.txt') -Value a
    Set-Content -LiteralPath (Join-Path $repoSujo 'b.txt') -Value b

    $repoAFrente = New-RepoWithRemote (Join-Path $base 'frente')
    1..3 | ForEach-Object { git -C $repoAFrente -c user.name=t -c user.email=t@t commit -q --allow-empty -m "c$_" }

    $repoSemRemote = New-Repo (Join-Path $base 'semremote')

    $repoDetached = New-RepoWithRemote (Join-Path $base 'detached')
    git -C $repoDetached checkout -q --detach 2>$null
  }
  It 'repo limpo e sincronizado não fica pendente' {
    $s = Get-GitRepoStatus $repoSincronizado
    $s.Pending | Should -BeFalse
    $s.Unpushed | Should -Be 0
    $s.Branch | Should -Be 'main'
  }
  It 'conta arquivos não commitados' {
    $s = Get-GitRepoStatus $repoSujo
    $s.Uncommitted | Should -Be 2
    $s.Pending | Should -BeTrue
  }
  It 'conta commits sem push' {
    (Get-GitRepoStatus $repoAFrente).Unpushed | Should -Be 3
  }
  It 'sem upstream fica pendente com Unpushed nulo' {
    $s = Get-GitRepoStatus $repoSemRemote
    $s.NoUpstream | Should -BeTrue
    $s.HasRemote | Should -BeFalse
    $s.Unpushed | Should -BeNullOrEmpty
    $s.Pending | Should -BeTrue
  }
  It 'HEAD destacado fica pendente' {
    $s = Get-GitRepoStatus $repoDetached
    $s.Branch | Should -Be '(detached)'
    $s.Pending | Should -BeTrue
  }
}

Describe 'Get-SensitiveItems' {
  It 'marca caminho inexistente sem erro' {
    $r = Get-SensitiveItems -Paths @{ x = "$TestDrive/nao-existe" }
    $r.Name | Should -Be 'x'
    $r.Exists | Should -BeFalse
    $r.SizeMB | Should -Be 0
  }
  It 'soma o tamanho de diretório existente' {
    $d = Join-Path $TestDrive 'sens'
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $d 'f.bin'), (New-Object byte[] 200000))
    $r = Get-SensitiveItems -Paths @{ s = $d }
    $r.Exists | Should -BeTrue
    $r.SizeMB | Should -BeGreaterThan 0
  }
}

Describe 'Get-DriveLayout' {
  It 'devolve as propriedades esperadas' {
    $l = Get-DriveLayout
    $l.PSObject.Properties.Name | Should -Contain 'DExists'
    $l.PSObject.Properties.Name | Should -Contain 'DIsSeparateDisk'
    $l.PSObject.Properties.Name | Should -Contain 'CDiskModel'
    $l.PSObject.Properties.Name | Should -Contain 'DDiskSizeGB'
    $l.DExists | Should -BeOfType [bool]
  }
}

Describe 'Format-InventoryReport' {
  BeforeAll {
    $pendente = [pscustomobject]@{ Path = 'D:\p\a'; Branch = 'main'; Uncommitted = 0; Unpushed = $null; NoUpstream = $true; HasRemote = $false; Pending = $true }
    $ok       = [pscustomobject]@{ Path = 'D:\p\b'; Branch = 'main'; Uncommitted = 0; Unpushed = 0; NoUpstream = $false; HasRemote = $true; Pending = $false }
    $drv = [pscustomobject]@{ DExists = $true; DIsSeparateDisk = $true; CDiskModel = 'SSD'; DDiskModel = 'HD'; CDiskSizeGB = 111.8; DDiskSizeGB = 931.5 }
    $txt = Format-InventoryReport -Repos @($pendente, $ok) -Drives $drv -Items @()
  }
  It 'conta pendentes de repos e termina com PENDENTES: n' {
    $txt | Should -Match 'PENDENTES: 1$'
    $txt | Should -Match '## Repositórios pendentes'
    $txt | Should -Match '## Repositórios ok'
    $txt | Should -Match '## Discos'
    $txt | Should -Match '## Itens para backup manual'
  }
  It 'mostra NoUpstream como "sem upstream", não como 0' {
    $txt | Should -Match 'sem upstream'
  }
  It 'diz que D: é disco separado' {
    $txt | Should -Match 'disco físico separado'
  }
}

Describe 'windows-inventory.ps1' {
  BeforeAll {
    $script = "$PSScriptRoot/../../docs/migration/windows-inventory.ps1"
    $ps = (Get-Process -Id $PID).Path
    $fixtureComPendente = Join-Path $TestDrive 'fx'
    New-Repo (Join-Path $fixtureComPendente 'semremote') | Out-Null
  }
  It 'sai com 2 e mensagem clara quando nenhuma raiz existe' {
    $out = & $ps -NoProfile -File $script -Roots "$TestDrive/nada" -OutFile "$TestDrive/r0.md" -SkipSensitive 2>&1
    $LASTEXITCODE | Should -Be 2
    ($out -join "`n") | Should -Match 'Nenhuma raiz'
  }
  It 'sai com 1 quando há repo pendente' {
    & $ps -NoProfile -File $script -Roots $fixtureComPendente -OutFile "$TestDrive/r.md" -SkipSensitive | Out-Null
    $LASTEXITCODE | Should -Be 1
    "$TestDrive/r.md" | Should -Exist
  }
}
