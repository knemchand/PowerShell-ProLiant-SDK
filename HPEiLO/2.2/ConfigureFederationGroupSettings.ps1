﻿####################################################################
#Federation group management
####################################################################

<#
.Synopsis
    This script allows user to add Federation Group with full priviliges,get/set the federation multicast details.

.DESCRIPTION
    This script allows user to to add Federation Group with full priviliges,get/set the federation multicast details.
	
	The cmdlets used from HPEiLOCmdlets module in the script are stated below:
	Enable-HPEiLOLog, Connect-HPEiLO, Add-HPEiLOFederationGroup, Get-HPEiLOFederationGroup, Disconnect-HPEiLO, Set-HPEiLOFederationMulticast, Get-HPEiLOFederationMulticast, Disable-HPEiLOLog

.PARAMETER GroupName
	Specifies the federation Group Name to be added.

.PARAMETER GroupKey
	Specifies the GroupKey for the group name.

.PARAMETER iLOConfigPrivilege
	Specifes whether iLO Config privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER LoginPrivilege
	Specifes whether user has login privilege or no. Valid values are "Yes", "No". Default value is "Yes".

.PARAMETER RemoteConsolePrivilege
	Specifes whether Remote Console Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER UserConfigPrivilege
	Specifes whether User Config Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER VirtualPowerAndResetPrivilege
	Specifes whether Virtual Power And Reset Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER VirtualMediaPrivilege
	Specifes whether Virtual Media Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER HostBIOSConfigPrivilege
	Specifes whether Host BIOS Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER HostNICConfigPrivilege
	Specifes whether Host NIC Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER HostStorageConfigPrivilege
	Specifes whether Host Storage Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER SystemRecoveryConfigPrivilege
	Specifes whether System Recovery Config Privilege has to be granted to the user or no. Valid values are "Yes", "No". Default value is "No".

.PARAMETER MulticastScope
	Use this option to set the multicastscope to Site, Link or organisation.

.PARAMETER MulticastTTL
	Sets the time to live, limiting the number of switches that can be traversed before the multicast discovery is stopped

.PARAMETER DiscoveryAuthentication
	Use this option to enable or disable the discovery authentication.

.EXAMPLE
    PS C:\HPEiLOCmdlets\Samples\> .\ConfigureFederationGroupSettings.ps1 -GroupName "GroupDemo" -GroupKey "demoKey" -MulticastScope Link -DiscoveryAuthentication Yes -MulticastTTL 120
	
	This script takes the required input and creates federation group with the above settings for the given iLO's.

.INPUTS
	iLOInput.csv file in the script folder location having iLO IPv4 address, iLO Username and iLO Password.

.OUTPUTS
    None (by default)

.NOTES
	Always run the PowerShell in administrator mode to execute the script.
	
    Company : Hewlett Packard Enterprise
    Version : 2.2.0.0
    Date    : 03/15/2019 

.LINK
    http://www.hpe.com/servers/powershell
#>

#Command line parameters
Param(

    [Parameter(Mandatory=$true)]
    [string[]]$GroupName, 
    [Parameter(Mandatory=$true)]
    [string[]]$GroupKey, 
	[ValidateSet("Yes","No")]
    [string[]]$iLOConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$LoginPrivilege="Yes",
    [ValidateSet("Yes","No")]
    [string[]]$RemoteConsolePrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$UserConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$VirtualPowerAndResetPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$VirtualMediaPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$HostBIOSConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$HostNICConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$HostStorageConfigPrivilege="No",
    [ValidateSet("Yes","No")]
    [string[]]$SystemRecoveryConfigPrivilege="No",
    [ValidateSet("Site", "Link", "Organization")]
    [Parameter(Mandatory=$true)]
    [string[]]$MulticastScope,
    [ValidateRange(1,255)]
    [Parameter(Mandatory=$true)]
    [string[]]$MulticastTTL,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Disabled", "30", "60", "120", "300", "600", "900", "1800")]
    [string[]]$AnnouncementInterval

    )
