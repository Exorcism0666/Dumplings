# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerUrl = $InstallerUrl = Get-RedirectedUrl1st -Uri 'https://download.10jqka.com.cn/index/download/id/689/'
}

# Version
$this.CurrentState.Version = [regex]::Match($InstallerUrl, 'iwc_?(\d+(?:\.\d+){2,})').Groups[1].Value

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