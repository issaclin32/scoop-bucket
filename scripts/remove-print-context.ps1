$reg_paths = @(
    'Registry::HKEY_CLASSES_ROOT\txtfile\shell\print'
    'Registry::HKEY_CLASSES_ROOT\batfile\shell\print'
    'Registry::HKEY_CLASSES_ROOT\cmdfile\shell\print'
    'Registry::HKEY_CLASSES_ROOT\ttcfile\shell\print'
    'Registry::HKEY_CLASSES_ROOT\ttffile\shell\print'
    'Registry::HKEY_CLASSES_ROOT\otffile\shell\print'
    'Registry::HKEY_CLASSES_ROOT\rtffile\shell\print'
    'Registry::HKEY_CLASSES_ROOT\regfile\shell\print'
)

$reg_paths | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "Removing $_"
        Remove-Item $_ -Force -Recurse
    }
}


Write-Host "The 'print' command has been removed from .txt/.bat/.cmd/.ttc/.ttf/.otf/.rtf/.reg files" -ForegroundColor Green