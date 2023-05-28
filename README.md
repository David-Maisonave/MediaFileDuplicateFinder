### 📢 New _(Windows, Linux, & MacOS)_ Release: [Downloads](https://github.com/David-Maisonave/MediaFileDuplicateFinder/releases/latest) 🔥
[![All Releases](https://img.shields.io/github/downloads/David-Maisonave/MediaFileDuplicateFinder/total.svg)](https://github.com/David-Maisonave/MediaFileDuplicateFinder/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues/David-Maisonave/MediaFileDuplicateFinder)](https://github.com/David-Maisonave/MediaFileDuplicateFinder/issues)

[![RepositoryBanner](VDF.GUI/Assets/RepositoryBanner_Small.png)](https://github.com/David-Maisonave/MediaFileDuplicateFinder)

**Media-File-Duplicate-Finder** finds duplicated video and image files based on similarities. Finds duplicates which have different file types, format, resolution, frame rate, watermark, and file tags.

MediaFileDuplicateFinder (**MFDF**) was originally a fork of [0x90d/videoduplicatefinder](https://github.com/0x90d/videoduplicatefinder).  Originally this fork was created so-as to add more features and to give the UI a more standard intuitive interface. MediaFileDuplicateFinder has fully broken off from the original fork, so that users can report issues and post enhancement request directly.

# [Downloads](https://github.com/David-Maisonave/MediaFileDuplicateFinder/releases/latest)
- [Downloads](https://github.com/David-Maisonave/MediaFileDuplicateFinder/releases/latest) are available for multiple platforms (**Windows**, **Linux**, & **MacOS**). 
- The Windows binaries are available in an install MSI package and in a portable ZIP file.
- For the latest release, click [here](https://github.com/David-Maisonave/MediaFileDuplicateFinder/releases/latest).

# Features 
- *[Finds duplicate videos / images based on similarities](https://github.com/David-Maisonave/MediaFileDuplicateFinder/wiki/1.-Features#Find-Duplicates)
- *Fast scanning speed
- *Cross-platform: Windows, Linux and MacOS
- *[Delete all duplicate files with lower resolution](https://github.com/David-Maisonave/MediaFileDuplicateFinder/wiki/1.-Features#Delete-duplicate-files-with-shorter-duration-lower-resolution).
- *[Delete all duplicate files with shorter duration](https://github.com/David-Maisonave/MediaFileDuplicateFinder/wiki/1.-Features#Delete-duplicate-files-with-shorter-duration-lower-resolution).
- Only delete files which match the filters.
  - In the original fork [0x90d/videoduplicatefinder](https://github.com/0x90d/videoduplicatefinder), all actions apply to filtered out items as well as viewable items. This makes it easy for a users to accidentally delete 100's of files unintentionally.
  - Media File Duplicate Finder does **NOT** delete files which are filtered out. What you see is what gets deleted. No hidden deletes!
- Remember window size and location from last running instance.
  - On program startup, sets the window size and position from the previous running instance.
  - Has logic to reset the window position and size by holding down the shift key during the first few seconds of startup. The reset option may be needed for the following situations.
    - Change in quantity of monitors
	- Change in monitor resolutions
	- Corrupt Window settings between running instances
- Windows Installer (MSI package), which includes ffmpeg binaries.
- [Windows Only] Exclude Hard Links (hardlinks) option which is more reliable and better optimized compared to VDF.
  - The exclude hard links option works on all NTFS drive configurations, where-as VDF fails to work on some NTFS configurations.
- Save on exit option has the following options:
  - Always_Save
  - Never_Save
  - Prompt_to_Save.
- Stream line menu having one toolbar (vs 2) which gives user more real-estate to view scan results.
- Swap file name options. Renames two files in a group, by swapping names.
- Select swap option. On groups with more than 2 files, allows user to select which files to swap names.
- Full scan option. Deletes content in the database before running a scan. Waring: No prompt given with this option.
- Run Clean Scan option. Before running the scan, removes database entries for files which no longer exists or failed on ffmpeg/ffprobe.
- Checkbox for show thumbnails option on main toolbar next to Zoom Thumbnails.
- Select duplicates with shorter file names.
- Search Directories listed on main window. Toolbar has a checkbox option which allows inclusive and exclusive directories to be displayed on main view.
- Play/Open Videos and Images from the context menu, and/or by using shortcut key F5. (This feature might get added to main fork)

_* Features which came with the original fork. All other features are unique to MediaFileDuplicateFinder (MFDF)_

### Future features
- Add support for Audio file comparison
- Option to remove rescan prompt.
- Option to clear the filters
- Command line options which can be used to schedule a scan and perform action.
- Feature to automatically translate file names from one language to another.

## Requirements
### FFmpeg >= v6.0:
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

## License
- Media File Duplicate Finder is licensed under GPLv3  
- ffmpeg & ffprobe are licensed under LGPL 2.1 / GPL v2


## Building
- .NET Core 6.x
- Visual Studio 2022
- Avalonia VS Extension is recommended but not required

## Committing
- Your pull request should only contain code for a single addition or fix
- Unless it refers to an existing issue, write into your pull request what it does
