<#
    .NOTES
    Author:  John Tyndall (iTyndall.com)
    Version: 1.0.0.0
    Details: www.iTyndall.com

    .DESCRIPTION
    This script generates a PREFETCH command, used to download (and verify) a file using IBM Endpoint Manager.

    .PARAMETER Url
    Specifies the URL of the file to download.

    .PARAMETER DownloadLocation
    Specifies the download location for the file.
    The default location is %TEMP%, which is normally the C:\Users\<CurrentUser>\AppData\Local\Temp folder.

    .PARAMETER ForceDownload
    Specifies whether or not to force the download.
    By default, if a file with the same name exists in the download location, it is not downloaded.
    Setting ForceDownload removes any existing file in the download location and initiates a re-download.

    .EXAMPLE

    New-Prefetch -Url http://www.iTyndall.com/readme.txt

    This command downloads the file readme.txt to the current user's temp folder.
    If the file exists, it is not downloaded.

    .EXAMPLE

    New-Prefetch -Url http://www.iTyndall.com/readme.txt -ForceDownload

    This command downloads the file readme.txt to the current user's temp folder.
    If the file exists, it is removed and re-downloaded.

    .EXAMPLE

    New-Prefetch -Url http://www.iTyndall.com/readme.txt -DownloadFolder C:\Users\John\Downloads

    This command downloads the file readme.txt to the C:\Users\John\Downloads folder.


#>
Param(
    [parameter(Mandatory=$true,Position=0, HelpMessage="The url of the file to download.")][string]$Url,
    [parameter(Mandatory=$false,Position=1, HelpMessage="The name that the prefetch command should use to download the file as.")][string]$PrefetchName,
    [parameter(Mandatory=$false,Position=2, HelpMessage="The folder to download the file to.")][string]$DownloadFolder=$env:TEMP,
    [switch]$ForceDownload
)

#get the actual name of the file to download
$FileName = ""
$FileName = ($Url.Split("/"))[-1]

If([string]::IsNullOrEmpty($PrefetchName)){
    $PrefetchName = $FileName
}

$FileDownload = ""
$FileDownload = "$DownloadFolder\$FileName"

#delete existing file if it exists
If ($ForceDownload) {
    If(Test-Path $FileDownload){
        Remove-Item $FileDownload
    }
}

#download file if it doesn't exist
If(-not (Test-Path $FileDownload)){
    $Web = New-Object System.Net.WebClient
    $Web.DownloadFile($Url,$FileDownload)
}

#calculate size and sha1 hash
If(Test-Path $FileDownload){
    $Size = (Get-Item $FileDownload).Length
    $Prefetch = "prefetch"

    $Sha1 = (Get-FileHash -Path $FileDownload -Algorithm SHA1).Hash

    $Prefetch += " $PrefetchName sha1:$($Sha1.ToLower()) size:$($Size) $($Url)"

    $Prefetch

} Else {
    Throw [System.IO.FileNotFoundException] "Could not download file $FileName from $Url"
}
