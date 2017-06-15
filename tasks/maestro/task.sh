#!/bin/bash

set -e

cd ./pcf-pipelines-maestro

source ./operations/operations.sh
for script in ./operations/scripts/*.sh; do
  source $script
done
for script in ./tasks/maestro/scripts/*.sh; do
  source $script
done

processDebugEnablementConfig "./common/credentials.yml"  # determine if script debug needs to be enabled

previous_concourse_url="" # initialize current concourse url variable

parseConcourseCredentials "./common/credentials.yml" "true"

# prepare Concourse FLY cli in the task container (see ./tasks/maestro/scripts/tools.sh)
prepareTools "$cc_url"

loginConcourseTeam "$cc_url" "$cc_main_user" "$cc_main_pass" "main" "$skip_ssl_verification"

# Process pipelines YAML patches that will apply to all foundations
# See function definition in ./operations/operations.sh
processPipelinePatchesForAllFoundations

for foundation in ./foundations/*.yml; do

    # parse foundation name
    foundation_fullname=$(basename "$foundation")
    foundation_name="${foundation_fullname%.*}"
    iaasType=$(grep "iaas_type" $foundation | cut -d " " -f 2)

    echo "Processing pipelines for foundation [$foundation_name] with IaaS [$iaasType]"

    # get Concourse credentials from foundation file (see ./tasks/maestro/scripts/concourse.sh)
    parseConcourseCredentials "$foundation" "false"
    parseConcourseFoundationCredentials "$foundation"

    concourseFlySync "$cc_url" "$previous_concourse_url" "main"
    previous_concourse_url=$cc_url     # save current concourse url

    # login into Concourse main team (see ./tasks/maestro/scripts/concourse.sh)
    loginConcourseTeam "$cc_url" "$cc_main_user" "$cc_main_pass" "main" "$skip_ssl_verification"
    # create concourse team for the foundation if not existing yet (see ./tasks/maestro/scripts/concourse.sh)
    createConcourseFoundationTeam "$foundation_name" "$cc_user" "$cc_pass" "main"
    # Login into the corresponding Concourse team for the foundation (see ./tasks/maestro/scripts/concourse.sh)
    loginConcourseTeam "$cc_url" "$cc_user" "$cc_pass" "$foundation_name" "$skip_ssl_verification"

    # Process pipelines YAML patches for each foundation according to its configuration (see ./tasks/operations/operations.sh)
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
