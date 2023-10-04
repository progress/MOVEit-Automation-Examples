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

# Initialize an array to hold the results for exporting to csv
$taskReport = @()

# Loop through each task
$taskList | ForEach-Object {
    # Get full details for task
    $task = $_ | Get-MIATask

    # Only report on the first source
    $source = $task.steps.Source | Select-Object -First 1

    # Only report on the first destination
    $dest = switch ($task.TT) {
        'COS'   { $task.steps.For.steps.Destination | Select-Object -First 1 }
        default { $task.steps.Destination | Select-Object -First 1 }
    }

    # Only report on the first success next action
    $successNA = switch ($task.TT) {
        'COS'   {
            ($task.steps.If.When | Where-Object { 
                $_.Criteria.comp.a -eq '[TASKSTATUS]' -and 
                $_.Criteria.comp.b -eq 'Success' -and 
                $_.steps.Email 
            } | Select-Object -First 1).steps.Email
        }
        default {
            $task.NextActions.NextAction | Where-Object { $_.DoIfSuccess -eq 1 } | Select-Object -First 1
        }
    }

    # Only report on the first failure next action
    $failureNA = switch ($task.TT) {
        'COS'   {
            ($task.steps.If.When | Where-Object { 
                $_.Criteria.comp.a -eq '[TASKSTATUS]' -and 
                $_.Criteria.comp.b -eq 'Failure' -and 
                $_.steps.Email 
            } | Select-Object -First 1).steps.Email
        }
        default {
            $task.NextActions.NextAction | Where-Object { $_.DoIfFailure -eq 1 } | Select-Object -First 1
        }
    }

    # Append the info for this task to an array
    $taskReport += [pscustomobject]@{
        Name = $task.Name
        SourceHost = ($hostList | Where-Object { $_.ID -eq $source.HostID}).Name
        SourcePath = if ($source.Type -eq 'siLock') {$source.FolderName} else {$source.Path}
        DestHost = ($hostList | Where-Object { $_.ID -eq $dest.HostID}).Name
        DestPath = if ($dest.Type -eq 'siLock') {$dest.FolderName} else {$dest.Path}
        SuccessEmail = $successNA.AddressTo
        FailureEmail = $failureNA.AddressTo
    }

    # Write the item to the pipeline too so it is displayed to the console
    $taskReport[-1]

} | Format-Table

Disconnect-MIAServer

# Write out the results to a CSV File
$taskReport | Export-Csv -Path ("{0}_{1:yyyy-MM-ddThhmmss}_TaskReport.csv" -f $Hostname, (Get-Date))