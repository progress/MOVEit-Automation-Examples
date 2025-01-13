<#

.SYNOPSIS

MOVEit Automation custom script to generate hash files

.DESCRIPTION

A custom script for MOVEit Automation to generate hash files uploaded along with data files.  For example, if
a task uploads the file 'moveit-automation.pdf', this script can be run as a process step in the task to calculate 
the file hash of the data file and generate the hash file 'moveit-automation.pdf.sha256' which is also uploaded.

.PARAMETER GenerateHash_HashAlgorithm

Task parameter to specify the hash algorithm, such as MD5 or SHA256 (default)

.PARAMETER GenerateHash_HashFileExtension

Task parameter to specify the hash file extension, such as '.md5' or '.sha2'.  The default is
'.<hashAlgorithm>'.

#>

# Checking to make sure this is not the first step.
if ($miaclient.MIGetTaskInfo('NSources') -eq 0) {
    $miaclient.MISetErrorCode(581)
    $miaclient.MISetErrorDescription('ERROR This script cannot be the first step in a task')
    exit
}

# Checking to make sure this is running once-per-file.
if (-not [bool][int]$miaclient.MIGetTaskInfo('ProcessIsPerFile')) {
    $miaclient.MISetErrorCode(584)
    $miaclient.MISetErrorDescription('ERROR This script must be run per-file')
    exit
}

# GenerateHash_HashAlgorithm parameter (default to SHA256)
if (-not ($hashAlgorithm = $miaclient.MIGetTaskParam('GenerateHash_HashAlgorithm'))) {
    # Default
    $hashAlgorithm = 'sha256'
}
$miaclient.MILogMsg("HashAlgorithm: $hashAlgorithm")

# GenerateHash_HashFileExtension parameter
if (-not ($hashFileExtension = $miaclient.MIGetTaskParam('GenerateHash_HashFileExtension'))) {
    # Default based on $hashAlgorithm
    $hashFileExtension = ".$hashAlgorithm"
}
$miaclient.MILogMsg("HashFileExtension: $hashFileExtension")

try {
    # Get the fileinfo of this file  
    $fi = Get-Item -Path $miaclient.MICacheFilename()

    # Compute the hash of the file
    $fileHash = $fi | Get-FileHash -Algorithm $hashAlgorithm

    # Write the hash to a new file to be transferred
    $newCacheFilename = $miaclient.MINewCacheFilename()
    Set-Content -Path $newCacheFilename -Value $fileHash.Hash
    $hashFilename = $miaclient.MIGetOriginalFilename() + $hashFileExtension
    $miaclient.MIAddFile($newCacheFilename, $hashFilename)

    # log the hash
    $miaclient.MISetErrorDescription("$($fileHash.Algorithm)=$($fileHash.Hash)")
}
catch {
    $miaclient.MISetErrorCode(10000)
    $miaclient.MISetErrorDescription("Error: " + $Error)
 }