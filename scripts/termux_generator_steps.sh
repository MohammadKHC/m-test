# Funktion, um den Paketnamen zu überprüfen
check_names() {
    if [[ $TERMUX_APP__PACKAGE_NAME =~ '_' ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME =~ '-' ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == package ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == package.* ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.package ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.package.* ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == in ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == in.* ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.in ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.in.* ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == is ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == is.* ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.is ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.is.* ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == as ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == as.* ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.as ]] || \
       [[ $TERMUX_APP__PACKAGE_NAME == *.as.* ]]
    then
        echo "[!] Package name must not contain underscores, dashes, or invalid patterns!"
        exit 2
    fi

    if [[ $TERMUX_APP__PACKAGE_NAME == *"com.termux"* ]] && \
        [[ "$TERMUX_APP__PACKAGE_NAME" != "com.termux" ]]; then
        echo "[!] Sorry, please choose a unique custom name that does not contain 'com.termux'"
        echo "(and is not an exact substring of it either) to avoid side effects."
        echo "Examples: 'com.test.termux' is OK, but 'com.termux.test' or 'com.ter' could have side effects."
        exit 2
    fi

    if [[ $ADDITIONAL_PACKAGES == *"termux-x11-nightly"* ]]; then
        echo "[!] That version of termux-x11-nightly is precompiled and"
        echo "cannot be compiled by termux-generator with any custom name inserted!"
        echo "To use termux-x11-nightly with termux-generator, just set"
        echo "'--type f-droid', then install the .apk files termux-generator builds."
        echo "A source-built and patched 'termux-x11-nightly' package is"
        echo "automatically preinstalled."
        exit 2
    fi
}

clean_docker() {
    docker container kill termux-generator-package-builder 2> /dev/null || true
    docker container rm -f termux-generator-package-builder 2>/dev/null || true
    if ! docker image rm ghcr.io/termux/package-builder 2>/dev/null; then
        echo "[*] Warning: not removing Docker package builder image for \"F-Droid\" Termux, likely because it is either not downloaded yet, or in use by other containers."
    fi
    if ! docker image rm ghcr.io/termux-play-store/package-builder 2>/dev/null; then
        echo "[*] Warning: not removing Docker package builder image for \"Google Play\" Termux, likely because it is either not downloaded yet, or in use by other containers."
    fi
}

clean_artifacts() {

}

# Funktion, um Repositories herunterzuladen
download() {
        git clone --depth 1 https://github.com/termux/termux-packages.git               termux-packages-main
}

build_plugin() {
}

install_plugin() {
}

# Funktion, um Bootstrap-Patches anzuwenden
patch_bootstraps() {
    # The reason why it is necessary to replace the name first, then patch bootstraps, but do the reverse for apps,
    # is because command-not-found must be partially unpatched back to the default TERMUX_PREFIX to build,
    # so that patch must apply after the bootstraps' name replacement has completed, but the apps contain the
    # string "com.termux" in their code in many more places than the bootstraps do, so it's easier to patch them first.
    if [[ "$TERMUX_APP__PACKAGE_NAME" != "com.termux" ]]; then
        replace_termux_name termux-packages-main "$TERMUX_APP__PACKAGE_NAME"
    fi

    apply_patches "$TERMUX_APP_TYPE-patches/bootstrap-patches" termux-packages-main

    local bashrc="termux-packages-main/packages/bash/etc-bash.bashrc"

    cp -f "$TERMUX_GENERATOR_HOME/scripts/termux_generator_utils.sh" termux-packages-main/scripts/
}

# Funktion, um die App zu patchen
patch_apps() {
}

build_termux_x11() {
}


move_termux_x11_deb() {
}

# Funktion, um Bootstraps zu erstellen
build_bootstraps() {
    pushd termux-packages-main

    local bootstrap_script_args=""

    if [ -n "$ENABLE_SSH_SERVER" ]; then
        ADDITIONAL_PACKAGES+=",openssh"
    fi

    bootstrap_script_args+=" --add ${ADDITIONAL_PACKAGES}"

    if [[ "$TERMUX_APP_TYPE" == "f-droid" ]]; then
        local bootstrap_script="build-bootstraps.sh"
        local bootstrap_architectures="aarch64"
        if [ -n "${DISABLE_BOOTSTRAP_SECOND_STAGE-}" ]; then
            bootstrap_script_args+=" --disable-bootstrap-second-stage"
        fi
    else
        local bootstrap_script="generate-bootstraps.sh"
        local bootstrap_architectures="aarch64"
        bootstrap_script_args+=" --build"
    fi

    if [ -n "${BOOTSTRAP_ARCHITECTURES}" ]; then
        bootstrap_architectures="$BOOTSTRAP_ARCHITECTURES"
    fi

    bootstrap_script_args+=" --architectures $bootstrap_architectures"

    if [[ "${CI-}" != "true" ]]; then
        scripts/run-docker.sh "scripts/$bootstrap_script" $bootstrap_script_args
    else
        scripts/setup-ubuntu.sh
        scripts/setup-android-sdk.sh
        scripts/free-space.sh
        rm -f "${HOME}"/lib/ndk-*.zip "${HOME}"/lib/sdk-*.zip
        sed -i "s|/home/builder/termux-packages|$(pwd)|g" "scripts/$bootstrap_script"
        "scripts/$bootstrap_script" $bootstrap_script_args
    fi

    popd
}

# Funktion, um Bootstraps zu kopieren
move_bootstraps() {
}

# Funktion, um die App zu bauen
build_apps() {
}

# Funktion, um die APK zu kopieren
move_apks() {
}
