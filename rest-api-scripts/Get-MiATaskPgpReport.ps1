#Requires -Modules MOVEit.MIA
#Requires -Version 7

<#
.SYNOPSIS
    Sample script to generate a report of MOVEit Automation tasks using PGP and
    the associated key(s)
.NOTES    
.COMPONENT
    Requires the MOVEit.MIA module
    Install-Module -Name MOVEit.MIA    
.EXAMPLE
    ./Get-MiATaskPgpReport.ps1 -Hostname <hostname> -Credential <username>
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

# Define a function to recurse through a task and find all steps
function Select-MiATaskStep {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [psobject]$InputObject,
        
        [Parameter()]
        [ValidateSet('Source', 'Process', 'Destination', 'NextAction', 'Email')]
        [string[]]$StepName = @('Source', 'Process', 'Destination', 'NextAction', 'Email')
    )

    begin {        
        $containerName = 'steps', 'For', 'If', 'When'
    }

    process {        
        $InputObject.PSObject.Properties | ForEach-Object {
            if ($_.Name -in $StepName) {
                # This is a property we are looking for
                [pscustomobject]@{$_.Name = $_.Value}                
            }
            elseif ($_.Name -in $containerName) {
                # Recurse
                $_.Value | Select-MiATaskStep -StepName $StepName
            }
        }
    }
}

$pgpScript = @(
    [PSCustomObject]@{Id = 100021; Name = 'PGP Encrypt Only'}
    [PSCustomObject]@{Id = 100022; Name = 'PGP Encrypt and Sign'}
    [PSCustomObject]@{Id = 100023; Name = 'PGP Decrypt'}
)

# Get a list of keys and tasks
$pgpKeyList = Get-MIAPgpKey
$taskList = Get-MIATask

# Initialize an array to hold the results for exporting to csv
$taskReport = @()

# Loop through each task
$taskList | ForEach-Object {   
    $task = $_

    # Determine if this task has any process steps that do PGP and, if so, process this task
    $task | Select-MiATaskStep -StepName Process | Where-Object {$pgpScript.Id -eq $_.Process.ScriptID} | ForEach-Object {
        $process = $_.process

        # Determine the recipient key(s) used and their expiration date.  The key could be specified at the process or at
        # the task level.
        $recipientKey = $null
        if ($parameter = ($process.Parameters.Parameter | Where-Object Name -eq 'PGPRecipientKey') ??
                            ($task.Parameters.Parameter | Where-Object Name -eq 'PGPRecipientKey')) {
            $recipientKeyId = $parameter.value -split '\|'
            $recipientKey = $pgpKeyList | Where-Object {$_.Id -in $recipientKeyId}
        }

        # Append the info for this task to an array
        $taskReport += [pscustomobject]@{
            Name                = $task.Name
            Type                = $task.TT
            Scheduled           = $task.Scheduled
            Process             = ($pgpScript | Where-Object Id -eq $process.ScriptID).Name
            RecipientKey        = $recipientKey.Uid #-join '; '
            RecipientKeyPubPriv = $recipientKey.PubPriv #-join '; '
            RecipientKeyExpires = $recipientKey.Expires #-join '; '
        }

        # Write the item to the pipeline too so it is displayed to the console
        $taskReport[-1]
    }
} | Format-Table

Disconnect-MIAServer

# Write out the results to a CSV File
if (!$SkipCsv) {
    $taskReport | Export-Csv -Path ("{0}_{1:yyyy-MM-ddThhmmss}_PgpTaskReport.csv" -f $Hostname, (Get-Date))
}