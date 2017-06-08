function prepareTools() {
    current_concourse_url="${1}"
    prev_concourse_url="${2}"
    admin_team="${3}"

    # Download fly CLI from concourse server if not done yet
    echo "Preparing Concourse FLY cli"

    if [ -e "./fly" ]; then
        set +e
        [ "$prev_concourse_url" != "$current_concourse_url" ] && echo "Synchronizing FLY..." && ./fly -t $admin_team sync
        set -e
    else
       echo "Downloading FLY from Concorse server $current_concourse_url"
       wget -O fly $current_concourse_url/api/v1/cli?arch=amd64\&platform=linux
       chmod +x ./fly
       echo "FLY version in use:"
       ./fly --version
    fi

    echo "Preparing YAML PATCH tool"
    wget -O yaml_patch https://github.com/krishicks/yaml-patch/releases/download/v0.0.5/yaml_patch_linux && chmod 755 yaml_patch


}
