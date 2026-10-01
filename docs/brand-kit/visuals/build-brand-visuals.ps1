param(
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

Add-Type -AssemblyName System.Drawing

$visualDir = Join-Path $ProjectRoot 'docs\brand-kit\visuals'
$logoPath = Join-Path $ProjectRoot 'assets\images\logo_wordmark.png'
$fontPath = Join-Path $ProjectRoot 'assets\fonts\IBMPlexSansArabic-700.ttf'

$palette = [ordered]@{
    Terracotta = '#9E3D18'
    Olive = '#66705B'
    Sand = '#C9B79C'
    Cream = '#F6F0E5'
    Charcoal = '#252321'
}

$fontCollection = [System.Drawing.Text.PrivateFontCollection]::new()
$fontCollection.AddFontFile($fontPath)
$fontFamily = $fontCollection.Families | Select-Object -First 1

function New-Color {
    param(
        [string]$Hex,
        [int]$Alpha = 255
    )

    $clean = $Hex.Replace('#', '')
    return [System.Drawing.Color]::FromArgb(
        $Alpha,
        [Convert]::ToInt32($clean.Substring(0, 2), 16),
        [Convert]::ToInt32($clean.Substring(2, 2), 16),
        [Convert]::ToInt32($clean.Substring(4, 2), 16)
    )
}

function New-Font {
    param(
        [float]$Size,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    return [System.Drawing.Font]::new(
        $fontFamily,
        [Math]::Max(1, $Size),
        $Style,
        [System.Drawing.GraphicsUnit]::Pixel
    )
}

function Set-HighQuality {
    param([System.Drawing.Graphics]$Graphics)

    $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $Graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
}

function New-RoundedPath {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Radius
    )

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = [Math]::Min($Radius * 2, [Math]::Min($Width, $Height))

    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Fill-Rounded {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Brush]$Brush,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Radius = 24
    )

    $path = New-RoundedPath $X $Y $Width $Height $Radius
    $Graphics.FillPath($Brush, $path)
    $path.Dispose()
}

function Draw-RoundedBorder {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Pen]$Pen,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Radius = 24
    )

    $path = New-RoundedPath $X $Y $Width $Height $Radius
    $Graphics.DrawPath($Pen, $path)
    $path.Dispose()
}

