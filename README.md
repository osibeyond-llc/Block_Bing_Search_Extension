# Block_Bing_Search_Extension
A Powershell script to run on domain controllers to prevent Office 365 updates from installing the new extension that will force Bing as the default search engine in Chrome and Firefox
This script needs to be run on the domain controller with the FSMO roles. If there is not a Central Store already configured to push GPOs to replicated servers, it will create that central store and then download the administrative template files for the newest version of Office. It will extract those .admx files and copy them to the central store, then create the GPO that prevents Office 365 updates from pushing the Bing Search extension with the monthly productivity app updates. It uses the registry key `HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate` - which corresponds to the GPO item Computer Configuration -> Policies -> Administrative Templates -> Microsoft Office -> Updates -> Don't Install Extension for Microsoft Search in Bing that makes Bing the default search engine -> enabled. This will then link the GPO to the root of the AD forest, but this can be configured to apply to individual OUs in more organized domains.
