# 4Passwords / Thycotic Secret Server Export Toolbox

This powershell script is a script to Export Secrets from Thycotic Secret Server by Template and by date in an format that can be imported in secret server.

The feature to export by template is something we were missing for years. In this powershell script we can do this and much more.

The scripts features are:

- Export all secrets by template
- Export all secrets by template and from a given dat that were updated or changed

TODO improvements:

- Export also pathname to be used in the Secret Server Import
- Specify custom pathname or not pathname at all
- Export results to a file
- Create Authentication wrapper to use Windows Authentication and other authentication options (currently only UID+Pass and OTP)
- Export All templates to seperate files or console
- Export Restricted Secrets, like require comment or checkin/checkout (so they are exported and the secret will be created)
- Enumerate the Foldername as is done with the Template name (in combination of suppliing a path or previous)
