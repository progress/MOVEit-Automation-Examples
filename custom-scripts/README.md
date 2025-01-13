# MOVEit Automation Custom Scripts

## Description
MOVEit Automation supports [custom scripts](https://docs.progress.com/bundle/moveit-automation-web-admin-help-2024/page/Custom-Scripts.html).  These are some example custom scripts. 

### Generate-HashFile
A custom script for MOVEit Automation to generate hash files uploaded along with data files.  For example, if
a task uploads the file 'moveit-automation.pdf', this script can be run as a process step in the task to calculate 
the file hash of the data file and generate the hash file 'moveit-automation.pdf.sha256' which is also uploaded.

### Verify-HashFile
A custom script for MOVEit Automation to verify hash files downloaded along with data files.  For example, if
a task downloads the files 'moveit-automation.pdf' and 'moveit-automation.pdf.sha256', this script can be run
as a process step in the task to calculate the file hash of the data file and verify it against the hash contained
in the hash file.

### Send-MiTPackage
MOVEit Automation natively supports transfering files to/from MOVEit Transfer folders.  However, it does not support sending files as ad hoc packages, which is primarily indended as a person-to-person interface.  This example custom script can be used to _automate_ sending files as ad hoc packages using the MOVEit Transfer REST API.

## Support
These script examples come with no warranty or support from anyone and are offered as-is.