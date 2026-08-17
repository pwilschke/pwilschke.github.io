# pwilschke.github.io

Personal academic website, built with [Quarto](https://quarto.org) and served by
GitHub Pages at <https://pwilschke.github.io>.

## Building

```powershell
.\build.ps1            # compile the CV, render the site into docs/
.\build.ps1 -SkipCv    # site only, when the CV has not changed
.\build.ps1 -Preview   # live-reloading preview at localhost, Ctrl+C to stop
```

Quarto is not on PATH on this machine — it ships inside Positron and RStudio, and
`build.ps1` finds it there. LaTeX comes from TinyTeX in `%APPDATA%\TinyTeX`.

## Publishing

Pages serves from the **`main` branch, `/docs` folder**, so the rendered output is
committed rather than built by CI:

```powershell
.\build.ps1
git add -A
git commit -m "Update site"
git push
```

The live site updates within a minute or two. `docs/.nojekyll` is written by the
build and must stay — without it GitHub runs the output through Jekyll, which
strips Quarto's `site_libs/` folders.

## Layout

```
_quarto.yml       site config: navbar, theme, which pages get built
index.qmd         home page — bio, contact, research interests
research.qmd      research statement; commented template for listing papers
cv.qmd            embedded PDF viewer + download link
teaching.qmd      NOT PUBLISHED — excluded from render, navbar entry commented out
writing.qmd       NOT PUBLISHED — same; includes notes on turning it into a blog
styles.scss       light theme
styles-dark.scss  dark theme (the navbar has a toggle)
cv/cv.tex         CV source, canonical copy
cv/citations.bib  bibliography for the CV's Publications section
cv.pdf            built CV — this is the file the site links to; committed
docs/             rendered site — committed, this is what Pages serves
```

## Turning on a hidden tab

Two edits in `_quarto.yml`: delete the page's `"!teaching.qmd"` line under
`project.render`, and uncomment its entry under `website.navbar.left`. Then fill
in the `.qmd`, which already has a template in it.

## Adding a paper

`research.qmd` has a commented-out template at the bottom. Put the PDF in a
`papers/` folder at the repo root and link to it as `papers/name.pdf` — Quarto
copies it into `docs/` automatically.

## The headshot

`assets/headshot.jpg` is generated from the camera original, which is gitignored
because browsers cannot display HEIC:

```powershell
pip install pillow pillow-heif
python tools/make_headshot.py headshot.heic
```

The script squares the crop, resizes to 3x display size, and strips EXIF. To
reframe, run it with `--preview` to get a coordinate grid over the full frame,
read new numbers off it, and edit `CROP` at the top of the script.

The home page lays the photo out beside the name rather than using Quarto's
title block — which is why `index.qmd` has no `title:` and sets `pagetitle:`
instead. See the `.hero` rules in `styles.scss`.

## The CV

`cv/cv.tex` is the source of truth. Edit it, then run `.\build.ps1`, which
compiles it and copies the PDF to the repo root where the site expects it.

The **Publications** section is commented out in `cv.tex` because
`cv/citations.bib` has no real entries yet. Add entries and delete the `%` marks
to switch it back on — the CV uses `\nocite{*}`, so everything in the `.bib` gets
printed and there is nothing else to wire up.
