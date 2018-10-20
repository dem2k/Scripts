Param([Parameter(Mandatory)]$Url, [Parameter(Mandatory)]$Pages)

Set-StrictMode -Version Latest

function Main() {
    Get-Fb2Header
    for ($i = 1; $i -le $Pages; $i++) {
        $progressPreference = 'silentlyContinue'
        "<section id=""seite_$i"">"
        Fetch-Page ( $Url -replace "/(\d+?)-", "/`${1}-$i-" )
        # "<p>-- $i --</p>"
        "</section>"
        $progressPreference = 'Continue'
        Write-Progress -Activity "Downloading Pages..." -Status "Page $i" -PercentComplete ($i / $Pages * 100)
    }
    Get-Fb2Footer
}

function Fetch-DocumentInfo($Url) {
    $Author = "Unknown Author"
    $Title  = "Unknown Title"
    $Genre  = "unrecognised"
    $content = (Invoke-WebRequest $Url | select Content) -split "`n"
    
    $content | where {$_ -match '<meta property="og:title" content="(.*?)" />'} | Out-Null
    if ($Matches) {
        $Author = ($Matches[1] -split " - ")[0]
        $Title = ($Matches[1] -split " - ")[1]
    }

    $content | where {$_ -match '<a itemprop="genre".*?>(.*?)</a>'} | Out-Null
    if ($Matches) {
        $Genre = $Matches[1].tolower()
    }

    # result
    $Author,$Title,$Genre
}

function Fetch-Page ($Url) {
    $lines = (Invoke-WebRequest $Url | select Content) -split "`n"
    Filter-PageContent $lines | Filter-Html
}

function Filter-PageContent($RawContent) {
    $startIdx = 0
    $endIdx = 0
    $divnav = $false
    for ($i = 0; $i -lt $RawContent.Count; $i++) {
        $cursor = $RawContent[$i]
        if ($cursor.StartsWith('<div class="navigation">')) {
            $divnav = $true
        }
        if ($divnav -and ($startIdx -eq 0) -and ($cursor -eq "</div>")) {
            $startIdx = $i + 1
        }
        if (($startIdx -gt 0) -and ($cursor.StartsWith( "<script"))) {
            $endIdx = $i - 1
            break
        }
    }
    $RawContent[$startIdx..$endIdx]
}

function Filter-Html {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]$HtmlText
    )
    process {
        $HtmlText -replace "<div.*?>", "<title>" -replace "</div>", "</title>" -replace "&nbsp;", " " -replace "<br>", "<empty-line/>" -replace "<em>","<emphasis>" -replace "</em>","</emphasis>"
    }
}

function Get-Fb2Header { 
@"
<?xml version="1.0" encoding="UTF-8"?>
<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0" xmlns:xlink="http://www.w3.org/1999/xlink">
    <description>
        <title-info>
            <genre>$Genre</genre>
            <author>$Author</author>
            <book-title>$Title</book-title>
            <lang>ru</lang>
        </title-info>
		<document-info>
            <author>LibKing.ru</author>
            <program-used>LibKingDownloader.ps1 by dem2k</program-used>
            <date>$(Get-Date)</date>
            <src-url>$Url</src-url>
			<id>$(New-Guid)</id>
			<version>3.1415901184082031</version>
		</document-info>
    </description>
<body>
"@
}
    
function Get-Fb2Footer {
@"
</body>
</FictionBook>
"@
}

$Author, $Title, $Genre = Fetch-DocumentInfo $Url
$outputFile = "{0} - {1}.fb2" -f $Author, $Title
Main | Out-File $outputFile -Encoding utf8

#Pause
