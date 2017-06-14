# This function contains the list of scripts to process pipeline YAML patches for each foundation.
# Typically, the execution of these scripts should be controlled by a flag in
# the foundation configuration file (./foundations/*.yml), which path is provided the "$foundation" variable
processPipelinePatchesPerFoundation() {

  foundation="${1}"
  iaasType="${2}"

  echo "Foundation pipelines patches: preparing template files for upgrade-tile and upgrade-opsmgr."
  # the presence of these two files in the maestro root dir is expected by maestro scripts
  cp ./globalPatchFiles/upgrade-ops-manager/$iaasType/pipeline.yml ./upgrade-opsmgr.yml
  cp ./globalPatchFiles/upgrade-tile/pipeline.yml ./upgrade-tile-template.yml

  # *** GATED APPLY CHANGES patch - keep this entry before processUsePivnetReleasePatch ***
  processGatedApplyChangesJobPatch "$foundation" "$iaasType"

  # Retrive pcf-pipelines from PivNet release. Controlled by flag pcf-pipelines-source
  processPcfPipelinesSourcePatch "$foundation" "$iaasType"

}

# This function contains the list of scripts to process pipeline YAML patches for ALL foundations.
# Typically, the execution of these scripts should be controlled by a flag in
# the ./common/credentials file.
processPipelinePatchesForAllFoundations() {

  echo "Global pipeline patches processing."

  echo "Preparing files for all upgrade-ops-manager pipelines"
  mkdir -p ./globalPatchFiles/upgrade-ops-manager
  cp -R ../pcf-pipelines/upgrade-ops-manager/* ./globalPatchFiles/upgrade-ops-manager/.

  echo "Preparing files for upgrade-tile pipelines"
  mkdir -p ./globalPatchFiles/upgrade-tile
  cp ../pcf-pipelines/upgrade-tile/* ./globalPatchFiles/upgrade-tile/.

  echo "Processing Pivotal Releases source patch"
  processPivotalReleasesSourcePatch "./common/credentials.yml"

}
