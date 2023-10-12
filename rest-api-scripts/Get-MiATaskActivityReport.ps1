#Requires -Modules MOVEit.MIA

<#
.SYNOPSIS
    Sample script to generate a basic report of MOVEit Automation task activity.
.NOTES
    
.COMPONENT
    Requires the MOVEit.MIA module
    Install-Module -Name MOVEit.MIA    
.EXAMPLE
    ./Get-MiATaskActivityReport.ps1 -Hostname <hostname> -Credential <username>
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Hostname,

    [Parameter(Mandatory)]
    [System.Management.Automation.Credential()]
    [pscredential]$Credential
)

# Exit if we can't connect
try { Connect-MIAServer -Hostname $hostname -Credential $Credential } catch { throw }

# Get a list of tasks
$taskList = Get-MIATask

# Initialize an array to hold the results for exporting to csv
$taskReport = @()

# Loop through each task
$taskList | ForEach-Object {
    # Determine the last time the task ran
    $params = @{
        TaskId      = $_.ID
        #Status      = 'Success','Failure'
        #FilesSent   = 1 # or more
        OrderBy     = '!StartTime'
        MaxCount    = 1
    }
    $taskRun = Get-MIAReportTaskRun @params
    
    # Append the info for this task to an array
    $taskReport += [pscustomobject]@{
        Name = $_.Name
        Scheduled = $_.Scheduled
        LastStartTime = $taskRun.StartTime
        Status = $taskRun.Status
        FilesSent = $taskRun.FilesSent
        TotalBytesSent = $taskRun.TotalBytesSent
    }

    # Write the item to the pipeline too so it is displayed to the console
    $taskReport[-1]

} | Format-Table

Disconnect-MIAServer

# Write out the results to a CSV File
$taskReport | Export-Csv -Path ("{0}_{1:yyyy-MM-ddThhmmss}_TaskActivityReport.csv" -f $Hostname, (Get-Date))