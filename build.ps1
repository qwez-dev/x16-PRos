# ==================================================================
# x16-PRos -- The x16-PRos build script for Windows (PowerShell)
# Copyright (C) 2025 PRoX2011
# Minimal deps: NASM only (place nasm.exe in PATH or tools\nasm\nasm.exe)
# ==================================================================

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

# Colors (approximate to original)
function Print([string]$color, [string]$msg) {
    $map = @{
        "RED"="Red"; "GREEN"="Green"; "YELLOW"="Yellow"; "BLUE"="Cyan"; "NC"="Gray"
    }
    Write-Host $msg -ForegroundColor ($map[$color])
}

# Resolve nasm: prefer local tools\nasm\nasm.exe, then PATH
function Resolve-Tool([string]$name, [string]$localRel){
  $local = Join-Path $PSScriptRoot $localRel
  if (Test-Path $local) { return $local }
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  throw "Tool not found: $name (put it at $localRel or add to PATH)"
}
$nasm = Resolve-Tool "nasm.exe" "tools\nasm\nasm.exe"

# Prepare folders
New-Item -ItemType Directory -Force -Path "bin" | Out-Null
New-Item -ItemType Directory -Force -Path "disk_img" | Out-Null
$img = "disk_img\x16pros.img"

# Geometry constants for 1.44MB FAT12
$BPS=512; $SPC=1; $RS=1; $NF=2; $NDE=224; $SPF=9; $TS=2880; $MEDIA=0xF0
$ClusterSize = $BPS * $SPC
$RootSects   = [int][math]::Ceiling(($NDE*32)/$BPS)     # 14
$FirstRootSector = $RS + ($NF*$SPF)                     # 19
$FirstDataSector = $FirstRootSector + $RootSects        # 33

# Helpers
function To-Short83([string]$path){
  $fn   = [System.IO.Path]::GetFileName($path)
  $base = [System.IO.Path]::GetFileNameWithoutExtension($fn)
  $ext  = ([System.IO.Path]::GetExtension($fn)).TrimStart('.')

  function Filter83([string]$s){
    $s = $s.ToUpperInvariant()
    $allowed = New-Object 'System.Collections.Generic.HashSet[char]'
    for($i=[int][char]'A'; $i -le [int][char]'Z'; $i++){ [void]$allowed.Add([char]$i) }
    for($i=[int][char]'0'; $i -le [int][char]'9'; $i++){ [void]$allowed.Add([char]$i) }
    foreach ($code in 36,37,39,45,95,64,126,96,33,40,41,123,125,94,35,38) { [void]$allowed.Add([char]$code) } # $ % ' - _ @ ~ ` ! ( ) { } ^ # &
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $s.ToCharArray()){
      if ($allowed.Contains($ch)) { [void]$sb.Append($ch) }
    }
    return $sb.ToString()
  }

  $base = Filter83 $base
  $ext  = Filter83 $ext

  if ([string]::IsNullOrWhiteSpace($base)) { $base = "NONAME" }
  if ($base.Length -gt 8) { $base = $base.Substring(0,8) }
  if ($ext.Length  -gt 3) { $ext  = $ext.Substring(0,3) }

  $name = ($base.PadRight(8,' ') + $ext.PadRight(3,' '))
  return ,([byte[]][System.Text.Encoding]::ASCII.GetBytes($name))
}
function Set-LE16([byte[]]$a,[int]$o,[int]$v){ $a[$o]=[byte]($v -band 0xFF); $a[$o+1]=[byte](($v -shr 8)-band 0xFF) }
function Set-LE32([byte[]]$a,[int]$o,[uint32]$v){ for($i=0;$i -lt 4;$i++){ $a[$o+$i]=[byte](($v -shr (8*$i)) -band 0xFF) } }
function Set-FAT12([byte[]]$fat,[int]$cl,[int]$val){
  $off = [int][math]::Floor($cl*3/2)
  if(($cl % 2) -eq 0){
    $fat[$off]   = [byte]($val -band 0xFF)
    $fat[$off+1] = [byte]( ($fat[$off+1] -band 0xF0) -bor ( ($val -shr 8) -band 0x0F ) )
  } else {
    $fat[$off]   = [byte]( ($fat[$off] -band 0x0F) -bor ((($val -band 0x0F) -shl 4)) )
    $fat[$off+1] = [byte]( ($val -shr 4) -band 0xFF )
  }
}

