Set objFirewall = CreateObject("HNetCfg.FwMgr")
Set objPolicy = objFirewall.LocalPolicy.CurrentProfile
Set WshShell = WScript.CreateObject("WScript.Shell")

Set objApplication = CreateObject("HNetCfg.FwAuthorizedApplication")
objApplication.Name = "Firefox"
objApplication.IPVersion = 2
objApplication.ProcessImageFileName = Wshshell.ExpandEnvironmentStrings("%PROGRAMFILES(x86)%") & "\mozilla firefox\firefox.exe"
objApplication.RemoteAddresses = "*"
objApplication.Scope = 0
objApplication.Enabled = True

Set colApplications = objPolicy.AuthorizedApplications
colApplications.Add(objApplication)