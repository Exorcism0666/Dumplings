$RepoOwner = 'postgresql-interfaces'
$RepoName = 'psqlodbc'

$Object1 = (Invoke-GitHubApi -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases").Where({ $_.prerelease -eq $false -and -not $_.tag_name.Contains('mimalloc') }, 'First')[0]

# Version
$this.CurrentState.Version = $Object1.tag_name -replace '^REL-' -replace '_', '.'

# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerType          = 'burn'
  InstallerUrl           = Join-Uri 'https://ftp.postgresql.org/pub/odbc/releases/' "$($Object1.tag_name)/" $Object1.assets.Where({ $_.name.EndsWith('.exe') -and $_.name.Contains('setup') }, 'First')[0].name
  AppsAndFeaturesEntries = @(
    [ordered]@{
      DisplayVersion = $this.CurrentState.Version -replace '\b0+(?=\d)'
    }
  )
}
$this.CurrentState.Installer += [ordered]@{
  Architecture           = 'x86'
  InstallerType          = 'wix'
  InstallerUrl           = Join-Uri 'https://ftp.postgresql.org/pub/odbc/releases/' "$($Object1.tag_name)/" $Object1.assets.Where({ $_.name.EndsWith('.msi') -and $_.name.Contains('x86') }, 'First')[0].name
  AppsAndFeaturesEntries = @(
    [ordered]@{
      DisplayVersion = $this.CurrentState.Version
    }
  )
}
$this.CurrentState.Installer += [ordered]@{
  Architecture           = 'x64'
  InstallerType          = 'wix'
  InstallerUrl           = Join-Uri 'https://ftp.postgresql.org/pub/odbc/releases/' "$($Object1.tag_name)/" $Object1.assets.Where({ $_.name.EndsWith('.msi') -and $_.name.Contains('x64') }, 'First')[0].name
  AppsAndFeaturesEntries = @(
    [ordered]@{
      DisplayVersion = $this.CurrentState.Version
    }
  )
}

switch -Regex ($this.Check()) {
  'New|Changed|Updated' {
    try {
      # ReleaseTime
      $this.CurrentState.ReleaseTime = $Object1.published_at.ToUniversalTime()
    } catch {
      $_ | Out-Host
      $this.Log($_, 'Warning')
    }

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