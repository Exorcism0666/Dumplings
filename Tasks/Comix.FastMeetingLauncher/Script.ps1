function Get-ReleaseTime {
  try {
    # ReleaseTime
    $this.CurrentState.ReleaseTime = [regex]::Match($Object2.InnerText, '发布日期：(\d{4}-\d{1,2}-\d{1,2})').Groups[1].Value | Get-Date -Format 'yyyy-MM-dd'
  } catch {
    $_ | Out-Host
    $this.Log($_, 'Warning')
  }
}

$Object1 = Invoke-WebRequest -Uri 'https://www.hst.com/pages/download/tools/' | ConvertFrom-Html
$Object2 = $Object1.SelectSingleNode('//div[@class="list-date-dark-right" and contains(., "好视通启动助手")]')

# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerUrl = $Object2.SelectSingleNode('.//a[contains(@href, ".exe")]').Attributes['href'].Value
}

$Object3 = Invoke-WebRequest -Uri $this.CurrentState.Installer[0].InstallerUrl -Method Head
# ETag
$ETag = $Object3.Headers.ETag[0]

# Case 0: Force submit the manifest
if ($Global:DumplingsPreference.Contains('Force')) {
  $this.Log('Skip checking states', 'Info')

  # ETag
  $this.CurrentState.ETag = @($ETag)

  $InstallerFile = Get-TempFile -Uri $this.CurrentState.Installer[0].InstallerUrl
  # Version
  $this.CurrentState.Version = $InstallerFile | Read-ProductVersionFromExe
  # InstallerSha256
  $this.CurrentState.Installer[0]['InstallerSha256'] = (Get-FileHash -Path $InstallerFile -Algorithm SHA256).Hash

  Get-ReleaseTime

  $this.Print()
  $this.Write()
  $this.Message()
  $this.Submit()
  return
}

# Case 1: The task is newly created
if ($this.Status.Contains('New')) {
  $this.Log('New task', 'Info')

  # ETag
  $this.CurrentState.ETag = @($ETag)

  $InstallerFile = Get-TempFile -Uri $this.CurrentState.Installer[0].InstallerUrl
  # Version
  $this.CurrentState.Version = $InstallerFile | Read-ProductVersionFromExe
  # InstallerSha256
  $this.CurrentState.Installer[0]['InstallerSha256'] = (Get-FileHash -Path $InstallerFile -Algorithm SHA256).Hash

  Get-ReleaseTime

  $this.Print()
  $this.Write()
  return
}

# Case 2: The ETag was not updated
if ($ETag -in $this.LastState.ETag) {
  $this.Log("The version $($this.LastState.Version) from the last state is the latest", 'Info')
  return
}

$InstallerFile = Get-TempFile -Uri $this.CurrentState.Installer[0].InstallerUrl
# Version
$this.CurrentState.Version = $InstallerFile | Read-ProductVersionFromExe
# InstallerSha256
$this.CurrentState.Installer[0]['InstallerSha256'] = (Get-FileHash -Path $InstallerFile -Algorithm SHA256).Hash

# Case 3: The installer file has an invalid version
if ([string]::IsNullOrWhiteSpace($this.CurrentState.Version)) {
  throw 'The current state has an invalid version'
}

Get-ReleaseTime

# Case 4: The ETag was updated, but the hash wasn't
if ($this.CurrentState.Installer[0].InstallerSha256 -eq $this.LastState.Installer[0].InstallerSha256) {
  $this.Log('The ETag was changed, but the hash is the same', 'Info')

  # ETag
  $this.CurrentState.ETag = $this.LastState.ETag + $ETag

  $this.Write()
  return
}

# ETag
$this.CurrentState.ETag = @($ETag)

switch -Regex ($this.Check()) {
  # Case 6: The ETag, hash, and version were updated
  'Updated|Rollbacked' {
    $this.Print()
    $this.Write()
    $this.Message()
    $this.Submit()
  }
  # Case 5: Both the ETag and the hash were updated, but the version wasn't
  Default {
    $this.Log('The ETag and the hash were changed, but the version is the same', 'Info')
    $this.Config.IgnorePRCheck = $true
    $this.Print()
    $this.Write()
    $this.Message()
    $this.Submit()
  }
}