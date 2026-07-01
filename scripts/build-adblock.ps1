param(
    [string]$CoreUrl = "https://raw.githubusercontent.com/mohavise/mohavise-adblock-core/main/core-domains.txt",
    [string]$DomainOutputFile = "..\adblock-domains.txt",
    [string]$HostOutputFile = "..\adblock-hosts.txt",
    [string]$OutputFile = "..\adblock-domains.rsc",
    [string]$ListName = "mohavise-adblock"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptRoot

if (Test-Path -LiteralPath $CoreUrl) {
    $coreLines = Get-Content -LiteralPath $CoreUrl
} else {
    $content = Invoke-WebRequest -Uri $CoreUrl -UseBasicParsing
    $coreLines = $content.Content -split "`r?`n"
}

$final = $coreLines |
    ForEach-Object { $_.Trim().ToLowerInvariant() } |
    Where-Object { $_ -ne "" -and !$_.StartsWith("#") } |
    Sort-Object -Unique

Set-Content -LiteralPath $DomainOutputFile -Value $final -Encoding ASCII
Set-Content -LiteralPath $HostOutputFile -Value ($final | ForEach-Object { "0.0.0.0 $_" }) -Encoding ASCII

$updated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
$lines = [System.Collections.Generic.List[string]]::new()
[void]$lines.Add("# managed-by=mohavise-mikrotik-adblock")
[void]$lines.Add("# project=mohavise-adlist-block")
[void]$lines.Add("# do-not-edit-manually")
[void]$lines.Add("# generated-at=$updated")
[void]$lines.Add("/ip dns static remove [/ip dns static find comment~`"managed-by=mohavise-mikrotik-adblock`"]")

foreach ($domain in $final) {
    [void]$lines.Add(":do { /ip dns static add name=$domain address=0.0.0.0 type=A comment=`"managed-by=mohavise-mikrotik-adblock list=$ListName`" } on-error={}")
}

Set-Content -LiteralPath $OutputFile -Value $lines -Encoding ASCII
Write-Host "Generated $DomainOutputFile, $HostOutputFile, and $OutputFile with $($final.Count) blocked domains."
