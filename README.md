# 4Passwords / Thycotic Secret Server Export Toolbox

This powershell script is a script to Export Secrets from Thycotic Secret Server by Template and by date in an format that can be imported in secret server.

The feature to export by template is something we were missing for years. In this powershell script we can do this and much more.

The scripts features are:

- Export all secrets by template
- Export all secrets by template from a given date that were updated or changed
- Export Full pathnames to be used in the Secret Server Import
- Added options to Specify custom pathname or no pathname at all

TODO improvements:

- Export results to a file
- Create Authentication wrapper to use Windows Authentication and other authentication options (currently only UID+Pass and OTP)
- Export All templates to seperate files or console
- Export Restricted Secrets, like require comment or checkin/checkout (so they are exported and the secret will be created)
- Enumerate the Foldername as is done with the Template name (in combination of suppliing a path or previous)

To use the script, you need to change the preferences inside the script that are in the top

###### Script preferences / settings
#
#

# Define the proxy
$url = "https://yoursecretserver.uri/webservices/sswebservice.asmx"

# the folderid -1 is the root or open a secret in a folder and see the folderid in the url
$folderId = "-1"

# walk on all the subfolders set it to $true or $false
$searchsubfolders = $true

# add the folder path of the secret to the export list
$addfolderpathtoexport = $true

# override folder path from the exported secret path with a custom path
$overridefolderpath = $false
$overridefolderpathValue = "/Import"

#give the exact template name
$templateName = "SSH"

#specify the date to lookforupdated or created secrets (specify the date below)
$exportonlysecretsbeforeDate = $false

# enter the date in the format below dd-MM-yyyy hh:mm:ss
$exportonlysecretsbeforeDatevalue = "01-02-2015 23:00:01"

#enter the short domainname, local or empty
$domain = ''

#
#
#### END Script preferences.


