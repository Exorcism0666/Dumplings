$this.CurrentState = Invoke-WondershareXmlUpgradeApi -ProductId 5387 -Version '8.0.0.0' -Locale 'zh-CN'

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = "https://cc-download.wondershare.cc/cbs_down/pdfelement_$($this.CurrentState.Version)_full5387.exe"
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = "https://cc-download.wondershare.cc/cbs_down/pdfelement_64bit_$($this.CurrentState.Version)_full5387.exe"
}

$ToBeSubmitted = $true
if ($this.CurrentState.Version.Split('.')[0] -ne '10') {
  $this.Log('The ProductCode needs to be updated', 'Error')
  $ToBeSubmitted = $false
}

switch ($this.Check()) {
  ({ $_ -ge 1 }) {
    $this.Write()
  }
  ({ $_ -ge 2 }) {
    $this.Print()
    $this.Message()
  }
  ({ $_ -ge 3 -and $ToBeSubmitted }) {
    $this.Submit()
  }
}
