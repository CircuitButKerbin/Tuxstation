# TuxStation
A bash script to port Stationeers to a LinuxPlayer version of Unity, allowing the game to run natively on linux without Proton or Wine.  
## Getting Started
To run the installation script, check that `config.sh` has the right directories for your platform. For me on archlinux with steam installed through pacman, it looks like.
```sh
export STATIONEERS_PATH="$HOME/.local/share/Steam/steamapps/common/Stationeers"
export STATIONEERS_DEDICATED_PATH="$HOME/.local/share/Steam/steamapps/common/Stationeers Dedicated Server"
export OUTPUT_PATH="$HOME/.local/share/Steam/steamapps/common/StationeersLinux"
```
Most of the dependencies are automatically downloaded. Note that the Unity is fairly big (~7GB Unextracted), so if you have it already downloaded, you can create a symlink
to Unity 2022.3.62f3's `Editor` folder inside `cache`, which by default will be `$PWD/cache` where the convert.sh script is ran.  
  
Also, you **must have Stationeers & Stationeers Dedicated Server installed** for the installation to work. Stationeers DS is where the linux versions of `steamapi_64.so` 
and `libRakNetDLL.so` are pulled from.  

After running the script, it will generate a copy of the game in `OUTPUT_PATH` that you can run with the `./run_bepinex.sh` in the output folder. You **must** run the game under bepinex,
otherwise the `Assets.Scripts.GameManager` will crash which completely breaks the game. This is caused by two methods in the class that are imports from `user32.dll`, which just change the
window title on Windows. The source for the patcher & plugin `.dll` can be found in the [Tuxstation-patcher repository](https://github.com/CircuitButKerbin/Tuxstation-Patcher).

You can clear cache after you run the script, as the files from those are copyied and not linked. If you find any files pulled from the Server build or the `cache` that are linked and not copied
please report it as an issue that contains the filename(s) and path, with the generated `blame.txt` file.

## Reporting issues
If you experience an issue with installation, include the output of the ./convert.sh if it failed to finish. If it finished but resulted in a broken game (e.g, launches to a broken main menu,
can't load into worlds, etc.), include the `blame.txt` that is generated in the StationeersLinux folder, along side the UnityPlayer log at `~/.config/unity3d/Rocketwerkz/rocketstation/Player.log`

## Known issues
- NixOS requires the game to be ran over steam-run, otherwise Unity can't figure out graphics and will fail to launch. `-force-vulkan` or `-force-glcore` won't resolve the issue
as Unity will report that Vulkan isn't supported by the system when it most-definitely is.
- ~~Discord Integration doesn't work. No clue where to find a linux build of the `discord_game_sdk.dll`~~ Thanks to [laraproto](https://github.com/laraproto) for finding a linux build of the SDK.
- Z-fighting on some items and Mars on the preview screen. More than likely fixable but I haven't researched into it.
