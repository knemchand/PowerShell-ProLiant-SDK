﻿<#********************************************Description********************************************

This script is an example of how to update iLO firmware in enclosure.


***************************************************************************************************#>

#Step 1: Use Find-HPEOA to find all the OAs with firmware later then v4.00
$scriptFolder = Split-Path $PSCommandPath -Parent
$path = [System.IO.Path]::Combine($scriptFolder, "Input.csv")
$csv = $null

if(Test-Path $path)
{
    $csv = Import-Csv $path
}
else
{
    Write-Host "Input.csv file is missing."
    exit
}

if($csv -ne $null)
{
    $findOA = Find-HPEOA $csv.IP -Verbose

    if($findOA -ne $null)
    {
        $connection =  $findOA|
        where {$_.Firmware.StartsWith("4.")} |
        % {Add-Member -PassThru -InputObject $_ Username $csv.Username}|
        % {Add-Member -PassThru -InputObject $_ Password $csv.Password}|
        Connect-HPEOA 
    }
    else
    {
        Write-Host "No available OA server found." -ForegroundColor Red
        exit
    }
}
else
{
    Write-host "No entry found in CSV file, add OA details" -ForegroundColor Red
    exit
}

#Step 2: Use Get-HPEOAFWSummary to get all the firmware information within the Enclosure.
#The cmdlet is supported with OA firmware v4.00 and later.
$firm = Get-HPEOAFWSummary $connection

for($i = 0; $i -lt $firm.Count; $i++)
{
    #Then desplay all the information one by one.
    Write-Host "#Firmware information for $($firm[$i].IP) $($firm[$i].Hostname)#" -ForegroundColor Green

    Write-Host "## OA Firmware Information ##" -ForegroundColor DarkGreen
    $firm[$i].OnboardAdministratorFirmwareInformation | Format-Table

    Write-Host "## Device Firmware Information ##" -ForegroundColor DarkGreen
    $ilo3baystring = $null
    $ilo4baystring = $null
    foreach($d in $firm[$i].DeviceFirmwareInformation)
    {
        Write-Host "Bay $($d.Bay)"
        $d.DeviceFWDetail| Format-Table
        Write-Host "`n"
        if($d.DeviceFWDetail.FirmwareComponent.Contains("iLO3"))    
        {
            if($ilo3baystring -eq $null)
            {
                $ilo3baystring = "" + $d.Bay
            }
            else
            {
                $ilo3baystring = $ilo3baystring + "," + $d.Bay
            }
        }
        elseif($d.DeviceFWDetail.FirmwareComponent.Contains("iLO4"))
        {
            if($ilo4baystring -eq $null)
            {
                $ilo4baystring = "" + $d.Bay
            }
            else
            {
                $ilo4baystring = $ilo4baystring + "," + $d.Bay
            }
        }
    }

    #Step 3: Update ilo firmware with the specified iLO firmware bin files.
    #iLO3 and iLO4 firmware need to be updated seperately. 
    #Update-HPEOAiLO is valid only for ProLiant SERVER blades.
    if($ilo3baystring -ne $null)
    {
        $ilo3Url = Read-Host = "Enter iLO3 firmware URL`t"
        Update-HPEOAiLO -Connection $connection[$i] -Bay $ilo3baystring -URL $ilo3Url -Verbose 
    }

    if($ilo4baystring -ne $null)
    {
        $ilo4Url = Read-Host = "Enter iLO4 firmware URL`t"
        Update-HPEOAiLO -Connection $connection[$i] -Bay $ilo4baystring -url $ilo4Url -Verbose
    }
}


