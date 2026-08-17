# build.ps1 -- rebuild the whole site.
#
#   .\build.ps1            # compile the CV, then render the site into docs/
#   .\build.ps1 -SkipCv    # site only (the CV has not changed)
#   .\build.ps1 -Preview   # live-reloading local preview; Ctrl+C to stop
#
# Quarto is not on PATH on this machine -- it ships inside Positron and RStudio,
# so this script finds it. Same story for pdflatex, which lives in TinyTeX.

param(
    [switch]$SkipCv,
    [switch]$Preview
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# --- locate quarto -----------------------------------------------------------
$quartoCandidates = @(
    "C:\Program Files\Positron\resources\app\quarto\bin\quarto.exe",
    "C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe",
    "C:\Program Files\Quarto\bin\quarto.exe",
    "$env:LOCALAPPDATA\Programs\Quarto\bin\quarto.exe"
)
$quarto = (Get-Command quarto -ErrorAction SilentlyContinue).Source
if (-not $quarto) { $quarto = $quartoCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1 }
if (-not $quarto) { throw "Could not find quarto.exe. Install Quarto, or edit the candidate list in build.ps1." }
Write-Host "quarto : $quarto" -ForegroundColor DarkGray

# --- compile the CV ----------------------------------------------------------
if (-not $SkipCv) {
    $tinytex = "$env:APPDATA\TinyTeX\bin\windows"
    if (Test-Path $tinytex) { $env:PATH = "$tinytex;$env:PATH" }
    if (-not (Get-Command latexmk -ErrorAction SilentlyContinue)) {
        throw "latexmk not found. Install TinyTeX, or run with -SkipCv."
    }

    Write-Host "Compiling cv/cv.tex ..." -ForegroundColor Cyan
    Push-Location "$root\cv"
    try {
        latexmk -pdf -interaction=nonstopmode -quiet cv.tex | Out-Null
        if (-not (Test-Path "$root\cv\cv.pdf")) { throw "latexmk produced no PDF; see cv/cv.log" }
        # The site links to the copy at the repo root, which is what gets committed.
        Copy-Item "$root\cv\cv.pdf" "$root\cv.pdf" -Force
        Write-Host "  -> cv.pdf" -ForegroundColor DarkGray
    }
    finally { Pop-Location }
}

# --- render ------------------------------------------------------------------
Push-Location $root
try {
    if ($Preview) {
        & $quarto preview
    }
    else {
        Write-Host "Rendering site ..." -ForegroundColor Cyan
        & $quarto render
        if ($LASTEXITCODE -ne 0) { throw "quarto render failed (exit $LASTEXITCODE)" }

        # Stops GitHub Pages from running the output through Jekyll, which would
        # drop Quarto's site_libs/ folders because of the underscore convention.
        New-Item -ItemType File -Path "$root\docs\.nojekyll" -Force | Out-Null

        Write-Host "`nDone. Site is in docs/." -ForegroundColor Green
        Write-Host "Commit and push, and GitHub Pages will pick it up:" -ForegroundColor DarkGray
        Write-Host "  git add -A; git commit -m 'Update site'; git push" -ForegroundColor DarkGray
    }
}
finally { Pop-Location }
