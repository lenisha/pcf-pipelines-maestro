processGatedApplyChangesJobPatch() {

  foundation="${1}"
  iaasType="${2}"

  # Executed only when flag is "gated-Apply-Changes-Job" is set to "true" in foundation config file
  gatedApplyChangesJob=$(grep "gated-Apply-Changes-Job" $foundation | cut -d ":" -f 2 | tr -d " ")
  if [ "${gatedApplyChangesJob,,}" == "true" ]; then

      echo "Applying Gated Apply Changes job patch to upgrade-opsmgr pipeline file."
      cp ./upgrade-opsmgr.yml ./upgrade-opsmgr-tmp.yml
      cp ./operations/opsfiles/gated-apply-changes.yml ./gated_apply_changes-opsmgr.yml
      sed -i "s/RESOURCE_NAME_GOES_HERE/pivnet-opsmgr/g" ./gated_apply_changes-opsmgr.yml
      sed -i "s/MAIN_JOB_NAME_GOES_HERE/upgrade-opsmgr/g" ./gated_apply_changes-opsmgr.yml
      sed -i "s/PREVIOUS_JOB_NAME_GOES_HERE/upgrade-opsmgr/g" ./gated_apply_changes-opsmgr.yml
      cat ./upgrade-opsmgr-tmp.yml | ./yaml_patch -o ./gated_apply_changes-opsmgr.yml > ./upgrade-opsmgr.yml

      echo "Processing Gated Apply Changes job patch to upgrade-tile pipeline template - removing wait_for_opsman task."
      cat > remove_wait_for_opsman_task.yml <<EOF
---
- op: remove
  path: /jobs/name=upgrade-tile/task=wait-opsman-clear
EOF
      cat ./upgrade-tile-template.yml | ./yaml_patch -o ./remove_wait_for_opsman_task.yml > ./upgrade-tile-tmp.yml
      echo "Applying Gated Apply Changes job patch to upgrade-tile pipeline template."
      cp ./operations/opsfiles/gated-apply-changes.yml ./gated_apply_changes-tiles.yml
      sed -i "s/MAIN_JOB_NAME_GOES_HERE/upgrade-tile/g" ./gated_apply_changes-tiles.yml
      cat ./upgrade-tile-tmp.yml | ./yaml_patch -o ./gated_apply_changes-tiles.yml > ./upgrade-tile-template.yml

  fi
}