try
{
    $path = Split-Path -Parent $PSCommandPath
    $path = join-Path $path "\iLOInput.csv"
    $inputcsv = Import-Csv $path
	if($inputcsv.IP.count -eq $inputcsv.Username.count -eq $inputcsv.Password.count -eq 0)
	{
		Write-Host "Provide values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}

    $notNullIP = $inputcsv.IP | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullUsername = $inputcsv.Username | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
    $notNullPassword = $inputcsv.Password | Where-Object {-Not [string]::IsNullOrWhiteSpace($_)}
	if(-Not($notNullIP.Count -eq $notNullUsername.Count -eq $notNullPassword.Count))
	{
        Write-Host "Provide equal number of values for IP, Username and Password columns in the iLOInput.csv file and try again."
        exit
	}
}
catch
{
    Write-Host "iLOInput.csv file import failed. Please check the file path of the iLOInput.csv file and try again."
    Write-Host "iLOInput.csv file path: $path"
    exit
}

Clear-Host

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference ="SilentlyContinue"

# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow
#Decribe what script does to the user

Write-Host "This script allows user to get the federation group and federation multicast settings, configure them and add new group to the federation group.`n" -ForegroundColor Green

#Load HPEiLOCmdlets module
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEiLOCmdlets"))
{
    Write-Host "Loading module :  HPEiLOCmdlets"
    Import-Module HPEiLOCmdlets
    if(($(Get-Module -Name "HPEiLOCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEiLOCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPEiLOCmdlets"
    Write-Host "HPEiLOCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine."
    Write-host ""
}

$Error.Clear()

#Enable logging feature
Write-Host "Enabling logging feature" -ForegroundColor Yellow
$log = Enable-HPEiLOLog
$log | fl

if($Error.Count -ne 0)
{ 
	Write-Host "`nPlease launch the PowerShell in administrator mode and run the script again." -ForegroundColor Yellow 
	Write-Host "`n****** Script execution terminated ******" -ForegroundColor Red 
	exit 
}	

try
{
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference ="SilentlyContinue"

    [bool]$isParameterCountEQOne = $false;

    foreach ($key in $MyInvocation.BoundParameters.keys)
    {
        $count = $($MyInvocation.BoundParameters[$key]).Count
        if($count -ne 1 -and $count -ne $inputcsv.Count)
        {
            Write-Host "The input paramter value count and the input csv IP count does not match. Provide equal number of IP's and parameter values." -ForegroundColor Red    
            exit;
        }
        elseif($count -eq 1)
        {
            $isParameterCountEQOne = $true;
        }

    }
    Write-Host "`nConnecting using Connect-HPEiLO`n" -ForegroundColor Yellow
    $connection = Connect-HPeiLO -IP $inputcsv.IP -Username $inputcsv.Username -Password $inputcsv.Password -DisableCertificateAuthentication
	
	$Error.Clear()

    if($Connection -eq $null)
    {
        Write-Host "`nConnection could not be established to any target iLO.`n" -ForegroundColor Red
        $inputcsv.IP | fl
        exit;
    }

    if($Connection.count -ne $inputcsv.IP.count)
    {
        #List of IP's that could not be connected
        Write-Host "`nConnection failed for below set of targets" -ForegroundColor Red
        foreach($item in $inputcsv.IP)
        {
            if($Connection.IP -notcontains $item)
            {
                $item | fl
            }
        }

        #Prompt for user input
        $mismatchinput = Read-Host -Prompt 'Connection object count and parameter value count does not match. Do you want to continue? Enter Y to continue with script execution. Enter N to cancel.'
        if($mismatchinput -ne 'Y')
        {
            Write-Host "`n****** Script execution stopped ******" -ForegroundColor Yellow
            exit;
        }
    }

    
    foreach($connect in $connection)
    {

        Write-Host "`nAdding the Federation Group for $($connect.IP)." -ForegroundColor Green

        if($isParameterCountEQOne)
        {
            $appendText= " -GroupName " +$GroupName
            foreach ($key in $MyInvocation.BoundParameters.keys)
            {
               if($key -match "Privilege" -or $key -eq "GroupKey")
               {
                    $appendText +=" -"+$($key)+" "+$($MyInvocation.BoundParameters[$key])
               }
            }
        }
        else
        {
            $index = $csv.IP.IndexOf($connect.IP)
            $appendText= " -GroupName " +$GroupName[$index]
            foreach ($key in $MyInvocation.BoundParameters.keys)
            {
               if($key -match "Privilege" -or $key -eq "GroupKey")
               {
                    $value = $($MyInvocation.BoundParameters[$key])
                    $appendText +=" -"+$($key)+" "+$value[$index]
               }
            }
        }
        
        #executing the cmdlet Add-HPEiLODirectoryGroup 
        $cmdletName = "Add-HPEiLOFederationGroup"
        $expression = $cmdletName + " -connection $" + "connect" +$appendText
        $output = Invoke-Expression $expression

        #checking for cmdlet failure
        if($output.StatusInfo -ne $null)
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to add federation group for $($output.IP): "$message -ForegroundColor Red
        }

        Write-Host "`nGetting the added federation group info." -ForegroundColor Green
        if($isParameterCountEQOne)
        {
            $output = Get-HPEiLOFederationGroup -Connection $connect -GroupName $GroupName
        }
        else
        {
            $output = Get-HPEiLOFederationGroup -Connection $connect -GroupName $GroupName[$index]
        }
       
        #displaying Directory Group information
        if($output.Status -ne "OK")
        {   
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to get federation group info for $($output.IP): "$message -ForegroundColor Red
        }
        else
        {  Write-Host "`nFederation group info for $($output.IP)." -ForegroundColor Green; $output | Out-String }
        

        Write-Host "`nModifying Federation Multicast settings." -ForegroundColor green
        if($isParameterCountEQOne)
        {
            $output = Set-HPEiLOFederationMulticast -Connection $connect -DiscoveryAuthentication Yes -MulticastScope $MultiCastScope -MulticastTTL $MulticastTTL -AnnouncementInterval $AnnouncementInterval
        }
        else
        {
            $output = Set-HPEiLOFederationMulticast -Connection $connect -DiscoveryAuthentication Yes -MulticastScope $MultiCastScope[$index] -MulticastTTL $MulticastTTL[$index] -AnnouncementInterval $AnnouncementInterval[$index]
        }

        if($output.StatusInfo -ne $null)
        {  
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to set federation multicast info for $($output.IP): "$message -ForegroundColor Red 
                
        }
        
         Write-Host "`nGetting the Federation Multicast settings" -ForegroundColor green
         $output = Get-HPEiLOFederationMulticast -Connection $connect

        if($output.Status -eq "OK")
        {
                
            Write-Host "`nFederation multicast information for $($output.IP)" -ForegroundColor Green
            $output | out-string
        }
        else
        {
            $message = $output.StatusInfo.Message; 
            Write-Host "`nFailed to get federation multicast information for $($output.IP): "$message -ForegroundColor Red 
        }
    }
   
 }
 catch
 {
 }
finally
{
    if($connection -ne $null)
    {
        #Disconnect 
		Write-Host "Disconnect using Disconnect-HPEiLO `n" -ForegroundColor Yellow
		$disconnect = Disconnect-HPEiLO -Connection $Connection
		$disconnect | fl
		Write-Host "All connections disconnected successfully.`n"
    }  
	
	#Disable logging feature
	Write-Host "Disabling logging feature`n" -ForegroundColor Yellow
	$log = Disable-HPEiLOLog
	$log | fl
	
	if($Error.Count -ne 0 )
    {
        Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
    }
	
    Write-Host "`n****** Script execution completed ******" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIjtwYJKoZIhvcNAQcCoIIjqDCCI6QCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBLzsGx1boGRrZi
# M7aRNL+jxCAr1PvNTCMZZZAdWcfogKCCHsMwggPuMIIDV6ADAgECAhB+k+v7fMZO
# WepLmnfUBvw7MA0GCSqGSIb3DQEBBQUAMIGLMQswCQYDVQQGEwJaQTEVMBMGA1UE
# CBMMV2VzdGVybiBDYXBlMRQwEgYDVQQHEwtEdXJiYW52aWxsZTEPMA0GA1UEChMG
# VGhhd3RlMR0wGwYDVQQLExRUaGF3dGUgQ2VydGlmaWNhdGlvbjEfMB0GA1UEAxMW
# VGhhd3RlIFRpbWVzdGFtcGluZyBDQTAeFw0xMjEyMjEwMDAwMDBaFw0yMDEyMzAy
# MzU5NTlaMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsayzSVRLlxwS
# CtgleZEiVypv3LgmxENza8K/LlBa+xTCdo5DASVDtKHiRfTot3vDdMwi17SUAAL3
# Te2/tLdEJGvNX0U70UTOQxJzF4KLabQry5kerHIbJk1xH7Ex3ftRYQJTpqr1SSwF
# eEWlL4nO55nn/oziVz89xpLcSvh7M+R5CvvwdYhBnP/FA1GZqtdsn5Nph2Upg4XC
# YBTEyMk7FNrAgfAfDXTekiKryvf7dHwn5vdKG3+nw54trorqpuaqJxZ9YfeYcRG8
# 4lChS+Vd+uUOpyyfqmUg09iW6Mh8pU5IRP8Z4kQHkgvXaISAXWp4ZEXNYEZ+VMET
# fMV58cnBcQIDAQABo4H6MIH3MB0GA1UdDgQWBBRfmvVuXMzMdJrU3X3vP9vsTIAu
# 3TAyBggrBgEFBQcBAQQmMCQwIgYIKwYBBQUHMAGGFmh0dHA6Ly9vY3NwLnRoYXd0
# ZS5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADA/BgNVHR8EODA2MDSgMqAwhi5odHRw
# Oi8vY3JsLnRoYXd0ZS5jb20vVGhhd3RlVGltZXN0YW1waW5nQ0EuY3JsMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIBBjAoBgNVHREEITAfpB0wGzEZ
# MBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMTANBgkqhkiG9w0BAQUFAAOBgQADCZuP
# ee9/WTCq72i1+uMJHbtPggZdN1+mUp8WjeockglEbvVt61h8MOj5aY0jcwsSb0ep
# rjkR+Cqxm7Aaw47rWZYArc4MTbLQMaYIXCp6/OJ6HVdMqGUY6XlAYiWWbsfHN2qD
# IQiOQerd2Vc/HXdJhyoWBl6mOGoiEqNRGYN+tjCCBKMwggOLoAMCAQICEA7P9DjI
# /r81bgTYapgbGlAwDQYJKoZIhvcNAQEFBQAwXjELMAkGA1UEBhMCVVMxHTAbBgNV
# BAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1l
# IFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzIwHhcNMTIxMDE4MDAwMDAwWhcNMjAx
# MjI5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29y
# cG9yYXRpb24xNDAyBgNVBAMTK1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vydmlj
# ZXMgU2lnbmVyIC0gRzQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCi
# Yws5RLi7I6dESbsO/6HwYQpTk7CY260sD0rFbv+GPFNVDxXOBD8r/amWltm+YXkL
# W8lMhnbl4ENLIpXuwitDwZ/YaLSOQE/uhTi5EcUj8mRY8BUyb05Xoa6IpALXKh7N
# S+HdY9UXiTJbsF6ZWqidKFAOF+6W22E7RVEdzxJWC5JH/Kuu9mY9R6xwcueS51/N
# ELnEg2SUGb0lgOHo0iKl0LoCeqF3k1tlw+4XdLxBhircCEyMkoyRLZ53RB9o1qh0
# d9sOWzKLVoszvdljyEmdOsXF6jML0vGjG/SLvtmzV4s73gSneiKyJK4ux3DFvk6D
# Jgj7C72pT5kI4RAocqrNAgMBAAGjggFXMIIBUzAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBzBggrBgEFBQcBAQRn
# MGUwKgYIKwYBBQUHMAGGHmh0dHA6Ly90cy1vY3NwLndzLnN5bWFudGVjLmNvbTA3
# BggrBgEFBQcwAoYraHR0cDovL3RzLWFpYS53cy5zeW1hbnRlYy5jb20vdHNzLWNh
# LWcyLmNlcjA8BgNVHR8ENTAzMDGgL6AthitodHRwOi8vdHMtY3JsLndzLnN5bWFu
# dGVjLmNvbS90c3MtY2EtZzIuY3JsMCgGA1UdEQQhMB+kHTAbMRkwFwYDVQQDExBU
# aW1lU3RhbXAtMjA0OC0yMB0GA1UdDgQWBBRGxmmjDkoUHtVM2lJjFz9eNrwN5jAf
# BgNVHSMEGDAWgBRfmvVuXMzMdJrU3X3vP9vsTIAu3TANBgkqhkiG9w0BAQUFAAOC
# AQEAeDu0kSoATPCPYjA3eKOEJwdvGLLeJdyg1JQDqoZOJZ+aQAMc3c7jecshaAba
# tjK0bb/0LCZjM+RJZG0N5sNnDvcFpDVsfIkWxumy37Lp3SDGcQ/NlXTctlzevTcf
# Q3jmeLXNKAQgo6rxS8SIKZEOgNER/N1cdm5PXg5FRkFuDbDqOJqxOtoJcRD8HHm0
# gHusafT9nLYMFivxf1sJPZtb4hbKE4FtAC44DagpjyzhsvRaqQGvFZwsL0kb2yK7
# w/54lFHDhrGCiF3wPbRRoXkzKy57udwgCRNx62oZW8/opTBXLIlJP7nPf8m/PiJo
# Y1OavWl0rMUdPH+S4MO8HNgEdTCCBUwwggM0oAMCAQICEzMAAAA12NVZWwZxQSsA
# AAAAADUwDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEpMCcGA1UEAxMgTWljcm9zb2Z0IENvZGUgVmVyaWZpY2F0aW9u
# IFJvb3QwHhcNMTMwODE1MjAyNjMwWhcNMjMwODE1MjAzNjMwWjBvMQswCQYDVQQG
# EwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFkZFRydXN0IEV4
# dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBFeHRlcm5hbCBD
# QSBSb290MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt/caM+byAAQt
# OeBOW+0fvGwPzbX6I7bO3psRM5ekKUx9k5+9SryT7QMa44/P5W1QWtaXKZRagLBJ
# etsulf24yr83OC0ePpFBrXBWx/BPP+gynnTKyJBU6cZfD3idmkA8Dqxhql4Uj56H
# oWpQ3NeaTq8Fs6ZxlJxxs1BgCscTnTgHhgKo6ahpJhiQq0ywTyOrOk+E2N/On+Fp
# b7vXQtdrROTHre5tQV9yWnEIN7N5ZaRZoJQ39wAvDcKSctrQOHLbFKhFxF0qfbe0
# 1sTurM0TRLfJK91DACX6YblpalgjEbenM49WdVn1zSnXRrcKK2W200JvFbK4e/vv
# 6V1T1TRaJwIDAQABo4HQMIHNMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1UdEwEB
# /wQIMAYBAf8CAQIwHQYDVR0OBBYEFK29mHo0tCb3+sQmVO8DveAky1QaMAsGA1Ud
# DwQEAwIBhjAfBgNVHSMEGDAWgBRi+wohW39DbhHaCVRQa/XSlnHxnjBVBgNVHR8E
# TjBMMEqgSKBGhkRodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
# dWN0cy9NaWNyb3NvZnRDb2RlVmVyaWZSb290LmNybDANBgkqhkiG9w0BAQUFAAOC
# AgEANiui8uEzH+ST9/JphcZkDsmbYy/kcDeY/ZTse8/4oUJG+e1qTo00aTYFVXoe
# u62MmUKWBuklqCaEvsG/Fql8qlsEt/3RwPQCvijt9XfHm/469ujBe9OCq/oUTs8r
# z+XVtUhAsaOPg4utKyVTq6Y0zvJD908s6d0eTlq2uug7EJkkALxQ/Xj25SOoiZST
# 97dBMDdKV7fmRNnJ35kFqkT8dK+CZMwHywG2CcMu4+gyp7SfQXjHoYQ2VGLy7BUK
# yOrQhPjx4Gv0VhJfleD83bd2k/4pSiXpBADxtBEOyYSe2xd99R6ljjYpGTptbEZL
# 16twJCiNBaPZ1STy+KDRPII51KiCDmk6gQn8BvDHWTOENpMGQZEjLCKlpwErULQo
# rttGsFkbhrObh+hJTjkLbRTfTAMwHh9fdK71W1kDU+yYFuDQYjV1G0i4fRPleki4
# d1KkB5glOwabek5qb0SGTxRPJ3knPVBzQUycQT7dKQxzscf7H3YMF2UE69JQEJJB
# SezkBn02FURvib9pfflNQME6mLagfjHSta7K+1PVP1CGzV6TO21dfJo/P/epJViE
# 3RFJAKLHyJ433XeObXGL4FuBNF1Uusz1k0eIbefvW+Io5IAbQOQPKtF/IxVlWqyZ
# lEM/RlUm1sT6iJXikZqjLQuF3qyM4PlncJ9xeQIx92GiKcQwggViMIIESqADAgEC
# AhEA9gP0mTXPZTn2yIY3QoRiSDANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJH
# QjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3Jk
# MRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNB
# IENvZGUgU2lnbmluZyBDQTAeFw0xOTAzMjAwMDAwMDBaFw0yMDAzMTkyMzU5NTla
# MIHSMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgMAkNBMRIw
# EAYDVQQHDAlQYWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBTdHJlZXQx
# KzApBgNVBAoMIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkxGjAY
# BgNVBAsMEUhQIEN5YmVyIFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0IFBhY2th
# cmQgRW50ZXJwcmlzZSBDb21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAxn6S4GKz84Vp6B0NS6an0medYR3H8tTlS1YtHXQ+yDcCYUPwO571Ow0Y
# 5PUpwPZDbVwVlnr9arpXpAoom94OgvXsWSFt1dxF29mbBo7REnfKvENJ6zZaM3rp
# wUI2BLZQtrgGyh9S/9A7+r+IODtqI0AJxK6NXQTlPQq2LSZE9U11SWoztEU46a9X
# bA8A3pKbmYUpishqWWSDJv3Ac4nih7AflSGfwzMmE8lz3Uuqca38q+o41oMMGCaz
# SUL6hWq4B14gezMm1aZL54CQcZeJ278RuzeNFJd3usAhOAzQo6x5a/EBQ6SYGLgj
# A7Sy+eUIfQZMiRW9di+nt2d2bvGJ/QIDAQABo4IBhjCCAYIwHwYDVR0jBBgwFoAU
# DuE6qFM6MdWKvsG7rWcaA4WtNA4wHQYDVR0OBBYEFCF3lOUzCZDTIitn8qJPmpKT
# ZDrbMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBABgNVHSAEOTA3MDUGDCsGAQQBsjEB
# AgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzBDBgNV
# HR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29SU0FD
# b2RlU2lnbmluZ0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPgYIKwYBBQUHMAKGMmh0
# dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0EuY3J0
# MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG9w0B
# AQsFAAOCAQEAFm/NzB/b1PZajQ6I/7pFL8msZuwIQIhQ76TNZvxH+fYoJ5YkdZRx
# E2fL4WRBIyl0vnno+xDkDE71+7Ea2UtuX3BB+xdjXByut5VkN9VJ6sg8rEa38y3I
# cvLYjcFGitYeTz5J1Q4jLKka591xkK6M5rXMuGNCPL04mZjNQI9YfsSYv5Cav/qq
# k/co+NSTein2B3YMrAKsNu1nYh2JZCLB+3mfWY08Q7UgjDN0NBsk4LNEWq0BwVcv
# QfXZADy7Xy2hj3rbAFaCVKiZ/ale2cEORBoi/Wv1+ztEZIWCKEdRXcDfoULgzaoH
# q9a+H08IOsXGVWijsWcCTctbT5Mst1qRRDCCBXcwggRfoAMCAQICEBPqKHBb9Ozt
# DDZjCYBhQzYwDQYJKoZIhvcNAQEMBQAwbzELMAkGA1UEBhMCU0UxFDASBgNVBAoT
# C0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBUVFAgTmV0
# d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDAeFw0wMDA1
# MzAxMDQ4MzhaFw0yMDA1MzAxMDQ4MzhaMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRo
# ZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAIASZRc2DsPbCLPQrFcNdu3NJ9NMrVCDYeKqIE0JLWQJ3M6Jn8w9qez2z8Hc
# 8dOx1ns3KBErR9o5xrw6GbRfpr19naNjQrZ28qk7K5H44m/Q7BYgkAk+4uh0yRi0
# kdRiZNt/owbxiBhqkCI8vP4T8IcUe/bkH47U5FHGEWdGCFHLhhRUP7wz/n5snP8W
# nRi9UY41pqdmyHJn2yFmsdSbeAPAUDrozPDcvJ5M/q8FljUfV1q3/875PbcstvZU
# 3cjnEjpNrkyKt1yatLcgPcp/IjSufjtoZgFE5wFORlObM2D3lL5TN5BzQ/Myw1Pv
# 26r+dE5px2uMYJPexMcM3+EyrsyTO1F4lWeL7j1W/gzQaQ8bD/MlJmszbfduR/pz
# Q+V+DqVmsSl8MoRjVYnEDcGTVDAZE6zTfTen6106bDVc20HXEtqpSQvf2ICKCZNi
# jrVmzyWIzYS4sT+kOQ/ZAp7rEkyVfPNrBaleFoPMuGfi6BOdzFuC00yz7Vv/3uVz
# rCM7LQC/NVV0CUnYSVgaf5I25lGSDvMmfRxNF7zJ7EMm0L9BX0CpRET0medXh55Q
# H1dUqD79dGMvsVBlCeZYQi5DGky08CVHWfoEHpPUJkZKUIGy3r54t/xnFeHJV4Qe
# D2PW6WK61l9VLupcxigIBCU5uA4rqfJMlxwHPw1S9e3vL4IPAgMBAAGjgfQwgfEw
# HwYDVR0jBBgwFoAUrb2YejS0Jvf6xCZU7wO94CTLVBowHQYDVR0OBBYEFFN5v1qq
# K0rPVIDh2JvAnfKyA2bLMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MBEGA1UdIAQKMAgwBgYEVR0gADBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3Js
# LnVzZXJ0cnVzdC5jb20vQWRkVHJ1c3RFeHRlcm5hbENBUm9vdC5jcmwwNQYIKwYB
# BQUHAQEEKTAnMCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29t
# MA0GCSqGSIb3DQEBDAUAA4IBAQCTZfY3g5UPXsOCHB/Wd+c8isCqCfDpCybx4MJq
# daHHecm5UmDIKRIO8K0D1gnEdt/lpoGVp0bagleplZLFto8DImwzd8F7MhduB85a
# FEE6BSQb9hQGO6glJA67zCp13blwQT980GM2IQcfRv9gpJHhZ7zeH34ZFMljZ5Hq
# ZwdrtI+LwG5DfcOhgGyyHrxThX3ckKGkvC3vRnJXNQW/u0a7bm03mbb/I5KRxm5A
# +I8pVupf1V8UU6zwT2Hq9yLMp1YL4rg0HybZexkFaD+6PNQ4BqLT5o8O47RxbUBC
# xYS0QJUr9GWgSHn2HYFjlp1PdeD4fOSOqdHyrYqzjMchzcLvMIIF9TCCA92gAwIB
# AgIQHaJIMG+bJhjQguCWfTPTajANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4w
# HAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVz
# dCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAyMDAwMDAwWhcN
# MzAxMjMxMjM1OTU5WjB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBN
# YW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExp
# bWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQTCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIYijTKFehifSfCWL2MIHi3cfJ8U
# z+MmtiVmKUCGVEZ0MWLFEO2yhyemmcuVMMBW9aR1xqkOUGKlUZEQauBLYq798PgY
# rKf/7i4zIPoMGYmobHutAMNhodxpZW0fbieW15dRhqb0J+V8aouVHltg1X7XFpKc
# AC9o95ftanK+ODtj3o+/bkxBXRIgCFnoOc2P0tbPBrRXBbZOoT5Xax+YvMRi1hsL
# jcdmG0qfnYHEckC14l/vC0X/o84Xpi1VsLewvFRqnbyNVlPG8Lp5UEks9wO5/i9l
# NfIi6iwHr0bZ+UYc3Ix8cSjz/qfGFN1VkW6KEQ3fBiSVfQ+noXw62oY1YdMCAwEA
# AaOCAWQwggFgMB8GA1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1Ud
# DgQWBBQO4TqoUzox1Yq+wbutZxoDha00DjAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0T
# AQH/BAgwBgEB/wIBADAdBgNVHSUEFjAUBggrBgEFBQcDAwYIKwYBBQUHAwgwEQYD
# VR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNl
# cnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNy
# bDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRy
# dXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZ
# aHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEATWNQ
# 7Uc0SmGk295qKoyb8QAAHh1iezrXMsL2s+Bjs/thAIiaG20QBwRPvrjqiXgi6w9G
# 7PNGXkBGiRL0C3danCpBOvzW9Ovn9xWVM8Ohgyi33i/klPeFM4MtSkBIv5rCT0qx
# jyT0s4E307dksKYjalloUkJf/wTr4XRleQj1qZPea3FAmZa6ePG5yOLDCBaxq2Na
# yBWAbXReSnV+pbjDbLXP30p5h1zHQE1jNfYw08+1Cg4LBH+gS667o6XQhACTPlNd
# NKUANWlsvp8gJRANGftQkGG+OY96jk32nw4e/gdREmaDJhlIlc5KycF/8zoFm/lv
# 34h/wCOe0h5DekUxwZxNqfBZslkZ6GqNKQQCd3xLS81wvjqyVVp4Pry7bwMQJXcV
# NIr5NsxDkuS6T/FikyglVyn7URnHoSVAaoRXxrKdsbwcCtp8Z359LukoTBh+xHsx
# QXGaSynsCz1XUNLK3f2eBVHlRHjdAd6xdZgNVCT98E7j4viDvXK6yz067vBeF5Jo
# bchh+abxKgoLpbn0nu6YMgWFnuv5gynTxix9vTp3Los3QqBqgu07SqqUEKThDfgX
# xbZaeTMYkuO1dfih6Y4KJR7kHvGfWocj/5+kUZ77OYARzdu1xKeogG/lU9Tg46LC
# 0lsa+jImLWpXcBw8pFguo/NbSwfcMlnzh6cabVgxggRKMIIERgIBATCBkTB8MQsw
# CQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQH
# EwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1Nl
# Y3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQQIRAPYD9Jk1z2U59siGN0KEYkgwDQYJ
# YIZIAWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG
# 9w0BCQQxIgQgDz5IdWq0dHuQ3LMaexTW2oVriCEiPBFM0lZMp9LFopQwDQYJKoZI
# hvcNAQEBBQAEggEABT8esvYJlp9HZJiBLHpMiS4KD6DWFJyp5RUARuaCX4tsF4+c
# R3CX09/RCmtv+rECx8nsCVXnnIPbIx6X5xwohk8qQ9v9LqSyTvpN7bDX+q5BIm0P
# PeM0zFjyjmNdNxzxDCUh5PJa6QZmieyM2lB6mNZ2SikwcPE6IQa+ZSiho+p01lVv
# FCFi/9Dl+md+dgByFnzHtBMPTlr4F+gP/bdb/ux+/RlR7xQf3z85LSaY6U2YBGxd
# EzgPFuBtAkJCv8xyBcv52sJqWVJvQuh0OmkVU5IocKSo9EEmHkQqqHMWpV5FnpCp
# QEG+NHEVb3YkMXK8DFJhrmPC6PObfLJ33Tkn3qGCAgswggIHBgkqhkiG9w0BCQYx
# ggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBD
# b3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2
# aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAYBgkq
# hkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xOTAzMjEwNjM4
# MDFaMCMGCSqGSIb3DQEJBDEWBBSX3FJpIrePhlqODFphpCGcWZxRGjANBgkqhkiG
# 9w0BAQEFAASCAQBa2KTPluthDYqfixLoKwaceAY8luMbaB2n3c8lFRvTvxpaCdgP
# bKtMy2VK1fufk81/ZQScaeGWsv/2zqE5/kvLqJEfE2pupp9d9N2qpsT0WpL2KImS
# oizGoqpLhxfYOa7v94VSYdozYqLbrg4dy+GmRBAO9kDfbFXh9YvfB8p3nPWmL63M
# C1CVi9XO2aQA/hVjvY5kG/fOzAiIxn5jkMpONw7quvZ9/RXQ7cbralbakwEHk8Vd
# d7N9paeqBoQ+0lcPkHY2oCa/5xaqBphZXYzXq3xwEdaPDqXBORQox11Sd8KrJDO4
# UJ/vW2EkOwidsfKlJIwjb+dq7vxhseyAaSZh
# SIG # End signature block
