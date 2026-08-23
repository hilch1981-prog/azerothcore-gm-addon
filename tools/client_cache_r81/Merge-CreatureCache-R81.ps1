param(
    [string]$WowRoot = "",
    [string]$TargetPath = "",
    [string]$PatchPath = ""
)

$ErrorActionPreference = "Stop"
$ExpectedMagic = "BOMW"
$ExpectedBuild = 12340
$ExpectedLocale = [byte[]](0x52, 0x4B, 0x6F, 0x6B) # RKok = reversed koKR
$ExpectedRecordSize = 96
$HeaderSize = 24

function Read-Bytes([string]$Path) { return [System.IO.File]::ReadAllBytes($Path) }
function U32([byte[]]$Bytes, [int]$Offset) { return [BitConverter]::ToUInt32($Bytes, $Offset) }

function Bytes-Equal([byte[]]$Left, [byte[]]$Right) {
    if ($null -eq $Left -or $null -eq $Right -or $Left.Length -ne $Right.Length) { return $false }
    for ($i = 0; $i -lt $Left.Length; $i++) { if ($Left[$i] -ne $Right[$i]) { return $false } }
    return $true
}

function Slice-Bytes([byte[]]$Bytes, [int]$Offset, [int]$Length) {
    $result = New-Object byte[] $Length
    [Array]::Copy($Bytes, $Offset, $result, 0, $Length)
    return $result
}

function Validate-Header([byte[]]$Bytes, [string]$Path, [bool]$IsPatch) {
    if ($Bytes.Length -lt ($HeaderSize + 8)) { throw "WDB 파일이 너무 작습니다: $Path" }
    $magic = [System.Text.Encoding]::ASCII.GetString($Bytes, 0, 4)
    $build = U32 $Bytes 4
    $locale = Slice-Bytes $Bytes 8 4
    $recordSize = U32 $Bytes 12
    $recordVersion = U32 $Bytes 16
    $cacheVersion = U32 $Bytes 20
    if ($magic -ne $ExpectedMagic) { throw "creaturecache WDB가 아닙니다: $Path (Magic=$magic)" }
    if ($build -ne $ExpectedBuild) { throw "Build 12340 캐시가 아닙니다: $Path (Build=$build)" }
    if (-not (Bytes-Equal $locale $ExpectedLocale)) {
        $localeHex = ($locale | ForEach-Object { $_.ToString("X2") }) -join " "
        throw "koKR creaturecache가 아닙니다: $Path (LocaleBytes=$localeHex)"
    }
    if ($recordSize -ne $ExpectedRecordSize) { throw "3.3.5a creaturecache recordSize가 아닙니다: $Path (recordSize=$recordSize, expected=96)" }
    if ($recordVersion -eq 0) { throw "recordVersion=0인 WDB는 사용하지 않습니다: $Path" }
    if ($IsPatch -and $cacheVersion -ne 0) { throw "R8.1 patch WDB의 cacheVersion은 0이어야 합니다: $Path (cacheVersion=$cacheVersion)" }
}

