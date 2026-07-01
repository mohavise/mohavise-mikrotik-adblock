param(
    [string]$SourcesFile = "sources.txt",
    [string]$AllowlistFile = "allowlist-core.txt",
    [string]$CustomBlocklistFile = "blocklist-custom.txt",
    [string]$DomainOutputFile = "adblock-domains.txt",
    [string]$OutputFile = "adblock-domains.rsc",
    [string]$ListName = "mohavise-adblock"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Read-DomainFile {
    param([string]$Path)

    if (!(Test-Path -LiteralPath $Path)) {
        return @()
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim().ToLowerInvariant()
        if ($line -ne "" -and !$line.StartsWith("#")) {
            $line = $line -replace "^\|\|", ""
            $line = $line -replace "\^$", ""
            $line = $line -replace "^0\.0\.0\.0\s+", ""
            $line = $line -replace "^127\.0\.0\.1\s+", ""
            $line = $line -replace "^address=/", ""
            $line = $line -replace "/.*$", ""

            if ($line -match "^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$") {
                $line
            }
        }
    }
}

function Read-SourceFile {
    param([string]$Path)

    if (!(Test-Path -LiteralPath $Path)) {
        return @()
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -ne "" -and !$line.StartsWith("#")) {
            $line
        }
    }
}

function Test-Allowlisted {
    param(
        [string]$Domain,
        [string[]]$AllowedDomains
    )

    foreach ($allowed in $AllowedDomains) {
        if ($Domain -eq $allowed -or $Domain.EndsWith(".$allowed")) {
            return $true
        }
    }

    return $false
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$sources = Read-SourceFile $SourcesFile
$allow = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
Read-DomainFile $AllowlistFile | ForEach-Object { [void]$allow.Add($_) }
$allowedDomains = @($allow)

$blocks = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

foreach ($source in $sources) {
    try {
        $content = Invoke-WebRequest -Uri $source -UseBasicParsing
        $temp = New-TemporaryFile
        Set-Content -LiteralPath $temp -Value $content.Content -Encoding UTF8
        Read-DomainFile $temp | ForEach-Object { [void]$blocks.Add($_) }
        Remove-Item -LiteralPath $temp -Force
    }
    catch {
        Write-Warning "Failed to download $source"
        Write-Warning $_.Exception.Message
    }
}

Read-DomainFile $CustomBlocklistFile | ForEach-Object { [void]$blocks.Add($_) }

$final = $blocks |
    Where-Object { -not (Test-Allowlisted -Domain $_ -AllowedDomains $allowedDomains) } |
    Sort-Object

Set-Content -LiteralPath $DomainOutputFile -Value $final -Encoding ASCII

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
Write-Host "Generated $DomainOutputFile and $OutputFile with $($final.Count) blocked domains."
