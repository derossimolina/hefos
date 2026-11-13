BeforeAll {
  $script = "$PSScriptRoot/../../docs/migration/backup-to-external.ps1"
  $ps = (Get-Process -Id $PID).Path
}

Describe 'backup-to-external.ps1' {
  It 'recusa destino inexistente com código 2' {
    $out = & $ps -NoProfile -File $script -Dest 'Q:\nao-existe' -DryRun 2>&1
    $LASTEXITCODE | Should -Be 2
    ($out -join "`n") | Should -Match 'Conecte o disco externo'
  }
  It 'recusa destino no mesmo disco físico do C:' {
    $out = & $ps -NoProfile -File $script -Dest $env:TEMP -DryRun 2>&1
    $LASTEXITCODE | Should -Be 2
    ($out -join "`n") | Should -Match 'mesmo disco'
  }
  It 'recusa destino no mesmo disco físico do D:' -Skip:(-not (Test-Path 'D:\')) {
    $out = & $ps -NoProfile -File $script -Dest 'D:\' -DryRun 2>&1
    $LASTEXITCODE | Should -Be 2
    ($out -join "`n") | Should -Match 'mesmo disco'
  }
}
