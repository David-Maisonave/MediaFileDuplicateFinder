@echo off
setlocal ENABLEDELAYEDEXPANSION
:: ################################################################################################
:: Description: This script performs the below steps. See next sections for command line options and requirements.
:: 1. Builds the solution
::    A. Builds multiple platforms (Windows, Linux, MAC)
::    B. Sets Major version, Minor version, Build version and Revision version. (major.minor.build.revision [1.33.2022.123])
::       1) Sets major version with value in file release_variables.txt
::       2) Sets minor version with an incremented value. 
::          a) Gets previous minor version from file {release_minor_version.txt}, increments it, and saves it back to the file.
::       3) Sets the build version and revision version with the current date. 
::          a) The year is set for the build value, and julian date is set for the revision value.
::	 Example: [1.6.2023.123] Where 1 is major version, 6 is 
::    C. Sets the identifier as the to the incremented minor version value.
::       1) The identifier helps when updating a program. It helps the installer to determine if the new install is newer than the current installation.
::    D. Sets release name by getting the value from release_variables.txt
::    E. If a setup project (VdProj file) exist (%ReleaseName%_Setup\%ReleaseName%_Setup.vdproj)
::       1) Creates a copy of the VdProj file with the ProductVersion number updated to the new incremented value.
::       2) Builds the setup project
::       3) Moves and renames the MSI file so that the MSI file includes the version number and the file name is in the same format as the other compressed packages
::       4) Adds the MSI package to the list of files to be uploaded to the new Github release
:: 2. Compresses windows files to zip, and all others to tgz
:: 3. Updates Github Repository if steps 1 & 2 completed successfully
:: 4. Creates a new Github release using the version

:: ################################################################################################
:: Usage command line options
:: NoRepoUpdate
::					The repository is NOT updated
:: NoBld
::					The projects do NOT get built, and the minor version is not incremented.
::					Uses the last build version.
:: NoCompress
::					Skips compressing packaged files.
:: NoGitRel
::					Does NOT create a new Github release, and does NOT upload packages
:: NoIncVer
::					Does NOT increment minor version, and uses last version from previous build.
:: NoIncUpdate
::					Increments minor version, but does NOT increment the value in release_minor_version.txt
:: NoSetup
::					Do NOT build Setup Project (VDPROJ)
:: NoVdProjReset
::					Leaves the VdProj modified, and does NOT reset to original file.
:: NoClean
::					Does NOT delete temporary files after processing
:: RelNotes
::					Release notes used to create Git release package. Argument should have double quotes.
::					This option overrides the value in the release_variables.txt
::					Can include batch variables: %ReleaseName%, %MajorVersion%, %MinorVersion%, %DotNetVer%, %ReleaseTitle%, %Identifier%, %ProgramVersion%, %ReleaseTag%, %YEAR%, %MONTH%, %DAY%
::					Example: GitRelease.cmd RelNotes "%ReleaseName% Version %MajorVersion%.%MinorVersion% build date=%YEAR%-%MONTH%-%DAY%"
::					Default is "%ReleaseName%_Ver%MajorVersion%.%MinorVersion%"
:: RelTitle
::					Release title used to create Git release package. Default is "%ReleaseName%_Ver%MajorVersion%.%MinorVersion%"
::					This option overrides the value in the release_variables.txt
::					Can include batch variables. See RelNotes.
::					Default is "%ReleaseName%_Ver%MajorVersion%.%MinorVersion%"
:: TestRun
::					This option is the same as the combination of the following options:
::					NoRepoUpdate & NoGitRel & NoIncUpdate & NoClean
:: TestVar
::					Only display variable values.
::					To avoid incrementing version, use this command in conjunction with NoIncUpdate. Example: GitRelease.cmd TestVar NoIncUpdate
::
:: Example Usage:
::					GitRelease.cmd TestRun
::					GitRelease.cmd NoRepoUpdate NoGitRel
::					GitRelease.cmd TestVar NoIncUpdate
::					GitRelease.cmd RelNotes "Beta Version %MinorVersion%" RelTitle MediaFileDuplicateFinderApp
::					GitRelease.cmd RelTitle "Latest of %ReleaseName% Version %MinorVersion%"
:: Requirements
:: Git installation: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
:: Github CLI: https://github.com/cli/cli/releases
:: dotnet and Visual Studio 2019, 2022, or higher
::		dotnet path must be in environmental %PATH%
::		If the solution has multiple projects, the project file "Base output path" settings should be set to $(SolutionDir)bin
::		This setting is normally needed because command line "-o" is no longer supported by dotnet.
:: 7zip installed if 7z is not installed in path (C:\Program Files\7-Zip), change the value of variable Prg7Zip to correct path.
:: Requires a files called release_minor_version.txt and release_variables.txt. See example file in this repository.
::		This file name can be changed by modifying variable ReleaseFileVariables.
::		The file contains release name, major version, minor version and dotnet target version.
::		It should be in the below format (excluding "::"). See example release_variables.txt file in this repository.
::				Enter solution release name below. Recommend using no spaces.
::				MyApplicationProgramNameHere
::				Enter desired major version number below. Value must be between 0-9999
::				1
::				Enter targeted dotnet version below.
::				net7.0
::				Enter release title which can use the following arguments:%ReleaseName%, %MajorVersion%, %MinorVersion%, %DotNetVer%, %ReleaseTitle%, %Identifier%, %ProgramVersion%, %ReleaseTag%, %YEAR%, %MONTH%, %DAY%
::				%ReleaseName%
::				Enter release notes which can use same arguments as release title.
::				Version %MajorVersion%.%MinorVersion% build date=%YEAR%-%MONTH%-%DAY%
:: Setup Project
::		If the solution has an installer (Setup Project), this script will built it if it has the following format:
::		Project-File:	%ReleaseName%_Setup\%ReleaseName%_Setup.vdproj
::		Project-Output:	.\%ReleaseName%_Setup\Release\%ReleaseName%_Setup.msi

