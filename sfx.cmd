@Echo Off
Echo Off
Rem Builds or applies the SFX stub that unpacks zakoai-proxy.exe next to this file.
SetLocal EnableDelayedExpansion
Set "HERE=%~dp0"
Set "WORK=D:\zkbuild"
Set "DIST=%~dp0dist\ZakoAI-Proxy-Windows"
Set "DLL=%WORK%\zakoai-proxy.exe"
Set "CAB=%WORK%\cab\zakoai-proxy.cab"
Set "IEXPRESS=%SystemRoot%\System32\iexpress.exe"

If /I "%~1"=="make" Goto :Make
If /I "%~1"=="apply" Goto :Apply
Echo Usage: sfx.cmd make ^| apply
Exit /B 1

:Make
If Not Exist "%DLL%" (
    Echo Missing %DLL%
    Exit /B 1
)
If /I "%~2"=="lowmem" (
    Set "PRESS=MSZip"
    Set "MEM=0"
) Else (
    Set "PRESS=LZX"
    Set "MEM=21"
)
If Not Exist "%WORK%\cab" MkDir "%WORK%\cab"
del /q "%WORK%\cab\*.cab" 2>Nul
>"%WORK%\cab\pack.ddf" Echo .Set CabinetName1=zakoai_proxy.cab
>>"%WORK%\cab\pack.ddf" Echo .Set DiskDirectoryTemplate=%WORK%\cab
>>"%WORK%\cab\pack.ddf" Echo .Set Cabinet=on
>>"%WORK%\cab\pack.ddf" Echo .Set Compress=on
>>"%WORK%\cab\pack.ddf" Echo .Set CompressionType=%PRESS%
>>"%WORK%\cab\pack.ddf" Echo .Set CompressionMemory=%MEM%
>>"%WORK%\cab\pack.ddf" Echo .Set MaxDiskSize=0
>>"%WORK%\cab\pack.ddf" Echo .Set CabinetFileCountThreshold=0
>>"%WORK%\cab\pack.ddf" Echo .Set FolderFileCountThreshold=0
>>"%WORK%\cab\pack.ddf" Echo .Set FolderSizeThreshold=0
>>"%WORK%\cab\pack.ddf" Echo .Set RptFileName=nul
>>"%WORK%\cab\pack.ddf" Echo .Set InfFileName=nul
>>"%WORK%\cab\pack.ddf" Echo "%DLL%"
"%SystemRoot%\System32\makecab.exe" /F "%WORK%\cab\pack.ddf"
If ErrorLevel 1 Exit /B 1
>"%WORK%\cab\payload.sed" Echo [Version]
>>"%WORK%\cab\payload.sed" Echo Class=IEXPRESS
>>"%WORK%\cab\payload.sed" Echo SEDVersion=3
>>"%WORK%\cab\payload.sed" Echo [Options]
>>"%WORK%\cab\payload.sed" Echo PackagePurpose=InstallApp
>>"%WORK%\cab\payload.sed" Echo ShowInstallProgramWindow=1
>>"%WORK%\cab\payload.sed" Echo HideExtractAnimation=0
>>"%WORK%\cab\payload.sed" Echo UseLongFileName=1
>>"%WORK%\cab\payload.sed" Echo InsideCompressed=1
>>"%WORK%\cab\payload.sed" Echo CAB_FixedSize=0
>>"%WORK%\cab\payload.sed" Echo CAB_ResvCodeSigning=0
>>"%WORK%\cab\payload.sed" Echo RebootMode=N
>>"%WORK%\cab\payload.sed" Echo InstallPrompt=
>>"%WORK%\cab\payload.sed" Echo DisplayLicense=
>>"%WORK%\cab\payload.sed" Echo FinishMessage=
>>"%WORK%\cab\payload.sed" Echo TargetName=%CAB%
>>"%WORK%\cab\payload.sed" Echo FriendlyName=ZakoAI Proxy runtime
>>"%WORK%\cab\payload.sed" Echo AppLaunched=powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%%EXTRACT_DIR%%\..\unpack.ps1"
>>"%WORK%\cab\payload.sed" Echo PostInstallCmd=%SystemRoot%\System32\cmd.exe /c ""%%EXTRACT_DIR%%\..\unpack.ps1""
>>"%WORK%\cab\payload.sed" Echo AdminQuietInstCmd=
>>"%WORK%\cab\payload.sed" Echo UserQuietInstCmd=
>>"%WORK%\cab\payload.sed" Echo SourceFiles=SourceFiles
>>"%WORK%\cab\payload.sed" Echo [Strings]
>>"%WORK%\cab\payload.sed" Echo FILE0="zakoai-proxy.exe"
>>"%WORK%\cab\payload.sed" Echo [SourceFiles]
>>"%WORK%\cab\payload.sed" Echo SourceFiles0=%%EXTRACT_DIR%%\
>>"%WORK%\cab\payload.sed" Echo [SourceFiles0]
>>"%WORK%\cab\payload.sed" Echo %%FILE0%%=
%IEXPRESS% /N /Q "%WORK%\cab\payload.sed"
If ErrorLevel 1 Exit /B 1
If Exist "%CAB%" (
    Echo CAB built: %CAB%
    Exit /B 0
)
Echo CAB not produced
Exit /B 1

:Apply
If Not Exist "%CAB%" (
    Echo Missing %CAB% - run "sfx.cmd make" first
    Exit /B 1
)
Set "STUB=%DIST%\zakoai_proxy.sfx"
copy /y "%IEXPRESS%" "%STUB%" >Nul
cmd /c copy /b "%STUB%" + "%CAB%" "%DIST%\zakoai_proxy.exe" >Nul
If Exist "%DIST%\zakoai_proxy.exe" (
    For %%F In ("%DIST%\zakoai_proxy.exe") Do Echo SFX built: %%~zF bytes
    Exit /B 0
)
Exit /B 1





