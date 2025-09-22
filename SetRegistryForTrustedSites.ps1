# -------------------------------------------------------------------------------------------------
#  <copyright file="SetRegistryForTrustedSites.ps1" company="Microsoft">
#      Copyright (c) Microsoft Corporation. All rights reserved.
#  </copyright>
#
#  Description: This script adds URLs used by Azure site recovery in trusted zone.
# -------------------------------------------------------------------------------------------------

param(
    [Parameter(Mandatory=$false)]
    [string]
	$LaunchApplication = "Yes"
)
	
<#
.Synopsis  
  Creating registry keys for trusted sites.
  
#>

$InternetSettingsRegistryHive = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings";
$TrustedSitesEscDomainsRegistryHive = $InternetSettingsRegistryHive + "\ZoneMap\EscDomains";
$TrustedSitesDomainsRegistryHive = $InternetSettingsRegistryHive + "\ZoneMap\Domains";
$InternetExplorerRegistryHive = "HKCU:\Software\Microsoft\Internet Explorer\New Windows";
$regKeyIEAllow = $InternetExplorerRegistryHive + "\Allow";
$regKeyEscBlankDomain = $TrustedSitesEscDomainsRegistryHive + "\blank";
$regKeyBlankDomain = $TrustedSitesDomainsRegistryHive + "\blank";
$machineHostName = (Get-WmiObject win32_computersystem).DNSHostName
$LogFileDir = "$env:SystemRoot\Temp"
$CurrentDateTime = Get-Date -Format "MM-dd-yyyyTHH-mm-ss"
$logName = $LogFileDir + "\SetRegistry-" + $CurrentDateTime + ".log"
$DefaultURL = "https://" + $machineHostName + ":44368"
$edgeFolder = $Env:SystemDrive + "\Program Files (x86)\Microsoft\Edge\Application"
$edgeExe = $edgeFolder + "\msedge.exe"
$ieFolder = $Env:SystemDrive + "\Program Files (x86)\Internet Explorer"
$ieExe = $ieFolder + "iexplore.exe"

## This routine writes the output string to the console and also to a log file.
function Log-Info([string] $OutputText)
{
    $OutputText | %{ Write-Output $_; Out-File -filepath $logName -inputobject $_ -append -encoding "ASCII" }
}

## This routine writes the output string to the console and also to a log file.
function Log-Error([string] $OutputText)
{
    $OutputText | %{ Write-Error $_; Out-File -filepath $logName -inputobject $_ -append -encoding "ASCII" }
}

<#
.SYNOPSIS
    Adds Trusted Local domains to registry.
#>
function AddTrustedLocalDomains
{
    Log-Info "Adding trusted local domains."

    $machineName = (Get-WmiObject win32_computersystem).DNSHostName
    $domainName = (Get-WmiObject win32_computersystem).Domain
    $fqdn = $machineName+"."+$domainName
    
    Log-Info "machineName = $machineName"
    Log-Info "domainName = $domainName"
    Log-Info "fqdn = $fqdn"
    
    # List of trusted local domains.
    $trustedLocalDomains = New-Object System.Collections.Generic.List[string]
    $trustedLocalDomains.Add("localhost");
    $trustedLocalDomains.Add($machineName);
    $trustedLocalDomains.Add($fqdn);

    # Create trusted local domain registry keys.
    foreach ($domain in $trustedLocalDomains)
    {
        New-ItemProperty -Path $regKeyIEAllow -Name $domain -Value 0 -Force

        $regKeyEscDomain = $TrustedSitesEscDomainsRegistryHive + "\" + $domain
        $regKeyDomain = $TrustedSitesDomainsRegistryHive + "\" + $domain
        foreach ($regKey in $regKeyEscDomain,$regKeyDomain)
        {
            if ( -not (Test-Path $regKey))
            {
                Log-Info "Creating $regKey"
                New-Item -Path $regKey -Force
            }
            
            # Add https key and setting its value to 1.
            New-ItemProperty -Path $regKey -Name "https" -Value 1 -Force
        }
    }
}

<#
.SYNOPSIS
    Adds Trusted domains to registry.
