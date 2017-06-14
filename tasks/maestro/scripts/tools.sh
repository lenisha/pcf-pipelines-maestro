function prepareTools() {
    current_concourse_url="${1}"

    # Download fly CLI from concourse server if not done yet
    echo "Downloading FLY from Concourse server $current_concourse_url"
    wget -O fly $current_concourse_url/api/v1/cli?arch=amd64\&platform=linux
    chmod +x ./fly
    echo "FLY version in use:"
    ./fly --version

    echo "Preparing YAML PATCH tool"
    wget -O yaml_patch https://github.com/krishicks/yaml-patch/releases/download/v0.0.7/yaml_patch_linux && chmod 755 yaml_patch
}

function processDebugEnablementConfig() {

  config_file="${1}"

  set +e
  isDebugEnabled=$(grep "enableDebugMessages" $config_file | grep "^[^#;]" | cut -d " " -f 2)
  set -e
  if [ "${isDebugEnabled,,}" == "true" ]; then
      set -x;
  fi

}
