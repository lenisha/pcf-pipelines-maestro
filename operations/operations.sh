# This function contains the list of scripts to process pipeline YAML patches for each foundation.
# Typically, the execution of these scripts should be controlled by a flag in
# the foundation configuration file (./foundations/*.yml), which path is provided the "$foundation" variable
processPipelinePatchesPerFoundation() {

  foundation="${1}"
  iaasType="${2}"

  echo "Preparing pipeline files for upgrade-tile and upgrade-opsmgr pipelines template."
  # the presence of those two files in the maestro root dir is expected by maestro scripts
  cp ../pcf-pipelines/upgrade-tile/pipeline.yml ./upgrade-tile-template.yml
  cp ../pcf-pipelines/upgrade-ops-manager/$iaasType/pipeline.yml ./upgrade-opsmgr.yml

  # *** GATED APPLY CHANGES patch - keep this entry before processUsePivnetReleasePatch ***
  processGatedApplyChangesJobPatch "$foundation" "$iaasType"

  # Retrive pcf-pipelines from PivNet release. Controlled by flag use-pivnet-release
  processUsePivnetReleasePatch "$foundation" "$iaasType"

}

# This function contains the list of scripts to process pipeline YAML patches for ALL foundations.
# Typically, the execution of these scripts should be controlled by a flag in
# the ./common/credentials file.
processPipelinePatchesForAllFoundations() {
   echo "No global pipeline patches for now."
}
