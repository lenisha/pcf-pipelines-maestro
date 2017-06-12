function parseConcourseCredentials() {
  foundation_params_file="${1}"

  # get Concourse information and admin credentials
  export cc_url=$(grep "concourse_url" $foundation_params_file | cut -d " " -f 2)
  export cc_main_user=$(grep "concourse_main_userid" $foundation_params_file | cut -d ":" -f 2 | tr -d " ")
  export cc_main_pass=$(grep "concourse_main_pass" $foundation_params_file | cut -d ":" -f 2 | tr -d " ")
  export cc_user=$(grep "concourse_team_userid" $foundation_params_file | cut -d ":" -f 2 | tr -d " ")
  export cc_pass=$(grep "concourse_team_pass" $foundation_params_file | cut -d ":" -f 2 | tr -d " ")
  export skip_ssl_verification=$(grep "concourse_skip_ssl_verification" $foundation_params_file | cut -d ":" -f 2 | tr -d " ")
}

function loginConcourseTeam() {

    concourse_url="${1}"
    userid="${2}"
    passwd="${3}"
    team="${4}"
    skip_ssl_verification="${5}"
    user_auth_params="-u $userid -p $passwd"
    [ "${userid,,}" == "none" ] && user_auth_params=" ";
    [ "${skip_ssl_verification,,}" == "true" ] && user_auth_params="$user_auth_params -k";
    echo "Performing FLY login to team [$team] of Concourse server $cc_url"
    ./fly -t $team login -c $concourse_url $user_auth_params -n "$team"

}

function createConcourseFoundationTeam() {
  foundation_name="${1}"
  cc_user="${2}"
  cc_pass="${3}"
  admin_team="${4}"

  set +e
  team_existence=$(./fly -t main_team teams | grep $foundation_name)
  set -e
  if [ -z "${team_existence}" ]; then
      echo "Concourse team for foundation [$foundation_name] not found, creating it."
      yes | ./fly -t $admin_team set-team -n $foundation_name --basic-auth-username="$cc_user" --basic-auth-password="$cc_pass"
  else
    echo "Concourse team for foundation [$foundation_name] already exists, skipping its creation"
  fi

}
