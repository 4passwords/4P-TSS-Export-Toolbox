
#
#
# export secrets by template v1.2.3
# by jan dijk | MCCS | 4passwords.com
#
# features: export by template, by folder or subfolders & export by datechanged after X
# set the booleans and variables below
#
# you can copy the csv output directly in the import section of Secret server to import the exported secrets by tempalte or date.
#
# TODO-Improvement: Export also pathname to be used in the Secret Server Import
# TODO-Improvement: Specify custom pathname or not pathname at all
# TODO-Improvement: Export results to a file
# TODO-Improvement: Create Authentication wrapper to use Windows Authentication and other authentication options
# TODO-Improvement: Export All templates to a file or console
# TODO-Improvement: Export also Restricted Secrets, like require comment or checkin/checkout (so they are exported and the secret will be created)
# TODO-Improvement: Enemurate the Foldername as is done with the Template name (in combination of suppliing a path or previous)
#
# Note: you will only export secrets that you have permission on and do not have any checkout or requirement comment security options enabled.
# enable the unlimited administrative mode to make sure you can export all secrets that are in secret server.
#
#

###### Script preferences / settings
#
#

# Define the proxy
$url = "https://yoursecretserver.url/webservices/sswebservice.asmx"

# the folderid -1 is the root or open a secret in a folder and see the folderid in the url
$folderId = "-1"

# walk on all the subfolders set it to $true or $false
$searchsubfolders = $true

#give the exact template name
$templateName = "SSH"

#specify the date to lookforupdated or created secrets (specify the date below)
$exportonlysecretsbeforeDate = $false

# enter the date in the format below dd-MM-yyyy hh:mm:ss
$exportonlysecretsbeforeDatevalue = "12-12-2014 23:00:01"

#enter the short domainname, local or empty
$domain = ''

#
#
#### END Script preferences.


############################################
# execution, do not change after this part #
############################################

$proxy = New-WebServiceProxy -uri $url -UseDefaultCredential -Namespace "ss"

#convert manualdate to date object
$exportonlysecretsbeforeDateconverted = (Get-Date $exportonlysecretsbeforeDatevalue)

# Define the user credentials
$username = Read-Host -Prompt "Enter your userid: ";
$password = Read-Host -Prompt "Enter your password: " -AsSecureString;
$otp = Read-Host -Prompt "Enter your OTP for 2FA (displayed in your 2FA app): " -AsSecureString;

#store password
$Credentials = New-Object System.Management.Automation.PSCredential `
     -ArgumentList $username, $password

$CredentialsOTP = New-Object System.Management.Automation.PSCredential `
     -ArgumentList $username, $otp
$tokenResult = $proxy.AuthenticateRADIUS($username, $Credentials.GetNetworkCredential().Password, '', $domain, $CredentialsOTP.GetNetworkCredential().Password)
if($tokenResult.Errors.Count -gt 0)
{
    echo "Authentication Error: " +  $tokenResult.Errors[0]
    Return
}
$token = $tokenResult.Token

# remove password and otp from memory
Remove-Variable password
Remove-Variable otp
Remove-Variable Credentials
Remove-Variable CredentialsOTP

 
 #check templatename
   $templateIdCollection = $proxy.GetSecretTemplates($token).SecretTemplates | Where {$_.Name -eq $templateName}
    if($templateIdCollection -eq $null)
    {
       $msg =  "Error: Unable to find Secret Template " +  $templateName
        echo $msg
        Return
    }

     #check templatename (todo to make folders
  # $folderIdCollection = $proxy.GetSecretTemplates($token).SecretTemplates | Where {$_.Name -eq $templateName}
  #  if($templateIdCollection -eq $null)
  #  {
  #     $msg =  "Error: Unable to find Secret Template " +  $templateName
  #      echo $msg
  #      Return
  #  }

echo "--------------------------------------------"

write-host "Templatename: " -NoNewline
write-host $templateName -NoNewline
write-host " ID: " -NoNewline
write-host $templateIdCollection.Id -NoNewline
write-host
$templateId = $templateIdCollection.Id

echo "--------------------------------------------"
#$templateId = "xxxx";


#begin main

echo "Searching for secrets in folder $folderId with templateid:$templateId"
#SearchSecretsByFolder(token, searchTerm, folderId, includeSubFolders, includeDeleted, includeRestriced)
$secretSummaries = $proxy.SearchSecretsByFolder($token, "", $folderId, $searchsubfolders, $false, $false).SecretSummaries
$sb = new-object system.text.stringBuilder

