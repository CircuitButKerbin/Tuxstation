#!/bin/bash
source "config.sh"

CACHE_DIR="$PWD/cache"

unity_version="2022.3.62f3"
unity_changeset="96770f904ca7"

cimgui_version="1.88"
cimgui_download="https://raw.githubusercontent.com/ImGuiNET/ImGui.NET/v$cimgui_version/deps/cimgui/linux-x64/cimgui.so"

unity_download="https://download.unity3d.com/download_unity/$unity_changeset/LinuxEditorInstaller/Unity-$unity_version.tar.xz"

bepinex_version="5.4.23.5"
bepinex_download="https://github.com/icsharpcode/SharpZipLib/releases/download/v$icsharpziplib_version/SharpZipLib.$icsharpziplib_version.nupkg"

icsharpziplib_version="1.0.0"
icsharpziplib_download="https://github.com/icsharpcode/SharpZipLib/releases/download/v$icsharpziplib_version/SharpZipLib.$icsharpziplib_version.nupkg"

fetch_dependency() {
    local url="$1"
    local output="$2"

    if [ -f "$output" ]; then
        echo "Using cached version of $output"
        return
    fi
    curl -L -o "$output" "$url"
}

get_dependencies_paths() {
    export DEP_Unity="$CACHE_DIR/Editor"
    export DEP_BepInEx="$CACHE_DIR/bepinex_$bepinex_version"
    export DEP_SharpZipLib="$CACHE_DIR/icsharpziplib_$icsharpziplib_version/lib/net45/ICSharpCode.SharpZipLib.dll"
    export DEP_Cimgui="$CACHE_DIR/cimgui_$cimgui_version.so"
}

download_dependencies() {
    local skip_download="$1"
    mkdir -p "$CACHE_DIR"
    if [ "$skip_download" != "true" ]; then
        fetch_dependency "$unity_download" "$CACHE_DIR/unity_$unity_version.tar.xz"
        fetch_dependency "$cimgui_download" "$CACHE_DIR/cimgui_$cimgui_version.so"
        fetch_dependency "$bepinex_download" "$CACHE_DIR/bepinex_$bepinex_version.zip"
        fetch_dependency "$icsharpziplib_download" "$CACHE_DIR/icsharpziplib_$icsharpziplib_version.zip"
    else
        echo "Skipping download..."
    fi
    export DEP_Cimgui="$CACHE_DIR/cimgui_$cimgui_version.so"

    if [ -d "$CACHE_DIR/Editor" ]; then
        echo "Unity $unity_version already extracted, skipping extraction."
    else
        echo "Extracting Unity $unity_version... This may take a while."
        tar -xf "$CACHE_DIR/unity_$unity_version.tar.xz" -C "$CACHE_DIR"
    fi
    export DEP_Unity="$CACHE_DIR/Editor"

    if [ -d "$CACHE_DIR/bepinex_$bepinex_version" ]; then
        echo "BepInEx $bepinex_version already extracted, skipping extraction."
    else
        echo "Extracting BepInEx $bepinex_version..."
        unzip -o "$CACHE_DIR/bepinex_$bepinex_version.zip" -d "$CACHE_DIR/bepinex_$bepinex_version"
    fi
    export DEP_BepInEx="$CACHE_DIR/bepinex_$bepinex_version"

    if [ -d "$CACHE_DIR/icsharpziplib_$icsharpziplib_version" ]; then
        echo "SharpZipLib $icsharpziplib_version already extracted, skipping extraction."
    else
        echo "Extracting SharpZipLib $icsharpziplib_version..."
        unzip -o "$CACHE_DIR/icsharpziplib_$icsharpziplib_version.zip" -d "$CACHE_DIR/icsharpziplib_$icsharpziplib_version"
    fi
    export DEP_SharpZipLib="$CACHE_DIR/icsharpziplib_$icsharpziplib_version/lib/net45/ICSharpCode.SharpZipLib.dll"
    
    if [ ! -f "$DEP_Cimgui" ]; then
        echo "Error: cimgui dependency not found at $DEP_Cimgui"
        exit 1
    fi

    if [ ! -d "$DEP_Unity" ]; then
        echo "Error: Unity dependency not found at $DEP_Unity"
        exit 1
    fi

    if [ ! -d "$DEP_BepInEx" ]; then
        echo "Error: BepInEx dependency not found at $DEP_BepInEx"
        exit 1
    fi

    if [ ! -f "$DEP_SharpZipLib" ]; then
        echo "Error: SharpZipLib dependency not found at $DEP_SharpZipLib"
        exit 1
    fi

    echo "Remote dependencies downloaded and extracted successfully."
}

verify_game_dependencies() {
    if [ ! -d "$STATIONEERS_PATH" ]; then
        echo "Stationeers not found in $STATIONEERS_PATH. Ensure steam is installed and that the path is correct."
        exit 1
    fi
    export STATIONEERS_PATH

    if [ ! -d "$STATIONEERS_DEDICATED_PATH" ]; then
        echo "Stationeers Dedicated Server not found in $STATIONEERS_DEDICATED_PATH. Ensure steam is installed and that the path is correct."
        echo "It can be installed by SteamCMD. See: https://stationeers-wiki.com/Dedicated_Server_Guide#Linux"
        exit 1
    fi
    export STATIONEERS_DEDICATED_PATH
}