#Step 4: Disconnect the connections.
if($connection -ne $null)
{
    Disconnect-HPEOA $connection
}
# SIG # Begin signature block
# MIIjpgYJKoZIhvcNAQcCoIIjlzCCI5MCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDLjiVXBwcOCnex
# Kc04YrfHg4V6E/65acULpUTly5RVw6CCHrIwggPuMIIDV6ADAgECAhB+k+v7fMZO
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
# lEM/RlUm1sT6iJXikZqjLQuF3qyM4PlncJ9xeQIx92GiKcQwggVpMIIEUaADAgEC
# AhAnlft9qr383J/sD2dic7k4MA0GCSqGSIb3DQEBCwUAMH0xCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSMwIQYDVQQDExpDT01PRE8gUlNB
# IENvZGUgU2lnbmluZyBDQTAeFw0xODAzMjEwMDAwMDBaFw0xOTAzMjEyMzU5NTla
# MIHSMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgMAkNBMRIw
# EAYDVQQHDAlQYWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBTdHJlZXQx
# KzApBgNVBAoMIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkxGjAY
# BgNVBAsMEUhQIEN5YmVyIFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0IFBhY2th
# cmQgRW50ZXJwcmlzZSBDb21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAzqI1vNsHY9aqhM+vzhUIkq4Boums7iJ1wInnLei2Lbpmn75pQultxKMS
# bmQTkP0JKYTTQK9dTnq1CkyheRsOHoxf3Tuzhpi6ovmbOzDm9y55AZQkHDQK0Pcg
# 0MUQoHKtEJUifQYj8eASdA7qSqc3NROJljCLI4kP+MK/NDqrVsCy6M/KHMaj+4Tp
# pwV7egZ0tMkWIkWwhIelSIpaCElAy+/H1azQWpwZMmR5fX8yJqL0dRLwl/EF+zT7
# 8iwL1M5++NHoRhGSOehH97sX1L3FIdG2hRfs8JnVBop8pOFIFqtXojDkCdtdFNMe
# YY8PTVECNJiVBcvBoB/9v0X/HKKCMQIDAQABo4IBjTCCAYkwHwYDVR0jBBgwFoAU
# KZFg/4pN+uv5pmq4z/nmS71JzhIwHQYDVR0OBBYEFNGeIRuysIgJ0V7e2q8QhJ/p
# YhFCMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBGBgNVHSAEPzA9MDsGDCsGAQQBsjEB
# AgEDAjArMCkGCCsGAQUFBwIBFh1odHRwczovL3NlY3VyZS5jb21vZG8ubmV0L0NQ
# UzBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9DT01P
# RE9SU0FDb2RlU2lnbmluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPgYIKwYBBQUH
# MAKGMmh0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNvZGVTaWduaW5n
# Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJ
# KoZIhvcNAQELBQADggEBAJdXHI0K/7cogXHydvYmVcuNVOsMO4L0PL0EMtKYS1yP
# v/xtc2xtCoOJeYxwhE328UyEfNotQmqD5z4b6SlwnKRtw4Tu267aJkImnDRQu0u+
# eI3j2PORVJrrBlyRnPVS3/8uDIRcvmdqgvw4tWlFRfIYpFNvyv7ev6+tzjWjUT/z
# qVSsvImWN95ZILcaSfAAZaNX4LpkF8J5twCg40rvT22jRnWrsdv4h1ZtwHq2UsRf
# 1iE6i+2JKRqpwLw1gpTGxeMZSCJ/75g4q/6nwryHCnmBWhgBfR+u/f6fPrNRJZ1E
# uWcU/wlQb1vqs+qfH6sJseRE6+6aavDcNE+R+S1EJRcwggV0MIIEXKADAgECAhAn
# Zu5W60nzjqvXcKL8hN4iMA0GCSqGSIb3DQEBDAUAMG8xCzAJBgNVBAYTAlNFMRQw
# EgYDVQQKEwtBZGRUcnVzdCBBQjEmMCQGA1UECxMdQWRkVHJ1c3QgRXh0ZXJuYWwg
# VFRQIE5ldHdvcmsxIjAgBgNVBAMTGUFkZFRydXN0IEV4dGVybmFsIENBIFJvb3Qw
# HhcNMDAwNTMwMTA0ODM4WhcNMjAwNTMwMTA0ODM4WjCBhTELMAkGA1UEBhMCR0Ix
# GzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEa
# MBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNVBAMTIkNPTU9ETyBSU0Eg
# Q2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQCR6FSS0gpWsawNJN3Fz0RndJkrN6N9I3AAcbxT38T6KhKPS38QVr2f
# cHK3YX/JSw8Xpz3jsARh7v8Rl8f0hj4K+j5c+ZPmNHrZFGvnnLOFoIJ6dq9xkNfs
# /Q36nGz637CC9BR++b7Epi9Pf5l/tfxnQ3K9DADWietrLNPtj5gcFKt+5eNu/Nio
# 5JIk2kNrYrhV/erBvGy2i/MOjZrkm2xpmfh4SDBF1a3hDTxFYPwyllEnvGfDyi62
# a+pGx8cgoLEfZd5ICLqkTqnyg0Y3hOvozIFIQ2dOciqbXL1MGyiKXCJ7tKuY2e7g
# UYPDCUZObT6Z+pUX2nwzV0E8jVHtC7ZcryxjGt9XyD+86V3Em69FmeKjWiS0uqlW
# Pc9vqv9JWL7wqP/0uK3pN/u6uPQLOvnoQ0IeidiEyxPx2bvhiWC4jChWrBQdnArn
# cevPDt09qZahSL0896+1DSJMwBGB7FY79tOi4lu3sgQiUpWAk2nojkxl8ZEDLXB0
# AuqLZxUpaVICu9ffUGpVRr+goyhhf3DQw6KqLCGqR84onAZFdr+CGCe01a60y1Dm
# a/RMhnEw6abfFobg2P9A3fvQQoh/ozM6LlweQRGBY84YcWsr7KaKtzFcOmpH4MN5
# WdYgGq/yapiqcrxXStJLnbsQ/LBMQeXtHT1eKJ2czL+zUdqnR+WEUwIDAQABo4H0
# MIHxMB8GA1UdIwQYMBaAFK29mHo0tCb3+sQmVO8DveAky1QaMB0GA1UdDgQWBBS7
# r34CPfqm8TyEjq3uOJjs2TIy1DAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUw
# AwEB/zARBgNVHSAECjAIMAYGBFUdIAAwRAYDVR0fBD0wOzA5oDegNYYzaHR0cDov
# L2NybC51c2VydHJ1c3QuY29tL0FkZFRydXN0RXh0ZXJuYWxDQVJvb3QuY3JsMDUG
# CCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0
# LmNvbTANBgkqhkiG9w0BAQwFAAOCAQEAZL+D8V+ahdDNuKEpVw3oWvfR6T7ydgRu
# 8VJwux48/00NdGrMgYIl08OgKl1M9bqLoW3EVAl1x+MnDl2EeTdAE3f1tKwc0Dur
# FxLW7zQYfivpedOrV0UMryj60NvlUJWIu9+FV2l9kthSynOBvxzz5rhuZhEFsx6U
# LX+RlZJZ8UzOo5FxTHxHDDsLGfahsWyGPlyqxC6Cy/kHlrpITZDylMipc6LrBnsj
# nd6i801Vn3phRZgYaMdeQGsj9Xl674y1a4u3b0b0e/E9SwTYk4BZWuBBJB2yjxVg
# WEfb725G/RX12V+as9vYuORAs82XOa6Fux2OvNyHm9Gm7/E7bxA4bzCCBeAwggPI
# oAMCAQICEC58h8wOk0pS/pT9HLfNNK8wDQYJKoZIhvcNAQEMBQAwgYUxCzAJBgNV
# BAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1Nh
# bGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSswKQYDVQQDEyJDT01P
# RE8gUlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTEzMDUwOTAwMDAwMFoX
# DTI4MDUwODIzNTk1OVowfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIg
# TWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENB
# IExpbWl0ZWQxIzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5nIENBMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAppiQY3eRNH+K0d3pZzER68we
# /TEds7liVz+TvFvjnx4kMhEna7xRkafPnp4ls1+BqBgPHR4gMA77YXuGCbPj/aJo
# nRwsnb9y4+R1oOU1I47Jiu4aDGTH2EKhe7VSA0s6sI4jS0tj4CKUN3vVeZAKFBhR
# LOb+wRLwHD9hYQqMotz2wzCqzSgYdUjBeVoIzbuMVYz31HaQOjNGUHOYXPSFSmsP
# gN1e1r39qS/AJfX5eNeNXxDCRFU8kDwxRstwrgepCuOvwQFvkBoj4l8428YIXUez
# g0HwLgA3FLkSqnmSUs2HD3vYYimkfjC9G7WMcrRI8uPoIfleTGJ5iwIGn3/VCwID
# AQABo4IBUTCCAU0wHwYDVR0jBBgwFoAUu69+Aj36pvE8hI6t7jiY7NkyMtQwHQYD
# VR0OBBYEFCmRYP+KTfrr+aZquM/55ku9Sc4SMA4GA1UdDwEB/wQEAwIBhjASBgNV
# HRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGA1UdIAQKMAgw
# BgYEVR0gADBMBgNVHR8ERTBDMEGgP6A9hjtodHRwOi8vY3JsLmNvbW9kb2NhLmNv
# bS9DT01PRE9SU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDBxBggrBgEFBQcB
# AQRlMGMwOwYIKwYBBQUHMAKGL2h0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9E
# T1JTQUFkZFRydXN0Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21v
# ZG9jYS5jb20wDQYJKoZIhvcNAQEMBQADggIBAAI/AjnD7vjKO4neDG1NsfFOkk+v
# wjgsBMzFYxGrCWOvq6LXAj/MbxnDPdYaCJT/JdipiKcrEBrgm7EHIhpRHDrU4ekJ
# v+YkdK8eexYxbiPvVFEtUgLidQgFTPG3UeFRAMaH9mzuEER2V2rx31hrIapJ1Hw3
# Tr3/tnVUQBg2V2cRzU8C5P7z2vx1F9vst/dlCSNJH0NXg+p+IHdhyE3yu2VNqPeF
# RQevemknZZApQIvfezpROYyoH3B5rW1CIKLPDGwDjEzNcweU51qOOgS6oqF8H8tj
# OhWn1BUbp1JHMqn0v2RH0aofU04yMHPCb7d4gp1c/0a7ayIdiAv4G6o0pvyM9d1/
# ZYyMMVcx0DbsR6HPy4uo7xwYWMUGd8pLm1GvTAhKeo/io1Lijo7MJuSy2OU4wqjt
# xoGcNWupWGFKCpe0S0K2VZ2+medwbVn4bSoMfxlgXwyaiGwwrFIJkBYb/yud29Ag
# yonqKH4yjhnfe0gzHtdl+K7J+IMUk3Z9ZNCOzr41ff9yMU2fnr0ebC+ojwwGUPuM
# J7N2yfTm18M04oyHIYZh/r9VdOEhdwMKaGy75Mmp5s9ZJet87EUOeWZo6CLNuO+Y
# hU2WETwJitB/vCgoE/tqylSNklzNwmWYBp7OSFvUtTeTRkF8B93P+kPvumdh/31J
# 4LswfVyA4+YWOUunMYIESjCCBEYCAQEwgZEwfTELMAkGA1UEBhMCR0IxGzAZBgNV
# BAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UE
# ChMRQ09NT0RPIENBIExpbWl0ZWQxIzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBT
# aWduaW5nIENBAhAnlft9qr383J/sD2dic7k4MA0GCWCGSAFlAwQCAQUAoHwwEAYK
# KwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYB
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKk2+eU1aEGV
# t06jAtvCu3P6BXu/VHM0neLeehL44VfYMA0GCSqGSIb3DQEBAQUABIIBAH4/r1YJ
# OcrzTMIqUl8XLCJrVxey4R/pSBRZLAXDxyIuI4/kiWTnPZltvf5uaUQQhLEmxqXv
# CVycKINCXTUbWGmOzGB/19a7Y2gVtizi58wipcrbjr7LKRmz0zYff8Rb44SX+yUS
# auqKHXdkNuiWcGAmcQ8sUyZKUdf9fNiPNzYzNtebUYWEI0Tvy/QjI1483Aoip29/
# q/uvE572xNvIYClVCcqMGvc2qVhHcaGB7gfINbaO8ajjPgEQkkojQG/Su/BfxDcb
# voatnHJOgPycuDeyjoNb+AyH4Tf+4FqB49HMjnE1nhmGHBSUDBiq5ap0zG8I70Og
# ImM9wKnt4Ss1OhqhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQsw
# CQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNV
# BAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0
# OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMTgwODAyMDUxOTE4WjAjBgkqhkiG9w0BCQQx
# FgQUp+YOfhurmdIU1IKdE0cbfJ7CCP8wDQYJKoZIhvcNAQEBBQAEggEAF/IIBVd3
# 67CcbCIlixnGPnaUngm9U6+tnk2e38P1stFbgBC3vprwZ9ssJzf1wI/yoM6jcHD/
# zRxal6N2qnW2oo29wzq4LHlV3xCNfhpoW84crpbw7wXqy2s4lGvJmT7uJ8frMLpR
# NCICt4eWe3VvuLdHTkjIqNxDaYerF+GsR9fQiPFTwIBZHpS9O9nAr3tlw3jzyd4T
# DWuFxE06pjT5GJucyiXyDMuv7oRKVN/8Y6gatqvN7r6gQPyG7fa7DDjpg290jZms
# KC21Lo4Q2JfYBc+sA0pi3wZBfL/vajHKbzxirZ+8AA1lZgdC2QYQI3zayJ4S1RVg
# 8V4DttnWiL68jQ==
# SIG # End signature block