:: Used for output format, to make it easier to read output
set Line__Separator1=#####################################################
set Line__Separator2=*****************************************************
set Line__Separator3=-----------------------------------------------------
set Line__Separator4=.....................................................

:: ################################################################################################
echo %Line__Separator1%
echo Step [0]: Make sure dotnet.exe is available before anything else
WHERE dotnet
IF %ERRORLEVEL% NEQ 0 (
	echo %Line__Separator1%
	echo %Line__Separator2%
	echo Error: dotnet.exe is not installed, or its path is not in the environmental variable path
	echo        How to fix:
	echo            Make sure dotnet is installed.
	echo            Make sure dotnet.exe installation path is included in the environmental variable path
	echo Performing early exit due to missing dotnet.exe!!!!
	echo %Line__Separator2%
	echo %Line__Separator1%
	EXIT /B 0
)
:: ################################################################################################
echo %Line__Separator1%
echo Step [1]: Get command line variables
set IsTrue=true
set NoRepoUpdate=
set NoBld=
set NoCompress=
set NoGitRel=
set NoIncUpdate=
set NoIncVer=
set NoClean=
set TestVar=
set RelNotes=
set RelTitle=
for %%a in (%*) do (
	if [%%a] == [NoRepoUpdate] (set NoRepoUpdate=%IsTrue%) else (
		if [%%a] == [NoBld] (
			set NoBld=%IsTrue%
			set NoIncVer=%IsTrue%
		) else (
			if [%%a] == [NoCompress] (set NoCompress=%IsTrue%) else (
				if [%%a] == [NoGitRel] (set NoGitRel=%IsTrue%) else (
					if [%%a] == [NoIncVer] (set NoIncVer=%IsTrue%) else (
						if [%%a] == [NoIncUpdate] (set NoIncUpdate=%IsTrue%) else (
							if [%%a] == [TestVar] (set TestVar=%IsTrue%) else (
								if [%%a] == [TestRun] (
									set NoRepoUpdate=%IsTrue%
									set NoGitRel=%IsTrue%
									set NoIncUpdate=%IsTrue%
									set NoClean=%IsTrue%
								) else (
									if [%%a] == [NoSetup] (set NoSetup=%IsTrue%) else (
										if [%%a] == [NoVdProjReset] (set NoVdProjReset=%IsTrue%) else (
											if [%%a] == [NoClean] (set NoClean=%IsTrue%) else (
												if [%%a] == [RelNotes] (set RelNotes=%IsTrue%) else (
													if [%%a] == [RelTitle] (set RelTitle=%IsTrue%) else (
														if [!RelNotes!] == [%IsTrue%] (call set "RelNotes=%%a") else (
															if [!RelTitle!] == [%IsTrue%] (set RelTitle=%%a)
														)
													)
												)
											)
										)
									)
								)
							)
						)
					)
				)
			)
		)
	)
)

