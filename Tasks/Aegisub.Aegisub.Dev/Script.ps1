$Prefix = 'http://plorkyeran.com/aegisub/'

$Object1 = Invoke-WebRequest -Uri $Prefix | ConvertFrom-Html

$ReleaseNotesTitle = $Object1.SelectSingleNode('/html/body/h3[1]').InnerText

# Version
$this.CurrentState.Version = [regex]::Match($ReleaseNotesTitle, '(r[\d]+)').Groups[1].Value

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x86'
  InstallerUrl = $Prefix + $Object1.SelectSingleNode('/html/body/div[1]/a[1]').Attributes['href'].Value
}
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Prefix + $Object1.SelectSingleNode('/html/body/div[2]/a[1]').Attributes['href'].Value
}

# ReleaseTime
$this.CurrentState.ReleaseTime = [datetime]::ParseExact(
  [regex]::Match($ReleaseNotesTitle, '(\d{2}/\d{2}/\d{2})').Groups[1].Value,
  'MM/dd/yy',
  $null
).ToString('yyyy-MM-dd')

# ReleaseNotes (en-US)
$this.CurrentState.Locale += [ordered]@{
  Locale = 'en-US'
  Key    = 'ReleaseNotes'
  Value  = $Object1.SelectSingleNode('/html/body/ul[2]') | Get-TextContent | Format-Text
}

switch ($this.Check()) {
  ({ $_ -ge 1 }) {
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
