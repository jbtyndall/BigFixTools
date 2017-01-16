<#
    .NOTES
    Author:  John Tyndall (iTyndall.com)
    Version: 1.0.2.0
    Details: www.iTyndall.com

    .SYNOPSIS
    Creates a new prefetch command, used by IBM Endpoint Manager to download and verify a file.
    
    .DESCRIPTION
    This cmdlet creates a new prefetch command, used by IBM Endpoint Manager to download and verify a file.

    To create the command, the cmdlet downloads the file specified by the Url parameter to the folder location specified by the DownloadLocation parameter. It then calculates the SHA1 hash and size of the downloaded file.

    .PARAMETER Url
    Specifies the URL of the file to download.

    .PARAMETER PrefetchName
    Specifies the name that the prefetch command should use to download the file as.

    .PARAMETER DownloadLocation
    Specifies the download location for the file.
    The default location is %TEMP%, which is normally the C:\Users\<CurrentUser>\AppData\Local\Temp folder.

    .PARAMETER ForceDownload
    Specifies whether or not to force the download.
    By default, if a file with the same name exists in the download location, it is not downloaded.
    Setting ForceDownload removes any existing file in the download location and initiates a re-download.

    .INPUTS

    None. You cannot pipe input to this cmdlet.
    
    .OUTPUTS 
    
    System.String. A prefetch command with the syntax

    prefetch <name> sha1:<value> size:<value> <url>

    where
     
    - <name> is the name of a file (32 characters or less, composed of ASCII characters a-z, A-Z, 0-9, -, _, and non-leading periods)
    - sha1:<value> is the secure hash algorithm value of the file specified by <url>
    - size:<value> is the size in bytes of the file specified by <url>
    - <url> is the location of the site, including the filename, of the file to be downloaded.

    .EXAMPLE

    New-Prefetch -Url http://www.iTyndall.com/readme.txt

    This command downloads the file readme.txt to the current user's temp folder.
    If the file exists, it is not downloaded.
    
    The generated prefetch command is, e.g.,

    prefetch readme.txt sha1:0123456789 size:1234 http://www.iTyndall.com/readme.txt

    .EXAMPLE

    New-Prefetch -Url http://www.iTyndall.com/readme.txt -ForceDownload

    This command downloads the file readme.txt to the current user's temp folder.
    If the file exists, it is removed and re-downloaded.

    The generated prefetch command is, e.g.,

    prefetch readme.txt sha1:0123456789 size:1234 http://www.iTyndall.com/readme.txt

    .EXAMPLE

    New-Prefetch -Url http://www.iTyndall.com/readme.txt -DownloadFolder C:\Users\John\Downloads

    This command downloads the file readme.txt to the C:\Users\John\Downloads folder.

    The generated prefetch command is, e.g.,

    prefetch readme.txt sha1:0123456789 size:1234 http://www.iTyndall.com/readme.txt

    .EXAMPLE

    New-Prefetch -Url http://www.iTyndall.com/readme.txt -PrefetchName readmeNOW.txt

    This command downloads the file readme.txt to the current user's temp folder.
    Since a PrefetchName is specified, the prefetch command will download the file as readmeNOW.txt.

    The generated prefetch command is, e.g.,

    prefetch readmeNOW.txt sha1:0123456789 size:1234 http://www.iTyndall.com/readme.txt


#>

Function New-Prefetch{
Param(
    [Parameter(Mandatory=$true,Position=0, HelpMessage="The url of the file to download.")][string]$Url,
    [Parameter(Mandatory=$false,Position=1, HelpMessage="The name that the prefetch command should use to download the file as.")][string]$PrefetchName,
    [Parameter(Mandatory=$false,Position=2, HelpMessage="The folder to download the file to.")][string]$DownloadFolder=$env:TEMP,
    [switch]$ForceDownload,
    [switch]$IsPrefetchItem
)

    #get the actual name of the file to download
    $FileName = ""
    $FileName = ($Url.Split("/"))[-1]

    #set empty PrefetchName to the name of the file being downloaded
    If([string]::IsNullOrEmpty($PrefetchName)){
        $PrefetchName = $FileName
    }

    #check size
    #could use ValidateSet, but want a custom message
    If($PrefetchName.Length -gt 32){
        $Ex = New-Object System.ArgumentOutOfRangeException("PrefetchName", "The character length of $($PrefetchName.Length) for the file named $PrefetchName is too long. Try the command again with -PrefetchName to shorten the name of the file so that is is fewer than or equal to 32 characters.")
        Throw $Ex
    }

    $FileDownload = ""
    $FileDownload = "$DownloadFolder\$FileName"

    #force download (i.e., by removing any existing files)
    If ($ForceDownload) {
        Remove-Item $FileDownload -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    #download file if it doesn't exist
    If(-not (Test-Path $FileDownload)){
        $Web = New-Object System.Net.WebClient
        $Web.DownloadFile($Url,$FileDownload)
    }

    #calculate size and sha1 hash
    If(Test-Path $FileDownload){
    
        $Size = (Get-Item $FileDownload).Length
    
        $Sha1 = (Get-FileHash -Path $FileDownload -Algorithm SHA1).Hash

        $Sha256 = (Get-FileHash -Path $FileDownload -Algorithm SHA256).Hash

        If($IsPrefetchItem){
            #$PrefetchCommand = "add prefetch item name=$PrefetchName size=$Size sha1=$($Sha1.ToLower()) url=$Url"
            $PrefetchCommand = "add prefetch item name=$PrefetchName size=$Size sha1=$($Sha1.ToLower()) url=$Url sha256=$($Sha256.ToLower())"
        } Else {
            #$PrefetchCommand = "prefetch $PrefetchName sha1:$($Sha1.ToLower()) size:$Size $Url"
            $PrefetchCommand = "prefetch $PrefetchName sha1:$($Sha1.ToLower()) size:$Size $Url sha256:$($Sha256.ToLower())"
        }

        if (Test-Path "C:\Windows\System32\clip.exe"){ $PrefetchCommand | C:\Windows\System32\clip.exe }

        $PrefetchCommand


    } Else {
        $Ex = New-Object System.IO.FileNotFoundException("Could not find a file named $FileName in the $DownloadFolder folder.")
        Throw $Ex
    }
}
