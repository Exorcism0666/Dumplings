$Object1 = Invoke-RestMethod -Uri 'https://www.yy.com/yyweb/download/getLink?id=153'

# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerUrl = $Object1.url
}

# Version
$this.CurrentState.Version = $this.CurrentState.Installer[0].InstallerUrl -replace '.+/yyaudio/(\d+(?:\.\d+){2,})/\d+/(\d+)/.+', '$1.$2'

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    $this.Print()
    $this.Write()
  }
  'Changed|Updated' {
    $this.Message()
  }
  'Updated' {
    $this.Submit()
  }
}
