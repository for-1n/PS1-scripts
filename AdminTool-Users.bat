<# :
@echo off 
net session >nul 2>&1
if %errorlevel% neq 0 (	
	powershell -Noprofile -ExecutionPolicy Bypass -Command  "Start-Process -FilePath '%0' -Verb RunAs"
exit /b
)
cd /d "%~dp0"
powershell -Noprofile -ExecutionPolicy Bypass -Command "iex ((Get-content '%~f0' -Raw)) "
#>

function delete-user {
	clear
	get-localuser | out-host
	$c = Read-Host "which acc you want to delete?"
	$b = get-localuser -name $c -erroraction SilentlyContinue
	if ($b) {
		$vaha = $b.SID.value
			Write-Host "Deleting this $c" -foregroundcolor yellow
			Get-CimInstance -Classname Win32_UserProfile | where-object  {$_.SID -eq $vaha} | Remove-CimInstance -confirm
			Remove-localuser -name $c -confirm
			Write-Host "The user $c has been delete" -foregroundcolor green
	} else {
			Write-Host "This user does not exist" -foregroundcolor red
	}
	$usertype = read-host "Tap Enter to Continue"
}



function create-user {
	clear
	$user = Read-Host "Name your user"
	if (get-localuser $user -ErrorAction SilentlyContinue) {
		Write-Host "This user has been created,select other name" -ForegroundColor red
	} else {
		New-localuser -name $user -ErrorAction SilentlyContinue -password (read-host -asSecureString "write your password") -PasswordNeverExpires -UserMayNotChangePassword
		Add-LocalGroupMember -member $user -SID S-1-5-32-555 
		Add-LocalGroupMember -member $user -SID S-1-5-32-545
		Write-Host "The user $user has been created congratulations" -ForegroundColor green
	}
	$usertype = read-host "Tap Enter to Continue"
}



function Showuser-AndGroup {
	clear
	write-host "                       Your users
	-----------------------------" -ForegroundColor green
	get-localuser | out-host
	write-host "                       Your groups
	-----------------------------" -ForegroundColor green
	Get-LocalGroup | Where-Object { $_.SID.Value -in "S-1-5-32-555", "S-1-5-32-545", "S-1-5-32-544" } | Select-Object Name | Out-host
	Read-host 'Tap enter to continue'
}



function autoreg-fromCSV {
	clear
	$A = Join-Path -Path $pwd -ChildPath "Open.csv"
	if (Test-path $A) {
		$userlist = import-csv -path $A -Delimiter ';'
		foreach ($line in $userlist) {
			$username = "$($line.users)_$($line.familia)"
			$pass = $line.password | convertTo-Securestring -As -force
			if (-not (get-localUser -name $username -ErrorAction silentlycontinue)) {
				New-localUser -Name $username -password $pass -passwordneverexpires -UsermaynotchangePassword
				Add-localgroupmember -member $username -SID S-1-5-32-555
				Add-localgroupmember -member $username -SID S-1-5-32-545	
				Write-Host "user $username has been created congratulations" -ForegroundColor green			
			} else {
				write-host "The $username has been created" -ForegroundColor red
			}
		}
	} else {
		Write-Host "You dont have the Open.csv in this folder" -foregroundcolor red
		Write-Host "Copy Open.csv to this folder" -foregroundcolor red
	}
	$usertype = read-host "Tap Enter to Continue"
}



function autodel-fromCSV {
	clear
	$B = Join-Path -Path $pwd -ChildPath "Open.csv"
	if (Test-path $B) {
		$userlist = import-csv -path $B -Delimiter ';'
		foreach($line in $userlist) {
			$username = "$($line.users)_$($line.familia)"
			$profile = get-localuser -name $username -erroraction SilentlyContinue
			if ($profile) {
				$usersid = $profile.SID.value
				write-host "Delete user with name $username" -foregroundcolor yellow
				Get-CimInstance -Classname Win32_userprofile | where-object {$_.SID -eq $usersid } | Remove-CimInstance 
				Remove-localuser -SID $usersid
			} else {
				write-host "This username $username does not exist" -foregroundcolor red
			}
		}
	} else {
		Write-Host "You dont have the Open.csv in this folder" -foregroundcolor red
		Write-Host "Copy Open.csv to this folder" -foregroundcolor red
	}
	Read-host "Tap Enter to Continue"
}

do {
	clear
	                                                                       
	$menutext = @"
                    ____  _____    _____ __________  ________  ______
                   / __ \/ ___/   / ___// ____/ __ \/  _/ __ \/_  __/
                  / /_/ /\__ \    \__ \/ /   / /_/ // // /_/ / / /   
                 / ____/___/ /   ___/ / /___/ _, _// // ____/ / /    
                /_/    /____/   /____/\____/_/ |_/___/_/     /_/     
                                                     							 
                       ------------------------------
                                   Type
                          1 to get and delete user
                          2 to create new user 
                          3 to check users and group
                          4 to autoreg-fromCSV
                          5 to autodel-fromCSV
                          0 to exit
                       ------------------------------
"@
	Write-Host $menuText -ForegroundColor Cyan
	$usertype = Read-Host
	switch ($usertype) {
		"1" {delete-user}
		"2" {create-user}
		"3" {Showuser-AndGroup}
		"4" {autoreg-fromCSV}
		"5" {autodel-fromCSV}
		"0" {exit}
	}
} while($true)
