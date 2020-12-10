Write-Host
Write-Host "Letzter bekannte Release:"
git log | grep release | select -First 1

Write-Host
$rel = Read-Host "Neue Release Version ?"

if(-not $rel.StartsWith("v")){
    $rel="v"+$rel
}

Write-Host
git flow release start "$rel"

Write-Host
git commit -a -m"Release $rel"

Write-Host
git flow release finish -m"Release finished"

Write-Host
git push origin --all
git push origin --tags

Pause
