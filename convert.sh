#!/bin/bash
set -e
source config.sh
source deps.sh

declare -A file_blame

download_dependencies false

verify_game_dependencies



filtered_copy() {
    local src="$1"
    local dst="$2"
    local -n exclude_list="$3"
    mkdir -p "$dst"
    for file in $src; do
        local filename
        filename=$(basename "$file")
        if [[ " ${exclude_list[*]} " == *" $filename "* ]]; then
            continue
        fi
        cp -r "$file" "$dst/"
        file_blame["$dst/$(basename "$file")"]=$file
    done
}

filtered_copy_overwrite() {
    local src="$1"
    local dst="$2"
    local -n exclude_list="$3"
    mkdir -p "$dst"
    for file in "$src"/*; do
        local filename
        filename=$(basename "$file")
        if [[ " ${exclude_list[*]} " == *" $filename "* ]]; then
            continue
        fi
        cp -rf "$file" "$dst/"
        file_blame["$dst/$(basename "$file")"]=$file
    done
}

filtered_link_overwrite() {
    local src="$1"
    local dst="$2"
    local -n exclude_list="$3"
    mkdir -p "$dst"
    for file in "$src"/*; do
        local filename
        filename=$(basename "$file")
        if [[ " ${exclude_list[*]} " == *" $filename "* ]]; then
            continue
        fi
        rm -rf "${dst:?}/$filename"
        ln -sf "$file" "$dst/"
        file_blame["$dst/$(basename "$file")"]=$file
    done
}

link_all() {
    local src="$1"
    local dst="$2"
    mkdir -p "$dst"
    for file in "$src"/*; do
        ln -s "$file" "$dst/"
        file_blame["$dst/$(basename "$file")"]=$file
    done
}

filtered_link() {
    local src="$1"
    local dst="$2"
    local -n exclude_list="$3"
    mkdir -p "$dst"
    for file in "$src"/*; do
        local filename
        filename=$(basename "$file")
        if [[ " ${exclude_list[*]} " == *" $filename "* ]]; then
            continue
        fi
        ln -s "$file" "$dst/"
        file_blame["$dst/$(basename "$file")"]=$file
    done
}

write_blame_file() {
    local blame_file="$OUTPUT_PATH/blame.txt"
    for dst in "${!file_blame[@]}"; do
        echo "$dst -> ${file_blame[$dst]}" >> "$blame_file"
    done
}


setup_linux_edition() {
    STATIONEERS_DATA="$STATIONEERS_PATH/rocketstation_Data"
    # STATIONEERS_MONO="$STATIONEERS_PATH/rocketstation_Data/MonoBleedingEdge"
    OUTPUT_DATA="$OUTPUT_PATH/rocketstation_Data"
    OUTPUT_MONO="$OUTPUT_PATH/rocketstation_Data/MonoBleedingEdge"
    UNITY_LINUXPLAYER="$CACHE_DIR/Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations/linux64_player_nondevelopment_mono"
    UNITY_LINUX_MONO="$CACHE_DIR/Editor/Data/MonoBleedingEdge/lib/mono/net_4_x-linux"
    UNITY_LINUX_MONO_LIBS="$CACHE_DIR/Editor/Data/MonoBleedingEdge/lib"
    UNITY_LINUX_MONO_RUNTIME="$UNITY_LINUXPLAYER/Data/MonoBleedingEdge"
    if [[ -d "$OUTPUT_PATH" && ! -z "$( ls -A "$OUTPUT_PATH")" ]]; then
        echo "Output directory $OUTPUT_PATH already exists and is not empty. Remove it before running this script."
        exit 1
    fi
    mkdir -p "$OUTPUT_PATH"

    echo "Symlinking game resources..."
    mkdir -p "$OUTPUT_PATH/rocketstation_Data"
    # shellcheck disable=SC2034
    local excluded_data_subdirs=(
        "Managed"
        "Plugins"
        "MonoBleedingEdge"
    )
    filtered_link "$STATIONEERS_DATA" "$OUTPUT_DATA" excluded_data_subdirs
    for dir in "${excluded_data_subdirs[@]}"; do
        mkdir -p "$OUTPUT_DATA/$dir"
    done
    
    echo "Symlinking game assemblies..."
    link_all "$STATIONEERS_DATA/Managed" "$OUTPUT_DATA/Managed"

    echo "Updating with Linux player assemblies..."
    for file in "$UNITY_LINUXPLAYER/Data/Managed"/*.dll; do
        filename=$(basename "$file")
        cp -f "$file" "$OUTPUT_DATA/Managed/"
        file_blame["$OUTPUT_DATA/Managed/$filename"]="$file"
    done

    echo "Updating .NET assemblies to Linux versions..."
    for file in "$UNITY_LINUX_MONO"/*.dll; do
        filename=$(basename "$file")
        cp -f "$file" "$OUTPUT_DATA/Managed/"
        file_blame["$OUTPUT_DATA/Managed/$filename"]="$file"
    done
    echo "Copying & Setting up Mono runtime libraries..."
    mkdir -p "$OUTPUT_MONO/x86_64"
    mkdir -p "$OUTPUT_MONO/etc"
    for file in "$UNITY_LINUX_MONO_RUNTIME/x86_64"/*.so; do
        filename=$(basename "$file")
        cp -f "$file" "$OUTPUT_MONO/x86_64/"
        file_blame["$OUTPUT_MONO/x86_64/$filename"]="$file"
    done
    cp -r "$UNITY_LINUX_MONO_RUNTIME/etc" "$OUTPUT_MONO/"
    file_blame["$OUTPUT_MONO/etc"]="$UNITY_LINUX_MONO_RUNTIME/etc"
    ln -sf "$OUTPUT_MONO" "$OUTPUT_MONO/MonoBleedingEdge"

    echo "Updating Mono libraries"
    for file in "$UNITY_LINUX_MONO_LIBS"/*.so; do
        filename=$(basename "$file")
        cp -f "$file" "$OUTPUT_MONO/x86_64/"
        file_blame["$OUTPUT_MONO/x86_64/$filename"]="$file"
    done
    echo "Updating Game Assemblies"
    cp -f "$DEP_SharpZipLib" "$OUTPUT_DATA/Managed/"
    file_blame["$OUTPUT_DATA/Managed/$(basename "$DEP_SharpZipLib")"]="$DEP_SharpZipLib"

    echo "Updating Game Native Plugins"
    cp -f "$DEP_Cimgui" "$OUTPUT_DATA/Plugins/cimgui.so"
    
    file_blame["$OUTPUT_DATA/Plugins/$(basename "$DEP_Cimgui")"]="$DEP_Cimgui"
    cp -f "$DEP_DiscordGameSDK/lib/x86_64/discord_game_sdk.so" "$OUTPUT_DATA/Plugins/discord_game_sdk.so"

    cp -f "$STATIONEERS_DEDICATED_PATH/rocketstation_DedicatedServer_Data/Plugins/"* "$OUTPUT_DATA/Plugins/"
    for file in "$OUTPUT_DATA/Plugins"/*; do
        filename=$(basename "$file")
        if [[ -f "$STATIONEERS_DEDICATED_PATH/rocketstation_DedicatedServer_Data/Plugins/$filename" ]]; then
            file_blame["$OUTPUT_DATA/Plugins/$filename"]="$STATIONEERS_DEDICATED_PATH/rocketstation_DedicatedServer_Data/Plugins/$filename"
        fi
    done
    mv -f "$OUTPUT_DATA/Plugins/libsteam_api.so" "$OUTPUT_DATA/Plugins/steam_api64.so"
    file_blame["$OUTPUT_DATA/Plugins/steam_api64.so"]="$OUTPUT_DATA/Plugins/libsteam_api.so"

    echo "Installing BepInEx..."
    cp -r "$DEP_BepInEx/." "$OUTPUT_PATH/"
    cp -rf "$PWD/BepInEx/." "$OUTPUT_PATH/BepInEx"
    mv "$OUTPUT_PATH/BepInEx/run_bepinex.sh" "$OUTPUT_PATH/run_bepinex.sh"
    mkdir -p "$OUTPUT_PATH/BepInEx/patchers"
    mkdir -p "$OUTPUT_PATH/BepInEx/plugins"

    echo "Installing Tuxstation Patcher..."
    cp -r "$DEP_Tuxstation/Tuxceil.dll" "$OUTPUT_PATH/BepInEx/patchers/"
    file_blame["$OUTPUT_PATH/BepInEx/patchers/Tuxceil.dll"]="$DEP_Tuxstation/Tuxceil.dll"
    cp -r "$DEP_Tuxstation/Tuxharmony.dll" "$OUTPUT_PATH/BepInEx/plugins"
    file_blame["$OUTPUT_PATH/BepInEx/plugins/Tuxharmony.dll"]="$DEP_Tuxstation/Tuxharmony.dll"

    echo "Setting up Linux UnityPlayer..."
    cp "$UNITY_LINUXPLAYER/LinuxPlayer" "$OUTPUT_PATH/rocketstation.x86_64"
    cp "$UNITY_LINUXPLAYER/UnityPlayer.so" "$OUTPUT_PATH/UnityPlayer.so"
    chmod +x "$OUTPUT_PATH/rocketstation.x86_64"
    chmod +x "$OUTPUT_PATH/UnityPlayer.so"

    echo 'Setup Done. Launch the Linux edition by running the run_bepinex.sh that is in the output directory.'

    write_blame_file
}


setup_linux_edition