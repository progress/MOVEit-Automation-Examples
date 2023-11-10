# MOVEit Automation REST API examples
## Description
MOVEit Automation supports a [REST API](https://docs.ipswitch.com/MOVEit/Automation2023/API/REST-API/index.html).  These are some example PowerShell scripts that call the REST API. 

## Requirements
These scripts require
- MOVEit Automation server with REST API option
- PowerShell 7
- [MOVEit.MIA module](https://github.com/Tony-Perri/MOVEit.MIA)

Once you have PowerShell 7 installed, install the MOVEit.MIA module:
```powershell
Install-Module -Name MOVEit.MIA
```
## Usage
After downloading the scripts, simply change directories to the folder containing the scripts and run them.  Feel free to edit them as well, they are examples after all.

### Get-MiAHostReport
Sample script to generate a basic report of MOVEit Automation hosts
```powershell
# Generate a simple Hosts report and save to a CSV file
.\Get-MiAHostReport.ps1 -Hostname <hostname> -Credential <username>

# Optionally skip creating the CSV file
.\Get-MiAHostReport.ps1 -Hostname <hostname> -Credential <username> -SkipCsv
```

### Get-MIATaskActivityReport
Sample script to generate a basic report of MOVEit Automation task activity.
```powershell
.\Get-MiATaskActivityReport.ps1 -Hostname <hostname> -Credential <username>
```

### Get-MiATaskPgpReport
Sample script to generate a report of MOVEit Automation tasks using PGP and the associated key(s)
```powershell
# Generate report and save to CSV file
.\Get-MiATaskPgpReport.ps1 -Hostname <hostname> -Credential <username>

# Optionally skip creating the CSV file
.\Get-MiATaskPgpReport.ps1 -Hostname <hostname> -Credential <username> -SkipCsv
```

### Get-MiATaskReport
Sample script to generate a basic report of MOVEit Automation tasks
```powershell
.\Get-MiATaskReport.ps1 -Hostname <hostname> -Credential <username>
```
## Support
These script examples come with no warranty or support from anyone and are offered as-is.
