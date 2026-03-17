#!/bin/bash
steam_apps_path="$HOME/.steam/steam/steamapps"

stationeers_path="$steam_apps_path/common/Stationeers"
stationeers_dedicated_path="$steam_apps_path/common/Stationeers Dedicated Server"
output_path="$steam_apps_path/common/StationeersLinux"

unity_version="2022.3.62f3"
unity_changeset="96770f904ca7"

cimgui_version="1.88"
cimgui_download="https://raw.githubusercontent.com/ImGuiNET/ImGui.NET/v$cimgui_version/deps/cimgui/linux-x64/cimgui.so"

unity_download="https://download.unity3d.com/download_unity/$unity_changeset/LinuxEditorInstaller/Unity-$unity_version.tar.xz"

bepinex_version="5.4.23.5"
bepinex_download="https://github.com/BepInEx/BepInEx/releases/download/v$bepinex_version/BepInEx_linux_x64_$bepinex_version.zip"

icsharpziplib_version="1.0.0"
icsharpziplib_download="https://github.com/icsharpcode/SharpZipLib/releases/download/v$icsharpziplib_version/SharpZipLib.$icsharpziplib_version.nupkg"

cache_dir="$PWD/cache" # Caches the downloaded files

if [ ! -d "$steam_apps_path" ]; then
    echo "Steam apps directory not found in $steam_apps_path. Ensure steam is installed and that the path is correct."
    exit 1
fi

if [ ! -d "$stationeers_path" ]; then
    echo "Stationeers not found in $stationeers_path. Ensure steam_apps_path is correct and that Stationeers is installed."
    exit 1
fi

if [ ! -d "$stationeers_dedicated_path" ]; then
    echo "Stationeers Dedicated Server not found in $stationeers_dedicated_path. Ensure steam_apps_path is correct and that Stationeers Dedicated Server is installed."
    echo "It can be installed by SteamCMD. See: https://stationeers-wiki.com/Dedicated_Server_Guide#Linux"
    exit 1
fi

download_file() {
    local url="$1"
    local output="$2"

    if [ -f "$output" ]; then
        echo "File $output already exists, skipping download."
        return
    fi

    echo "Downloading $url to $output..."
    curl -L -o "$output" "$url"
}

get_sources() {
    mkdir -p "$cache_dir"
    download_file "$unity_download" "$cache_dir/unity_$unity_version.tar.xz"
    download_file "$cimgui_download" "$cache_dir/cimgui_$cimgui_version.so"
    download_file "$bepinex_download" "$cache_dir/bepinex_$bepinex_version.zip"
    download_file "$icsharpziplib_download" "$cache_dir/icsharpziplib_$icsharpziplib_version.zip"
    if [ -d "$cache_dir/Editor" ]; then
        echo "Unity $unity_version already extracted, skipping extraction."
    else
        echo "Extracting Unity $unity_version... This may take a while."
        tar -xf "$cache_dir/unity_$unity_version.tar.xz" -C "$cache_dir"
    fi

    if [ -d "$cache_dir/bepinex_$bepinex_version" ]; then
        echo "BepInEx $bepinex_version already extracted, skipping extraction."
    else
        echo "Extracting BepInEx $bepinex_version..."
        unzip -o "$cache_dir/bepinex_$bepinex_version.zip" -d "$cache_dir/bepinex_$bepinex_version"
    fi

    if [ -d "$cache_dir/icsharpziplib_$icsharpziplib_version" ]; then
        echo "SharpZipLib $icsharpziplib_version already extracted, skipping extraction."
    else
        echo "Extracting SharpZipLib $icsharpziplib_version..."
        unzip -o "$cache_dir/icsharpziplib_$icsharpziplib_version.zip" -d "$cache_dir/icsharpziplib_$icsharpziplib_version"
    fi
}

excluded_data_subdirs=(
    "Managed"
    "Plugins"
    "MonoBleedingEdge"
)

excluded_dlls=(
    "Assembly-CSharp-firstpass.dll"
    "Assembly-CSharp.dll"
)

