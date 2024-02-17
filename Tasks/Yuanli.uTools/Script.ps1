$EdgeDriver = Get-EdgeDriver
$EdgeDriver.Navigate().GoToUrl('https://u.tools/')

$Prefix = $EdgeDriver.ExecuteScript('return publishURL', $null)
$Object1 = $EdgeDriver.ExecuteScript('return publishPlatform', $null)

$Identical = $true
if ($Object1.'win-x64'.version -ne $Object1.'win-ia32'.version) {
  $this.Log('Distinct versions detected', 'Warning')
  $Identical = $false
}

# Version
$this.CurrentState.Version = [regex]::Match($Object1.'win-x64'.version, '([\d\.]+)').Groups[1].Value

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = $Prefix + $Object1.'win-ia32'.package
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Prefix + $Object1.'win-x64'.package
}

switch ($this.Check()) {
  ({ $_ -ge 1 }) {
    try {
      # ReleaseNotesUrl
      $this.CurrentState.Locale += [ordered]@{
        Key   = 'ReleaseNotesUrl'
        Value = $ReleaseNotesUrl = Get-RedirectedUrl -Uri "https://open.u-tools.cn/redirect?target=update_description&version=$($this.CurrentState.Version)"
      }
    } catch {
      $_ | Out-Host
      $this.Log($_, 'Warning')
      # ReleaseNotesUrl
      $this.CurrentState.Locale += [ordered]@{
        Key   = 'ReleaseNotesUrl'
        Value = $null
      }
    }

    if ($ReleaseNotesUrl) {
      try {
        $Object2 = Invoke-WebRequest -Uri $ReleaseNotesUrl | ConvertFrom-Html

        $ReleaseNotesTitleNode = $Object2.SelectSingleNode("/html/body/h1[contains(text(), '$($this.CurrentState.Version)')]")
        if ($ReleaseNotesTitleNode) {
          $ReleaseNotesNodes = for ($Node = $ReleaseNotesTitleNode.NextSibling; $Node.Name -ne 'h1'; $Node = $Node.NextSibling) { $Node }
          # ReleaseNotes (zh-CN)
          $this.CurrentState.Locale += [ordered]@{
            Locale = 'zh-CN'
            Key    = 'ReleaseNotes'
            Value  = $ReleaseNotesNodes | Get-TextContent | Format-Text
          }
        } else {
          $this.Log("No ReleaseNotes (zh-CN) for version $($this.CurrentState.Version)", 'Warning')
        }
      } catch {
        $_ | Out-Host
        $this.Log($_, 'Warning')
      }
    }

    $this.Write()
  }
  ({ $_ -ge 2 }) {
    $this.Print()
    $this.Message()
  }
  ({ $_ -ge 3 -and $Identical }) {
    $this.Submit()
  }
}
