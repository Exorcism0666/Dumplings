$RepoOwner = 'XmacsLabs'
$RepoName = 'mogan'

$Object1 = Invoke-GitHubApi -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases/latest"

# Version
$this.CurrentState.Version = $Object1.tag_name -creplace '^v'

# Installer
$this.CurrentState.Installer += [ordered]@{
  Architecture = 'x64'
  InstallerUrl = $Object1.assets.Where({ $_.name.EndsWith('.exe') -and $_.name.Contains('64bit') -and $_.name.Contains('installer') }, 'First')[0].browser_download_url | ConvertTo-UnescapedUri
}

# ReleaseTime
$this.CurrentState.ReleaseTime = $Object1.published_at.ToUniversalTime()

switch ($this.Check()) {
  ({ $_ -ge 1 }) {
    try {
      $Object2 = (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/${RepoOwner}/${RepoName}/HEAD/docs/guide/ChangeLog_v$($this.CurrentState.Version).md" | ConvertFrom-Markdown).Html | ConvertFrom-Html

      $ReleaseNotesTitleNode = $Object2.SelectSingleNode("/h1[contains(text(), '$($this.CurrentState.Version)')]")
      if ($ReleaseNotesTitleNode) {
        # ReleaseNotes (en-US)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'en-US'
          Key    = 'ReleaseNotes'
          Value  = $ReleaseNotesTitleNode.SelectNodes('./following-sibling::node()') | Get-TextContent | Format-Text
        }

        # ReleaseNotesUrl (en-US)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'en-US'
          Key    = 'ReleaseNotesUrl'
          Value  = "https://mogan.app/guide/ChangeLog_v$($this.CurrentState.Version).html"
        }
      } else {
        $this.Logging("No ReleaseNotes (en-US) for version $($this.CurrentState.Version)", 'Warning')
        # ReleaseNotesUrl (en-US)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'en-US'
          Key    = 'ReleaseNotesUrl'
          Value  = $Object1.html_url
        }
      }
    } catch {
      $_ | Out-Host
      $this.Logging($_, 'Warning')
      # ReleaseNotesUrl (en-US)
      $this.CurrentState.Locale += [ordered]@{
        Locale = 'en-US'
        Key    = 'ReleaseNotesUrl'
        Value  = $Object1.html_url
      }
    }

    try {
      $Object2 = (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/${RepoOwner}/${RepoName}/HEAD/docs/zh/guide/ChangeLog_v$($this.CurrentState.Version).md" | ConvertFrom-Markdown).Html | ConvertFrom-Html

      $ReleaseNotesTitleNode = $Object2.SelectSingleNode("/h1[contains(text(), '$($this.CurrentState.Version)')]")
      if ($ReleaseNotesTitleNode) {
        # ReleaseNotes (zh-CN)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'zh-CN'
          Key    = 'ReleaseNotes'
          Value  = $ReleaseNotesTitleNode.SelectNodes('./following-sibling::node()') | Get-TextContent | Format-Text
        }

        # ReleaseNotesUrl (zh-CN)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'zh-CN'
          Key    = 'ReleaseNotesUrl'
          Value  = "https://mogan.app/zh/guide/ChangeLog_v$($this.CurrentState.Version).html"
        }
      } else {
        $this.Logging("No ReleaseNotes (zh-CN) for version $($this.CurrentState.Version)", 'Warning')
        # ReleaseNotesUrl (zh-CN)
        $this.CurrentState.Locale += [ordered]@{
          Locale = 'zh-CN'
          Key    = 'ReleaseNotesUrl'
          Value  = $Object1.html_url
        }
      }
    } catch {
      $_ | Out-Host
      $this.Logging($_, 'Warning')
      # ReleaseNotesUrl (zh-CN)
      $this.CurrentState.Locale += [ordered]@{
        Locale = 'zh-CN'
        Key    = 'ReleaseNotesUrl'
        Value  = $Object1.html_url
      }
    }

    $this.Write()
  }
  ({ $_ -ge 2 }) {
    $this.Message()
  }
  ({ $_ -ge 3 }) {
    $this.Submit()
  }
}
