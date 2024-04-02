# MOVEit Automation "Send-MITPackage" example script
## Description
MOVEit Automation natively supports transfering files to/from MOVEit Transfer folders.  However, it does not support sending files as ad hoc packages, which is primarily indended as a person-to-person interface.  This example custom script can be used to _automate_ sending files as ad hoc packages using the MOVEit Transfer REST API.
## Requirements
This example script is a bit unique in that is makes use of PowerShell 7 by calling `pwsh` from a MOVEit Automation custom script, which is based on Windows PowerShell (x86).

This script require the following on the MOVEit Automation server
 - PowerShell 7
 - MOVEit.MIT module

 Once you have PowerShell 7 installed, install the MOVEit.MIT module:
 ```powershell
 Install-Module -Name MOVEit.MIT -AllUsers
 ```
## Usage
Perform the following to configure a MOVEit Automation task to send file(s) as an ad hoc package:

1. In MOVEit Automation, add a new script by either importing or copy/pasting [Send-MiTPackage](Send-MiTPackage.ps1).
2. Add a new traditional task.
3. Configure the task to 'Use original names' for 'Cache Files'
4. Add a 'source' to load the file(s) to send.
5. Add a 'process' to run the custom script added in step 1.
6. Edit the process parameters and add the following:
    * MiT_Hostname
    * MiT_Username
    * MiT_Password (_hint: configure as secure parameter_)
    * MiT_Package_Recipient
    * MiT_Package_Subject
    * MiT_Package_Body
7.  Configure the process to either:
    * Run 'Per File' and 'Use process as a destination'.  This will send one package per-file and also result in the 'Files Sent' and 'Total Bytes' being reflected in the 'Task Run' report.
    * Run 'Once After All Downloads'.  This will send all files in a single package.

At this point, the task should be ready to test.