echo %Line__Separator4%
echo Command line options:
echo    NoRepoUpdate	=   "%NoRepoUpdate%"
echo    NoBld			=   "%NoBld%"
echo    NoCompress		=   "%NoCompress%"
echo    NoGitRel		=   "%NoGitRel%"
echo    NoIncVer		=   "%NoIncVer%"
echo    NoIncUpdate		=   "%NoIncUpdate%"
echo    NoSetup			=   %NoSetup%
echo    NoVdProjReset	=   %NoVdProjReset%
echo    NoClean			=   %NoClean%
echo    TestVar			=   "%TestVar%"
echo    RelTitle		=   %RelTitle%
echo    RelNotes		=   %RelNotes%
echo %Line__Separator4%

:: ################################################################################################
echo %Line__Separator1%
set ReleaseFileVariables=release_variables.txt
set ReleaseFileMinorVersion=release_minor_version.txt
echo %Line__Separator3%
echo Step [2a]: Get variable values from "%~dp0%ReleaseFileVariables%"
:: Read variables from files
set "_var=VarDescription,ReleaseName,VarDescription,MajorVersion,VarDescription,DotNetVer,VarDescription,ReleaseTitle,VarDescription,ReleaseNotes,VarDescription,ProjToChngVer"
(for %%i in (%_var%)do set/p %%~i=)<.\%ReleaseFileVariables%
set /p MinorVersion=<.\%ReleaseFileMinorVersion%
set ReleaseName=%ReleaseName: =%
set MajorVersion=%MajorVersion: =%
set MinorVersion=%MinorVersion: =%
set DotNetVer=%DotNetVer: =%

if [%ReleaseName%] == [] (
	echo %Line__Separator1%
	echo Error: Exiting early because ReleaseName is empty. ReleaseName="%ReleaseName%".
	echo Check if file "%~dp0%ReleaseFileVariables%" is correctly formatted.
	echo %Line__Separator1%
	EXIT /B 0
)
if [%DotNetVer%] == [] (
	echo %Line__Separator1%
	echo Error: Exiting early because DotNetVer is empty. DotNetVer="%DotNetVer%".
	echo Check if file "%~dp0%ReleaseFileVariables%" is correctly formatted.
	echo %Line__Separator1%
	EXIT /B 0
)
if [%MajorVersion%] == [] (
	echo %Line__Separator1%
	echo Error: Exiting early because MajorVersion is empty. MajorVersion="%MajorVersion%".
	echo Check if file "%~dp0%ReleaseFileVariables%" is correctly formatted.
	echo %Line__Separator1%
	EXIT /B 0
)
if [%MinorVersion%] == [] (
	echo %Line__Separator1%
	echo Error: Exiting early because MinorVersion is empty. MinorVersion="%MinorVersion%".
	echo Check if file "%~dp0%ReleaseFileMinorVersion%" exist and is correctly formatted.
	echo %Line__Separator1%
	EXIT /B 0
)
if 1%MajorVersion% NEQ +1%MajorVersion% (
	echo %Line__Separator1%
	echo Error: Exiting early because MajorVersion is NOT numeric. MajorVersion="%MajorVersion%".
	echo Check if file "%~dp0%ReleaseFileVariables%" is correctly formatted.
	echo %Line__Separator1%
	EXIT /B 0
)
if 1%MinorVersion% NEQ +1%MinorVersion% (
	echo %Line__Separator1%
	echo Error: Exiting early because MinorVersion is NOT numeric. MinorVersion="%MinorVersion%".
	echo Check if file "%~dp0%ReleaseFileVariables%" is correctly formatted.
	echo %Line__Separator1%
	EXIT /B 0
)
:: If not incrementing skip following section
if [%NoIncVer%] == [%IsTrue%] (
	echo Skipping minor version increment
	goto :SkipIncVersion
)
echo Incrementing minor version
set /A MinorVersion+=1
:SkipIncVersion

echo ReleaseName = "%ReleaseName%"
echo MajorVersion = "%MajorVersion%"
echo MinorVersion = "%MinorVersion%"
echo DotNetVer = "%DotNetVer%"
echo ReleaseTitle = "%ReleaseTitle%"
echo ReleaseNotes = "%ReleaseNotes%"
echo ProjToChngVer = "%ProjToChngVer%"

