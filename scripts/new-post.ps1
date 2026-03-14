param(
  [Parameter(Mandatory = $true)]
  [string]$Title,

  [Parameter(Mandatory = $true)]
  [string]$Slug,

  [string]$Eyebrow = "Topic",
  [string]$ReadTime = "5 min read"
)

$today = Get-Date -Format "MMMM d, yyyy"
$template = Get-Content "templates/post-template.html" -Raw

$filled = $template
$filled = $filled -replace "\{\{TITLE\}\}", $Title
$filled = $filled -replace "\{\{SLUG\}\}", $Slug
$filled = $filled -replace "\{\{EYEBROW\}\}", $Eyebrow
$filled = $filled -replace "\{\{DATE\}\}", $today
$filled = $filled -replace "\{\{READTIME\}\}", $ReadTime

$target = "posts/$Slug.html"
$filled | Set-Content -Path $target

Write-Host "Created $target"
Write-Host "Homepage list updated automatically."


# Auto-refresh homepage list
./scripts/build-index.ps1


