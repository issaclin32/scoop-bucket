# credit: https://gregramsey.net/2014/05/14/automating-the-disk-cleanup-utility/
# more info here: http://support.microsoft.com/kb/253597

param(
    [Alias('r')]
    [switch]
    $ResetFlags
)

# check admin rights
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$is_admin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!($is_admin)){
    Write-Host 'This program requires admin rights' -ForegroundColor Red
    exit(1)
}

#ensure we're running on windows 8.1 (or up) first
$win_version = [System.Version](Get-CimInstance win32_operatingsystem).version
if ($win_version -lt [System.Version]'6.3.9600') {
    Write-Host 'This script requires Windows 8.1 or later' -ForegroundColor Red
    exit(1)
}

# check Powershell version
# '-ge 6' works in Powershell 7, but not in Powershell 5
if ($PSversionTable.PSVersion -ge [Version]::new(6,0,0,0)) { $func = 'Get-CimInstance' }
else { $func = 'Get-WmiObject' }

# Capture current free disk space on Drive C
$free_space_before = (&$func win32_logicaldisk -filter "DeviceID='C:'" | select-object Freespace).FreeSpace/1GB

$common_items = @(
    'Active Setup Temp Folders',
    'BranchCache',
    'Downloaded Program Files',
    'Internet Cache Files',
    'Old ChkDsk Files',
    'Previous Installations',
    'Recycle Bin',
    'Setup Log Files',
    'System error memory dump files',
    'System error minidump files',
    'Temporary Files',
    'Temporary Setup Files',
    'Update Cleanup',
    'Upgrade Discarded Files',
    'User file versions',
    'Windows Defender',
    'Windows ESD installation files',
    'Windows Upgrade Log Files'
)

$win_8_1_only = @(
    'Service Pack Cleanup',
    'Memory Dump Files',
    'Windows Error Reporting Archive Files',
    'Windows Error Reporting Queue Files',
    'Windows Error Reporting System Archive Files',
    'Windows Error Reporting System Queue Files'   
)

$win_10_only = @(
    'Language Pack',
    'RetailDemo Offline Content',
    'Temporary Sync Files',
    'Windows Error Reporting Files'
)

function Set-Flags {
    param(
        [Parameter(Mandatory=$True)]
        [String[]]
        $Flags
    )
    $Flags | ForEach-Object{
        Set-ItemProperty -path ('HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\{0}' -f $_) -name StateFlags0012 -type DWORD -Value 2
    }
    return
}

# Set StateFlags0012 setting for each item in Windows disk cleanup utility
if ($ResetFlags -or (-not (get-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name StateFlags0012 -ErrorAction SilentlyContinue))) {
    Write-Host 'Setting up StateFlags0012 for each item in disk cleanup utility' -ForegroundColor Yellow
    Set-Flags($common_items)
    
    # win 8.1
    if ($win_version -lt [System.Version]'10.0') {
        Set-Flags($win_8_1_only)
    }
    # win 10
    if ($win_version -ge [System.Version]'10.0') {
        Set-Flags($win_10_only)
    }
}
 
cleanmgr /sagerun:12

$seconds_elapsed = 0
do {
    Write-Host $("`rwaiting for cleanmgr to complete... ({0} seconds elapsed)" -f $seconds_elapsed) -NoNewline
    start-sleep 10
    $seconds_elapsed += 10
} while ((&$func win32_process | where-object {$_.processname -eq 'cleanmgr.exe'} | measure-object).count)
 
$free_space_after = (&$func win32_logicaldisk -filter "DeviceID='C:'" | select-object Freespace).FreeSpace/1GB
 
"`nFree Space Before Cleaning: {0:0.##} GB" -f $free_space_before
"Free Space After Cleaning: {0:0.##} GB" -f $free_space_after
