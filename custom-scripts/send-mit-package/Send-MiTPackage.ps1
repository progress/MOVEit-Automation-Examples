# This PowerShell 5.1 script is basically a 'wrapper' for a Pwsh 7 script.  The actual
# script is in the scriptblock which is passed to pwsh.exe.  This allows the actual
# script logic to run using Pwsh 7.

# Checking to make sure this is not the first step.
if ($miaclient.MIGetTaskInfo('NSources') -eq 0) {
    $miaclient.MISetErrorCode(581)
    $miaclient.MISetErrorDescription('ERROR A Send-MiTPackage process cannot be the first step in a task')
    exit
}

# Checking to make sure CacheUsesOriginalNames is configured
if (-not [bool][int]$miaclient.MIGetTaskInfo('CacheUsesOriginalNames')) {
	$miaclient.MISetErrorCode(578)
    $miaclient.MISetErrorDescription("ERROR Task-level 'Cache Files' option must be set to 'Use Original Names'")
    exit
}

# Array of arguments that will get passed in to the pwsh scriptblock
$sbArgs = @(
    $miaclient.MIGetTaskParam('MiT_Hostname')
    $miaclient.MIGetTaskParam('MiT_Username')
    (ConvertTo-SecureString ($miaclient.MIGetTaskParam('MiT_Password')) -AsPlainText -Force)
    $miaclient.MIGetTaskParam('MiT_Package_Recipient')
    $miaclient.MIGetTaskParam('MiT_Package_Subject')
    $miaclient.MIGetTaskParam('MiT_Package_Body')
)    

# Determine if the task is processing one or all downloaded files
if ([bool][int]$miaclient.MIGetTaskInfo('ProcessIsPerFile')) {
	# Single File
    $path = $miaclient.MICacheFilename()
}
else {
	# Multiple Files
	$cacheDir = $miaclient.MICacheDir()
    $cacheFiles = $miaclient.MICacheFiles()
	$path = $cacheFiles.split('|') | ForEach-Object { "$cacheDir\$_" }    
}

# Append the array of cache filepaths to the arguments.
$sbArgs += ,@($path)


# Log the arguments being passed to the scriptblock
$miaclient.MILogMsg("Preparing to send package with arguments:`n" + ($sbArgs | Out-String) )

try {
    # -- Begin pwsh7 scriptblock --
    
    # Call pwsh and pass it the scriptblock and args
    $sbOut = pwsh -Command {
        param(
            [string]$Hostname,
            [string]$Username,
            [SecureString]$Password,
            [string]$Recipient,
            [string]$Subject,
            [string]$Body,
            [string[]]$Path
        )

        try {
            Connect-MITServer -Hostname $Hostname -Credential ([pscredential]::new($Username, $Password))
            
            # Send a package
            $sendPackageParams = @{
                DeliveryReceipts = $true    
                Recipients = New-MITPackageRecipient -Role To -Type Unreg -Identifier $Recipient
                Subject = $Subject
                Body = $Body
                IsSecureBody = $false
                Attachments = @($Path | ForEach-Object { Set-MITPackageAttachment -Path $_ })
                ExpirationHours = 7*24
            }

            Send-MITPackage @sendPackageParams

            Disconnect-MITServer
        }
        catch {
            $PSItem
            exit 1
        }
    } -args $sbArgs
  
    # -- End pwsh7 scriptblock --

    # Log whatever the pwsh7 scriptblock output
    $miaClient.MILogMsg("Sending package output:`n" + ($sbOut | Out-String))

    # If the pwsh7 scriptblock returned an exitcode, throw an exception
    # so the error is logged.
    if (0 -ne $LASTEXITCODE) {
        throw $sbOut
    }
    
    $miaclient.MISetErrorDescription("Package sent to $($sbOut.recipients[0].identifier)")
}
catch {
    $miaclient.MISetErrorCode(10000)
    $miaclient.MISetErrorDescription("Error: " + $PSItem)
}