#Requires -Modules MOVEit.MIA

<#
.SYNOPSIS
    Sample script to generate a basic report of MOVEit Automation hosts
.NOTES
.COMPONENT
    Requires the MOVEit.MIA module
    Install-Module -Name MOVEit.MIA    
.EXAMPLE
    ./Get-MiAHostReport.ps1 -Hostname <hostname> -Credential <username>
.EXAMPLE
    ./Get-MiAHostReport.ps1 -Hostname <hostname> -Credential <username> -SkipCsv
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Hostname,

    [Parameter(Mandatory)]
    [System.Management.Automation.Credential()]
    [pscredential]$Credential,

    [Parameter()]
    [switch]$SkipCsv
)

# Exit if we can't connect
try { Connect-MIAServer -Hostname $hostname -Credential $Credential } catch { throw }

# Initialize an array to hold the results for exporting to csv
$hostReport = @()

# Loop through each host
Get-MIAHost | ForEach-Object {    
    # Append the info for this task to an array
    $hostReport += [pscustomobject]@{
        Id          = $_.ID
        Name        = $_.Name
        Type        = $_.Type
        Host        = $_.Host
        DefUsername = $_.DefUsername
        Desc        = $_.Desc
        UsedByCount = $_.UsedByCount
    }

    # Write the item to the pipeline too so it is displayed to the console
    $hostReport[-1]

} | Format-Table

Disconnect-MIAServer

# Write out the results to a CSV File
if (-not $SkipCsv) {
    $hostReport | Export-Csv -Path ("{0}_{1:yyyy-MM-ddThhmmss}_HostReport.csv" -f $Hostname, (Get-Date))
}