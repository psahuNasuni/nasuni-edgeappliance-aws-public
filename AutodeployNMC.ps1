#This script uses PowerShell Invoke-WebRequest to initialize a newly provisioned NMC

#Required Inputs: NMC hostname, username, password, reportFile (path)
#PowerShell Compatibility: Tested with PowerShell 7 (required for skipCertificateCheck)


#define the function for getting page state
#define script parameters
param ($varPath)



function GetPageState{
    $script:GetState=Invoke-RestMethod -Uri $GetStateUri -skipCertificateCheck -SessionVariable sv 
    #Regex pattern to compare two strings
    $startString = '">Install '
    $stopString = '</h2>'
    $pattern = "$startString(.*?)$stopString"

    #Perform the comparison operation to find the right wizard page
    $PageState = [regex]::Match($GetState,$pattern).Groups[1].Value

    #check to see if the wizard is complete and the Edge Appliance is waiting for login
    if ($PageState -NotLike '*Wizard*') {
        #Regex pattern to compare two strings
        $startString = 'button id="'
        $stopString = '_btn"'
        $pattern = "$startString(.*?)$stopString"
        #Perform the comparison operation
        $PageState = [regex]::Match($GetState,$pattern).Groups[1].Value
    }
    #Return result
    return $PageState
}

#get the invocation path for the script
$mypath = $MyInvocation.MyCommand.Path

#find the correct slash to use. Requires PowerShell 6
if ($isWindows -eq 'True)') {$slash = "\"} else {$slash = "/"} 

#determine full or local path
if (($varPath -like "*/*") -or ($varPath -like "*\*")) {$absolutePath = 'True'} else {$absolutePath = 'False'}

#if an absolute path was input use it as is
if ($absolutePath -eq 'True') {$fullVarPath = $varPath} else {
    $parentPath = Split-Path $mypath -Parent
    $fullVarPath = $parentPath + $slash + $varPath
}
#load Variables into the script
. $fullVarPath


$PageStateVar = GetPageState

Write-Output $PageStateVar
Write-Output $NMCHostname
if ($PageStateVar -like '*Network Configuration*' ) {
#LoginPage
$NetworkUri = "https://" + $NMCHostname + "/wizard/network/"
Write-Output $NetworkUri
$NetworkPage=Invoke-WebRequest -Uri $NetworkUri -skipCertificateCheck -SessionVariable sv 
$Form = $NetworkPage.InputFields
$csrfmiddlewaretoken = $Form[0].value
Write-Output $csrfmiddlewaretoken

#Submit Login Page
$NetworkHeaderInput = @{
    "Referer" = $NetworkUri
}
#"id_proto" = $networktype
Write-Output $nmcname
Write-Output $networktype
$NetworkFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "hostname" = $nmcname
    "proto" = $networktype
}


$SubmitNetworkPage=Invoke-WebRequest -Uri $NetworkUri -WebSession $sv -Method POST -Form $NetworkFormInput -Headers $NetworkHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitNetworkPage.StatusCode)"
}

$PageStateVar = GetPageState
Write-Output $PageStateVar
if ($PageStateVar -like '*Proxy Configuration*' ) {
#LoginPage
$ProxyUri = "https://" + $NMCHostname + "/wizard/proxy/"
$ProxyPage=Invoke-WebRequest -Uri $ProxyUri -skipCertificateCheck -SessionVariable sv 
$Form = $ProxyPage.InputFields
$csrfmiddlewaretoken = $Form[0].value

#Submit Login Page
$ProxyHeaderInput = @{
    "Referer" = $ProxyUri
}
#"id_enabled" = 'off'
$ProxyFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken

   
}


$SubmitProxyPage=Invoke-WebRequest -Uri $ProxyUri -WebSession $sv -Method POST -Form $ProxyFormInput -Headers $ProxyHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitProxyPage.StatusCode)"
}



