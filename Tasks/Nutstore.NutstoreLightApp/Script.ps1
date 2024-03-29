$Response = Invoke-RestMethod -Uri 'https://www.jianguoyun.com/static/exe/latestVersion'
# x86
$Object1 = $Response.Where({ $_.OS -eq 'windows-lightapp-electron-x86' }, 'First')[0]
# x64
$Object2 = $Response.Where({ $_.OS -eq 'windows-lightapp-electron-x64' }, 'First')[0]
# arm64
$Object3 = $Response.Where({ $_.OS -eq 'windows-lightapp-electron-arm64' }, 'First')[0]

# Version
$this.CurrentState.Version = $Object2.exVer

$Identical = $true
if ((@($Object1, $Object2, $Object3) | Sort-Object -Property 'exVer' -Unique).Count -gt 1) {
  $this.Log('Distinct versions detected', 'Warning')
  $Identical = $false
}

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = $Object1.exUrl
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Object2.exUrl
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'arm64'
  InstallerUrl = $Object3.exUrl
}

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    $this.Print()
    $this.Write()
  }
  'Changed|Updated' {
    $this.Message()
  }
  ({ $_ -match 'Updated' -and $Identical }) {
    $this.Submit()
  }
}