:: ################################################################################################
echo %Line__Separator3%
echo Step [2b]: Setup remaining pre-compile variables
:: Note: Change the following line, if 7z is installed in a different path.
set Prg7Zip=C:\Program Files\7-Zip\7z
:: Get and set the julian date
for /F "tokens=2-4 delims=/ " %%a in ("%date%") do (
   set /A "MM=1%%a-100, DD=1%%b-100, Ymod4=%%c%%4"
)
for /F "tokens=%MM%" %%m in ("0 31 59 90 120 151 181 212 243 273 304 334") do set /A JulianDate=DD+%%m
if %Ymod4% equ 0 if %MM% gtr 2 set /A JulianDate+=1
set PkgBaseDir=LocalPackageRepository
set PkgDir=%PkgBaseDir%\Ver%MajorVersion%-%MinorVersion%
set FileList=
set YEAR=%DATE:~-4%
set MONTH=%DATE:~4,2%
set DAY=%DATE:~7,2%
set Identifier=%MajorVersion%.%MinorVersion%
set ProgramVersion=%MajorVersion%.%MinorVersion%.%YEAR%.%JulianDate%
if [%RelTitle%] NEQ [] (set ReleaseTitle=%RelTitle%)
if [%RelNotes%] NEQ [] (set ReleaseNotes=%RelNotes%)
for /f "delims== tokens=1,2" %%a in ('set') do ( set ReleaseTitle=!ReleaseTitle:%%%%a%%=%%b! )
for /f "delims== tokens=1,2" %%a in ('set') do ( set ReleaseNotes=!ReleaseNotes:%%%%a%%=%%b! )
set ReleaseTitle=%ReleaseTitle:"=%
set ReleaseNotes=%ReleaseNotes:"=%
set ReleaseTitle="%ReleaseTitle%"
set ReleaseNotes="%ReleaseNotes%"
set ReleaseTag="%PkgPrefix%Ver%MajorVersion%.%MinorVersion%"
set PkgPrefix=%ReleaseName%_
set PkgPostfix=_Ver%MajorVersion%.%MinorVersion%
set SetupProjectFile_VdProj=%ReleaseName%_Setup\%ReleaseName%_Setup.vdproj
set SetupProjectFile_VdProj_Temp=%SetupProjectFile_VdProj%_temp.vdproj
set SetupProjectFile_VdProj_TempRename=%SetupProjectFile_VdProj%_temp_rename.vdproj
set ProductVersionStrToFind=ProductVersion
set AssemblyVersionStrToFind=AssemblyVer
set FileVersionStrToFind=FileVersion
:: Excluding 4th number from the product version, because VdProj do not allow Revision number in the ProductVersion
set NewProductVersionInVdPrj=        "ProductVersion" = "8:%MajorVersion%.%MinorVersion%.%YEAR%"
set NewAssemblyVersionLine="    ^<AssemblyVersion^>%MajorVersion%.%MinorVersion%.%YEAR%.%JulianDate%^</AssemblyVersion^>"
set NewFileVersionLine="    ^<FileVersion^>%MajorVersion%.%MinorVersion%.%YEAR%.%JulianDate%^</FileVersion^>"

set VS_Devenv=
set VS_DevenvExe=Common7\IDE\devenv.exe
WHERE devenv.exe
IF %ERRORLEVEL% NEQ 0 (
	:: Find the devenv.exe installed path (only needed for solutions with MSI package)
	echo %Line__Separator3%
	(for %%e in (Enterprise Professional Community) do (
		(for %%v in (2024 2022 2019 2017) do (
			if exist "C:\Program Files\Microsoft Visual Studio\%%v\%%e\%VS_DevenvExe%" (
				set VS_Devenv="C:\Program Files\Microsoft Visual Studio\%%v\%%e\%VS_DevenvExe%"
				goto :DoneDevenvSearch
			) else (
				if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%v\%%e\%VS_DevenvExe%" (
					set VS_Devenv="C:\Program Files (x86)\Microsoft Visual Studio\%%v\%%e\%VS_DevenvExe%"
					goto :DoneDevenvSearch
				)
			)
		))
	))
	echo %Line__Separator3%
) else (
	set VS_Devenv=devenv.exe
	echo Found %VS_Devenv%
)
:DoneDevenvSearch

