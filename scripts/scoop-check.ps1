scoop update
scoop status
$choice = Read-Host "Update All [Y/N] "
if ($choice.ToLower() -eq 'y') {
    sudo scoop update *
    scoop cleanup *
    scoop cache rm *
}
