#
# export secrets by template v1.2.5
# by jan dijk | MCCS | 4passwords.com
# https://github.com/4passwords/4P-TSS-Export-Toolbox
#
# set the booleans and variables below in the preferences section
# you can copy the csv output directly in the import section of Secret server to import the exported secrets by template or date.
#
#
# Script Features: 
#
# Export by template, by folder or subfolders
# Export all secrets by template from a given date that were updated or changed (good for migrations and or finding out changes overtime0
# Export foldernames and or override the foldernames in the exportlist (to customize and or be flexible for the import) or export no foldernames at all
# Export secrets with issue-374730518 to a configurable "Lost and Found" folder
#
# TODO-Improvement: Create Authentication wrapper to use Windows Authentication and other authentication options
# TODO-Improvement: Export All templates to a file or console
# TODO-Improvement: Export also Restricted Secrets, like require comment or checkin/checkout (so they are exported and the secret will be created)
# TODO-Improvement: Enemurate the Foldername as is done with the Template name (in combination of suppling a path or previous)
#
# Note: you will only export secrets that you have permission on and do not have any checkout or requirement comment security options enabled.
# enable the unlimited administrative mode to make sure you can export all secrets that are in secret server.
#
# issue-374730518: there is a small bug in retrieving a foldername from the api or the Thycotic interface, when you do not have all permissions on the folder tree (when a secret is shared from a folder directly)
# https://github.com/4passwords/4P-TSS-Export-Toolbox/issues/1#issue-374730518
# to work arround this: 1) turn off Admin/Configuration/Folder/View Permission on Specific Folder for Visibility or 2) unlimited admin mode or have permissions
#
# issue-374737457: there is a maximum runtime of the script. this is a hard set configurable parameter within Thycotic Secret Server (default 20 minutes)
# go Admin/General/Session Timeout for Webservices and configure it for the runtime you need for the export to complete
#
#

###### Script preferences / settings
#
#

# Define the proxy
$url = "https://yoursecretserver.url/webservices/sswebservice.asmx"

#enter the short domainname, local or empty
$domain = ''

#give the exact template name
$templateName = "SSH"

# the folderid -1 is the root or open a secret in a folder and see the folderid in the url
$folderId = "-1"

# walk on all the subfolders set it to $true or $false
$searchsubfolders = $true

# add the folder path of the secret to the export list
$addfolderpathtoexport = $true

# override folder path from the exported secret path with a custom path
$overridefolderpath = $false
$overridefolderpathValue = "\Import"

# specify the path where we need to place secrets that are affected by issue-374730518
$lostandfoundpathValue = "\Lost & Found"

#specify the date to lookforupdated or created secrets (specify the date below)
$exportonlysecretsbeforeDate = $false

# enter the date in the format below dd-MM-yyyy hh:mm:ss
$exportonlysecretsbeforeDatevalue = "01-02-2015 23:00:01"

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

echo "--------------------------------------------"



foreach($secretSummary in $secretSummaries)
{

    $secretname = $secretSummary.SecretName

    if ($secretSummary.SecretTypeId -eq $templateId)
	    {

       $secret = $proxy.GetSecret($token, $secretSummary.SecretId, $false, $null);

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
            
        # add the folderpath

        if ($addfolderpathtoexport -eq $true) 
            {

                if ($overridefolderpath -eq $true)
                    {
                       #add the override folder to the hash
                       $Hash.Add("Folder Name", "$overridefolderpathValue")
                    } else {
                        # enumerate the folder structure of a secret. and add it

                        # special case if the secret is in the root, then there is no path name and we need to skip it
                        if ( $secret.Secret.FolderId -ne "-1" )

                            {

                                #fetchfullfolderpatch
                                $testvar = Test-Path variable:Hashfolder
                                if ( $testvar -eq $true ) {
                                    $Hashfolder.clear()
                                    }
                                Remove-Variable testvar

                                $Hashfolder = [ordered]@{}
                                $secretfolderResult = $proxy.FolderGet($Token,$secret.Secret.FolderId)

                                # debug issue-374730518
                                #write-host
                                #write-host  "folderid:" $secretfolderResult.Folder.Id -NoNewline
                                #write-host  " foldername:" $secretfolderResult.Folder.name -NoNewline
                                #Write-Host

                                # check if we have issue-374730518 and skipt the retrieve folderpathbug with no rights to full folder
                                if ( $secretfolderResult.Folder.Id -ne $null )
                                {
                                $Hashfolder.add($secretfolderResult.Folder.Name,$secretfolderResult.Folder.Id)
                                $parentfolderResult = $proxy.FolderGet($Token,$secretfolderResult.Folder.ParentFolderId)

                                #checking if we have only one level then not add the parent
                                if ($parentfolderResult.Folder.Id -ne $null )
                                    { 
                                    $Hashfolder.add($parentfolderResult.Folder.Name,$parentfolderResult.Folder.Id)  
                                    } 

                                    $loopbreakpoint=0
                                    #$parentfolderResult = $proxy.FolderGet($Token,$parentfolderResult.Folder.ParentFolderId)
                                    DO
                                    {
                                    $parentfolderResult = $proxy.FolderGet($Token,$parentfolderResult.Folder.ParentFolderId)
                                    if ($parentfolderResult.Folder.Id -ne $null )
                                        {
                                            $Hashfolder.add($parentfolderResult.Folder.Name,$parentfolderResult.Folder.Id)
                                        }
                                    if ($parentfolderResult.Folder.Id -eq $null )
                                        {
                                            $loopbreakpoint=1
                                        }

                                    } While ($loopbreakpoint=0)

                                    $reversefolderindex = New-Object System.Collections.ArrayList
                                    foreach($BuildFolderlist in $Hashfolder.Keys)
                                        {
                                            $reversefolderindex.Add($BuildFolderlist) > null
                                        }
                                    $reversefolderindex.Reverse()
                        
                                    ForEach ($folderitem in $reversefolderindex) { $generatedfolderpath = $generatedfolderpath + "\$folderitem" }
                                    $Hash.Add("Folder Name", $generatedfolderpath)

                                    Remove-Variable generatedfolderpath

                                  # end of adding single item to path
                                } else {

                                # give the issue-374730518 secrets a special folder
                                $Hash.Add("Folder Name", $lostandfoundpathValue)

                                }
                            # end of root check
                            }

                    }
                
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
Remove-Variable hashfolder
Remove-Variable token
Remove-Variable tokenResult
 
