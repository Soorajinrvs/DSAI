<#
.SYNOPSIS
  Creates a blank DSAI project folder, ready to rename later.
.DESCRIPTION
  Makes a new folder with its own .continue\rules file (project instructions
  that Continue loads only when this folder is open in VS Code) and a NOTES.md
  file for facts to remember. Never overwrites: if the name is taken, a number
  is added ("New Idea 2", "New Idea 3", ...).
.EXAMPLE
  .\new-project.ps1
  .\new-project.ps1 -Name "Garden Planner" -Parent "D:\Projects"
#>
param(
  [string]$Name = "New Idea",
  [string]$Parent = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) "DSAI Projects")
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Parent | Out-Null

$target = Join-Path $Parent $Name
$n = 2
while (Test-Path -LiteralPath $target) { $target = Join-Path $Parent "$Name $n"; $n++ }

$rules = Join-Path $target ".continue\rules"
New-Item -ItemType Directory -Force -Path $rules | Out-Null
$today = Get-Date -Format 'yyyy-MM-dd'

@"
---
name: Project rules
alwaysApply: true
---
# Project: $(Split-Path $target -Leaf)

This is a new, blank project (created $today). Start fresh: assume nothing
from other projects.

- Describe what this project is about here once it has a purpose.
- Add any rules you want DSAI to follow while this folder is open.
- Keep lasting facts in NOTES.md in this folder.
"@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $rules "project.md")

@"
# Notes

Facts and decisions to remember for this project. DSAI does not remember past
chats on its own, so write important things here and attach this file (type @
in Continue and pick NOTES.md) when you need them.

## $today
- Project created.
"@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $target "NOTES.md")

Write-Host "Created: $target"
Write-Host "Open it in VS Code with File > Open Folder. Rename the folder any time."
