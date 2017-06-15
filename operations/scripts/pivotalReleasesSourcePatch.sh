processPivotalReleasesSourcePatch() {

  configurationsFile="${1}"

  # Executed only when flag is "pivotal-releases-source" is set to something other than the default pivnet
  pivotalReleasesSource=$(grep "pivotal-releases-source" "$configurationsFile" | grep "^[^#;]" | cut -d ":" -f 2 | tr -d " ")
  echo "Configured Pivotal Releases source: [$pivotalReleasesSource]"
  if [ "${pivotalReleasesSource,,}" == "s3" ]; then

      echo "Applying Pivotal Releases source patch for [$pivotalReleasesSource] to upgrade-opsmgr pipelines files."
      for iaasPipeline in ./globalPatchFiles/upgrade-ops-manager/*/pipeline.yml; do
          echo "Patching [$iaasPipeline]"
          cp $iaasPipeline ./upgrade-ops-manager-tmp.yml
          cat ./upgrade-ops-manager-tmp.yml | ./yaml_patch -o ./operations/opsfiles/use-product-releases-from-s3-opsmgr.yml > $iaasPipeline
      done

      echo "Applying Pivotal Releases source patch for [$pivotalReleasesSource] to upgrade-tiles pipelines files."
      cp ./globalPatchFiles/upgrade-tile/pipeline.yml ./upgrade-tile-tmp.yml
      cat ./upgrade-tile-tmp.yml | ./yaml_patch -o ./operations/opsfiles/use-product-releases-from-s3-tiles.yml > ./globalPatchFiles/upgrade-tile/pipeline.yml

      # Generate PivNet to S3 main pipeline
      createPivNetToS3Pipeline "$configurationsFile"

  fi
}

createPivNetToS3Pipeline() {
  configurationsFile="${1}"

  templateFoundationFile=$(grep "template-foundation-config-file" "$configurationsFile" | grep "^[^#;]" | cut -d ":" -f 2 | tr -d " ")
  if [ -z "${templateFoundationFile}" ]; then
    echo "Error creating the PivNet-to-S3 pipeline. Parameter 'template-foundation-config-file' is missing from /common/credentials.yml"
    exit 1
  fi
  templateFoundationFilePath="./foundations/$templateFoundationFile.yml"
  if [ -e "$templateFoundationFilePath" ]; then
      echo "Generating PivNet-to-S3 pipeline."
      cp ./pipelines/utils/pivnet-to-s3-bucket.yml ./pivnet-to-s3-bucket.yml

      # process opsmgr
      set +e
      opsmgr_product_version=$(grep "BoM_OpsManager_product_version" $templateFoundationFilePath | grep "^[^#;]" | cut -d ":" -f 2 | tr -d " ")
      set -e
      if [ -n "${opsmgr_product_version}" ]; then
          cp ./operations/opsfiles/pivnet-to-s3-bucket-opsmgr-entry.yml ./pivnet-to-s3-bucket-entry.yml
          sed -i "s/PRODUCTVERSION/$opsmgr_product_version/g" ./pivnet-to-s3-bucket-entry.yml

          # determine which IaaSes are used in the foundations files
          determineIaaSesInUse

          # remove IaaS not in use from OpsMgr files download job in Pivnet-To-S3 pipeline operations file
          removeIaaSFromPivnetToS3Pipeline

          echo "Adding OpsManager, version [$opsmgr_product_version] to PivNet-to-S3 pipeline"
          cp ./pivnet-to-s3-bucket.yml ./pivnet-to-s3-bucket-tmp.yml
          cat ./pivnet-to-s3-bucket-tmp.yml | ./yaml_patch -o ./pivnet-to-s3-bucket-entry.yml > ./pivnet-to-s3-bucket.yml
      else
          echo "No configuration found for Ops Mgr version in the BoM for [$templateFoundationFile], skipping it for the Pivnet-to-S3 pipeline."
      fi
      # process tiles
      set +e
      grep "BoM_tile_" $templateFoundationFilePath | grep "^[^#;]" > ./listOfEnabledTiles.txt
      set -e
      cat ./listOfEnabledTiles.txt | while read tileEntry
      do
        # make a copy of the template file for each tile
        cp ./operations/opsfiles/pivnet-to-s3-bucket-tile-entry.yml ./pivnet-to-s3-bucket-entry.yml

        tileEntryKey=$(echo "$tileEntry" | cut -d ":" -f 1 | tr -d " ")
        tileEntryValue=$(echo "$tileEntry" | cut -d ":" -f 2 | tr -d " ")  # product version
        tile_name=$(echo "$tileEntryKey" | cut -d "_" -f 3)
        tileMetadataFilename="./common/pcf-tiles/$tile_name.yml"

        if [ -e "$tileMetadataFilename" ]; then
          resource_name=$(grep "resource_name" $tileMetadataFilename | cut -d ":" -f 2 | tr -d " ")
          product_slug=$(grep "product_slug" $tileMetadataFilename | cut -d ":" -f 2 | tr -d " ")

          sed -i "s/PRODUCTSLUG/$product_slug/g" ./pivnet-to-s3-bucket-entry.yml
          sed -i "s/PRODUCTVERSION/$tileEntryValue/g" ./pivnet-to-s3-bucket-entry.yml
          sed -i "s/PRODUCTEXTENSION/pivotal/g" ./pivnet-to-s3-bucket-entry.yml
          sed -i "s/RESOURCENAME/$resource_name/g" ./pivnet-to-s3-bucket-entry.yml

          echo "Adding tile [$tile_name], version [$tileEntryValue] to PivNet-to-S3 pipeline"
          cp ./pivnet-to-s3-bucket.yml ./pivnet-to-s3-bucket-tmp.yml
          cat ./pivnet-to-s3-bucket-tmp.yml | ./yaml_patch -o ./pivnet-to-s3-bucket-entry.yml > ./pivnet-to-s3-bucket.yml
        else
          echo "Error creating the PivNet-to-S3 pipeline. Tile metadata file not found: [$tileMetadataFilename]"
          exit 1
        fi

      done
      # if at least one tile was found, then generate Pivnet-to-S3 pipeline
      if [ -e "./pivnet-to-s3-bucket-entry.yml" ]; then
          # removing placeholder entries
          sed -i "s/- name\: PLACEHOLDER/ /g" ./pivnet-to-s3-bucket.yml
          echo "Setting Pivnet-to-S3 pipeline."
          ./fly -t "main" set-pipeline -p "pivnet-to-s3-bucket" -c ./pivnet-to-s3-bucket.yml -l "$configurationsFile" -l "$templateFoundationFilePath" -n
      else
          echo "Skipping creation of Pivnet-to-S3 pipeline, no tile configuration found for foundation [$templateFoundationFile]."
      fi

  else
      echo "Error creating the PivNet-to-S3 pipeline. Parameter 'template-foundation-config-file' from /common/credentials.yml points to foundation [$templateFoundationFile], whose config file is not present under /foundations folder."
      exit
  fi
}

determineIaaSesInUse() {
  # determine which IaaSes are used in the foundations files
  # iterates through foundations config files and creates env variables for the corresponding IaaS
  for foundation in ./foundations/*.yml; do
      iaasInUse=$(grep "iaas_type" $foundation | cut -d ":" -f 2 | tr -d " ")
      variableName="maestro_IaaSinUse_${iaasInUse}"
      export "${variableName}"="true"
  done
}

removeIaaSFromPivnetToS3Pipeline() {

  # remove IaaS not in use from OpsMgr files download job in Pivnet-To-S3 pipeline operations file

  # get list of IaaSes from ops-mgr metadata file
  set +e
  grep -v -e '^[[:space:]]*$' ./common/opsmgr-metadata/globs.yml | grep "^[^#;]" > ./listOfIaaS.txt
  set -e
  # iterate through list of IaaSes and check for presence of env variable maestro_IaaSinUse_${iaasEntry}
  cat ./listOfIaaS.txt | while read iaasLineEntry
  do
      iaasEntry=$(echo "$iaasLineEntry" | cut -d ":" -f 1 | tr -d " ")
      variableName="maestro_IaaSinUse_${iaasEntry}"
      if [ -z "${!variableName}" ]; then
          # IaaS not in use - remove all corresponding sections from operations file
          sed -i "/# ${iaasEntry}+++/,/# ${iaasEntry}---/d" ./pivnet-to-s3-bucket-entry.yml
      else
          # IaaS is in use - remove only corresponding marker lines from operations file
          sed -i "/# ${iaasEntry}+++/d" ./pivnet-to-s3-bucket-entry.yml
          sed -i "/# ${iaasEntry}---/d" ./pivnet-to-s3-bucket-entry.yml
      fi
  done
}
