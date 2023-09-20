#Requires -Modules MOVEit.MIA

<#
.SYNOPSIS
    Sample script to generate a basic report of MOVEit Automation tasks
.NOTES
    This script is only looking at the first source and first destination per
    task.
.COMPONENT
    Requires the MOVEit.MIA module
    Install-Module -Name MOVEit.MIA    
.EXAMPLE
    ./Get-MiATaskReport.ps1 -Hostname <hostname> -Credential <username>
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

# Get a list of hosts and tasks
$hostList = Get-MIAHost
$taskList = Get-MIATask

# Loop through each task
$taskReport = $taskList | ForEach-Object {
    # Get full details for task
    $task = $_ | Get-MIATask

    # Only report on the first source
    $source = $task.steps.Source | Select-Object -First 1

    # Only report on the first destination
    $dest = $task.steps.Destination | Select-Object -First 1

    # Only report on the first success next action
    $successNA = $task.NextActions.NextAction | Where-Object { $_.DoIfSuccess -eq 1 } | Select-Object -First 1

    # Only report on the first failure next action
    $failureNA = $task.NextActions.NextAction | Where-Object { $_.DoIfFailure -eq 1 } | Select-Object -First 1

    [pscustomobject]@{
        Name = $task.Name
        SourceHost = ($hostList | Where-Object { $_.ID -eq $source.HostID}).Name
        SourcePath = if ($source.Type -eq 'siLock') {$source.FolderName} else {$source.Path}
        DestHost = ($hostList | Where-Object { $_.ID -eq $dest.HostID}).Name
        DestPath = if ($dest.Type -eq 'siLock') {$dest.FolderName} else {$dest.Path}
        SuccessEmail = $successNA.AddressTo
        FailureEmail = $failureNA.AddressTo
    }
}

# Write out the results to a CSV File
$taskReport | Export-Csv -Path ("{0}_{1:yyyy-MM-ddThhmmss}_TaskReport.csv" -f $Hostname, (Get-Date))

# Write out the results to the console
$taskReport | Format-Table

Disconnect-MIAServer