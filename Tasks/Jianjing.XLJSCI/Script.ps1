$Object1 = Invoke-RestMethod -Uri 'https://www.xljsci.com/whale/api/client/version' -Method Post

# Version
$this.CurrentState.Version = $Object1.data.showVersion

# ReleaseNotes (zh-CN)
$this.CurrentState.Locale += [ordered]@{
  Locale = 'zh-CN'
  Key    = 'ReleaseNotes'
  Value  = $Object1.data.intro | ConvertFrom-Html | Get-TextContent | Split-LineEndings | Select-Object -Skip 1 | Format-Text
}

$EdgeDriver = Get-EdgeDriver
$EdgeDriver.Navigate().GoToUrl('https://www.xljsci.com/download.html')

# Installer
$this.CurrentState.Installer += $Installer = [ordered]@{
  InstallerUrl = $InstallerUrl = $EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath('//div[starts-with(@class, "windowbox")]/a')).GetAttribute('href') | ConvertTo-UnescapedUri
}

if (!$InstallerUrl.Contains($this.CurrentState.Version)) {
  throw "Task $($this.Name): The InstallerUrl`n${InstallerUrl}`ndoesn't contain version $($this.CurrentState.Version)"
}

# ReleaseTime
$this.CurrentState.ReleaseTime = [regex]::Match(
  $EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath('//div[starts-with(@class, "windowbox")]/p[2]')).Text,
  '(\d{4}\.\d{1,2}\.\d{1,2})'
).Groups[1].Value | Get-Date -Format 'yyyy-MM-dd'

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
