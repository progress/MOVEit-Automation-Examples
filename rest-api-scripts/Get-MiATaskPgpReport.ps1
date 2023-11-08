#Requires -Modules @{ ModuleName="MOVEit.MIA"; ModuleVersion="0.3.4" }
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

# Get a list of pgp scripts, pgpkeys and tasks
$pgpScriptList = Get-MIAStandardScript -Name 'PGP*' -Fields ID,Name
$pgpKeyList = Get-MIAPgpKey
$taskList = Get-MIATask

# Initialize an array to hold the results for exporting to csv
$taskReport = @()

# Loop through each task
$taskList | ForEach-Object {   
    $task = $_

    # Determine if this task has any process steps that do PGP and, if so, process this task
    $task | Select-MiATaskStep -StepType Process -Expand | Where-Object {$_.ScriptID -in $pgpScriptList.Id} | ForEach-Object {
        $scriptName = ($pgpScriptList | Where-Object Id -eq $_.ScriptID).Name

        # Determine the recipient key(s) used and their expiration date.  The key could be specified at the process or at
        # the task level.
        $recipientKey = $null
        if ($parameter = ($_.Parameters.Parameter | Where-Object Name -eq 'PGPRecipientKey') ??
                            ($task.Parameters.Parameter | Where-Object Name -eq 'PGPRecipientKey')) {
            $recipientKeyId = $parameter.value -split '\|'
            $recipientKey = $pgpKeyList | Where-Object {$_.Id -in $recipientKeyId}
        }

        # Append the info for this task to an array
        $taskReport += [pscustomobject]@{
            Name                = $task.Name
            Type                = $task.TT
            Scheduled           = $task.Scheduled
            Process             = $scriptName
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
if (-not $SkipCsv) {
    $taskReport | Export-Csv -Path ("{0}_{1:yyyy-MM-ddThhmmss}_PgpTaskReport.csv" -f $Hostname, (Get-Date))
}