#Check if Chromium.exe is running from the OneLaunch path.  If So, kill it.
$OneLaunchProcess = get-process chromium -ErrorAction SilentlyContinue| where {$_.path -like "C:\Users\*\AppData\Local\OneLaunch\*\chromium\chromium.exe"}
if ($OneLaunchProcess) {
	$OneLaunchProcess | foreach {
		Stop-Process $_ -Force -Confirm:$false
	}
}
#Check if OneLaunch.exe is running.  If So, kill it.
$OneLaunchProcess2 = get-process onelaunch -ErrorAction SilentlyContinue | where {$_.path -like "C:\Users\*\AppData\Local\OneLaunch\*\onelaunch.exe"}
if ($OneLaunchProcess2) {
	$OneLaunchProcess2 | foreach {
		Stop-Process $_ -Force -Confirm:$false
	}
}
#Check if OneLaunchTray.exe is running.  If So, kill it.
$OneLaunchProcess3 = get-process onelaunchtray -ErrorAction SilentlyContinue | where {$_.path -like "C:\Users\*\AppData\Local\OneLaunch\*\onelaunchtray.exe"}
if ($OneLaunchProcess3) {
	$OneLaunchProcess3 | foreach {
		Stop-Process $_ -Force -Confirm:$false 
	}
}
#Check if "OneLaunch" bin or start menu folders exists under any user profile.  Must get the user profiles then search them each, because Get-ChildItem won't allow recursive searches in AppData and RTR doesn't seem to work with wildcards for the username in the path.
$Profiles = Get-ChildItem C:\Users
foreach ($Profile in $Profiles) {
	#Null out reused vars to avoid false match.
	$OneLaunchFolder = $null
	$StartMenuFolder = $null
	#Search user profiles for the OneLaunch bin dir.
	$OneLaunchFolder = Get-ChildItem OneLaunch -path "$($Profile.Fullname)\appdata\local" -ErrorAction SilentlyContinue
	#If bin dir exists, delete it.
	If ($OneLaunchFolder) {
		$OneLaunchFolder.fullname | foreach {
			Remove-Item $_ -Force -Recurse -Confirm:$False
		}
	}
	#Search user profiles for the OneLaunch start menu folder.
	$StartMenuFolder = Get-ChildItem OneLaunch -path "$($Profile.Fullname)\appdata\roaming\microsoft\windows\start menu\programs" -ErrorAction SilentlyContinue
	#If the start menu dir exists, delete it.
	If ($StartMenuFolder) {
		$StartMenuFolder.fullname | foreach {
			Remove-Item $_ -Force -Recurse -Confirm:$False
		}
	}
}
#Get any scheduled tasks "OneLaunchLaunchTask" and unregister them.
Get-ScheduledTask -TaskName OneLaunchLaunchTask -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
#Identify any installation keys in HKEY_USERS
$RegKeys = Get-childitem "registry::\HKEY_USERS" -ErrorAction SilentlyContinue | foreach {
	get-childitem -path "Registry::\HKEY_USERS\$($_.pschildname)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue
}
#Limit installation keys resultset to OneLaunch
$UninstallKeys = $RegKeys | where {$_.pschildname -eq '{4947c51a-26a9-4ed0-9a7b-c21e5ae0e71a}_is1'}
#Remove any installation keys for OneLaunch, if any exist.
if ($UninstallKeys) {
	$UninstallKeys | foreach {Remove-Item "$($_.PSPath)" -Force -Recurse -Confirm:$False}
}
#Find any reg keys in HKEY_USERS\[SID]\Software\ for OneLaunch
foreach ($User in (Get-ChildItem "registry::\hkey_users")) {
	$SoftwareKeys = $null
	$SoftwareKeys = Get-ChildItem "$($User.pspath)\software\OneLaunch" -ErrorAction SilentlyContinue
	#if any keys exist, recursively delete them.
	if ($SoftwareKeys) {
		$SoftwareKeys | foreach	{
			Remove-Item "$($_.PSPath)" -Force -Recurse -Confirm:$False
		}
	}
}