function Read-Wdb([byte[]]$Bytes, [string]$Path, [bool]$IsPatch) {
    Validate-Header $Bytes $Path $IsPatch
    $records = New-Object System.Collections.ArrayList
    $index = @{}
    $pos = $HeaderSize
    while ($true) {
        if ($pos + 8 -gt $Bytes.Length) { throw "WDB EOF가 없습니다: $Path" }
        $start = $pos
        $entry = U32 $Bytes $pos
        $size = U32 $Bytes ($pos + 4)
        $pos += 8
        if ($entry -eq 0 -and $size -eq 0) {
            if ($pos -ne $Bytes.Length) { throw "WDB EOF 뒤에 데이터가 남아 있습니다: $Path" }
            break
        }
        if ($entry -eq 0) { throw "Entry=0 레코드가 발견됐습니다: $Path" }
        if ($index.ContainsKey([uint32]$entry)) { throw "중복 Entry가 있습니다: $Path Entry=$entry" }
        if ($size -gt ($Bytes.Length - $pos)) { throw "WDB 레코드 크기가 파일 범위를 벗어납니다: $Path Entry=$entry Size=$size" }
        $rawLength = 8 + [int]$size
        $raw = Slice-Bytes $Bytes $start $rawLength
        $payload = Slice-Bytes $Bytes $pos ([int]$size)
        $record = [PSCustomObject]@{ Entry = [uint32]$entry; Size = [uint32]$size; Raw = $raw; Payload = $payload }
        [void]$records.Add($record)
        $index[[uint32]$entry] = $record
        $pos += [int]$size
    }
    return [PSCustomObject]@{ Header = (Slice-Bytes $Bytes 0 $HeaderSize); Records = $records; Index = $index }
}

function Verify-Merged($Original, $Patch, [byte[]]$MergedBytes, [string]$Path) {
    $merged = Read-Wdb $MergedBytes $Path $false
    if (-not (Bytes-Equal $Original.Header $merged.Header)) { throw "병합 검증 실패: 기존 24바이트 헤더가 변경됐습니다." }
    foreach ($record in $Original.Records) {
        if (-not $merged.Index.ContainsKey([uint32]$record.Entry)) { throw "병합 검증 실패: 기존 Entry $($record.Entry)가 사라졌습니다." }
        if (-not (Bytes-Equal $record.Raw $merged.Index[[uint32]$record.Entry].Raw)) { throw "병합 검증 실패: 기존 Entry $($record.Entry) 바이트가 변경됐습니다." }
    }
    foreach ($record in $Patch.Records) {
        if (-not $merged.Index.ContainsKey([uint32]$record.Entry)) { throw "병합 검증 실패: patch Entry $($record.Entry)가 없습니다." }
    }
    return $merged
}

function Merge-One([string]$PatchFile, [string]$TargetFile) {
    $targetBytes = Read-Bytes $TargetFile
    $patchBytes = Read-Bytes $PatchFile
    $target = Read-Wdb $targetBytes $TargetFile $false
    $patch = Read-Wdb $patchBytes $PatchFile $true
    $missing = New-Object System.Collections.ArrayList
    foreach ($record in $patch.Records) { if (-not $target.Index.ContainsKey([uint32]$record.Entry)) { [void]$missing.Add($record) } }
    Write-Host "검증 완료: $TargetFile" -ForegroundColor Cyan
    Write-Host "  기존 레코드: $($target.Records.Count) / R8.1 대상: $($patch.Records.Count) / 추가 필요: $($missing.Count)"
    if ($missing.Count -eq 0) {
        Write-Host "  모든 R8.1 크리처가 이미 캐시에 있습니다. 파일을 변경하지 않습니다." -ForegroundColor Green
        return
    }
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = $TargetFile + ".bak_R81_" + $stamp
    Copy-Item -LiteralPath $TargetFile -Destination $backup -Force
    $temp = $TargetFile + ".r81.tmp"
    $ms = New-Object System.IO.MemoryStream
    try {
        $ms.Write($target.Header, 0, $target.Header.Length)
        foreach ($record in $target.Records) { $ms.Write($record.Raw, 0, $record.Raw.Length) }
        foreach ($record in $missing) { $ms.Write($record.Raw, 0, $record.Raw.Length) }
        $zero = New-Object byte[] 8
        $ms.Write($zero, 0, 8)
        [System.IO.File]::WriteAllBytes($temp, $ms.ToArray())
    } finally { $ms.Dispose() }
    $mergedBytes = Read-Bytes $temp
    $merged = Verify-Merged $target $patch $mergedBytes $temp
    Move-Item -LiteralPath $temp -Destination $TargetFile -Force
    Write-Host "병합 완료: $TargetFile" -ForegroundColor Green
    Write-Host "  추가 레코드: $($missing.Count) / 최종: $($merged.Records.Count)"
    Write-Host "  백업: $backup" -ForegroundColor Cyan
}

