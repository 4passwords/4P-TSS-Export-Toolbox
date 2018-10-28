# 4Passwords / Thycotic Secret Server Export Toolbox
# v1.2.6

This powershell script is a script to Export Secrets from Thycotic Secret Server by Template and by date in an format that can be imported in secret server.

The feature to export by template is something we were missing for years. In this powershell script we can do this and much more.

The scripts features are:

- Export by template, by folder or subfolders
- Export all secrets by template from a given date that were updated or changed (good for migrations and or finding out changes overtime0
- Export foldernames and or override the foldernames in the exportlist (to customize and or be flexible for the import) or export no foldernames at all
- Export secrets with issue-374730518 to a configurable "Lost and Found" folder
- Authentication wrapper to use Oauth Authentication, Radius/OTP and Windows Authentication

TODO testing:

- TODO-TEST: Authentication methods oauth with or without Radius/OTP are tested, windows authentication needs to be fully tested.

TODO improvements:

- TODO-Improvement: Export All templates to a file or console
- TODO-Improvement: Export also Restricted Secrets, like require comment or checkin/checkout (so they are exported and the secret will be created)
- TODO-Improvement: Enemurate the Foldername as is done with the Template name (the idea is to supply a Full pathname)

To use the script, you need to change the preferences inside the script that are in the top

```powershell
###### Script preferences / settings
#
#

# Define the proxy
$url = "https://yoursecretserver.url/folder"

# craft the 
$urlOauth = $url + "/webservices/sswebservice.asmx"
$urlWindows = $url + "/winauthwebservices/sswinauthwebservice.asmx"

# script authentication method 
# use Windows Authentication or Oauth. (optoins: oauth,windows)
#
$scriptauth = "oauth"
#
# ask for otp / radius
$authenticateRadiusOTP = $true

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





