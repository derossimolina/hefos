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
