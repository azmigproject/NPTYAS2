


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
     
    $nptyas2ServerSource = "https://nptyas2storage.blob.core.windows.net/nptyas2files/NPTYAS2Server.zip?sp=r&st=2018-07-13T12:14:25Z&se=2020-12-30T20:14:25Z&spr=https&sv=2017-11-09&sig=a83t7rbCR1C4Ms0vIrCU8IFQwF%2FM0gVakXfa7zGaCx4%3D&sr=b"
    $nptyas2UISource = "https://nptyas2storage.blob.core.windows.net/nptyas2files/nptyAS2.zip?sp=r&st=2018-07-13T11:54:56Z&se=2020-12-30T19:54:56Z&spr=https&sv=2017-11-09&sig=PmBeVmgBDueqNqXOeVg7inN2U7421YIdFpVVUhcI4ls%3D&sr=b"
    $destination = "$workd"   
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

Function InstallJavaPolicy
{
    $workd = "c:\NPTYAS2tempFiles"
    $WorkingDir="c:\NPTYAS2tempFiles\JavaFiles"
    $src = "$WorkingDir\jce_policy-8"
    $dst = "C:\Program Files (x86)\Java\jre1.8.0_161\lib\security"
    $destination = "$workd" 
    If (!(Test-Path -Path $WorkingDir -PathType Container))
    { 
        New-Item -Path $WorkingDir  -ItemType directory 
    }
    $JavaPolicy="https://nptyas2storage.blob.core.windows.net/nptyas2files/jce_policy-8.zip?sp=r&st=2018-07-16T09:58:59Z&se=2020-12-31T17:58:59Z&spr=https&sv=2017-11-09&sig=DJ8khVFu43lNQHMIUyz7Wsn96heaPKy8JpVgS6Hi7AQ%3D&sr=b"
      
    $client = New-Object System.Net.WebClient    
    $client.DownloadFile($JavaPolicy, "$destination\jce_policy-8.zip")
    Unzip "$workd\jce_policy-8.zip" "$WorkingDir"
    Get-ChildItem $src | Move-Item -Destination $dst -Force

}

Function InstallIIS
{


        # --------------------------------------------------------------------
        # Checking Execution Policy
        # --------------------------------------------------------------------
        #$Policy = "Unrestricted"
        $Policy = "RemoteSigned"
        If ((get-ExecutionPolicy) -ne $Policy) {
          Write-Host "Script Execution is disabled. Enabling it now"
          Set-ExecutionPolicy $Policy -Force
          Write-Host "Please Re-Run this script in a new powershell enviroment"
          Exit
        }

        # --------------------------------------------------------------------
        # Define the variables.
        # --------------------------------------------------------------------
        $InetPubRoot = "D:\Inetpub"
        $InetPubLog = "D:\Inetpub\Log"
        $InetPubWWWRoot = "D:\Inetpub\WWWRoot"

        # --------------------------------------------------------------------
        # Loading Feature Installation Modules
        # --------------------------------------------------------------------
        Import-Module ServerManager 

        # --------------------------------------------------------------------
        # Installing IIS
        # --------------------------------------------------------------------
        Add-WindowsFeature -Name Web-Common-Http,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Http-Logging,Web-Request-Monitor,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Performance,Web-Mgmt-Console,Web-Mgmt-Compat,RSAT-Web-Server,WAS -IncludeAllSubFeature

        # --------------------------------------------------------------------
        # Loading IIS Modules
        # --------------------------------------------------------------------
        Import-Module WebAdministration

        # --------------------------------------------------------------------
        # Creating IIS Folder Structure
        # --------------------------------------------------------------------
        New-Item -Path $InetPubRoot -type directory -Force -ErrorAction SilentlyContinue
        New-Item -Path $InetPubLog -type directory -Force -ErrorAction SilentlyContinue
        New-Item -Path $InetPubWWWRoot -type directory -Force -ErrorAction SilentlyContinue

        # --------------------------------------------------------------------
        # Copying old WWW Root data to new folder
        # --------------------------------------------------------------------
        $InetPubOldLocation = @(get-website)[0].physicalPath.ToString()
        $InetPubOldLocation =  $InetPubOldLocation.Replace("%SystemDrive%",$env:SystemDrive)
        Copy-Item -Path $InetPubOldLocation -Destination $InetPubRoot -Force -Recurse

        # --------------------------------------------------------------------
        # Setting directory access
        # --------------------------------------------------------------------
        $Command = "icacls $InetPubWWWRoot /grant BUILTIN\IIS_IUSRS:(OI)(CI)(RX) BUILTIN\Users:(OI)(CI)(RX)"
        cmd.exe /c $Command
        $Command = "icacls $InetPubLog /grant ""NT SERVICE\TrustedInstaller"":(OI)(CI)(F)"
        cmd.exe /c $Command

        # --------------------------------------------------------------------
        # Setting IIS Variables
        # --------------------------------------------------------------------
        #Changing Log Location
        $Command = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.logfile.directory:$InetPubLog"
        cmd.exe /c $Command
        $Command = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralBinaryLogFile.directory:$InetPubLog"
        cmd.exe /c $Command
        $Command = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralW3CLogFile.directory:$InetPubLog"
        cmd.exe /c $Command

        #Changing the Default Website location
        Set-ItemProperty 'IIS:\Sites\Default Web Site' -name physicalPath -value $InetPubWWWRoot

        # --------------------------------------------------------------------
        # Checking to prevent common errors
        # --------------------------------------------------------------------
        If (!(Test-Path "C:\inetpub\temp\apppools")) {
          New-Item -Path "C:\inetpub\temp\apppools" -type directory -Force -ErrorAction SilentlyContinue
        }

        # --------------------------------------------------------------------
        # Deleting Old WWWRoot
        # --------------------------------------------------------------------
        Remove-Item $InetPubOldLocation -Recurse -Force

        # --------------------------------------------------------------------
        # Resetting IIS
        # --------------------------------------------------------------------
        $Command = "IISRESET"
        Invoke-Expression -Command $Command



}

InstallJava
InstallJavaPolicy
DowloadNPTYAS2Artifacts
