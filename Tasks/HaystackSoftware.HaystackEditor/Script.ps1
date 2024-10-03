$EdgeDriver = Get-EdgeDriver
$EdgeDriver.Navigate().GoToUrl('https://haystackeditor.com/')

$EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath('//p[text()="Download"]')).Click()

# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerUrl = $InstallerUrl = $EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath('//a[contains(@href, ".exe")]')).GetAttribute('href')
}

# Version
$this.CurrentState.Version = [regex]::Match($InstallerUrl, 'Setup-(\d+(?:\.\d+)+)').Groups[1].Value

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    try {
      $EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath('//a[text()="Changelog"]')).Click()

      $ReleaseNotesObject = $EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath("//div[contains(./p/strong/text(), '$($this.CurrentState.Version)')]")).GetAttribute('innerHTML') | ConvertFrom-Html
      # ReleaseNotes (en-US)
      $this.CurrentState.Locale += [ordered]@{
        Locale = 'en-US'
        Key    = 'ReleaseNotes'
        Value  = $ReleaseNotesObject.SelectNodes("./p[contains(./strong/text(), '$($this.CurrentState.Version)')]/following-sibling::node()") | Get-TextContent | Format-Text
      }
    } catch {
      $_ | Out-Host
      $this.Log($_, 'Warning')
    }

    $InstallerFile = Get-TempFile -Uri $this.CurrentState.Installer[0].InstallerUrl

    # InstallerSha256
    $this.CurrentState.Installer[0]['InstallerSha256'] = (Get-FileHash -Path $InstallerFile -Algorithm SHA256).Hash
    # RealVersion
    $this.CurrentState.RealVersion = $InstallerFile | Read-ProductVersionFromExe

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