param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$ThemeRoot = Join-Path $ProjectRoot 'Assets\Themes\cyberpunk_theme'
$OutputRoot = Join-Path $ThemeRoot 'energy_sheets'
$PreviewPath = Join-Path $ProjectRoot 'debug\cyber_energy_sheet_preview.png'
$FrameCount = 8
$CellSize = 512

if (Test-Path $OutputRoot) {
	Remove-Item -LiteralPath $OutputRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $PreviewPath -Parent) | Out-Null

Add-Type -ReferencedAssemblies @('System.Drawing') -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CyberEnergySheetBuilder {
    const int Cell = 512;

    static double Clamp(double v, double min, double max) {
        return Math.Max(min, Math.Min(max, v));
    }

    static double SmoothStep(double edge0, double edge1, double x) {
        double t = Clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
        return t * t * (3.0 - 2.0 * t);
    }

    static Color Composite(Color baseColor, Color glowColor) {
        if (baseColor.A < 32 || glowColor.A == 0) return baseColor;
        double a = glowColor.A / 255.0;
        int r = (int)Math.Round(baseColor.R * (1.0 - a) + glowColor.R * a);
        int g = (int)Math.Round(baseColor.G * (1.0 - a) + glowColor.G * a);
        int b = (int)Math.Round(baseColor.B * (1.0 - a) + glowColor.B * a);
        return Color.FromArgb(baseColor.A, r, g, b);
    }

    static PointF PortPoint(int bit) {
        if (bit == 1) return new PointF(256f, -8f);
        if (bit == 2) return new PointF(520f, 256f);
        if (bit == 4) return new PointF(256f, 520f);
        return new PointF(-8f, 256f);
    }

    static void DrawEnergyLine(Graphics g, PointF from, PointF to, double progress, int frameIndex, int bit) {
        progress = Clamp(progress, 0.0, 1.0);
        if (progress <= 0.0) return;
        PointF end = new PointF(
            (float)(from.X + (to.X - from.X) * progress),
            (float)(from.Y + (to.Y - from.Y) * progress)
        );
        using (Pen aura = new Pen(Color.FromArgb(34, 30, 255, 20), 54f))
        using (Pen bloom = new Pen(Color.FromArgb(76, 70, 255, 35), 30f))
        using (Pen core = new Pen(Color.FromArgb(210, 145, 255, 105), 10f))
        using (SolidBrush spark = new SolidBrush(Color.FromArgb(190, 180, 255, 120))) {
            aura.StartCap = aura.EndCap = LineCap.Round;
            bloom.StartCap = bloom.EndCap = LineCap.Round;
            core.StartCap = core.EndCap = LineCap.Round;
            g.DrawLine(aura, from, end);
            g.DrawLine(bloom, from, end);
            g.DrawLine(core, from, end);

            double front = progress;
            for (int i = 0; i < 5; i++) {
                double seed = ((frameIndex + 1) * (i + 3) * (bit + 11)) % 17 / 17.0;
                double t = Clamp(front - 0.08 - i * 0.13 + seed * 0.045, 0.02, progress);
                float x = (float)(from.X + (to.X - from.X) * t);
                float y = (float)(from.Y + (to.Y - from.Y) * t);
                float r = (float)(2.0 + seed * 3.0);
                g.FillEllipse(spark, x - r, y - r, r * 2f, r * 2f);
            }
        }
    }

    static Bitmap BuildOverlay(int mask, double progress, int frameIndex) {
        Bitmap overlay = new Bitmap(Cell, Cell, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(overlay)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            PointF center = new PointF(256f, 256f);
            int[] bits = new int[] { 1, 2, 4, 8 };
            foreach (int bit in bits) {
                if ((mask & bit) == 0) continue;
                DrawEnergyLine(g, PortPoint(bit), center, progress, frameIndex, bit);
            }
            if (mask != 0 && progress > 0.55) {
                double centerPulse = SmoothStep(0.55, 1.0, progress);
                using (SolidBrush joint = new SolidBrush(Color.FromArgb((int)(120 * centerPulse), 120, 255, 75))) {
                    float r = (float)(11.0 + 10.0 * centerPulse);
                    g.FillEllipse(joint, 256f - r, 256f - r, r * 2f, r * 2f);
                }
            }
        }
        return overlay;
    }

    public static void BuildSheet(string basePath, string finalPath, string outputPath, int mask, int frames, bool proceduralFinal) {
        using (Bitmap base0 = new Bitmap(basePath))
        using (Bitmap final0 = new Bitmap(finalPath))
        using (Bitmap sheet = new Bitmap(Cell * frames, Cell, PixelFormat.Format32bppArgb)) {
            if (base0.Width != Cell || base0.Height != Cell || final0.Width != Cell || final0.Height != Cell) {
                throw new Exception("All inputs must be 512x512: " + basePath + " / " + finalPath);
            }
            for (int f = 0; f < frames; f++) {
                double progress = f / (double)(frames - 1);
                using (Bitmap overlay = BuildOverlay(mask, progress, f)) {
                    for (int y = 0; y < Cell; y++) {
                        for (int x = 0; x < Cell; x++) {
                            Color baseColor = base0.GetPixel(x, y);
                            Color glowColor = overlay.GetPixel(x, y);
                            Color outColor = (f == 0 || mask == 0) ? baseColor : Composite(baseColor, glowColor);
                            sheet.SetPixel(f * Cell + x, y, outColor);
                        }
                    }
                }
            }
            string dir = Path.GetDirectoryName(outputPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            if (File.Exists(outputPath)) File.Delete(outputPath);
            sheet.Save(outputPath, ImageFormat.Png);
        }
    }
}
'@

function Add-Sheet {
	param(
		[System.Collections.ArrayList]$Entries,
		[string]$Type,
		[string]$Name,
		[string]$BaseRelative,
		[string]$FinalRelative,
		[int]$FlowMask,
		[bool]$ProceduralFinal = $false
	)
	$outDir = Join-Path $OutputRoot $Type
	$outName = "$Name`_sheet.png"
	$outPath = Join-Path $outDir $outName
	$basePath = Join-Path $ThemeRoot $BaseRelative
	$finalPath = Join-Path $ThemeRoot $FinalRelative
	[CyberEnergySheetBuilder]::BuildSheet($basePath, $finalPath, $outPath, $FlowMask, $FrameCount, $ProceduralFinal)
	$entry = [ordered]@{
		type = $Type
		name = $Name
		flow_mask = $FlowMask
		frames = $FrameCount
		frame_width = $CellSize
		frame_height = $CellSize
		sheet = ("res://Assets/Themes/cyberpunk_theme/energy_sheets/$Type/$outName" -replace '\\','/')
		base = ("res://Assets/Themes/cyberpunk_theme/$BaseRelative" -replace '\\','/')
		final = ("res://Assets/Themes/cyberpunk_theme/$FinalRelative" -replace '\\','/')
	}
	[void]$Entries.Add($entry)
}

$entries = [System.Collections.ArrayList]::new()

$iMasks = @(0, 5, 4, 1)
for ($i = 0; $i -lt $iMasks.Count; $i++) {
	Add-Sheet $entries 'i_slices' "i_slice_$i" 'i_slices\i_slice_0.png' "i_slices\i_slice_$i.png" $iMasks[$i]
}

$lMasks = @(0, 3, 1, 2)
for ($i = 0; $i -lt $lMasks.Count; $i++) {
	Add-Sheet $entries 'l_slices' "l_slice_$i" 'l_slices\l_slice_0.png' "l_slices\l_slice_$i.png" $lMasks[$i]
}

$tMasks = @(0, 5, 3, 6, 1, 4, 2, 7)
for ($i = 0; $i -lt $tMasks.Count; $i++) {
	Add-Sheet $entries 't_slices' "t_slice_$i" 't_slices\t_slice_0.png' "t_slices\t_slice_$i.png" $tMasks[$i]
}

$crossMasks = @(0, 5, 10, 6, 3, 9, 12, 1, 2, 4, 8, 15, 11, 7, 14, 13)
for ($i = 0; $i -lt $crossMasks.Count; $i++) {
	Add-Sheet $entries 'cross_slices' "cross_slice_$i" 'cross_slices\cross_slice_0.png' "cross_slices\cross_slice_$i.png" $crossMasks[$i]
}

Add-Sheet $entries 'cap' 'pipe_cap' 'pipe_cap.png' 'pipe_cap.png' 1 $true
Add-Sheet $entries 'source' 'source' 'source.png' 'source.png' 1 $true
Add-Sheet $entries 'target_slices' 'target_slice_0' 'target.png' 'target.png' 0
Add-Sheet $entries 'target_slices' 'target_slice_1' 'target.png' 'target_slices\target_slice_1.png' 1
Add-Sheet $entries 'target' 'target' 'target.png' 'target_slices\target_slice_1.png' 1

$manifest = [ordered]@{
	theme = 'cyberpunk_theme'
	frame_count = $FrameCount
	frame_width = $CellSize
	frame_height = $CellSize
	generated_by = 'Tools/generate_cyber_energy_sheets.ps1'
	sheets = $entries
}

$manifestPath = Join-Path $OutputRoot 'manifest.json'
$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding UTF8

$previewSheets = @(
	(Join-Path $OutputRoot 'i_slices\i_slice_1_sheet.png'),
	(Join-Path $OutputRoot 'l_slices\l_slice_1_sheet.png'),
	(Join-Path $OutputRoot 't_slices\t_slice_7_sheet.png'),
	(Join-Path $OutputRoot 'cross_slices\cross_slice_11_sheet.png'),
	(Join-Path $OutputRoot 'source\source_sheet.png'),
	(Join-Path $OutputRoot 'target_slices\target_slice_1_sheet.png')
)

Add-Type -AssemblyName System.Drawing
$preview = New-Object System.Drawing.Bitmap ($CellSize * $FrameCount), ($CellSize * $previewSheets.Count)
$graphics = [System.Drawing.Graphics]::FromImage($preview)
$graphics.Clear([System.Drawing.Color]::Transparent)
try {
	for ($row = 0; $row -lt $previewSheets.Count; $row++) {
		$img = [System.Drawing.Image]::FromFile($previewSheets[$row])
		try {
			$graphics.DrawImage($img, 0, $row * $CellSize, $img.Width, $img.Height)
		} finally {
			$img.Dispose()
		}
	}
	$preview.Save($PreviewPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
	$graphics.Dispose()
	$preview.Dispose()
}

Write-Output "generated_sheets=$($entries.Count)"
Write-Output "manifest=$manifestPath"
Write-Output "preview=$PreviewPath"
