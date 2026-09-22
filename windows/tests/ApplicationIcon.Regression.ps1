$ErrorActionPreference = 'Stop'

$projectDir = Join-Path $PSScriptRoot '..\WeChatExporter.Windows'
$icoPath = Join-Path $projectDir 'Assets\WeChatExporter.ico'
$pngPath = Join-Path $projectDir 'Assets\WeChatExporter-icon.png'
$projectPath = Join-Path $projectDir 'WeChatExporter.Windows.csproj'
$mainWindowPath = Join-Path $projectDir 'MainWindow.xaml'
$consentWindowPath = Join-Path $projectDir 'ConsentWindow.xaml'
$diagnosticPath = Join-Path $projectDir 'Services\DiagnosticUploader.cs'

if (-not (Test-Path -LiteralPath $icoPath -PathType Leaf)) { throw '缺少 ICO 资源' }
if (-not (Test-Path -LiteralPath $pngPath -PathType Leaf)) { throw '缺少 PNG 资源' }

$icoHash = (Get-FileHash -LiteralPath $icoPath -Algorithm SHA256).Hash
$pngHash = (Get-FileHash -LiteralPath $pngPath -Algorithm SHA256).Hash
if ($icoHash -ne '1FF4806E10712D7A3AAD0805FFCBE5C0F73B46A5DCF65932E1E419078CF9FB2D') { throw 'ICO 哈希不匹配' }
if ($pngHash -ne 'F29FA839AF781811AF7E04CCD5F3B2DBFE74859D4B17E7235BA3E9AF0DF2833E') { throw 'PNG 哈希不匹配' }

$bytes = [System.IO.File]::ReadAllBytes($icoPath)
if ($bytes.Length -lt 6) { throw 'ICO 文件过短' }
$count = [BitConverter]::ToUInt16($bytes, 4)
if ($bytes.Length -lt 6 + (16 * $count)) { throw 'ICO 目录损坏' }
$sizes = for ($i = 0; $i -lt $count; $i++) {
    $offset = 6 + (16 * $i)
    $width = if ($bytes[$offset] -eq 0) { 256 } else { [int]$bytes[$offset] }
    $height = if ($bytes[$offset + 1] -eq 0) { 256 } else { [int]$bytes[$offset + 1] }
    if ($width -ne $height) { throw "ICO 包含非正方形图层：${width}x${height}" }
    $width
}
$expectedSizes = @(16, 24, 32, 48, 64, 128, 256)
if ((Compare-Object $expectedSizes ($sizes | Sort-Object -Unique))) { throw 'ICO 尺寸集合不完整' }

$project = Get-Content -LiteralPath $projectPath -Raw
$mainWindow = Get-Content -LiteralPath $mainWindowPath -Raw
$consentWindow = Get-Content -LiteralPath $consentWindowPath -Raw
$diagnostic = Get-Content -LiteralPath $diagnosticPath -Raw

if (-not $project.Contains('<ApplicationIcon>Assets\WeChatExporter.ico</ApplicationIcon>')) { throw '项目未设置 ApplicationIcon' }
if (-not $project.Contains('<Resource Include="Assets\WeChatExporter.ico" />')) { throw '项目未嵌入 ICO' }
if (-not $project.Contains('<Resource Include="Assets\WeChatExporter-icon.png" />')) { throw '项目未嵌入 PNG' }
if (-not $project.Contains('<Version>2.16.0</Version>')) { throw 'Windows 版本不是 2.16.0' }

if (-not $mainWindow.Contains('Icon="Assets/WeChatExporter.ico"')) { throw '主窗口未设置标题栏图标' }
if (-not $mainWindow.Contains('Source="Assets/WeChatExporter-icon.png"')) { throw '主界面未显示 PNG 图标' }
if (-not $mainWindow.Contains('Width="48" Height="48" Stretch="Uniform"')) { throw '主界面图标尺寸或缩放方式不正确' }
if ($mainWindow.Contains('Text="💬"')) { throw '主界面仍包含旧表情图标' }
if (-not $consentWindow.Contains('Icon="Assets/WeChatExporter.ico"')) { throw '授权窗口未设置标题栏图标' }

if (-not $diagnostic.Contains('Version = "2.16.0"')) { throw '诊断版本不是 2.16.0' }
if (-not $diagnostic.Contains('Build = "32"')) { throw '诊断构建号不是 32' }

'PASS: Windows 应用图标、界面图标和版本配置符合规格'
