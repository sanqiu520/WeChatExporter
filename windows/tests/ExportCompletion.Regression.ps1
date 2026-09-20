$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $PSScriptRoot '..\WeChatExporter.Windows\ViewModels\MainViewModel.cs'
$source = Get-Content -LiteralPath $sourcePath -Raw
$start = $source.IndexOf('public async Task ExportSelectedAsync()', [StringComparison]::Ordinal)
$end = $source.IndexOf('public void ChooseExportFolder()', $start, [StringComparison]::Ordinal)
if ($start -lt 0 -or $end -le $start) { throw '找不到完整的 ExportSelectedAsync 方法' }
$method = $source.Substring($start, $end - $start)

if ($method.Contains('ShowAlert(')) { throw '导出成功分支仍会弹出模态提示' }
if (-not $method.Contains('AppendLog($"已按 {SelectedExportFormat} 格式导出')) { throw '缺少导出结果日志' }
if (-not $method.Contains('foreach (var line in summary)')) { throw '缺少逐文件摘要日志' }
if ($method -notmatch 'StatusText\s*=\s*exportSucceeded\s*\?\s*"导出完成"\s*:\s*"就绪"') { throw '没有按成功/失败设置最终状态' }
if (-not $method.Contains('ShowError(ex.Message)')) { throw '原错误提示路径被意外修改' }
'PASS: 导出成功反馈与错误路径符合规格'