function Build-FAT12Image([string]$imagePath,[string]$bootBin,[string[]]$filePaths){
  # Create entire image in memory to keep it simple and dependency-free
  $img  = New-Object byte[] ($TS*$BPS)    # 1,474,560 bytes
  $FAT  = New-Object byte[] ($SPF*$BPS)   # 4,608 bytes
  $ROOT = New-Object byte[] ($RootSects*$BPS)

  # FAT ID (media + EOC markers for clusters 0 and 1)
  $FAT[0]=[byte]$MEDIA; $FAT[1]=0xFF; $FAT[2]=0xFF

  $nextCl = 2
  $dirIdx = 0

  foreach($fp in $filePaths){
    if(-not (Test-Path $fp)){ continue }
    $data=[System.IO.File]::ReadAllBytes($fp)
    $need=[int][math]::Ceiling($data.Length/$ClusterSize)
    if($need -le 0){ $need=1 }

    # Build cluster chain
    $chain = @()
    for($i=0;$i -lt $need;$i++){ $chain += $nextCl; $nextCl++ }

    # Write data and FAT entries
    for($i=0;$i -lt $chain.Count;$i++){
      $cl = $chain[$i]
      $val = 0xFFF
      if ($i -lt ($chain.Count - 1)) { $val = $chain[$i+1] }
      Set-FAT12 $FAT $cl $val

      $srcOff = $i * $ClusterSize
      $remain = [Math]::Max(0, $data.Length - $srcOff)
      $len = [Math]::Min($ClusterSize, $remain)
      $dstOff = ($FirstDataSector + ($cl-2)) * $BPS
      if($len -gt 0){
        [System.Buffer]::BlockCopy($data, $srcOff, $img, $dstOff, $len)
      }
    }

    # Root directory entry
    $deOff = $dirIdx * 32
    $dirIdx++

    $name = To-Short83 $fp
    [System.Buffer]::BlockCopy($name,0,$ROOT,$deOff,11)
    $ROOT[$deOff+11]=0x20  # ATTR_ARCHIVE

    $now=Get-Date
    $dosTime = (($now.Hour -shl 11) -bor ($now.Minute -shl 5) -bor ([int]([math]::Floor($now.Second/2))))
    $dosDate = ((($now.Year-1980) -shl 9) -bor ($now.Month -shl 5) -bor $now.Day)
    Set-LE16 $ROOT ($deOff+14) $dosTime     # Create time
    Set-LE16 $ROOT ($deOff+16) $dosDate     # Create date
    Set-LE16 $ROOT ($deOff+22) $dosTime     # Write time
    Set-LE16 $ROOT ($deOff+24) $dosDate     # Write date
    Set-LE16 $ROOT ($deOff+26) $chain[0]    # First cluster
    Set-LE32 $ROOT ($deOff+28) ([uint32]($data.Length))
  }

  # FAT copies
  $fatOff = $RS*$BPS
  [System.Buffer]::BlockCopy($FAT,0,$img,$fatOff,$FAT.Length)                          # FAT #1
  [System.Buffer]::BlockCopy($FAT,0,$img,$fatOff+($SPF*$BPS),$FAT.Length)              # FAT #2

  # Root directory
  $rootOff = ($RS + ($NF*$SPF))*$BPS
  [System.Buffer]::BlockCopy($ROOT,0,$img,$rootOff,$ROOT.Length)

  # Boot sector (pad/trunc + signature 55AA)
  $boot=[System.IO.File]::ReadAllBytes($bootBin)
  if($boot.Length -lt 512){ $pad=New-Object byte[] (512-$boot.Length); $boot=$boot+$pad }
  if($boot.Length -gt 512){ $boot=$boot[0..511] }
  $boot[510]=0x55; $boot[511]=0xAA
  [System.Buffer]::BlockCopy($boot,0,$img,0,512)

  [System.IO.File]::WriteAllBytes($imagePath,$img)
}

