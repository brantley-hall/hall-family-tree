param(
    [string]$Repo = "C:\Users\roder\CascadeProjects\hall-family-tree\docs",
    [string]$MdFile = "final-ledger.md",
    [string]$HtmlFile = "final-ledger.html",
    [string]$PdfFile = "final-ledger.pdf"
)

$mdPath = Join-Path $Repo $MdFile
$htmlPath = Join-Path $Repo $HtmlFile
$pdfPath = Join-Path $Repo $PdfFile

# If a reorganized draft exists and we're rebuilding final-ledger.md, use it.
$reorgPath = Join-Path $Repo "final-ledger-reorganized.md"
if ((Test-Path $reorgPath) -and ($MdFile -eq "final-ledger.md")) {
    Copy-Item -Path $reorgPath -Destination $mdPath -Force
}

if (-not (Test-Path $mdPath)) {
    throw "Markdown file not found: $mdPath"
}

$bytes = [System.IO.File]::ReadAllBytes($mdPath)
$mdText = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = ($mdText -replace "`r`n","`n") -split "`n"

function Escape-Text([string]$t) {
    return $t -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
}

function Inline-Format([string]$t) {
    $t = Escape-Text $t
    # bold
    $t = [regex]::Replace($t, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    # italic (single asterisks)
    $t = [regex]::Replace($t, '(?<![\\*])\*(?!\s)(.+?)(?<!\s)\*(?![*])', '<em>$1</em>')
    return $t
}

$body = New-Object System.Collections.Generic.List[string]

$script:inP = $false
$script:paraText = ''
$script:inUl = $false
$script:inOl = $false
$script:inBq = $false
$script:bqLines = @()
$script:inCode = $false
$script:codeLines = New-Object System.Collections.Generic.List[string]
$script:inTable = $false
$script:tableHeaderDone = $false

function CloseParagraph {
    if ($script:inP) {
        $script:body.Add("<p>$script:paraText</p>")
        $script:paraText = ''
        $script:inP = $false
    }
}

function CloseList {
    if ($script:inUl) {
        $script:body.Add('</ul>')
        $script:inUl = $false
    } elseif ($script:inOl) {
        $script:body.Add('</ol>')
        $script:inOl = $false
    }
}

function CloseBlockquote {
    if ($script:inBq) {
        $txt = Inline-Format ($script:bqLines -join ' ')
        $script:body.Add("<blockquote><p>$txt</p></blockquote>")
        $script:bqLines = @()
        $script:inBq = $false
    }
}

function CloseCode {
    if ($script:inCode) {
        $code = ($script:codeLines | ForEach-Object { Escape-Text $_ }) -join "`r`n"
        $script:body.Add("<pre><code>$code</code></pre>")
        $script:codeLines.Clear()
        $script:inCode = $false
    }
}

function CloseTable {
    if ($script:inTable) {
        $script:body.Add('</table>')
        $script:inTable = $false
        $script:tableHeaderDone = $false
    }
}

function AddPageBreak {
    $script:body.Add('<div class="page-break"></div>')
}

# Parse title and header block
$h1 = ''
$sub1 = ''
$sub2 = ''
$author = ''
$date = ''
$version = ''
$bodyStart = $lines.Count

$titleLine = $lines[0]
if ($titleLine -match '^# (.+?):\s*(.+)$') {
    $h1 = Escape-Text $Matches[1]
    $sub1 = Escape-Text $Matches[2]
} else {
    $h1 = Escape-Text ($titleLine.TrimStart('#').Trim())
}

$headerStarted = $false
for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if (-not $headerStarted -and $line -match '^## (.+)$') {
        $sub2 = Escape-Text $Matches[1]
        $headerStarted = $true
        continue
    }
    if ($headerStarted) {
        if ($line -match '^\*\*Prepared by:\*\*\s*(.+)$') {
            $author = $Matches[1].Trim()
        } elseif ($line -match '^\*\*Date:\*\*\s*(.+)$') {
            $date = $Matches[1].Trim()
        } elseif ($line -match '^\*\*Version:\*\*\s*(.+)$') {
            $version = $Matches[1].Trim()
        } elseif ($line -eq '---') {
            $bodyStart = $i + 1
            break
        }
    }
}

# Build title header
$body.Add("<h1>$h1</h1>")
if ($sub1) { $body.Add("<div class='subtitle'>$sub1</div>") }
if ($sub2) { $body.Add("<div class='subtitle'>$sub2</div>") }
if ($author) { $body.Add("<div class='author'>Prepared by $author</div>") }
if ($date) { $body.Add("<div class='date'>$date</div>") }
if ($version) { $body.Add("<div class='date'>Version $version</div>") }
AddPageBreak