function Add-UniquePath([System.Collections.ArrayList]$List, [string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $full = [System.IO.Path]::GetFullPath($Path)
    foreach ($existing in $List) { if ([string]::Equals($existing, $full, [System.StringComparison]::OrdinalIgnoreCase)) { return } }
    [void]$List.Add($full)
}

if (Get-Process -Name "Wow" -ErrorAction SilentlyContinue) { throw "WoW가 실행 중입니다. 게임을 완전히 종료한 뒤 다시 실행하세요." }
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($PatchPath)) { $PatchPath = Join-Path $scriptDir "featured_creaturecache_r81.wdb" }
$PatchPath = [System.IO.Path]::GetFullPath($PatchPath)
if (-not (Test-Path -LiteralPath $PatchPath)) { throw "R8.1 patch WDB를 찾을 수 없습니다: $PatchPath" }
$patchProbe = Read-Wdb (Read-Bytes $PatchPath) $PatchPath $true
Write-Host "R8.1 patch 검증: $($patchProbe.Records.Count) records / Build 12340 / koKR / recordSize 96" -ForegroundColor DarkCyan

if (-not [string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not (Test-Path -LiteralPath $TargetPath)) { throw "대상 WDB를 찾을 수 없습니다: $TargetPath" }
    Merge-One $PatchPath $TargetPath
    exit 0
}

if ([string]::IsNullOrWhiteSpace($WowRoot)) {
    $candidates = @((Split-Path -Parent (Split-Path -Parent $scriptDir)), (Get-Location).Path) | Select-Object -Unique
    foreach ($candidate in $candidates) { if (Test-Path (Join-Path $candidate "Wow.exe")) { $WowRoot = $candidate; break } }
}
while ([string]::IsNullOrWhiteSpace($WowRoot) -or -not (Test-Path (Join-Path $WowRoot "Wow.exe"))) {
    Write-Host "WoW 3.3.5a의 Wow.exe가 있는 폴더를 입력하세요." -ForegroundColor Yellow
    $WowRoot = (Read-Host "WoW 폴더").Trim('"')
}
$WowRoot = [System.IO.Path]::GetFullPath($WowRoot)
$targets = New-Object System.Collections.ArrayList
$normal = Join-Path $WowRoot "Cache\WDB\koKR\creaturecache.wdb"
if (Test-Path -LiteralPath $normal) { Add-UniquePath $targets $normal }
if ($env:LOCALAPPDATA) {
    $root = [System.IO.Path]::GetPathRoot($WowRoot)
    if ($root -and $WowRoot.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $WowRoot.Substring($root.Length).TrimStart('\')
        if (-not [string]::IsNullOrWhiteSpace($relative)) {
            $virtualWow = Join-Path (Join-Path $env:LOCALAPPDATA "VirtualStore") $relative
            $virtual = Join-Path $virtualWow "Cache\WDB\koKR\creaturecache.wdb"
            if (Test-Path -LiteralPath $virtual) { Add-UniquePath $targets $virtual }
        }
    }
}
if ($targets.Count -eq 0) { throw "기존 Build 12340 koKR creaturecache.wdb를 찾지 못했습니다. 게임에 1회 로그인한 뒤 WoW를 완전히 종료하고 다시 실행하세요. R8.1은 서버 ClientCacheVersion을 추정해서 새 캐시를 만들지 않습니다." }
Write-Host "실제 creaturecache.wdb $($targets.Count)개 발견" -ForegroundColor Yellow
foreach ($target in $targets) { Merge-One $PatchPath $target }
Write-Host "R8.1 캐시 병합 검증이 완료되었습니다. /reload가 아니라 WoW를 완전히 다시 실행하세요." -ForegroundColor Green