echo "--------------------------------------------"



foreach($secretSummary in $secretSummaries)
{

    $secretname = $secretSummary.SecretName

    if ($secretSummary.SecretTypeId -eq $templateId)
	    {

       $secretname = $proxy.GetSecret($token, $secretSummary.SecretId, $false, $null);

        $Hash = [ordered]@{}
        $Hashindex = [ordered]@{}
        $Hash.SecretId = $secretSummary.SecretId
        $Hashindex.SecretName = $secretSummary.SecretTypeName
      
        $exportheadercount = 0

        # get all secret values
        foreach($Item in $secret.Secret.Items)
            {
            $Hash.Add($Item.FieldName, $Item.Value)
            }


        # walk the array of shame (header)
        $exportitemcounter = 0
        if ($printheaderamount -eq 0) 
            {

            foreach ($exportheader in $hash.keys) 
                {
                if ($exportheadercount -eq 0) 
                    { 
                    write-host "SecretName," -NoNewline 
                
                    $exportheadercount++
                        } else {
                            write-host "$exportheader," -NoNewline    
                        }
                    } 
                $printheaderamount = 1
                write-host
                }

        # Secret value's in csv
        $exportitemcounter = 0
        foreach ($exportitem in $hash.values) 
            {
            if ($exportitemcounter -eq 0) 
                { 
                
                if ($exportonlysecretsbeforeDate -eq $false) {
                
                        write-host "$script:secretname," -NoNewline 
                    }

                if ($exportonlysecretsbeforeDate -eq $true)
                    {
                    # fetch the audit
                    $auditResult = $proxy.GetSecretAudit($Token,$exportitem)
                    $getlastCREATE =  $auditResult.SecretAudits | select  -Property Action, DateRecorded  | ? { $_ -match "CREATE"  }
                    $getlastUPDATE =  $auditResult.SecretAudits | select  -Property Action, DateRecorded  | ? { $_ -match "UPDATE"  } 

                    $collectDates = @()

                    if ($getlastCREATE.DateRecorded -ne $null) {
                        $collectDates += $getlastCREATE.DateRecorded | sort -Descending | select -First 1
                        }
                    if ($getlastUPDATE.DateRecorded -ne $null) {
                        $collectDates += $getlastUPDATE.DateRecorded | sort -Descending | select -First 1
                        }

                    if ($collectDates -ne $null) {
                        $latestauditDateRaw = $collectDates | sort -Descending | select -First 1
                        }

                    if ($latestauditDateRaw -ne $null) {
                        $latestauditDateCheck = (Get-Date $latestauditDateRaw)
                        }

                    if($latestauditDateCheck -ge $exportonlysecretsbeforeDateconverted) {
                    
                        write-host "$script:secretname," -NoNewline 
                        } else {

                            #write-host "skipping" -NoNewline

                        } 

                       
                    }
                $exportitemcounter++
                } else {
                if ($exportonlysecretsbeforeDate -eq $true)
                    {
                        #write-host "--- " -NoNewline
                        #write-host $latestauditDateCheck -NoNewline
                        #write-host " vs " -NoNewline
                        #write-host $exportonlysecretsbeforeDateconverted -NoNewline
                        #write-host " ---" -NoNewline
                        #write-host ""

                        if($latestauditDateCheck -ge $exportonlysecretsbeforeDateconverted) {
                        write-host `"$exportitem`"`, -NoNewline
                        
                        } else {

                        #write-host "skipping" -NoNewline

                        }



                    } else {
                        write-host `"$exportitem`"`, -NoNewline
                    }

                }
            }

        if ($exportonlysecretsbeforeDate -eq $true) {

                    if($latestauditDateCheck -ge $exportonlysecretsbeforeDateconverted) {
                        #uncomment to debug the dates the secrets are hitted on
                        #write-host "$latestauditDateCheck," -NoNewline
                        write-host 
                    } else {
                        #write-host "skipping" -NoNewline
                    }     

                } else {

                write-host

                }
        $exportitemcounter = 0
       }

}
$printheaderamount = 0
$hash.Clear()
Remove-Variable hash
Remove-Variable token
Remove-Variable tokenResult
 