function Show-DiskContents([string]$imagePath){
  $bytes = [System.IO.File]::ReadAllBytes($imagePath)
  $rootOff = ($RS + ($NF*$SPF))*$BPS
  $entries = @()
  for($i=0; $i -lt $NDE; $i++){
    $off = $rootOff + $i*32
    $first = $bytes[$off]
    if ($first -eq 0x00) { break }        # end of directory
    if ($first -eq 0xE5) { continue }     # deleted
    $attr = $bytes[$off+11]
    if ($attr -eq 0x0F) { continue }      # LFN
    # name + ext
    $nameBytes = $bytes[$off..($off+7)]
    $extBytes  = $bytes[($off+8)..($off+10)]
    $name = ([Text.Encoding]::ASCII.GetString($nameBytes)).Trim()
    $ext  = ([Text.Encoding]::ASCII.GetString($extBytes)).Trim()
    if ($ext.Length -gt 0) { $name = "$name.$ext" }
    $size = [BitConverter]::ToUInt32($bytes, $off+28)
    $entries += @{Name=$name; Size=$size}
  }
  foreach($e in $entries){
    Write-Host "  $($e.Name) ($($e.Size) bytes)"
  }
}

# ==================================================================
# Build flow (messages match the Linux script)
# ==================================================================

Print "NC" ""
Print "GREEN" "========== Starting x16-PRos build... =========="
Print "NC" ""

Print "BLUE" "Compiling bootloader (boot.asm)..."
& $nasm -f bin "src/bootloader/boot.asm" -o "bin/BOOT.BIN"
if ($LASTEXITCODE) { throw "Bootloader compilation failed" }

Print "BLUE" "Compiling kernel (kernel.asm)..."
& $nasm -f bin "src/kernel/kernel.asm" -o "bin/KERNEL.BIN"
if ($LASTEXITCODE) { throw "Kernel compilation failed" }

Print "BLUE" "Creating disk image..."
# (Done in-memory in Build-FAT12Image)

Print "BLUE" "Formatting disk image..."
# (Done in-memory in Build-FAT12Image)

Print "BLUE" "Writing bootloader to disk..."
# (Done in-memory in Build-FAT12Image)

Print "BLUE" "Copying kernel to disk..."
# (Done in-memory in Build-FAT12Image)

Print "NC" ""
Print "BLUE" "Compiling programs package..."

# Compile programs and collect files for image
$programs = @(
  @{src="programs/hello.asm"   ; out="HELLO.BIN"   }
  @{src="programs/write.asm"   ; out="WRITER.BIN"  }
  @{src="programs/barchart.asm"; out="BCHART.BIN"  }
  @{src="programs/brainf.asm"  ; out="BRAINF.BIN"  }
  @{src="programs/calc.asm"    ; out="CALC.BIN"    }
  @{src="programs/memory.asm"  ; out="MEMORY.BIN"  }
  @{src="programs/mine.asm"    ; out="MINE.BIN"    }
  @{src="programs/piano.asm"   ; out="PIANO.BIN"   }
  @{src="programs/snake.asm"   ; out="SNAKE.BIN"   }
  @{src="programs/space.asm"   ; out="SPACE.BIN"   }
  @{src="programs/procentc.asm"; out="PROCENTC.BIN"}
) | Where-Object { Test-Path $_.src }

foreach($p in $programs){
  & $nasm -f bin $p.src -o ("bin\" + $p.out)
  if ($LASTEXITCODE) { throw ("Program compilation failed: " + $p.src) }
}

# Collect files to put into the image
$files = @("bin\KERNEL.BIN")
$files += ($programs | ForEach-Object { "bin\" + $_.out })
foreach($t in @("LICENSE.TXT","ABOUT.TXT")){ if(Test-Path $t){ $files += $t } }

# Build image (boot + kernel + programs + texts)
Build-FAT12Image $img "bin\BOOT.BIN" $files

Print "NC" ""
Print "YELLOW" "Disk contents:"
Show-DiskContents $img

Print "NC" ""
Print "GREEN" "========== Build completed successfully! =========="