# Main body parsing
for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $trim = $line.Trim()

    if ($trim -eq '') {
        CloseParagraph
        CloseList
        CloseBlockquote
        continue
    }

    # Code fence
    if ($trim -match '^```') {
        if ($script:inCode) {
            CloseCode
        } else {
            CloseParagraph; CloseList; CloseBlockquote; CloseTable
            $script:inCode = $true
        }
        continue
    }

    if ($script:inCode) {
        $script:codeLines.Add($line)
        continue
    }

    # Table
    if ($trim.StartsWith('|')) {
        CloseParagraph; CloseList; CloseBlockquote
        if (-not $script:inTable) {
            $script:body.Add('<table>')
            $script:inTable = $true
            $script:tableHeaderDone = $false
        }
        if ($trim -match '^\|?[-\s:|]+\|?$') {
            $script:tableHeaderDone = $true
            continue
        }
        $cells = $trim.Split('|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        $tag = if ($script:tableHeaderDone) { 'td' } else { 'th' }
        $row = '<tr>'
        foreach ($cell in $cells) {
            $row += "<$tag>$(Inline-Format $cell)</$tag>"
        }
        $row += '</tr>'
        $script:body.Add($row)
        if (-not $script:tableHeaderDone) { $script:tableHeaderDone = $true }
        continue
    } else {
        CloseTable
    }

    # Blockquote
    if ($trim -match '^>\s?(.*)$') {
        CloseParagraph; CloseList
        $script:bqLines += $Matches[1]
        $script:inBq = $true
        continue
    } else {
        CloseBlockquote
    }

    # Headers
    if ($trim -match '^###\s+(.+)$') {
        CloseParagraph; CloseList; CloseBlockquote
        $script:body.Add("<h3>$(Inline-Format $Matches[1])</h3>")
        continue
    }
    if ($trim -match '^##\s+(.+)$') {
        CloseParagraph; CloseList; CloseBlockquote
        if ($Matches[1] -eq 'Sources and References') { AddPageBreak }
        $script:body.Add("<h2>$(Inline-Format $Matches[1])</h2>")
        continue
    }
    if ($trim -match '^#\s+(.+)$') {
        CloseParagraph; CloseList; CloseBlockquote
        $script:body.Add("<h1>$(Inline-Format $Matches[1])</h1>")
        continue
    }

    # Horizontal rule
    if ($trim -match '^(---|\*\*\*|___)$') {
        CloseParagraph; CloseList; CloseBlockquote
        continue
    }

    # Unordered list
    if ($trim -match '^[-*]\s+(.*)$') {
        CloseParagraph; CloseBlockquote
        if (-not $script:inUl) {
            $script:body.Add('<ul>')
            $script:inUl = $true
        }
        $script:body.Add("<li>$(Inline-Format $Matches[1])</li>")
        continue
    } else {
        if ($script:inUl) { CloseList }
    }

    # Ordered list
    if ($trim -match '^\d+\.\s+(.*)$') {
        CloseParagraph; CloseBlockquote
        if (-not $script:inOl) {
            $script:body.Add('<ol>')
            $script:inOl = $true
        }
        $script:body.Add("<li>$(Inline-Format $Matches[1])</li>")
        continue
    } else {
        if ($script:inOl) { CloseList }
    }

    # Paragraph (continues until blank line or block marker)
    if (-not $script:inP) {
        $script:paraText = Inline-Format $line
        $script:inP = $true
    } else {
        $script:paraText += ' ' + (Inline-Format $line)
    }
}

CloseParagraph
CloseList
CloseBlockquote
CloseCode
CloseTable

# Read the existing HTML head (styles, etc.)
if (-not (Test-Path $htmlPath)) {
    throw "Existing HTML template not found: $htmlPath"
}
$oldHtmlBytes = [System.IO.File]::ReadAllBytes($htmlPath)
$oldHtml = [System.Text.Encoding]::UTF8.GetString($oldHtmlBytes)
$headMatch = [regex]::Match($oldHtml, '(?s)^(.*?</head>)')
if (-not $headMatch.Success) {
    throw "Could not find </head> in existing HTML."
}
$head = $headMatch.Value

# Update title tag to match current H1/subtitle
$titleString = if ($sub1) { "$h1`: $sub1" } else { $h1 }
$head = [regex]::Replace($head, '<title>.*?</title>', "<title>$titleString</title>")

$html = $head + "`r`n<body>`r`n" + ($body -join "`r`n") + "`r`n</body>`r`n</html>"
[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.Encoding]::UTF8)

# Generate PDF using Edge
if (Test-Path $pdfPath) { Remove-Item $pdfPath -Force }
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$uri = 'file:///' + ($htmlPath -replace '\\','/')
Start-Process -FilePath $edge -ArgumentList '--headless', "--print-to-pdf=$pdfPath", $uri -NoNewWindow -Wait
