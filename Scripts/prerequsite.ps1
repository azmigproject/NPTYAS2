


Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}




Function DowloadNPTYAS2Artifacts
{
    $WorkingDir="c:\NPTYAS21"
    $workd = "c:\NPTYAS2tempFiles"
    
    Set-ExecutionPolicy RemoteSigned
    # Check if work directory exists if not create it
    If (!(Test-Path -Path $workd -PathType Container))
    { 
        New-Item -Path $workd  -ItemType directory 
    }
     If (!(Test-Path -Path $WorkingDir -PathType Container))
    { 
        New-Item -Path $WorkingDir  -ItemType directory 
    }
    $nptyas2ServerSource = "https://nptyas2storage.blob.core.windows.net/nptyas2files/NPTYAS2Server.zip"
    $nptyas2UISource = "https://nptyas2storage.blob.core.windows.net/nptyas2files/nptyAS2.zip"
    $destination = "$workd"
    #wget "$nptyas2ServerSource" -outfile "$destination\NPTYAS2Server.zip"
    #wget "$nptyas2UISource" -outfile "$destination\nptyAS2.zip"
    $client = New-Object System.Net.WebClient    
    $client.DownloadFile($nptyas2ServerSource, "$destination\NPTYAS2Server.zip")
    $client.DownloadFile($nptyas2UISource, "$destination\nptyAS2.zip")
    Unzip "$workd\NPTYAS2Server.zip" "$WorkingDir"
    Unzip "$workd\nptyAS2.zip" "$WorkingDir"
}
Function InstallJava
{
 
     # Download and silent install Java Runtime Environement
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
    # working directory path
    $workd = "c:\temp"
    Set-ExecutionPolicy RemoteSigned
    # Check if work directory exists if not create it
    If (!(Test-Path -Path $workd -PathType Container))
    { 
        New-Item -Path $workd  -ItemType directory 
    }

    #create config file for silent install
    $text = '
    INSTALL_SILENT=Enable
    AUTO_UPDATE=Enable
    SPONSORS=Disable
    REMOVEOUTOFDATEJRES=1
    '
    $text | Set-Content "$workd\jreinstall.cfg"
    
    #download executable, this is the small online installer
    $source = "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=230511_2f38c3b165be4555a1fa6e98c45e0808"
    $destination = "$workd\jreInstall.exe"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($source, $destination)

    #install silently
    Start-Process -FilePath "$workd\jreInstall.exe" -ArgumentList INSTALLCFG="$workd\jreinstall.cfg"

    # Wait 120 Seconds for the installation to finish
    Start-Sleep -s 180

    # Remove the installer
    rm -Force $workd\jre*

}
#InstallJava
DowloadNPTYAS2Artifacts
