<#------------------Assumptions & Methodology-----------#

1. Assumes all files within monitored environment are content-unique (No duplicates).
2. File created = monitored file's path AND hash do not exist in the baseline.
3. File altered = monitored file's path exists in the basline, but not its hash.
4. File deleted =  basline file's path AND hash are not found.
5. File renamed = monitored file's hash exists in the basline, but not its path.
6. Files altered AND renamed are treated as "created" files, where 
   the original file (baseline path/hash comination) is assumed to be "deleted".

#>


#------------------Setup--------------------------------#
$monlist = @()
$filelist = @()
$folderlist = @()
$input = ""

Function MonList {
$i = 1
write-host "
Monitor List:"
foreach ($x in $monlist) { Write-Host $i. $x; $i += 1} 
}

Function FileHashFunc {

$filelist = @()
$folderlist = @()
$files = Get-ChildItem -path $monlist -force -Recurse

foreach ($f in $files){
    if ($f.mode -ilike "*a*"){ $filelist += $f.FullName }
    elseif ($f.mode -ilike "*d*"){ $folderlist += $f.FullName }
}

if ($filelist.count -ne 0) { $hashed = get-filehash -path $filelist }
return $hashed

}


#------------------User Input--------------------------#
while ($input -ne "ok"){

$input = (read-host "
Enter a directory to monitor ('ok' to scan)").Trim()
if ($input -ne "") {
$tp = Test-Path -path $input }

    if (($input -ne "ok") -and ($input -ne "")){

    if ($tp -ne $True){
    write-host "* not a valid directory" -ForegroundColor Red 
    MonList }

    elseif ($input -in $monlist){
    write-host "* already added" -ForegroundColor Red 
    MonList }

    else {
    $monlist += $input
    write-host "* added to monitor list" -ForegroundColor Green
    MonList }

    }

}


#------------------Baseline Dictionaries---------------#
$fileHashes = FileHashFunc

# Basline Dictionary (Path, Hash)
$BaseDict = [ordered]@{}
foreach ($x in $fileHashes) { $BaseDict.add($x.path, $x.hash) }


#------------------Active Monitoring-------------------#
while ($true) {
    start-sleep -Milliseconds 2500
    Clear-Host
    Start-Sleep -Milliseconds 500
    
    $fileHashes = FileHashFunc
     
    # Created or Altered
    foreach ($f in $fileHashes) {
       
            # Created
            if (($f.path -notin $BaseDict.Keys) -and ($f.hash -notin $BaseDict.Values)) { 
            write-host "* File Created: $($f.path)" -ForegroundColor Cyan }

            # Altered
            if (($f.path -in $BaseDict.Keys) -and ($f.hash -notin $BaseDict.Values)) { 
            write-host "* File Altered: $($f.Path)" -ForegroundColor magenta }

    }
    
    # Deleted or Renamed
    $hashList = @()
    foreach ($f in $fileHashes) { $hashList += $f.hash }
       
    foreach ($Path in $BaseDict.Keys) {

            $pathexists = test-path -path $Path
            $hashexists = ($BaseDict[$Path] -in $hashList) -eq $true

            # Deleted
            if (($pathexists -eq $false) -and ($hashexists -eq $false)) { 
            write-host "* File Deleted: $($Path)" -ForegroundColor Red }
            
            # Renamed
            elseif (($pathexists -eq $false) -and ($hashexists -eq $true)) { 
            foreach ($f in $fileHashes) { if ($f.hash -eq $BaseDict[$Path]) 
            { write-host "* File Renamed: $($Path) --> $($f.Path)" -ForegroundColor Yellow }}}
    }

}
