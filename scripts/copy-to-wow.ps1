[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [Alias("Path")]
    [string[]] $WowRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$addonName = "BuffTimers"
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$sourceDirectories = @("libs", "Media")
$sourceFiles = @(
    "BuffTimers.lua",
    "BuffTimers.toc",
    "embeds.xml",
    "Locales.lua",
    "Options.lua"
)

foreach ($directoryName in $sourceDirectories) {
    $sourcePath = Join-Path $sourceRoot $directoryName
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        throw "Required source directory not found: $sourcePath"
    }
}

foreach ($fileName in $sourceFiles) {
    $sourcePath = Join-Path $sourceRoot $fileName
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Required source file not found: $sourcePath"
    }
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Source,

        [Parameter(Mandatory = $true)]
        [string] $Destination
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
        $destinationPath = Join-Path $Destination $item.Name

        if ($item.PSIsContainer) {
            Copy-DirectoryContents -Source $item.FullName -Destination $destinationPath
        }
        else {
            Copy-Item -LiteralPath $item.FullName -Destination $destinationPath -Force
        }
    }
}

function Test-WowClientDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo] $Directory
    )

    if ($Directory.Name -notmatch '^_.+_$') {
        return $false
    }

    $flavorFile = Join-Path $Directory.FullName ".flavor.info"
    if (Test-Path -LiteralPath $flavorFile -PathType Leaf) {
        return $true
    }

    return @(
        Get-ChildItem -LiteralPath $Directory.FullName -Filter "Wow*.exe" -File -ErrorAction SilentlyContinue
    ).Count -gt 0
}

$candidateRoots = @()
$explicitRoots = $PSBoundParameters.ContainsKey("WowRoot")

if ($explicitRoots) {
    if (-not $WowRoot -or $WowRoot.Count -eq 0) {
        throw "At least one path must be supplied with -WowRoot."
    }

    $candidateRoots += $WowRoot
}
else {
    $uninstallKeyPatterns = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    if (Get-PSDrive -Name HKLM -ErrorAction SilentlyContinue) {
        foreach ($entry in Get-ItemProperty -Path $uninstallKeyPatterns -ErrorAction SilentlyContinue) {
            $displayName = $entry.PSObject.Properties["DisplayName"]
            $installLocation = $entry.PSObject.Properties["InstallLocation"]

            if (
                $displayName -and
                $displayName.Value -like "World of Warcraft*" -and
                $installLocation
            ) {
                $candidateRoots += $installLocation.Value
            }
        }
    }

    $programFiles = [Environment]::GetEnvironmentVariable("ProgramFiles")
    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")

    if ($programFiles) {
        $candidateRoots += Join-Path $programFiles "World of Warcraft"
    }

    if ($programFilesX86) {
        $candidateRoots += Join-Path $programFilesX86 "World of Warcraft"
    }

    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        if (-not $drive.Root) {
            continue
        }

        $candidateRoots += Join-Path $drive.Root "World of Warcraft"
        $candidateRoots += Join-Path $drive.Root "Games\World of Warcraft"
        $candidateRoots += Join-Path $drive.Root "Blizzard Games\World of Warcraft"
    }
}

$resolvedRoots = @{}
foreach ($candidateRoot in $candidateRoots) {
    if ([string]::IsNullOrWhiteSpace($candidateRoot)) {
        continue
    }

    $expandedRoot = [Environment]::ExpandEnvironmentVariables($candidateRoot.Trim().Trim('"'))
    if (-not (Test-Path -LiteralPath $expandedRoot -PathType Container)) {
        if ($explicitRoots) {
            throw "World of Warcraft directory not found: $expandedRoot"
        }

        continue
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $expandedRoot).ProviderPath
    $resolvedRoots[$resolvedRoot] = $true
}

if ($resolvedRoots.Count -eq 0) {
    throw "No World of Warcraft installation was found. Pass its directory with -WowRoot."
}

$clientDirectories = @{}
foreach ($root in $resolvedRoots.Keys) {
    $rootDirectory = Get-Item -LiteralPath $root

    if (Test-WowClientDirectory -Directory $rootDirectory) {
        $clientDirectories[$rootDirectory.FullName] = $rootDirectory
        continue
    }

    foreach ($directory in Get-ChildItem -LiteralPath $root -Directory -Force) {
        if (Test-WowClientDirectory -Directory $directory) {
            $clientDirectories[$directory.FullName] = $directory
        }
    }
}

if ($clientDirectories.Count -eq 0) {
    $searchedRoots = @($resolvedRoots.Keys | Sort-Object) -join ", "
    throw "No installed game-version directories were found below: $searchedRoots"
}

$copiedCount = 0
$failures = @()

foreach ($clientDirectory in @($clientDirectories.Values | Sort-Object FullName)) {
    $addonDirectory = Join-Path $clientDirectory.FullName "Interface\AddOns\$addonName"

    if (-not $PSCmdlet.ShouldProcess($addonDirectory, "Copy $addonName addon files")) {
        continue
    }

    try {
        New-Item -ItemType Directory -Path $addonDirectory -Force | Out-Null

        foreach ($directoryName in $sourceDirectories) {
            Copy-DirectoryContents `
                -Source (Join-Path $sourceRoot $directoryName) `
                -Destination (Join-Path $addonDirectory $directoryName)
        }

        foreach ($fileName in $sourceFiles) {
            Copy-Item `
                -LiteralPath (Join-Path $sourceRoot $fileName) `
                -Destination (Join-Path $addonDirectory $fileName) `
                -Force
        }

        $copiedCount++
        Write-Host "Copied $addonName to $($clientDirectory.Name)."
    }
    catch {
        $failures += "$($clientDirectory.Name): $($_.Exception.Message)"
    }
}

if ($failures.Count -gt 0) {
    throw "Copy failed for one or more game versions:`n$($failures -join "`n")"
}

if ($copiedCount -gt 0) {
    Write-Host "Copied $addonName to $copiedCount installed game version(s)."
}
elseif ($WhatIfPreference) {
    Write-Host "Found $($clientDirectories.Count) installed game version(s); no files were copied because -WhatIf was used."
}