function New-CanvasFrom {
    param([string]$Path)

    $source = [System.Drawing.Bitmap]::new($Path)
    $canvas = [System.Drawing.Bitmap]::new(
        $source.Width,
        $source.Height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.DrawImageUnscaled($source, 0, 0)
    $graphics.Dispose()
    $source.Dispose()
    return $canvas
}

function Draw-ImageCover {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $scale = [Math]::Max($Width / [double]$Image.Width, $Height / [double]$Image.Height)
    $sourceWidth = [int]($Width / $scale)
    $sourceHeight = [int]($Height / $scale)
    $sourceX = [int](($Image.Width - $sourceWidth) / 2)
    $sourceY = [int](($Image.Height - $sourceHeight) / 2)

    $destination = [System.Drawing.Rectangle]::new($X, $Y, $Width, $Height)
    $source = [System.Drawing.Rectangle]::new($sourceX, $sourceY, $sourceWidth, $sourceHeight)
    $Graphics.DrawImage($Image, $destination, $source, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-LogoCard {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Logo,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $cardBrush = [System.Drawing.SolidBrush]::new((New-Color $palette.Cream 242))
    Fill-Rounded $Graphics $cardBrush $X $Y $Width $Height 28
    $cardBrush.Dispose()

    $logoSize = [int]($Width * 0.58)
    $logoX = $X + [int](($Width - $logoSize) / 2)
    $logoY = $Y + [int]($Height * 0.07)
    $Graphics.DrawImage($Logo, $logoX, $logoY, $logoSize, $logoSize)

    $textBrush = [System.Drawing.SolidBrush]::new((New-Color $palette.Charcoal))
    $font = New-Font ([Math]::Max(14, $Width * 0.052)) ([System.Drawing.FontStyle]::Bold)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textRect = [System.Drawing.RectangleF]::new(
        [float]($X + 18),
        [float]($logoY + $logoSize - 2),
        [float]($Width - 36),
        [float]($Height * 0.15)
    )
    $Graphics.DrawString('FROM IDEA TO FINISH', $font, $textBrush, $textRect, $format)

    $pen = [System.Drawing.Pen]::new((New-Color $palette.Terracotta), [Math]::Max(2, $Width * 0.006))
    $lineY = $Y + $Height - [int]($Height * 0.095)
    $points = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new([float]($X + $Width * 0.10), [float]$lineY),
        [System.Drawing.PointF]::new([float]($X + $Width * 0.32), [float]$lineY),
        [System.Drawing.PointF]::new([float]($X + $Width * 0.42), [float]($lineY - $Height * 0.055)),
        [System.Drawing.PointF]::new([float]($X + $Width * 0.52), [float]$lineY),
        [System.Drawing.PointF]::new([float]($X + $Width * 0.90), [float]$lineY)
    )
    $Graphics.DrawLines($pen, $points)

    $format.Dispose()
    $font.Dispose()
    $textBrush.Dispose()
    $pen.Dispose()
}

function Draw-SwatchRow {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$X,
        [int]$Y,
        [int]$Size,
        [int]$Gap,
        [int]$Radius = 10
    )

    $colors = @(
        $palette.Terracotta,
        $palette.Olive,
        $palette.Sand,
        $palette.Cream,
        $palette.Charcoal
    )

    $index = 0
    foreach ($hex in $colors) {
        $brush = [System.Drawing.SolidBrush]::new((New-Color $hex))
        Fill-Rounded $Graphics $brush ($X + ($index * ($Size + $Gap))) $Y $Size $Size $Radius
        $brush.Dispose()
        $index++
    }
}

function Draw-SmallLabel {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$ColorHex = '#F6F0E5',
        [float]$Size = 18
    )

    $brush = [System.Drawing.SolidBrush]::new((New-Color $ColorHex))
    $font = New-Font $Size ([System.Drawing.FontStyle]::Bold)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Near
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rect = [System.Drawing.RectangleF]::new([float]$X, [float]$Y, [float]$Width, [float]$Height)
    $Graphics.DrawString($Text, $font, $brush, $rect, $format)
    $format.Dispose()
    $font.Dispose()
    $brush.Dispose()
}

function Save-Png {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force
    }
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

$logo = [System.Drawing.Bitmap]::new($logoPath)
$campaignSource = [System.Drawing.Bitmap]::new((Join-Path $visualDir 'shattab-campaign-4x5-source.png'))
$storySource = [System.Drawing.Bitmap]::new((Join-Path $visualDir 'shattab-story-9x16-source.png'))
$materialSource = [System.Drawing.Bitmap]::new((Join-Path $visualDir 'shattab-material-1x1-source.png'))

