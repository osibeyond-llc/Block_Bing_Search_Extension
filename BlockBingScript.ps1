# Script to implement Stop Bing Installation
#check for FSMO hold server, if this server is not FSMO hold, exit with error
#check if GPMC pulls from central store.

#written by Benjamin Cornwell of OSIbeyond, LLC
#January 2020


#$DOMAIN = Read-Host -Prompt 'input domain name. (ex: BJC.local)';
$domain = $env:USERDNSDOMAIN
Write-Host "Is it the same as:  $domain ?";


$CentralStore = $False;
if(Test-Path C:\Windows\SYSVOL\sysvol\$domain\Policies\PolicyDefinitions){
    Write-Host "Central Store exists. Continuing...";
    $CentralStore = $True;
}
else{
    Write-Host "Central Store does NOT exist. Creating...";
    $CentralStore = $False;
}

if(!$CentralStore){
    Copy-Item -Path "C:\Windows\PolicyDefinitions" -Destination "C:\Windows\SYSVOL\sysvol\$domain\Policies\" -Recurse;
    Start-Sleep 5;
    Write-Host "Central Store created."
}
$FSMOserver = Get-ADDomainController -Filter * | Select-Object Name, Domain, Forest, OperationMasterRoles | Where-Object {$_.OperationMasterRoles} | Select-Object Name;
$FSMOserver = $FSMOserver.Name;
#Write-Host "FSMO server is $FSMOserver. You are on $env:COMPUTERNAME. Are you on the FSMO Server?  (Y/n)"
if($env:COMPUTERNAME -ne $FSMOserver){
    Write-Host "Do this on the other server. Exiting...";
    exit;
}
else{
    Write-Host "`n You are on the correct server.";
    Write-Host "`n Continuing...";
}



New-Item -ItemType "Directory" -Path "C:\$env:HOMEPATH\Desktop\ExtractedADMX";

#download .exe for new admx templates
wget https://download.microsoft.com/download/2/E/E/2EEEC938-C014-419D-BB4B-D184871450F1/admintemplates_x64_4966-1000_en-us.exe -OutFile C:\$env:HOMEPATH\Desktop\admintemplates_x64_4966-1000_en-us.exe;

#extract new templates to new directory
Start-Process -FilePath "C:\$env:HOMEPATH\Desktop\admintemplates_x64_4966-1000_en-us.exe" -ArgumentList "/extract:C:\$env:HOMEPATH\Desktop\ExtractedADMX", "/quiet";

#copy admx files to SYSVOL location
Copy-Item -Path "C:\$env:HOMEPATH\Desktop\ExtractedADMX\admx\*.admx" -Destination "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions";

#copy en_us file to SYSVOL location
Copy-Item -Path "C:\$env:HOMEPATH\Desktop\ExtractedADMX\admx\en-us" -Destination "C:\Windows\SYSVOL\sysvol\$env:USERDNSDOMAIN\Policies\PolicyDefinitions" -Recurse -Force

#Make the new GPO
New-GPO -Name "Computer: Block Bing Search Extension" -Server $FSMOserver;

#Set GPO and assign it to the domain
Set-GPRegistryValue -Name "Computer: Block Bing Search Extension" -Key "HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" -ValueName preventbinginstall -Type DWord -Value 1

#Link GPO
$TARGET = Get-ADDomain | Select-Object DistinguishedName

New-GPLink -Name "Computer: Block Bing Search Extension" -Target $TARGET.DistinguishedName -LinkEnabled Yes

