#---------------------------Setup---------------------------------#

$dirs = @()
$filelist = @()
$folderlist = @()
$input = ""

#------------------------Baseline---------------------------#
$BasePath = "$($env:USERPROFILE)\Documents\Baseline.txt"
    
$BaselineExists = Test-path -path $BasePath
    
if ($BaselineExists -eq "True") {
remove-item -path $BasePath
}
else {
New-Item -path $BasePath
}

# UserInput
while ($input -ne "done"){

$input = read-host "
Enter a directory to monitor ('done' to exit)"
$tp = Test-Path -path $input

    if ($input -ne "done"){
    if ($tp -eq $False){
        write-host "$($input) is not a valid directory" -ForegroundColor Red
    }
    else{
    $dirs += $input
    write-host($dirs)
    write-host "$($input) added to monitor list" -ForegroundColor Green
    }
    }

}


#--------------------------FileSift------------------------------------#
while ($dirs -ne 0){

$folderlist = @()

foreach ($dir in $dirs){
    $files = Get-ChildItem -path $dir -force
    foreach ($f in $files){
        if ($f.mode -ilike "*a*"){
        $filelist += ("$dir\$f")
        }
        elseif ($f.mode -ilike "*d*"){
            $folderlist += ("$dir\$f")
        }

            }}
$dirs = @()
$dirs = $folderlist
}


#-------------------Getting hash values and appending them to Baseline.txt--------------------#
$fileHashes = get-filehash -path $filelist

foreach ($fhash in $fileHashes) {
add-content -path $BasePath -value "$($fhash.path)||$($fhash.hash)"
}

$SavedBaseline = get-content -path $BasePath

# Path, Hash Dictionary
$BaseDict = [ordered]@{}
    foreach ($line in $SavedBaseline) {
    $BaseDict.add($line.split("|")[0],$line.split("|")[2])
    }

# Hash, Path Dictionary
$RevBaseDict = [ordered]@{}
    foreach ($x in $BaseDict.keys) {
    $RevBaseDict.Add($BaseDict[$x], $x)
    }


#-------------------------Active Monitoring---------------------------#

while ($true) {
    start-sleep -seconds 2.5
    clear-host
    start-sleep -seconds 0.75
        
        $files = Get-ChildItem -path $Monitored_Environment -force
        $FileDict = @{}
        $FolderDict = @{}

        FileSift

        $FileHashes = get-filehash -path $FileDict.keys
        
        $FHDict = [ordered]@{}
        foreach ($f in $FileHashes) {
        $FHDict.add($f.hash, $f.path)
        }
       
    # Created or Altered (Ver. 2)
    foreach ($FileHash in $FileHashes) {
        
            # Notify if a new file has been created
        
            if (($BaseDict[$FileHash.path] -eq $null) -and ($RevBaseDict[$FileHash.hash] -eq $null)) {
                write-host "*File Created* $($FileHash.path)" -ForegroundColor Cyan
            }

            else {
            
            
                if (($BaseDict[$FileHash.path] -ne $null) -and ($BaseDict[$FileHash.path] -ne $FileHash.Hash)) {
    
                write-host "*File Altered* $($FileHash.Path)" -ForegroundColor magenta
                }
              
        }
       
       }
    

    # Deleted
    foreach ($key in $BaseDict.keys) {

     $pathexists = test-path -path $key
     $hashexists = (($FHDict[$BaseDict[$key]] -ne $null) -eq $true)

           if (($pathexists -eq $false) -and ($hashexists -eq $false)) {
           write-host "*File Deleted* $($key)" -ForegroundColor Red
           
           }
           }

    # Renamed
    foreach ($BVal in $BaseDict.values) {

        foreach ($F in $FileHashes) {
    
            if (($F.hash -eq $BVal) -and ($RevBaseDict[$F.hash] -ne $F.path)) {
        
                write-host "*File Renamed* $($RevBaseDict[$F.hash]) --> $($F.path)" -foregroundcolor yellow
    break
            }

            }
            }
            
            
  }



write-host ""