#>
function AddTrustedDomains
{
    Log-Info "Adding trusted domains."
    
    # List of trusted domains.
    $trustedDomains = New-Object System.Collections.Generic.List[string]
    $trustedDomains.Add("*.live.com")
    $trustedDomains.Add("*.microsoft.com");
    $trustedDomains.Add("*.microsoftonline.com");
    $trustedDomains.Add("*.microsoftonline-p.com");
    $trustedDomains.Add("*.azure.net");
    $trustedDomains.Add("*.azure.com");
    $trustedDomains.Add("*.msecnd.net");
    $trustedDomains.Add("*.windows.net");
    $trustedDomains.Add("*.gfx.ms");
	$trustedDomains.Add("*.azuremigrate.blob.core.windows.net");
    $trustedDomains.Add("*.microsoft.ca1.qualtrics.com");
    $trustedDomains.Add("*.vmware.com");
    $trustedDomains.Add("*.msftauth.net");
    $trustedDomains.Add("*.msauth.net");
    $trustedDomains.Add("*.microsoftonline.cn");
    $trustedDomains.Add("*.microsoftonline-p.cn");
    $trustedDomains.Add("*.azure.cn");
    $trustedDomains.Add("*.microsoftonline.de");
    $trustedDomains.Add("*.microsoftonline-p.de");
    $trustedDomains.Add("*.azure.de");
    $trustedDomains.Add("*.microsoftazure.de");
    $trustedDomains.Add("*.microsoftonline.us");
    $trustedDomains.Add("*.microsoftonline-p.us");
    $trustedDomains.Add("*.azure.us");
    
    # Create trusted domain registry keys.
    foreach ($domain in $trustedDomains)
    {
        $regKeyEscDomain = $TrustedSitesEscDomainsRegistryHive + "\" + $domain
        $regKeyDomain = $TrustedSitesDomainsRegistryHive + "\" + $domain
        
        foreach ($regKey in $regKeyEscDomain,$regKeyDomain)
        {
            if ( -not (Test-Path $regKey))
            {
                Log-Info "Creating $regKey"
                New-Item -Path $regKey -Force
            }
            
            # Add https key and setting its value to 2.
            New-ItemProperty -Path $regKey -Name "https" -Value 2 -Force
        }	
    }
}

<#
.SYNOPSIS
    Create blank registry keys.
#>
function AddBlankRegistryKeys
{
    foreach ($regKey in $regKeyEscBlankDomain,$regKeyBlankDomain)
    {
        if ( -not (Test-Path $regKey))
        {
            Log-Info "Creating $regKey"
            New-Item -Path $regKey -Force
        }
        
        # Add about registry key and setting its value to 2.
        New-ItemProperty -Path $regKey -Name "about" -Value 2 -Force
    }
}

###############
## Main flow ##
###############

try
{
    # List of registry hives.
    $registryHives = New-Object System.Collections.Generic.List[string]
    $registryHives.Add($InternetSettingsRegistryHive);
    $registryHives.Add($TrustedSitesEscDomainsRegistryHive);
    $registryHives.Add($TrustedSitesDomainsRegistryHive);
    $registryHives.Add($InternetExplorerRegistryHive);
    $registryHives.Add($regKeyIEAllow);

    # Create registry hives.
    foreach ($regHive in $registryHives)
    {
        if ( -not (Test-Path $regHive))
        {
            Log-Info "Creating $regHive"
            New-Item -Path $regHive -Force
        }
    }
     
    New-ItemProperty -Path $InternetExplorerRegistryHive -Name "PopupMgr" -Value 0 -Force
    New-ItemProperty -Path $InternetSettingsRegistryHive -Name "WarnonZoneCrossing" -Value 0 -Force

    AddTrustedLocalDomains
    AddTrustedDomains
    AddBlankRegistryKeys

    if ($LaunchApplication.ToLower() -eq "yes")
    {
        # Launch url.
        Log-Info "Launching url - $DefaultURL"
        Start $DefaultURL
    }

    #Create a shortcut for launching appliance portal
    $Shell = New-Object -ComObject ("WScript.Shell")
    $ShortCut = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\Microsoft Azure Appliance Configuration Manager.lnk")
    if (Test-Path -Path $edgeExe)
    {
  	    $ShortCut.TargetPath = $edgeExe
 	    $ShortCut.WorkingDirectory = $edgeFolder
    }
    else
    {
	    $ShortCut.TargetPath = $ieExe
	    $ShortCut.WorkingDirectory = $ieFolder
    }

    $ShortCut.Arguments = $DefaultURL
    $ShortCut.WindowStyle = 1
    $ShortCut.IconLocation = $Env:SystemDrive + "\Program Files\Microsoft Azure Appliance Configuration Manager\favicon.ico"
    $ShortCut.Save()
}
catch
{
    Log-Error "Script execution failed with error: $_.Exception.Message"
    Log-Error "Error Record: $_.Exception.ErrorRecord"
    Log-Error "Exception caught:  $_.Exception"
    exit 1
}