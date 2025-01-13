<#

.SYNOPSIS

MOVEit Automation custom script to verify hash files

.DESCRIPTION

A custom script for MOVEit Automation to verify hash files downloaded along with data files.  For example, if
a task downloads the files 'moveit-automation.pdf' and 'moveit-automation.pdf.sha256', this script can be run
as a process step in the task to calculate the file hash of the data file and verify it against the hash contained
in the hash file.

.PARAMETER VerifyHash_HashAlgorithm

Task parameter to specify the hash algorithm, such as MD5 or SHA256 (default)

.PARAMETER VerifyHash_HashFileExtension

Task parameter to specify the hash file extension, such as '.md5' or '.sha2'.  The default is
'.<hashAlgorithm>'.

.PARAMETER VerifyHash_IgnoreHashFile

Task parameter to determine if the hash files are moved/copied to the destination or ignored (default).  Set to 
'False' in order to move/copy the hash files to the destination.

.PARAMETER VerifyHash_RequireHash

Task parameter to determine if a hash file is required.  Default is true so any files w/out a cooresponding hash file 
will not be processed.  Set to 'False' to not require a hash file

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

# Checking to make sure CacheUsesOriginalNames.
if (-not [bool][int]$miaclient.MIGetTaskInfo('CacheUsesOriginalNames')) {
    $miaclient.MISetErrorCode(578)
    $miaclient.MISetErrorDescription("ERROR Task-level 'Cache Files' option must be set to 'Use Original Names'")
    exit
}

# VerifyHash_HashAlgorithm parameter (default to SHA256)
if (-not ($hashAlgorithm = $miaclient.MIGetTaskParam('VerifyHash_HashAlgorithm'))) {
    # Default
    $hashAlgorithm = 'sha256'
}
$miaclient.MILogMsg("HashAlgorithm: $hashAlgorithm")

# VerifyHash_HashFileExtension parameter
if (-not ($hashFileExtension = $miaclient.MIGetTaskParam('VerifyHash_HashFileExtension'))) {
    # Default based on $hashAlgorithm
    $hashFileExtension = ".$hashAlgorithm"
}
$miaclient.MILogMsg("HashFileExtension: $hashFileExtension")

# VerifyHash_IgnoreHashFile parameter (default is $True)
$ignoreHashFile = (-not ($miaclient.MIGetTaskParam('VerifyHash_IgnoreHashFile') -eq "$False"))
$miaclient.MILogMsg("IgnoreHashFile: $ignoreHashFile")

# VerifyHash_RequireHashFile parameter (default is $True)
$requireHashFile = (-not ($miaclient.MIGetTaskParam('VerifyHash_RequireHashFile') -eq "$False"))
$miaclient.MILogMsg("RequireHashFile: $requireHashFile")

try {
    # Get the fileinfo of this file  
    $fi = Get-Item -Path $miaclient.MICacheFilename()

    # See if it is an actual file or a hash file based on the extension
    if ( $fi.Extension -ne $hashFileExtension ) {
        # Verify there is a cooresponding hash file
        $hashFilepath = "$fi$hashFileExtension" 
        if ( Test-Path -Path $hashFilepath) {
            # Compute the hash of the file and compare to the hash in the hash file
            $fileHash = $fi | Get-FileHash -Algorithm $hashAlgorithm
            if ( $fileHash.Hash -eq (Get-Content -Path $hashFilepath) ) {
                # Hashes match, so we'll log the hash
                $miaclient.MISetErrorDescription("$($fileHash.Algorithm)=$($fileHash.Hash)")
            }
            else {
                # Hash mismatch
                $miaclient.MISetErrorCode(501)
                $miaclient.MISetErrorDescription("Calculated hash does not match hash file")
            }
        }
        else {
            # No cooresponding hash file
            if ($requireHashFile) {
                $miaclient.MISetErrorCode(502)
                $miaclient.MISetErrorDescription("No cooresponding hash file")
            }
        }
    }
    else {
        # Ignore the hash file
        if ($ignoreHashFile) {
            $miaclient.MIIgnoreThisFile($true, $false)
        }
    }  
}
catch {
   $miaclient.MISetErrorCode(10000)
   $miaclient.MISetErrorDescription("Error: " + $Error)
}