$PageStateVar = GetPageState
Write-Output $PageStateVar
if ($PageStateVar -like '*Review Network Settings*' ) {
#Updates Page
$ReadyUri = "https://" + $NMCHostname + "/wizard/netready/"

$ReadyPage=Invoke-WebRequest -Uri $ReadyUri -skipCertificateCheck -SessionVariable sv 
$Form = $ReadyPage.InputFields
$csrfmiddlewaretoken = $Form[0].value

#Submit Login Page
$ReadyHeaderInput = @{
    "Referer" = $ReadyUri
}

$ReadyFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
   
   
}

$SubmitReadyPage=Invoke-WebRequest -Uri $ReadyUri -WebSession $sv -Method POST -Form $ReadyFormInput -Headers $ReadyHeaderInput -skipCertificateCheck -MaximumRedirection 0
write-output "-Status Code: $($SubmitReadyPage.StatusCode)"
}


Start-Sleep -s 60


$PageStateVar = GetPageState
Write-Output $PageStateVar
if ($PageStateVar -like '*Update*' ) {
#Updates Page
$UpdatesUri = "https://" + $NMCHostname + "/wizard/updates/"

$UpdatesPage=Invoke-WebRequest -Uri $UpdatesUri -skipCertificateCheck -SessionVariable sv 
$Form = $UpdatesPage.InputFields
$csrfmiddlewaretoken = $Form[0].value

#Submit Login Page
$UpdatesHeaderInput = @{
    "Referer" = $UpdatesUri
}

$UpdatesFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "comfirm" = "on"
}

$SubmitUpdatesPage=Invoke-WebRequest -Uri $UpdatesUri -WebSession $sv -Method POST -Form $UpdatesFormInput -Headers $UpdatesHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitUpdatesPage.StatusCode)"
}




$PageStateVar = GetPageState
Write-Output $PageStateVar
if ($PageStateVar -like '*Terms of Service and License Agreement*' ) {
#Eula Page
$EulaUri = "https://" + $NMCHostname + "/wizard/eula/"

$EulaPage=Invoke-WebRequest -Uri $EulaUri -skipCertificateCheck -SessionVariable sv 
$Form = $EulaPage.InputFields
$csrfmiddlewaretoken = $Form[0].value

#Submit Login Page
$EulaHeaderInput = @{
    "Referer" = $EulaUri

}

$EulaFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "accept" = "on"
}


$EulaPage=Invoke-WebRequest -Uri $EulaUri -WebSession $sv -Method POST -Form $EulaFormInput -Headers $EulaHeaderInput -skipCertificateCheck
}




$PageStateVar = GetPageState
Write-Output $PageStateVar
if ($PageStateVar -like '*Authorization*' ) {
#Serial Page
$SerialUri = "https://" + $NMCHostname + "/wizard/serial/"

$SerialPage=Invoke-WebRequest -Uri $SerialUri -skipCertificateCheck -SessionVariable sv 
$Form = $SerialPage.InputFields
$csrfmiddlewaretoken = $Form[0].value

#Submit Login Page
$SerialHeaderInput = @{
    "Referer" = $SerialUri

}

Write-Output $serial
Write-Output $auth


$SerialFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "serial_number" = $serial
    "auth_code" = $auth
}

Write-Output $SerialFormInput
$SubmitSerial=Invoke-WebRequest -Uri $SerialUri -WebSession $sv -Method POST -Form $SerialFormInput -Headers $SerialHeaderInput -skipCertificateCheck
}

#ConfirmNew
$PageStateVar = GetPageState
Write-Output $PageStateVar
if ($PageStateVar -like '*Confirm New NMC Install*' ) {
$ConfirmNewUri = "https://" + $NMCHostname + "/wizard/confirmnew/"
$GetConfirmNew=Invoke-WebRequest -Uri $ConfirmNewUri -skipCertificateCheck -SessionVariable sv
$Form = $GetConfirmNew.InputFields
$csrfmiddlewaretoken = $Form[0].value
$ConfirmNewHeader = @{
    "Referer" = $ConfirmNewUri
}
$ConfirmNewFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "confirm" = "Install New NMC"
}
write-output "Confirming Install New Edge Appliance"
$SubmitConfirmNew=Invoke-WebRequest -Uri $ConfirmNewUri -WebSession $sv -Method POST -Form $ConfirmNewFormInput -Headers $ConfirmNewHeader -skipCertificateCheck
write-output "-Status Code: $($SubmitConfirmNew.StatusCode)"
}


