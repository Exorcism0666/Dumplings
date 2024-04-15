# Installer
$this.CurrentState.Installer += $InstallerX86 = [ordered]@{
  Architecture = 'x86'
  InstallerUrl = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise.msi'
}
$Object1 = Invoke-WebRequest -Uri $InstallerX86.InstallerUrl -Method Head -Headers @{'If-Modified-Since' = $this.LastState['LastModifiedX86'] } -SkipHttpErrorCheck
if ($Object1.StatusCode -eq 304) {
  $this.Log("The last version $($this.LastState.Version) is the latest, skip checking", 'Info')
  return
}

$this.CurrentState.Installer += $InstallerX64 = [ordered]@{
  Architecture = 'x64'
  InstallerUrl = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
}
$Object2 = Invoke-WebRequest -Uri $InstallerX64.InstallerUrl -Method Head -Headers @{'If-Modified-Since' = $this.LastState['LastModifiedX64'] } -SkipHttpErrorCheck
if ($Object2.StatusCode -eq 304) {
  $this.Log("The last version $($this.LastState.Version) is the latest, skip checking", 'Info')
  return
}

$InstallerX64File = Get-TempFile -Uri $InstallerX64.InstallerUrl

# InstallerSha256
$InstallerX64['InstallerSha256'] = (Get-FileHash -Path $InstallerX64File -Algorithm SHA256).Hash

# Version
$this.CurrentState.Version = (Read-MsiSummaryValue -Path $InstallerX64File -Name Comments).Split(' ')[0].Trim()

# LastModified
$this.CurrentState.LastModifiedX86 = $Object1.Headers.'Last-Modified'[0]
$this.CurrentState.LastModifiedX64 = $Object2.Headers.'Last-Modified'[0]

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
