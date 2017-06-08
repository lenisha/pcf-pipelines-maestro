function setTilesUpgradePipelines() {
  foundation="${1}"
  foundation_name="${2}"

  set +e
  grep "BoM_tile_" $foundation | grep "^[^#;]" > ./listOfEnabledTiles.txt
  set -e

  gatedApplyChangesJob=$(grep "gated-Apply-Changes-Job" $foundation | cut -d ":" -f 2 | tr -d " ")
  cat ./listOfEnabledTiles.txt | while read tileEntry
  do
    tileEntryKey=$(echo "$tileEntry" | cut -d ":" -f 1 | tr -d " ")
    tileEntryValue=$(echo "$tileEntry" | cut -d ":" -f 2 | tr -d " ")
    tile_name=$(echo "$tileEntryKey" | cut -d "_" -f 3)
    resource_name=$(grep "resource_name" ./common/pcf-tiles/$tile_name.yml | cut -d ":" -f 2 | tr -d " ")
    # Pipeline template file ./upgrade-tile-template.yml is produced by processPipelinePatchesPerFoundation() in ./patches/patches.sh
    cp ./upgrade-tile-template.yml ./upgrade-tile.yml
    # customize upgrade tile job name
    sed -i "s/upgrade-tile/upgrade-$tile_name-tile/g" ./upgrade-tile.yml
    if [ "${gatedApplyChangesJob,,}" == "true" ]; then
        sed -i "s/RESOURCE_NAME_GOES_HERE/$resource_name/g" ./upgrade-tile.yml
        sed -i "s/PREVIOUS_JOB_NAME_GOES_HERE/upgrade-$tile_name-tile/g" ./upgrade-tile.yml
    fi

    echo "Setting upgrade pipeline for tile [$tile_name], version [$tileEntryValue]"
    ./fly -t $foundation_name set-pipeline -p "$foundation_name-Upgrade-$tile_name" -c ./upgrade-tile.yml -l "./common/pcf-tiles/$tile_name.yml" -l ./common/credentials.yml -l "$foundation" -v "product_version=${tileEntryValue}" -n
  done

}