setup_linux_edition () {
    echo "Setting up StationeersLinux in $output_path..."
    mkdir -p "$output_path"
    mkdir -p "$output_path/rocketstation_Data"
    # Link standard game data files excluding Managed & Plugins
    for file in "$stationeers_path/rocketstation_Data"/*; do
        filename=$(basename "$file")
        if [[ " ${excluded_data_subdirs[@]} " =~ " $filename " ]]; then
            echo "Excluding $filename from copy."
            continue
        fi
        ln -s "$file" "$output_path/rocketstation_Data/"
        echo "Linked  $(basename "$file") -> /rocketstation_Data/$(basename "$file")"
    done
    # Create managed and copy everything but Assembly-CSharp from the regular game/*
    mkdir -p "$output_path/rocketstation_Data/Managed"
    for file in "$stationeers_path/rocketstation_Data/Managed"/*.dll; do
        filename=$(basename "$file")
        if [[ " ${excluded_dlls[@]} " =~ " $filename " ]]; then
            echo "Excluding $filename from copy."
            continue
        fi
        ln -s "$file" "$output_path/rocketstation_Data/Managed/"
        echo "Linked  $(basename "$file") -> /rocketstation_Data/Managed/$(basename "$file")"
    done
    # Overrides with linuxplayer-versions
    for file in "$cache_dir/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_player_nondevelopment_mono/Data/Managed"/*.dll; do
        filename=$(basename "$file")
        if [[ -f "$output_path/rocketstation_Data/Managed/$filename" ]]; then
            echo "Overriding $filename with Linux player version."
            rm "$output_path/rocketstation_Data/Managed/$filename"
        fi
        cp "$file" "$output_path/rocketstation_Data/Managed/$filename"
        echo "Linked  $filename -> /rocketstation_Data/Managed/$filename"
    done
    # Override .NET with unix versions
    for file in "$cache_dir/Editor/Data/MonoBleedingEdge/lib/mono/net_4_x-linux/"*.dll; do
        filename=$(basename "$file")
        if [[ -f "$output_path/rocketstation_Data/Managed/$filename" ]]; then
            echo "Overriding $filename with Unix version."
            rm "$output_path/rocketstation_Data/Managed/$filename"
        fi
        cp "$file" "$output_path/rocketstation_Data/Managed/$filename"
        echo "Linked  $filename -> /rocketstation_Data/Managed/$filename"
    done
    
    # Some Mono stuff that NixOS gets mad about
    for file in "$cache_dir/Editor/Data/MonoBleedingEdge/lib/"*.so; do
        filename=$(basename "$file")
        if [[ -f "$output_path/rocketstation_Data/Managed/$filename" ]]; then
            echo "Overriding $filename with Unix version."
            rm "$output_path/rocketstation_Data/Managed/$filename"
        fi
        cp "$file" "$output_path/rocketstation_Data/Managed/$filename"
        echo "Linked  $filename -> /rocketstation_Data/Managed/$filename"
    done

    # Update ICSharpZipLib to version with IDisposable support (if you attempt to load a save without it, your computer will explode)
    cp "$cache_dir/icsharpziplib_$icsharpziplib_version/lib/net45/ICSharpCode.SharpZipLib.dll" "$output_path/rocketstation_Data/Managed/ICSharpCode.SharpZipLib.dll"

    for file in "$cache_dir/Editor/Data/MonoBleedingEdge/lib/mono/net_4_x-linux/Facades/"*.dll; do
        filename=$(basename "$file")
        if [[ -f "$output_path/rocketstation_Data/Managed/$filename" ]]; then
            echo "Overriding $filename with Unix version."
            rm "$output_path/rocketstation_Data/Managed/$filename"
        fi
        cp "$file" "$output_path/rocketstation_Data/Managed/$filename"
        echo "Linked  $filename -> /rocketstation_Data/Managed/$filename"
    done

    # Link game code
    ln -s "$stationeers_path/rocketstation_Data/Managed/Assembly-CSharp-firstpass.dll" "$output_path/rocketstation_Data/Managed/"
    ln -s "$stationeers_path/rocketstation_Data/Managed/Assembly-CSharp.dll" "$output_path/rocketstation_Data/Managed/"

    ln -s "$stationeers_dedicated_path/rocketstation_DedicatedServer_Data/MonoBleedingEdge" "$output_path/rocketstation_Data/MonoBleedingEdge"
    echo "Linked  MonoBleedingEdge -> /rocketstation_Data/MonoBleedingEdge"

    mkdir -p "$output_path/rocketstation_Data/Plugins"
    # cimguio.so dependency
    cp "$cache_dir/cimgui_$cimgui_version.so" "$output_path/rocketstation_Data/Plugins/cimgui.so"
    echo "Copied cimgui.so to $output_path/rocketstation_Data/Plugins/cimgui.so"

    # link linux plugins
    for file in "$stationeers_dedicated_path/rocketstation_DedicatedServer_Data/Plugins/"/*; do
        filename=$(basename "$file")
        ln -s "$file" "$output_path/rocketstation_Data/Plugins/$filename"
        echo "Linked  $filename -> /rocketstation_Data/Plugins/$filename"
    done

    # the steamapi names differ between linux and windows for whatever reason
    ln -s "$output_path/rocketstation_Data/Plugins/libsteam_api.so" "$output_path/rocketstation_Data/Plugins/steam_api64.so"

    # BepInEx files
    for file in "$cache_dir/bepinex_$bepinex_version"/*; do
        filename=$(basename "$file")
        cp -r "$file" "$output_path/$filename"
        echo "Copied  $filename -> /$filename"
    done

    # Unity player setup
    cp -fr "$cache_dir/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_player_nondevelopment_mono/Data"* "$output_path/rocketstation_Data/"
    echo "Copied Unity player data files to $output_path/rocketstation_Data/"
    cp "$cache_dir/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_player_nondevelopment_mono/LinuxPlayer" "$output_path/rocketstation.x86_64"
    cp "$cache_dir/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_player_nondevelopment_mono/UnityPlayer.so" "$output_path/UnityPlayer.so"
    cp "$PWD/BepInEx/run_bepinex.sh" "$output_path/run_bepinex.sh"
    cp -rf "$PWD/BepInEx/plugins" "$output_path/BepInEx/plugins"
    cp -rf "$PWD/BepInEx/patchers" "$output_path/BepInEx/patchers"
    cp -rf "$PWD/BepInEx/config" "$output_path/BepInEx/config"
    chmod +x "$output_path/run_bepinex.sh"
    echo "Setup complete. You can run the Linux edition using $output_path/run_bepinex.sh"
}
get_sources
setup_linux_edition