#Create Admin
$PageStateVar = GetPageState
Write-Output $PageStateVar
if ($PageStateVar -like '*Create Admin User*' ) {
$CreateAdminUri = "https://" + $NMCHostname + "/wizard/createuser/"
$GetCreateAdmin=Invoke-WebRequest -Uri $CreateAdminUri -skipCertificateCheck -SessionVariable sv
$Form = $GetCreateAdmin.InputFields
$csrfmiddlewaretoken = $Form[0].value
$CreateAdminHeader = @{
    "Referer" = $ConfirmNewUri
}
$CreateAdminFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "username" = 	$nmcusername
    "pass1"	= $nmcpassword
    "pass2" = $nmcpassword
}
write-output "Creating new admin user"
$SubmitCreateAdmin=Invoke-WebRequest -Uri $CreateAdminUri -WebSession $sv -Method POST -Form $CreateAdminFormInput -Headers $CreateAdminHeader -skipCertificateCheck
write-output "-Status Code: $($SubmitCreateAdmin.StatusCode)"
}



$PageStateVar = GetPageState
Write-Output $PageStateVar
$LoginUri = "https://" + $NMCHostname + "/login/?next=/"
$GetLogin=Invoke-WebRequest -Uri $LoginUri -skipCertificateCheck -SessionVariable sv 
$Form = $GetLogin.InputFields
$csrfmiddlewaretoken = $Form[0].value

#Submit Login Page
$LoginHeaderInput = @{
    "Referer" = $LoginUri
}

$LoginFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "username" = $nmcusername
    "password" = $nmcpassword
}

#write-output "Logging into the NMC"

$SubmitLogin=Invoke-WebRequest -Uri $LoginUri -WebSession $sv -Method POST -Form $LoginFormInput -Headers $LoginHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitLogin.StatusCode)"


$PageStateVar = GetPageState
Write-Output $PageStateVar
$GroupUri = "https://" + $NMCHostname + "/config/accounts/addgroup/"
$GetGroup=Invoke-WebRequest -uri $GroupUri -skipCertificateCheck -WebSession $sv 
$Form = $GetGroup.InputFields
$csrfmiddlewaretoken = $Form[0].value

$GroupHeaderInput = @{
    "Referer" = $GroupUri
}

$GroupFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "name"	= $groupname
    "storage_access" = "False"
    "permissions" = "142"
    "api_permissions" =	"api"
    "filer_permissions"	= "super_user"
    "extra_emails" =""
    "filer_access" =	"super_user"
    "association" =	""
    "sso_association"	= ""
}



#might be neccessary when sso is enabled
#"sso_association"	= ""
$SubmitGroup=Invoke-WebRequest -Uri $GroupUri -WebSession $sv -Method POST -Form $GroupFormInput -Headers $GroupHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitGroup.StatusCode)"


$PageStateVar = GetPageState
Write-Output $PageStateVar
$UserUri = "https://" + $NMCHostname + "/config/accounts/edituser/1"
$GetUser=Invoke-WebRequest -uri $UserUri -skipCertificateCheck -WebSession $sv 
$Form = $GetUser.InputFields
$csrfmiddlewaretoken = $Form[0].value

$UserHeaderInput = @{
    "Referer" = $UserUri
}

$UserFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "username"  =	"admin"
    "email"	 = $adminemail
    "groups" = "2"
    "new_password1"	= ""
    "new_password2" =	""
}


$SubmitUser=Invoke-WebRequest -Uri $UserUri -WebSession $sv -Method POST -Form $UserFormInput -Headers $UserHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitUser.StatusCode)"


