
<# 
.SYNOPSIS
Uses SPO and PnP PowerShell functions to create and provision sites and subsites in SharePoint Online.
To run all available functions tenant admin privileges are required. 
As of 12/17/2017 this script relies on the October Release 1 version of the PnP cmdlets.

.DESCRIPTION
Various functions related to provisiong including: enable and create public and private CDN on O365, 
create a new site collection or subsite, pull a template from an SPO site and use it to provision new site(s).

.PARAMETER SPO_params
Refers to [name of your parameters file].xml which contains parameters for the site collections being created. 
You willl supply the path to the parameters file at the prompt.

.EXAMPLE
From the PowerShell prompt run .\SPO_PnP_Functions.ps1 You will be prompted for the path to your .xml paraameters file.
When creating site or web template files, a date stamp is added so that you will be able to select a version of the file if needed.

.NOTES
17-09-25 Assembled by Ramona Maxwell www.SolverInc.com/contact - Microsoft Public License (Ms-PL) USE AT YOUR OWN RISK, 
you assume all liability for your use of any code herein.

.LINK
[GitHub](https://github.com/sqlsolver/2017_PnP_ProvisioningDemo)
#>

#Verify the configuration file exists
    $SPO_params = Read-Host "Please enter the path to your configuration file"
	if (-not(Test-Path $SPO_params))	{ 
		Write-Warning "The file containing script parameters cannot be located."
		Write-Host "The file [name of file containing parameters].xml must be located in the same directory as the SPO_PnP_Functions script."
		return $false
		}

#Load the params
	$webParams = [xml](Get-Content $SPO_params)

#Housekeeping
	$ErrorActionPreference = "Continue"
	$dateStamp = Get-Date -Format "yyyy-MM-dd-hhmm"
	$transcript = ".\" + $dateStamp + "_" + $MyInvocation.MyCommand.Name.Replace(".ps1", "") + ".log"
	$outputFile = ".\" + $dateStamp + "_" + $MyInvocation.MyCommand.Name.Replace(".ps1", "") + "_run.doc"
	$siteTemplateFile = ".\" + $dateStamp + "_" + ($webParams.Config.SourceSite.SiteCollUrl -Replace'\b.*sites\b|\W|\bcom\b','') + "_siteCollTemplate.pnp"
	$webTemplateFile = ".\" + $dateStamp + "_" + ($webParams.Config.SourceWeb.WebUrl -Replace'\b.*sites\b|\W|\bcom\b','') + "_webTemplate.pnp"
	Start-Transcript -Path $transcript
	Set-PnPTraceLog -On -Level:Debug -LogFile $outputFile

#Connect to your SPO tenant. If are connected using Connect-SPOService PnP functions will not be available until without this.
	Connect-PnPOnline -url $webParams.Config.Tenant -credentials (Get-Credential)


#Get a site collection template
function pullSiteCollectionTemplate () {
	$srcSite = $webParams.Config.SourceSite.SiteCollUrl
	#Write-Output "The template of " $srcSite " will be saved as: " $siteTemplateFile
	Write-Output "Attempting to download template package from " $srcSite	
	try {
			Connect-PnPOnline -Url $srcSite  
			Get-PnPProvisioningTemplate `
			-Out $webParams.Config.SourceSite.SiteCollOutputFile `
			-IncludeSiteCollectionTermGroup `
			-PersistBrandingFiles
		}
		catch {
			Write-Host $_.Exception.Message -ForegroundColor:Red
			Write-Output `n "The error is: " $_.Exception.Message
		}
		finally {
		} 
		menuActions
}

#Get a web template
function pullWebTemplate () {
	$srcWeb = $webParams.Config.SourceWeb.WebUrl
	Write-Output "The template of " $srcWeb " will be saved as: " $webTemplateFile
	try {
			Connect-PnPOnline -Url $srcWeb 
			Get-PnPProvisioningTemplate `
			-Out $webTemplateFile `
			-Web $srcWeb `
			-PersistBrandingFiles
		}
	catch {
		Write-Host $_.Exception.Message -ForegroundColor:Red
		Write-Output `n "The error is: " $_.Exception.Message
	}
	finally {
	} 
	menuActions
}

#Create a new classic Site Collection
function newSiteColl () {
Connect-PnPOnline -Url $webParams.Config.Tenant  
#Get XML params for new Site Collection(s)
	try {
		$Sites = $webParams.Config.Sites.Site
		$Sites | ForEach-Object {
			New-PnPTenantSite `
			-RemoveDeletedSite `
			-Template $_.Template `
			-Title $_.Title `
			-Description $_.Description `
			-Url ($_.BaseUrl + $_.Url)`
			-Owner $_.Owner `
			-TimeZone $_.TimeZone

			Start-Sleep -Seconds 30
			$validatedSite = Get-SPOSite -Identity ($_.BaseUrl + $_.Url) `
			If ($validatedSite) {				
				Write-Host "The site collection $validatedSite has been created!" -ForegroundColor:Yellow
				Write-Host $validatedSite.RootWeb.SiteGroups -ForegroundColor:DarkBlue
				$u1 = $validatedSite.RootWeb.EnsureUser($_.Owner)
				$validatedSite.RootWeb.CreateDefaultAssociatedGroups($u1, $u2, $_.Name)
				$validatedSite.RootWeb.Update();
			}
		}
	}
	catch {
			Write-Host $_.Exception.Message -ForegroundColor:Red
			Write-Output `n "The error is: " $_.Exception.Message
		}
#removed finally block - see if script exits to menu after process
#Function did not complete with menuActions placed here...
}
#Create a new subweb
function newSubWeb () {
#Get XML params for new web(s).
	$Webs = $webParams.Config.Webs.Web
#Create webs
	try {
		$Webs | ForEach-Object {
			$webContext = Read-Host "Please enter the URL of the site where you want to create a subweb"
			Connect-PnPOnline -Url $webContext  
			New-PnPWeb
				-Title $_.Title 
				-Url $_.Url
				-Description $_.Description
				-Locale $_.Config.Webs.Web.Locale 
				-Template $_.Template
			}
	}
	catch {
		Write-Host $_.Exception.Message -ForegroundColor:Red
		Write-Output `n "The error is: " $_.Exception.Message
    }
    finally {
    }
	menuActions
}

#Apply a site collection template
function applySiteCollTemplate () {
#Connect to Target Site and apply template
try {
	$trgtSite = ($webParams.Config.BaseUrl + $webParams.Config.Sites.Site.Url)
	$trgtSite | ForEach-Object {
	Connect-PnPOnline -Url $trgtSite  
	Set-PnPTenantSite -Url $trgtSite -NoScriptSite:$false
	Apply-PnPProvisioningTemplate -Path $webParams.Config.OutputFile
	    }
	}
	catch {
		Write-Host $_.Exception.Message -ForegroundColor:Red
		Write-Output `n "The error is: " $_.Exception.Message
    }
    finally {
    }
	menuActions
}

#Apply a subsite template
function applyWebTemplate () {
	$trgtWeb = $webParams.Config.Webs.Web.Url #Needs a read-host to collect parent
try {
	$trgtWeb | ForEach-Object {
		Connect-PnPOnline -Url $trgtWeb  
		Set-PnPTenantSite -Url $trgtWeb -NoScriptSite:$false
		Apply-PnPProvisioningTemplate -Path $webParams.Config.WebOutputFile -Web $trgtWeb	
	    }
	}
	catch {
		Write-Host $_.Exception.Message -ForegroundColor:Red
		Write-Output `n "The error is: " $_.Exception.Message
    }
    finally {
    }
	menuActions
}

#Console menu
function menuActions () {
	do {
		while ($selection -eq $null) {
			$Title = $webParams.Config.MenuTitle
			Clear-Host
			Write-Host "================ $Title ================"
			
			Write-Host "1: Press '1' to create a new Site Collection."
			Write-Host "2: Press '2' to create a new subweb."
			Write-Host "3: Press '3' to extract a site template from an existing Site Collection."
			Write-Host "4: Press '4' to extract a template from an existing subweb."
			Write-Host "5: Press '5' to apply a site template to an existing SiteCollection."
			Write-Host "6: Press '6' to apply a template to an existing subweb."
			Write-Host "Q: Press 'Q' to quit."
			
		$selection = Read-Host "Please choose an operation from the list above"
		switch ($selection){
			'1' {newSiteColl}
			'2' {newSubWeb} 
			'3' {pullSiteCollectionTemplate}
			'4' {pullWebTemplate}
			'5' {applySiteCollTemplate}
			'6' {applyWebTemplate}
			'q' {
				Set-PnPTraceLog -Off
				Stop-Transcript
				return
				}
			}
		}
	}
	while ($selection -ne 'q')
}
menuActions