try {
    $campaign = New-CanvasFrom (Join-Path $visualDir 'shattab-campaign-4x5-source.png')
    $campaignGraphics = [System.Drawing.Graphics]::FromImage($campaign)
    Set-HighQuality $campaignGraphics
    $campaignCardWidth = [int]($campaign.Width * 0.27)
    Draw-LogoCard $campaignGraphics $logo 44 44 $campaignCardWidth $campaignCardWidth
    Save-Png $campaign (Join-Path $visualDir 'shattab-campaign-hero-4x5.png')
    $campaignGraphics.Dispose()
    $campaign.Dispose()

    $story = New-CanvasFrom (Join-Path $visualDir 'shattab-story-9x16-source.png')
    $storyGraphics = [System.Drawing.Graphics]::FromImage($story)
    Set-HighQuality $storyGraphics
    $storyCardWidth = [int]($story.Width * 0.31)
    Draw-LogoCard $storyGraphics $logo 42 42 $storyCardWidth $storyCardWidth

    $storyBandBrush = [System.Drawing.SolidBrush]::new((New-Color $palette.Charcoal 220))
    Fill-Rounded $storyGraphics $storyBandBrush 42 ($story.Height - 112) ($story.Width - 84) 64 20
    $storyBandBrush.Dispose()
    Draw-SmallLabel $storyGraphics 'FROM IDEA TO FINISH' 66 ($story.Height - 112) ($story.Width - 132) 64 $palette.Cream 20
    Save-Png $story (Join-Path $visualDir 'shattab-story-9x16.png')
    $storyGraphics.Dispose()
    $story.Dispose()

    $material = New-CanvasFrom (Join-Path $visualDir 'shattab-material-1x1-source.png')
    $materialGraphics = [System.Drawing.Graphics]::FromImage($material)
    Set-HighQuality $materialGraphics
    $materialCardSize = [int]($material.Width * 0.34)
    $materialCardX = [int](($material.Width - $materialCardSize) / 2)
    $materialCardY = [int](($material.Height - $materialCardSize) / 2)
    Draw-LogoCard $materialGraphics $logo $materialCardX $materialCardY $materialCardSize $materialCardSize
    Draw-SwatchRow $materialGraphics 48 ($material.Height - 90) 42 12 8
    Save-Png $material (Join-Path $visualDir 'shattab-material-1x1.png')
    $materialGraphics.Dispose()
    $material.Dispose()

    $boardWidth = 2400
    $boardHeight = 1500
    $board = [System.Drawing.Bitmap]::new(
        $boardWidth,
        $boardHeight,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $boardGraphics = [System.Drawing.Graphics]::FromImage($board)
    Set-HighQuality $boardGraphics

    $boardBackground = [System.Drawing.SolidBrush]::new((New-Color $palette.Charcoal))
    $boardGraphics.FillRectangle($boardBackground, 0, 0, $boardWidth, $boardHeight)
    $boardBackground.Dispose()

    Draw-SmallLabel $boardGraphics 'Shattab / Brand System' 90 64 960 62 $palette.Cream 34
    Draw-SmallLabel $boardGraphics 'From idea to finish.' 90 128 960 42 $palette.Sand 25
    $headerPen = [System.Drawing.Pen]::new((New-Color $palette.Terracotta), 4)
    $boardGraphics.DrawLine($headerPen, 90, 205, 2310, 205)
    $headerPen.Dispose()

    $leftX = 90
    $leftY = 245
    $leftW = 460
    $leftH = 980
    $middleX = 586
    $middleY = 245
    $middleW = 800
    $middleH = 980
    $rightX = 1422
    $rightY = 245
    $rightW = 888
    $rightTopH = 500
    $rightBottomY = 781
    $rightBottomH = 444

    $leftBrush = [System.Drawing.SolidBrush]::new((New-Color $palette.Cream))
    Fill-Rounded $boardGraphics $leftBrush $leftX $leftY $leftW $leftH 28
    $leftBrush.Dispose()
    Draw-LogoCard $boardGraphics $logo ($leftX + 34) ($leftY + 34) ($leftW - 68) 410
    Draw-SmallLabel $boardGraphics 'BASE MARK' ($leftX + 34) ($leftY + 495) ($leftW - 68) 34 $palette.Charcoal 20
    Draw-SmallLabel $boardGraphics 'The supplied terracotta wordmark is the identity anchor.' ($leftX + 34) ($leftY + 548) ($leftW - 68) 94 $palette.Charcoal 22
    Draw-SmallLabel $boardGraphics 'Keep it warm, clear, and close to the work.' ($leftX + 34) ($leftY + 670) ($leftW - 68) 74 $palette.Olive 20
    Draw-SwatchRow $boardGraphics ($leftX + 34) ($leftY + 830) 62 14 10
    Draw-SmallLabel $boardGraphics 'TERRACOTTA  /  OLIVE  /  SAND  /  CREAM  /  CHARCOAL' ($leftX + 34) ($leftY + 920) ($leftW - 68) 34 $palette.Charcoal 13

    $middleImageBrush = [System.Drawing.SolidBrush]::new((New-Color $palette.Cream))
    Fill-Rounded $boardGraphics $middleImageBrush $middleX $middleY $middleW $middleH 28
    $middleImageBrush.Dispose()
    Draw-ImageCover $boardGraphics $campaignSource ($middleX + 8) ($middleY + 8) ($middleW - 16) 700
    Draw-SmallLabel $boardGraphics 'CAMPAIGN IMAGE / 4:5' ($middleX + 34) ($middleY + 748) ($middleW - 68) 34 $palette.Charcoal 20
    Draw-SmallLabel $boardGraphics 'Real craft. Real materials. A quieter confidence.' ($middleX + 34) ($middleY + 795) ($middleW - 68) 55 $palette.Charcoal 24
    $middleRule = [System.Drawing.Pen]::new((New-Color $palette.Terracotta), 3)
    $boardGraphics.DrawLine($middleRule, $middleX + 34, $middleY + 892, $middleX + $middleW - 34, $middleY + 892)
    $middleRule.Dispose()
    Draw-SmallLabel $boardGraphics 'Use negative space for the mark and the next step.' ($middleX + 34) ($middleY + 918) ($middleW - 68) 42 $palette.Olive 18

    $rightTopBrush = [System.Drawing.SolidBrush]::new((New-Color $palette.Cream))
    Fill-Rounded $boardGraphics $rightTopBrush $rightX $rightY $rightW $rightTopH 28
    $rightTopBrush.Dispose()
    Draw-ImageCover $boardGraphics $materialSource ($rightX + 8) ($rightY + 8) ($rightW - 16) ($rightTopH - 16)
    $materialOverlay = [System.Drawing.SolidBrush]::new((New-Color $palette.Charcoal 205))
    Fill-Rounded $boardGraphics $materialOverlay ($rightX + 26) ($rightY + 26) 292 70 18
    $materialOverlay.Dispose()
    Draw-SmallLabel $boardGraphics 'MATERIAL / TACTILE / TRUE' ($rightX + 48) ($rightY + 26) 250 70 $palette.Cream 17

    $rightBottomBrush = [System.Drawing.SolidBrush]::new((New-Color $palette.Cream))
    Fill-Rounded $boardGraphics $rightBottomBrush $rightX $rightBottomY $rightW $rightBottomH 28
    $rightBottomBrush.Dispose()
    Draw-SmallLabel $boardGraphics 'SYSTEM NOTES' ($rightX + 40) ($rightBottomY + 36) 400 32 $palette.Charcoal 20
    Draw-SmallLabel $boardGraphics 'Warm surfaces. Clear steps. Visible proof.' ($rightX + 40) ($rightBottomY + 84) 760 46 $palette.Charcoal 25
    Draw-SwatchRow $boardGraphics ($rightX + 40) ($rightBottomY + 170) 86 18 14
    Draw-SmallLabel $boardGraphics 'PALETTE / RESTRAINED, HUMAN, MATERIAL' ($rightX + 40) ($rightBottomY + 272) 760 30 $palette.Olive 17
    $rightLinePen = [System.Drawing.Pen]::new((New-Color $palette.Terracotta), 4)
    $rightLinePoints = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new([float]($rightX + 40), [float]($rightBottomY + 375)),
        [System.Drawing.PointF]::new([float]($rightX + 245), [float]($rightBottomY + 375)),
        [System.Drawing.PointF]::new([float]($rightX + 315), [float]($rightBottomY + 340)),
        [System.Drawing.PointF]::new([float]($rightX + 385), [float]($rightBottomY + 375)),
        [System.Drawing.PointF]::new([float]($rightX + 760), [float]($rightBottomY + 375))
    )
    $boardGraphics.DrawLines($rightLinePen, $rightLinePoints)
    $rightLinePen.Dispose()

    Draw-SmallLabel $boardGraphics 'VISUAL DIRECTION / DOCUMENTARY CRAFT + QUIET EDITORIAL SPACE' 90 1328 2220 34 $palette.Sand 17
    Save-Png $board (Join-Path $visualDir 'shattab-brand-system-board-v2.png')
    $boardGraphics.Dispose()
    $board.Dispose()
}
finally {
    $logo.Dispose()
    $campaignSource.Dispose()
    $storySource.Dispose()
    $materialSource.Dispose()
    $fontCollection.Dispose()
}

Get-ChildItem -LiteralPath $visualDir -Filter '*.png' |
    Sort-Object Name |
    Select-Object Name, Length
