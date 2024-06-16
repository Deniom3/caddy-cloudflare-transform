$containers = @(
"library/caddy" # Main caddy container
"deniom3/caddy-cloudflare-transform" # Custom caddy container
)

$imageVersions = @{}
foreach ($container in $containers)
{
    Write-Output "Calling Docker Hub to get $container Versions..."
    $request = Invoke-RestMethod -Method GET -Uri "https://hub.docker.com/v2/repositories/$container/tags"
    $imageVersions[$container] = $request.results.name -match '^\d+\.\d+\.\d+$'
    while ($request.next)
    {
        Write-Output "   ... requesting page $(($request.next -split 'page=')[-1])"
        $request = Invoke-RestMethod -Method GET -Uri $request.next
        $imageVersions[$container] += $request.results.name -match '^\d+\.\d+\.\d+$'
    }

    Write-Output "Found the following $container Versions:"
    Write-Output $imageVersions[$container]
}

$latestOfficialVersion = $imageVersions["library/caddy"][0]
$latestdeniom3Version = $imageVersions["deniom3/caddy-cloudflare-transform"][0]

Write-Output "Latest Offical version: $latestOfficialVersion"
Write-Output "Latest deniom3 version: $latestdeniom3Version"

if ($imageVersions["library/caddy"].IndexOf($imageVersions["deniom3/caddy-cloudflare-transform"][0]) -gt 0)
{
    Write-Output "Docker image deniom3/caddy-cloudflare-transform:$($imageVersions[`"deniom3/caddy-cloudflare-transform`"][0]) is $($imageVersions["library/caddy"].IndexOf($imageVersions["deniom3/caddy-cloudflare-transform"][0])) version behind image library/caddy:$($imageVersions[`"library/caddy`"][0])"
    $regexStrings = Get-Content .\Dockerfile | Select-String '\d+\.\d+\.\d+' -AllMatches

    foreach ($string in $regexStrings)
    {
        Write-Output "   Processing line:     `"$string`""
        $oldString = $string.tostring()
        $newString = $oldString.replace($imageVersions["deniom3/caddy-cloudflare-transform"][0],$latestOfficialVersion)
        Write-Output "   New line:            `"$newString`""
        (Get-Content .\Dockerfile).Replace($oldString,$newString) | Set-Content .\Dockerfile
    }
}
else
{
    Write-Output "Docker image deniom3/caddy-cloudflare-transform:$($imageVersions[`"deniom3/caddy-cloudflare-transform`"][0]) matches image library/caddy:$($imageVersions[`"library/caddy`"][0])"
}


Write-Output ""
Write-Output "***************************************"
Write-Output "Performing Git Operations..."
git config user.email "deniom3@deniom3.tv"
git config user.name "deniom3"
Write-Output "Staging all changed files..."
git add .
if (git diff HEAD)
{
    Write-Output "Committing changes..."
    git commit -m "GitHub Actions commit: Updated caddy to $($latestOfficialVersion) [skip ci]"
    Write-Output "Applying git tag $($latestOfficialVersion)..."
    git tag -a v$($latestOfficialVersion) -m \"Caddy release v$($latestOfficialVersion)\"
    Write-Output "Pushing changes to master repository..."
    git push -q origin HEAD:master
    git push --tags -q origin HEAD:master
}
else
{
    "No changes have been made. Skipping Git Push"
}
Write-Output "Git Operations Complete..."
Write-Output "***************************************"
