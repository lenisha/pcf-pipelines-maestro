processPcfPipelinesSourcePatch() {

  foundation="${1}"
  iaasType="${2}"

  # Executed only when flag is "use-pivnet-release" is set to "true" in foundation config file
  pcfPipelinesSource=$(grep "pcf-pipelines-source" $foundation | cut -d ":" -f 2 | tr -d " ")

  if [ "${pcfPipelinesSource,,}" == "git" ]; then

      echo "Changing pcf-pipelines url in upgrade-opsmgr pipelines files."
      cp ./upgrade-opsmgr.yml ./upgrade-opsmgr-tmp.yml
      cat ./upgrade-opsmgr-tmp.yml | ./yaml_patch -o ./operations/opsfiles/replace-pcf-pipelines-git-repo-uri.yml > ./upgrade-opsmgr.yml

      echo "Changing pcf-pipelines url in upgrade-tiles pipelines files."
      cp ./upgrade-tile-template.yml ./upgrade-tile-tmp.yml
      cat ./upgrade-tile-tmp.yml | ./yaml_patch -o ./operations/opsfiles/replace-pcf-pipelines-git-repo-uri.yml > ./upgrade-tile-template.yml

  else

    if [ "${pcfPipelinesSource,,}" == "pivnet" ]; then

        echo "Applying pcf-pipelines-source patch [$pcfPipelinesSource] to upgrade-opsmgr pipeline file."
        cp ./upgrade-opsmgr.yml ./upgrade-opsmgr-tmp.yml
        cat ./upgrade-opsmgr-tmp.yml | ./yaml_patch -o ../pcf-pipelines/operations/use-pivnet-release.yml > ./upgrade-opsmgr.yml

        echo "Applying pcf-pipelines-source patch [$pcfPipelinesSource]  to upgrade-tile pipeline template."
        cp ./upgrade-tile-template.yml ./upgrade-tile-tmp.yml
        cat ./upgrade-tile-tmp.yml | ./yaml_patch -o ../pcf-pipelines/operations/use-pivnet-release.yml > ./upgrade-tile-template.yml

    fi
  fi
}
