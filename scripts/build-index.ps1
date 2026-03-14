param(
  [string]$IndexPath = "index.html",
  [string]$PostsDir = "posts"
)

$startMarker = "<!-- POSTS:START -->"
$endMarker = "<!-- POSTS:END -->"

if (-not (Test-Path $IndexPath)) {
  throw "Index file not found: $IndexPath"
}

$indexContent = Get-Content -Raw $IndexPath
if ($indexContent -notmatch [regex]::Escape($startMarker) -or $indexContent -notmatch [regex]::Escape($endMarker)) {
  throw "Markers not found in $IndexPath. Ensure $startMarker and $endMarker exist."
}

$posts = Get-ChildItem -Path $PostsDir -Filter "*.html" | ForEach-Object {
  $html = Get-Content -Raw $_.FullName

  $title = [regex]::Match($html, '<h2 class="page-title">([^<]+)</h2>').Groups[1].Value.Trim()
  $subtitle = [regex]::Match($html, '<p class="page-subtitle">([^<]+)</p>').Groups[1].Value.Trim()

  $summaryMatch = [regex]::Match($html, '<article class="essay">[\s\S]*?<p>\s*([\s\S]*?)\s*</p>')
  $summaryRaw = $summaryMatch.Groups[1].Value
  $summary = ($summaryRaw -replace '<[^>]+>', '' -replace '\s+', ' ').Trim()

  $parts = $subtitle -split '\s*(?:&middot;|·|•|\u00B7)\s*'
  $dateText = if ($parts.Count -gt 0) { $parts[0].Trim() } else { "" }
  $readTime = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "5 min read" }

  $dateValue = $null
  try {
    $dateValue = [datetime]::ParseExact($dateText, "MMMM d, yyyy", $null)
  } catch {
    try {
      $dateValue = [datetime]::Parse($dateText)
    } catch {
      $dateValue = [datetime]::MinValue
    }
  }

  [pscustomobject]@{
    Title = $title
    Subtitle = "$dateText &middot; $readTime"
    Summary = if ($summary.Length -gt 160) { $summary.Substring(0, 157) + "..." } else { $summary }
    Href = "posts/$($_.Name)"
    DateValue = $dateValue
  }
} | Sort-Object -Property DateValue -Descending

$cards = foreach ($post in $posts) {
@"
            <article class="post-card">
              <p class="post-meta">$($post.Subtitle)</p>
              <h3>$($post.Title)</h3>
              <p>
                $($post.Summary)
              </p>
              <a class="card-link" href="$($post.Href)">Read essay</a>
            </article>
"@
}

$cardsBlock = ($cards -join "`n").TrimEnd()
$pattern = [regex]::Escape($startMarker) + "[\s\S]*?" + [regex]::Escape($endMarker)
$replacement = "$startMarker`n$cardsBlock`n            $endMarker"

$updated = [regex]::Replace($indexContent, $pattern, $replacement)
Set-Content $IndexPath $updated

Write-Host "Updated $IndexPath with $($posts.Count) post(s)."