echo %Line__Separator1%
echo Program Version = %ProgramVersion% ;Release Name = "%ReleaseName%" ;Identifier = %Identifier%
echo YEAR = "%YEAR%" ;MONTH = "%MONTH%" ;DAY = "%DAY%" 
echo Release Title = %ReleaseTitle% ;Release Notes = %ReleaseNotes% 
echo %Line__Separator1%

echo Pre-compile variables set
echo %Line__Separator1%

if [%TestVar%] == [%IsTrue%] (EXIT /B 0)

if [%NoBld%] == [%IsTrue%] (
	echo Skipping build
	goto :SkipBuild
)


:: ################################################################################################
echo %Line__Separator1%
echo Step [3]: Start build process
:: If not inc-version, skip following section
if [%NoIncVer%] == [%IsTrue%] (
	echo Skipping saving version to project file
	goto :SkipSaveVersionToProj
)
set ProjToChngVer_temp=%ProjToChngVer%.temp
set ProjToChngVer_rename=%ProjToChngVer%.original
if exist %ProjToChngVer% (
	echo     %Line__Separator2%
	echo     Step [3a]: Update version in %ProjToChngVer%
	if exist %ProjToChngVer_rename% (del /Y .\%ProjToChngVer_rename%)
	if exist %ProjToChngVer_temp% (del /Y .\%ProjToChngVer_temp%)
	:: Replace the product version number
	>"%ProjToChngVer_temp%" (
		for /f "usebackq delims=" %%a in ("%ProjToChngVer%") do (
			SET fn=%%~na
			SET fn=!fn:~0,11!
			if [!fn!] == [%AssemblyVersionStrToFind%] (echo %NewAssemblyVersionLine:"=%) else (
				if [!fn!] == [%FileVersionStrToFind%] (echo %NewFileVersionLine:"=%) else (echo %%a)
			)
		)
	)
	if exist %ProjToChngVer_temp% (
		move /Y %ProjToChngVer% %ProjToChngVer_rename%
		move /Y %ProjToChngVer_temp% %ProjToChngVer%
		if [%NoClean%] == [%IsTrue%] ( echo Skipping delete of .\%ProjToChngVer_rename%) else (
			del /Q .\%ProjToChngVer_rename%
		)
	)
)
:SkipSaveVersionToProj

:: ************************************************************************************************
echo %Line__Separator2%
echo Step [3b]: Build all platforms in the solution and save to compress packages
if NOT exist %PkgBaseDir%\ (
	mkdir %PkgBaseDir%
)
if NOT exist %PkgDir%\ (
	mkdir %PkgDir%
) else (
	del /Q /F %PkgDir%\*
)
set ListOfOS=win-x64 osx-x64 linux-x64 osx-arm64
(for %%a in (%ListOfOS%) do (
	dotnet publish -c Release -v q --self-contained -r "%%a" --property:identifier=%Identifier% --property:version=%ProgramVersion%
	if %ERRORLEVEL% NEQ 0 (
		echo %Line__Separator1%
		echo Error: Performming early exist due to error %ERRORLEVEL% from dotnet on OS target "%%a".
		echo %Line__Separator1%
		EXIT /B 0
	)
	echo       %%a build success!
	echo       %Line__Separator3%
	if [%NoCompress%] == [%IsTrue%] (
		echo Skipping compressing files
	) else (
		if [%%a] == [win-x64] ( 
			echo          %Line__Separator4%
			echo          Creating %%a ZIP file
			"%Prg7Zip%" a -tzip "%PkgDir%\%PkgPrefix%%%a%PkgPostfix%.zip" "./bin/Release/%DotNetVer%/%%a/*"
			if %ERRORLEVEL% NEQ 0 (
				echo %Line__Separator1%
				echo Error: Performming early exist due to error %ERRORLEVEL% from 7z for file "%PkgDir%\%PkgPrefix%%%a%PkgPostfix%.zip".
				echo Check folder contents of "%~dp0bin\Release\%DotNetVer%\%%a"
				echo %Line__Separator1%
				EXIT /B 0
			)
			call set "FileList=%%FileList%%%PkgDir%\%PkgPrefix%%%a%PkgPostfix%.zip " 
			if [%NoSetup%] == [%IsTrue%] (echo Skipping building MSI) else (
				:: Try to build an MSI file if setup project exist using the project name + Setup
				if exist %SetupProjectFile_VdProj% (
					if [%VS_Devenv%] == [] (
						echo %Line__Separator1%
						echo Error: Can not build %SetupProjectFile_VdProj%, because devenv.exe was not found.
						echo         Possible fixes:
						echo             1. Install Visual Studio version 2022, 2019, or 2017
						echo             2. If using older VS version, or if using a non-standard installed path,
						echo                add the path to the system environmental variable PATH
						echo             3. Exclude building MSI [VdProj] by adding NoSetup to the command line options.
						echo %Line__Separator1%
						EXIT /B 0
					)
					if exist .\%SetupProjectFile_VdProj_Temp% (del /Y .\%SetupProjectFile_VdProj_Temp%)
					:: Replace the product version number
					>"%SetupProjectFile_VdProj_Temp%" (
					  for /f "usebackq delims=" %%a in ("%SetupProjectFile_VdProj%") do (
						SET fn=%%~na
						SET fn=!fn:~9,14!
						if [!fn!] == [%ProductVersionStrToFind%] (echo %NewProductVersionInVdPrj%) else (echo %%a)
					  )
					)
					if exist %SetupProjectFile_VdProj_Temp% (
						if exist .\%ReleaseName%_Setup\Release\%ReleaseName%_Setup.msi ( del /Y .\%ReleaseName%_Setup\Release\%ReleaseName%_Setup.msi )
						move /Y %SetupProjectFile_VdProj% %SetupProjectFile_VdProj_TempRename%
						move /Y %SetupProjectFile_VdProj_Temp% %SetupProjectFile_VdProj%
						set MakeMSI_Cmd=%VS_Devenv% %ReleaseName%.sln /build Release /project %SetupProjectFile_VdProj%  /projectconfig Release
						echo !MakeMSI_Cmd!
						!MakeMSI_Cmd!
						:: Note: Do not exit in the following if-block, because the files have to be renamed back. If previous command fails, the MSI move command will fail and exit.
						if %ERRORLEVEL% NEQ 0 (
							echo %Line__Separator1%
							echo Error: Devenv failed with return error %ERRORLEVEL%.
							echo   %Line__Separator4%
							echo   Issued Command:
							echo     !MakeMSI_Cmd!
							echo   %Line__Separator4%
							echo %Line__Separator1%
						) else (
							echo %Line__Separator3%
							echo MSI package build success...
						)
						if [%NoVdProjReset%] == [%IsTrue%] (echo Skipping resetting VdProj file back) else (
							move /Y %SetupProjectFile_VdProj% %SetupProjectFile_VdProj_Temp%
							move /Y %SetupProjectFile_VdProj_TempRename% %SetupProjectFile_VdProj%
						)
						move /Y .\%ReleaseName%_Setup\Release\%ReleaseName%_Setup.msi %PkgDir%\%PkgPrefix%%%a%PkgPostfix%_Setup.msi
						if %ERRORLEVEL% NEQ 0 (
							echo %Line__Separator1%
							echo Error: Failed to create MSI or failed to move MSI file to deployment path.
							echo         Possible fixes:
							echo             1. Check write permissions for path "%~dp0%PkgDir%"
							echo             2. Try following command on the DOS prompt in folder "%~dp0":
							echo                !MakeMSI_Cmd!
							echo             3. Exclude building MSI [VdProj] by adding NoSetup to the command line options.
							echo %Line__Separator1%
							EXIT /B 0
						)
						call set "FileList=%%FileList%%%PkgDir%\%PkgPrefix%%%a%PkgPostfix%_Setup.msi "
						if [%NoClean%] == [%IsTrue%] ( echo Skipping delete of %SetupProjectFile_VdProj_Temp%) else ( del /Q %SetupProjectFile_VdProj_Temp%	)
						echo %Line__Separator3%
						echo MSI package build and staging complete...
					) else (
						echo %Line__Separator1%
						echo Error: Failed to create temporary VdProj file [%SetupProjectFile_VdProj_Temp%]
						echo         Possible fixes:
						echo             1. Check write permissions for path "%~dp0%%SetupProjectFile_VdProj_Temp%"
						echo             2. Exclude building MSI [VdProj] by adding NoSetup to the command line options.
						echo %Line__Separator1%
						EXIT /B 0
					)
				)
			)
		) else (
			echo          %Line__Separator4%
			echo          Creating %%a TAR file
			"%Prg7Zip%" a -ttar %PkgDir%/%PkgPrefix%%%a%PkgPostfix%.tar "./bin/Release/%DotNetVer%/%%a/*"
			if %ERRORLEVEL% NEQ 0 (
				echo %Line__Separator1%
				echo Error: Performming early exist due to error %ERRORLEVEL% from 7z for file "%PkgDir%/%PkgPrefix%%%a%PkgPostfix%.tar".
				echo Check folder contents of "%~dp0bin\Release\%DotNetVer%\%%a"
				echo %Line__Separator1%
				EXIT /B 0
			)
			echo          %Line__Separator4%
			echo          Creating %%a TGZ file
			echo          "%Prg7Zip%" a %PkgDir%/%PkgPrefix%%%a%PkgPostfix%.tgz %PkgDir%/%PkgPrefix%%%a%PkgPostfix%.tar
			"%Prg7Zip%" a %PkgDir%/%PkgPrefix%%%a%PkgPostfix%.tgz %PkgDir%/%PkgPrefix%%%a%PkgPostfix%.tar
			if %ERRORLEVEL% NEQ 0 (
				echo %Line__Separator1%
				echo Error: Performming early exist due to error %ERRORLEVEL% from 7z for file "%PkgDir%/%PkgPrefix%%%a%PkgPostfix%.tgz".
				echo Check file "%~dp0%PkgDir%\%PkgPrefix%%%a%PkgPostfix%.tar"
				echo %Line__Separator1%
				EXIT /B 0
			)
			echo          %Line__Separator4%
			if [%NoClean%] == [%IsTrue%] ( echo Skipping delete of %PkgDir%\%PkgPrefix%%%a%PkgPostfix%.tar) else (
				del /Q .\%PkgDir%\%PkgPrefix%%%a%PkgPostfix%.tar
			)
			call set "FileList=%%FileList%%%PkgDir%\%PkgPrefix%%%a%PkgPostfix%.tgz "
		)
		echo       Package files compressed for %%a
		echo       %Line__Separator3%
	)
	echo    Process complete for %%a
	echo    %Line__Separator2%
))


echo All packages complete
echo Package build list = %FileList%
echo %Line__Separator1%
:SkipBuild

if [%NoRepoUpdate%] == [%IsTrue%] (
	echo Skipping repository update
	goto :SkipRepoUpdate
)
:: ################################################################################################
echo %Line__Separator1%
echo Step [4]: Update github repository
:: Add all file changes
git add .
:: Setup a silent commit
git commit --allow-empty-message -q --no-edit
:: Push the changes to the repository
git push
echo Git repository update complete.
echo %Line__Separator1%
:SkipRepoUpdate


if [%NoGitRel%] == [%IsTrue%] (
	echo Skipping creating a Git release
	goto :SkipCreatingGitRelease
)
:: ################################################################################################
echo %Line__Separator1%
echo Step [5]: Create new Github release and upload the packages
echo gh release create %ReleaseTag% %FileList% --latest --title %ReleaseTitle% --notes %ReleaseNotes%
gh release create %ReleaseTag% %FileList% --latest --title %ReleaseTitle% --notes %ReleaseNotes%
if %ERRORLEVEL% NEQ 0 (
	echo %Line__Separator1%
	echo %Line__Separator2%
	echo Error: Creating a Github release failed!
	echo Error: Failed due to error %ERRORLEVEL% from gh release for files %FileList%.
	echo        Check if these files exist in path "%~dp0%PkgDir%"
	echo        Check gh login status.
	echo              gh auth status
	echo              If not logged in, use command: gh auth login
	gh auth status
	echo %Line__Separator3%
	echo Package List:
	echo %FileList%
	echo %Line__Separator3%
	echo %Line__Separator2%
	echo %Line__Separator1%
	EXIT /B 0
)
echo Git release creation complete for ReleaseTag %ReleaseTag%
echo %Line__Separator1%
:SkipCreatingGitRelease

:: Saving incremented minor version is done last so if the build fails in above steps, this step is never executed
if [%NoIncUpdate%] == [%IsTrue%] (
	echo Skipping saving incremented minor version to file %ReleaseFileVariables%
	goto :SkipIncUpdate
)
:: ################################################################################################
echo %Line__Separator1%
echo Step [6]: Save incremented minor version to file %ReleaseFileMinorVersion%
echo %MinorVersion% >.\%ReleaseFileMinorVersion%
:SkipIncUpdate

echo %ReleaseTag% Done!

Explorer.exe %~dp0%PkgDir%