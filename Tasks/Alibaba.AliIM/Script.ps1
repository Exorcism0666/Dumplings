$EdgeDriver = Get-EdgeDriver
$EdgeDriver.Navigate().GoToUrl('https://market.m.taobao.com/app/im/ww-home/index.html')

$Button1 = $EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="root"]/div/div[1]/div[2]/div[2]'))
[OpenQA.Selenium.Interactions.Actions]::new($EdgeDriver).MoveToElement($Button1).Build().Perform()

# Installer
$this.CurrentState.Installer += [ordered]@{
  InstallerUrl = $InstallerUrl = $EdgeDriver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='root']/div/div[1]/div[2]/div[2]/div/div/div/a[1]")).GetAttribute('href')
}

# Version
$this.CurrentState.Version = [regex]::Match($InstallerUrl, '\((\d+\.\d+\.\d+[A-Za-z]*)\)').Groups[1].Value

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
