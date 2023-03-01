<# Script to search the registry for all software install keys.  Based on the script from https://github.com/bk-cs/rtr and modified to sort the output, add comments to assist with reading/modifying the script, the QuietUninstallString (where provided), UninstallString, and RegPath of the key to assist with removal of apps and cleanup of orphaned keys.
#> 

function grk ([string]$Str) {
	#Create a new object getting each hive from the registry
	$Obj = foreach ($N in (Get-ChildItem 'Registry::\').PSChildName) {
		#If the hive is HKEY_USERS, Get each user hive, using regex to include only user SIDs, excluding _CLASSES.
		if ($N -eq 'HKEY_USERS') {
		foreach ($V in (Get-ChildItem "Registry::\$N" -EA 0 | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' }).PSChildName) {
			#for each user hive, test if the supplied '$str' parameter (path past the user SID, i.e. 'Software\Microsoft\Windows\CurrentVersion\Uninstall') exists, if so, get all child objects.
			if (Test-Path "Registry::\$N\$V\$Str") { Get-ChildItem "Registry::\$N\$V\$Str" -EA 0 }
            }
		#Else if it's not a user hive, check after the hive for the supplied path in the $Str parameter. If it exists, get child objects.
        } elseif (Test-Path "Registry::\$N\$Str") {
            Get-ChildItem "Registry::\$N\$Str" -EA 0
        }
    }
	#For each found key, create a custom object called $I and add all properties to it, then output $I
    $Obj | ForEach-Object {
        $I = [PSCustomObject]@{}
		#Add the registry path for the install key to help with removal.
		$I | Add-Member -Name "RegPath" -Value "$($_.name)" -MemberType NoteProperty -Force
        foreach ($P in $_.Property) {
        	$I.PSObject.Properties.Add((New-Object PSNoteProperty($P,($_.GetValue($P)))))
        }
        $I
    }
}
#Run the grk function using Software\(remaining path) to check two places for install keys, filtering for objects that have a DisplayName, DisplayVersion, and Publisher, then selecting relevant properties.
$Out = @('Microsoft\Windows\CurrentVersion\Uninstall',
'Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall').foreach{
    grk "Software\$_" | Where-Object { $_.DisplayName -and $_.DisplayVersion -and $_.Publisher } | Select-Object DisplayName,DisplayVersion,Publisher,InstallLocation,QuietUninstallString,UninstallString,RegPath
}
#Display the output and sort by the displayname.  Optionally, append '| ft -auto' to this line to format as a table in PS.
$Out | sort displayname