$PageStateVar = GetPageState
Write-Output $PageStateVar
$DNSUri = "https://" + $NMCHostname + "/config/networking/"
$GetDNS=Invoke-WebRequest -uri $DNSUri -skipCertificateCheck -WebSession $sv 
$Form = $GetUser.InputFields
$csrfmiddlewaretoken = $Form[0].value

$DNSHeaderInput = @{
    "Referer" = $DNSUri
}

$DNSFormInput = [ordered]@{
    "csrfmiddlewaretoken" = $csrfmiddlewaretoken
    "confirmation_phrase_hidden" =	"Update Network Configuration"
    "hostname" =  $nmchostname
    "proto" = 	"dhcp2"
    "search_domain"   =	$searchdomain
    "primary_dns" =	$primarydns
    "secondary_dns" =	$secondarydns
    "ipaddr" = 	""
    "netmask" = 	""
    "gateway"  = 	""
    "mtu"  =	"9001"
}


$SubmitDNS=Invoke-WebRequest -Uri $DNSUri -WebSession $sv -Method POST -Form $DNSFormInput -Headers $DNSHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitDNS.StatusCode)"



$DirectoryUri = "https://" + $NMCHostname + "/config/directoryservices/"
$GetDirectory=Invoke-WebRequest -uri $DirectoryUri -skipCertificateCheck -WebSession $sv 
$Form = $GetDirectory.InputFields
$csrfmiddlewaretoken = $Form[1].value

$DirectoryHeaderInput = @{
    "Referer" = $DirectoryUri
    "csrftoken" = $csrfmiddlewaretoken
}

$DirectoryFormInput = [ordered]@{
    "csrfmiddlewaretoken"	=$csrfmiddlewaretoken
    "val_only" =	"false"
    "domain" =	$dirdomain
    "alter_hostname" =	"on"
    "workgroup" =	""
    "controllers" =	""
    "computerou" =	""
    "swap_ntp" =	"on"
    "backend" =	"ipa"
    "ldap_servers" =	""
    "kdcs" =	""
    "ldap_schema" =	""
    "ldap_user_search_base" =	""
    "ldap_group_search_base" =	""
    "ldap_user_name_attr" =	""
    "ldap_group_name_attr" =	""
    "ldap_netgroup_search_base"	= ""
    "ldap_bind_dn" =	""
    "ldap_bind_password" =	""
    "id_min" =	""
    "id_max" = 	""
    "domain_type" =	"ads"
    "username" =	$diruser
    "password" = 	$dirpass
    "password2"	= $dirpass
}


$SubmitDirectory=Invoke-WebRequest -Uri $DirectoryUri -WebSession $sv -Method POST -Form $DirectoryFormInput -Headers $DirectoryHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitDirectory.StatusCode)"

#submit again with val_only set to false so that the request is fully processed
$DirectoryFormInput['val_only'] = 'false'
$SubmitDirectory=Invoke-WebRequest -Uri $DirectoryUri -WebSession $sv -Method POST -Form $DirectoryFormInput -Headers $DirectoryHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitDirectory.StatusCode)"

$AjaxHeaderInput = @{
    "Referer" = $DirectoryUri
    "csrftoken" = $csrfmiddlewaretoken
    "X-Requested-With" = "XMLHttpRequest"
}

$DirectoryConfirmUri = "https://" + $NMCHostname + "/config/directoryservices/wizard_complete/"
$DirectoryConfirmFormInput = [ordered]@{
    "csrfmiddlewaretoken"	=$csrfmiddlewaretoken
    "username" =	$diruser
    "password" = 	$dirpass
    "password2"	= $dirpass
}


$SubmitConfirmDirectory=Invoke-WebRequest -Uri $DirectoryConfirmUri -WebSession $sv -Method POST -Form $DirectoryConfirmFormInput -Headers $AjaxHeaderInput -skipCertificateCheck
write-output "-Status Code: $($SubmitConfirmDirectory.StatusCode)"