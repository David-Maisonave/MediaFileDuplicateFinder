# Media File Duplicate Finder
[![All Releases](https://img.shields.io/github/downloads/David-Maisonave/MediaFileDuplicateFinder/total.svg)](https://github.com/David-Maisonave/MediaFileDuplicateFinder/releases/latest)

Media File Duplicate Finder finds duplicated video, images, and audio files based on similarity. It can finds duplicates which have different resolution, frame rate, watermark, and video file tags.

This fork from [0x90d/videoduplicatefinder](https://github.com/0x90d/videoduplicatefinder), has more features and the UI (user interface) has a more standard interface which makes it more intuitive.
# Features 
These features are not on the original base fork, and they're only include in **Media File Duplicate Finder**.
- Only delete files which match the filters.
  - The original fork [0x90d/videoduplicatefinder](https://github.com/0x90d/videoduplicatefinder), all actions apply to filtered out items as well as viewable items. It makes it easy for a user to unintentionally delete many files.
  - Media File Duplicate Finder does **NOT** delete files which are filtered out.
- Remember window size and location from last running instance.
  - On program startup, sets the window size and position from the previous running instance.
  - Has logic to reset the window position and size by holding down the shift key during the first few seconds of startup. The reset option may be needed for the following situations.
    - Change in quantity of monitors
	- Change in monitor resolutions
	- Corrupt Window settings between running instances
- [Windows Only] Exclude Hard Links (hardlinks) option which is more reliable and better optimized compared to VDF.
  - The exclude hard links option works on all NTFS drive configurations, where-as VDF fails to work on some NTFS configurations.
- Windows Installer (MSI package), which includes ffmpeg binaries.
- Save on exit option has the following options:
  - Save_Aways
  - Never_Save
  - Prompt_to_Save.
- Stream line menu having one toolbar (vs 2) which gives user more real-estate to view scan results.
- Swap file name options. Renames two files in a group, by swapping names.
- Select swap option. On groups with more than 2 files, allows user to select which files to swap names.
- Full scan option. Deletes content in the database before running a scan. Waring: No prompt given with this option.
- Run Clean Scan option. Before running the scan, removes database entries for files which no longer exists or failed on ffmpeg/ffprobe.
- Checkbox for show thumbnails option on main toolbar next to Zoom Thumbnails.
- Select duplicates with shorter file names.
### Future features
- Download release with all the required binaries needed to run the program. The original fork excludes some binaries.
- Option to remove rescan prompt.
- Search Directories listed on main window.
- Option to clear the filters
- Command line options which can be used to schedule a scan and perform action.

# Base Fork Description
## Features
- Finds duplicate videos / images based on similarity
- Fast scanning speed
- Cross-platform: Windows, Linux and MacOS GUI

## Binaries

[Daily build](https://github.com/0x90d/videoduplicatefinder/releases/tag/3.0.x) (You need to download FFmpeg and FFprobe yourself, see below! Please note the attachments of this release are automatically created and replaced on every new commit.)


## Requirements

### FFmpeg:

#### Windows user:
- The MSI package contains and installs the ffmpeg binaries. 
- If using the zip file, get the latest package from https://ffmpeg.org/download.html, and extract ffmpeg and ffprobe into the same directory of VDF.GUI.dll.

#### Linux user:
- Installing ffmpeg:
```
sudo apt-get update
sudo apt-get install ffmpeg
```
Open terminal in VDF folder and execute `./VDF.GUI`
You may need to set execute permission first `sudo chmod 777 VDF.GUI`

#### MacOS user:
- Install ffmpeg / ffprobe using homebrew

Open terminal in VDF folder and execute `./VDF.GUI` or if you have .NET installed `dotnet VDF.GUI.dll`
You may get a permission error. Open system settings of your Mac, go to `Privacy & Security` and then `Developer Tools`. Now add `Terminal` to the list.

## Screenshots (slightly outdated)
<img src="https://user-images.githubusercontent.com/46010672/129763067-8855a538-4a4f-4831-ac42-938eae9343bd.png" width="510">

## License
- Media File Duplicate Finder is licensed under GPLv3  
- ffmpeg & ffprobe are licensed under LGPL 2.1 / GPL v2
  - ffmpeg binaries are only included in the Windows MSI package.
  - If using zip file or when using other platform packages, use instructions in [FFmpeg](README.md#FFmpeg)


## Building
- .NET Core 6.x
- Visual Studio 2022
- Avalonia VS Extension is recommended but not required

## Committing
- Your pull request should only contain code for a single addition or fix
- Unless it refers to an existing issue, write into your pull request what it does
