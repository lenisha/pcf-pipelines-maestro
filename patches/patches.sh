# This function contains the list of scripts to process pipeline YAML patches for each foundation.
# Typically, the execution of these scripts should be controlled by a flag in
# the foundation configuration file (./foundations/*.yml), which path is provided the "$foundation" variable
processPipelinePatchesPerFoundation() {

  foundation="${1}"
  iaasType="${2}"

  # *** GATED APPLY CHANGES patch ***
  # Executed only when flag is "gated-Apply-Changes-Job" is set to "true" in foundation config file
  gatedApplyChangesJob=$(grep "gated-Apply-Changes-Job" $foundation | cut -d ":" -f 2 | tr -d " ")
  if [ "${gatedApplyChangesJob,,}" == "true" ]; then

      echo "Applying Gated Apply Changes job patch to upgrade-opsmgr pipeline file."
      cp ./patches/opsfiles/gated-apply-changes.yml ./gated_apply_changes-opsmgr.yml
      sed -i "s/RESOURCE_NAME_GOES_HERE/pivnet-opsmgr/g" ./gated_apply_changes-opsmgr.yml
      sed -i "s/MAIN_JOB_NAME_GOES_HERE/upgrade-opsmgr/g" ./gated_apply_changes-opsmgr.yml
      sed -i "s/PREVIOUS_JOB_NAME_GOES_HERE/upgrade-opsmgr/g" ./gated_apply_changes-opsmgr.yml
      cat ../pcf-pipelines/upgrade-ops-manager/$iaasType/pipeline.yml | ./yaml_patch -o ./gated_apply_changes-opsmgr.yml > ./upgrade-opsmgr.yml

      echo "Processing Gated Apply Changes job patch to upgrade-tile pipeline template - removing wait_for_opsman task."
      cat > remove_wait_for_opsman_task.yml <<EOF
---
- op: remove
  path: /jobs/name=upgrade-tile/task=wait-opsman-clear
EOF
      cat ../pcf-pipelines/upgrade-tile/pipeline.yml | ./yaml_patch -o ./remove_wait_for_opsman_task.yml > ./upgrade-tile-tmp.yml
      echo "Applying Gated Apply Changes job patch to upgrade-tile pipeline template."
      cp ./patches/opsfiles/gated-apply-changes.yml ./gated_apply_changes-tiles.yml
      sed -i "s/MAIN_JOB_NAME_GOES_HERE/upgrade-tile/g" ./gated_apply_changes-tiles.yml
      cat ./upgrade-tile-tmp.yml | ./yaml_patch -o ./gated_apply_changes-tiles.yml > ./upgrade-tile-template.yml

  else
      echo "Keeping inline apply changes task in upgrade-tile and upgrade-opsmgr pipelines template."
      cp ../pcf-pipelines/upgrade-tile/pipeline.yml ./upgrade-tile-template.yml
      cp ../pcf-pipelines/upgrade-ops-manager/$iaasType/pipeline.yml ./upgrade-opsmgr.yml
  fi
  # *** End of GATED APPLY CHANGES patch ***

}

# This function contains the list of scripts to process pipeline YAML patches for ALL foundations.
# Typically, the execution of these scripts should be controlled by a flag in
# the ./common/credentials file.
processPipelinePatchesForAllFoundations() {
   echo "No global pipeline patches for now."
}
