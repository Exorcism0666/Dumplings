$Object1 = Invoke-RestMethod -Uri 'https://releases.arc.net/windows/prod/Arc.appinstaller'

# Version
$this.CurrentState.Version = $Object1.AppInstaller.Version

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Object1.AppInstaller.MainPackage.Uri
}
# Récupérer le lien
$Uri = $Object1.AppInstaller.MainPackage.Uri

# Remplacer "x64" par "arm64"
$NewUri = $Uri.Replace("x64", "arm64")

$this.CurrentState.Installer += [ordered]@{
  Architecture = 'arm64'
  InstallerUrl = $NewUri
}

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
