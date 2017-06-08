#!/bin/bash

set -e

cd ./pcf-pipelines-maestro

source ./patches/patches.sh
source ./tasks/maestro/scripts/concourse.sh
source ./tasks/maestro/scripts/tools.sh
source ./tasks/maestro/scripts/opsmgr.sh
source ./tasks/maestro/scripts/tiles.sh
source ./tasks/maestro/scripts/buildpacks.sh
source ./tasks/maestro/scripts/stemcell.sh

previous_concourse_url=""

# Process pipelines YAML patches that will apply to all foundations
# See function definition in ./patches/patches.sh
processPipelinePatchesForAllFoundations

for foundation in ./foundations/*.yml; do

    # parse foundation name
    foundation_fullname=$(basename "$foundation")
    foundation_name="${foundation_fullname%.*}"
    iaasType=$(grep "iaas_type" $foundation | cut -d " " -f 2)

    echo "Processing pipelines for foundation [$foundation_name] with IaaS [$iaasType]"

    # get Concourse credentials from foundation file (see ./tasks/maestro/scripts/concourse.sh)
    parseConcourseCredentials "$foundation"

    # prepare Concourse FLY cli in the task container (see ./tasks/maestro/scripts/tools.sh)
    prepareTools "$cc_url" "$previous_concourse_url"
    previous_concourse_url=$cc_url     # save current concourse url

    # login into Concourse main team (see ./tasks/maestro/scripts/concourse.sh)
    loginConcourseTeam "$cc_url" "$cc_main_user" "$cc_main_pass" "main"
    # create concourse team for the foundation if not existing yet (see ./tasks/maestro/scripts/concourse.sh)
    createConcourseFoundationTeam "$foundation_name" "$cc_user" "$cc_pass" "main"
    # Login into the corresponding Concourse team for the foundation (see ./tasks/maestro/scripts/concourse.sh)
    loginConcourseTeam "$cc_url" "$cc_user" "$cc_pass" "$foundation_name"

    # Process pipelines YAML patches for each foundation according to its configuration (see ./tasks/patches/patches.sh)
    processPipelinePatchesPerFoundation "$foundation" "$iaasType"

    # ***** Pipeline for Ops-Manager Upgrades ***** (see ./tasks/maestro/scripts/opsmgr.sh)
    setOpsMgrUpgradePipeline "$foundation" "$foundation_name" "$iaasType"
    # ***** Pipeline for PCF Tiles Upgrades ***** (see ./tasks/maestro/scripts/tiles.sh)
    echo "Processing PCF tiles upgrade pipelines for [$foundation_name]"
    setTilesUpgradePipelines "$foundation" "$foundation_name" "$cc_pass"
    # ***** Pipeline for Buildpack Upgrade ***** (see ./tasks/maestro/scripts/buildpacks.sh)
    echo "Processing buildpacks upgrade pipelines for [$foundation_name]"
    setBuildpacksUpgradePipelines "$foundation" "$foundation_name"
    # ***** Pipeline for Stemcell Adhoc Upgrade ***** (see ./tasks/maestro/scripts/stemcell.sh)
    setStemcellAdhocUpgradePipeline "$foundation" "$foundation_name"

done