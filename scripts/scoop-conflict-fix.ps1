Get-ChildItem "$env:SCOOP\buckets" -Directory | Where-Object { Test-Path "$($_.FullName)\.git" } | ForEach-Object {
    git -C $_.FullName reset --hard
    git -C $_.FullName clean -fd
}
scoop update