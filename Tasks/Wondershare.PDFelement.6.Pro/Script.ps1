$this.CurrentState = Invoke-WondershareXmlUpgradeApi -ProductId 2990 -Version '6.0.0.0' -Locale 'en-US'

# Installer
$this.CurrentState.Installer += $Installer = [ordered]@{
  InstallerUrl = 'https://download.wondershare.com/cbs_down/pdfelement6-pro_full2990.exe'
}

switch ($this.Check()) {
  ({ $_ -ge 1 }) {
    $InstallerFile = Get-TempFile -Uri $Installer.InstallerUrl

    # InstallerSha256
    $Installer['InstallerSha256'] = (Get-FileHash -Path $InstallerFile -Algorithm SHA256).Hash
    # RealVersion
    $this.CurrentState.RealVersion = $InstallerFile | Read-ProductVersionFromExe

    $this.Write()
  }
  ({ $_ -ge 2 }) {
    $this.Print()
    $this.Message()
  }
  ({ $_ -ge 3 }) {
    $this.Submit()
  }
}
