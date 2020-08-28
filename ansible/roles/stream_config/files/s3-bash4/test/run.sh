#!/usr/bin/env bash
#
# Run tests for s3-bash4 commands
# (c) 2015 Chi Vinh Le <cvl@winged.kiwi>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -euo pipefail

readonly PROJECT_PATH=$(dirname $(pwd))
readonly SCRIPT_NAME="$(basename $0)"

# Includes
source ${PROJECT_PATH}/lib/s3-common.sh

##
# Print help and exit
# Arguments:
#   $1 int exit code
# Output:
#   string help
##
printUsageAndExitWith() {
  printf "Usage:\n"
  printf "  $SCRIPT_NAME [-k key] [-s file] [-r region] resource_path\n"
  printf "  $SCRIPT_NAME -h\n"
  printf "Example:\n"
  printf "  $SCRIPT_NAME -k key -s secret -r eu-central-1 /bucket/file.ext\n"
  printf "Options:\n"
  printf "  -h,--help\tPrint this help\n"
  printf "  -k,--key\tAWS Access Key ID. Default to environment variable AWS_ACCESS_KEY_ID\n"
  printf "  -r,--region\tAWS S3 Region. Default to environment variable AWS_DEFAULT_REGION\n"
  printf "  -s,--secret\tFile containing AWS Secret Access Key. If not set, secret will be environment variable AWS_SECRET_ACCESS_KEY\n"
  printf "     --version\tShow version\n"
  exit $1
}

##
# Parse command line and set global variables
# Arguments:
#   $@ command line
# Globals:
#   AWS_ACCESS_KEY_ID     string
#   AWS_SECRET_ACCESS_KEY string
#   AWS_REGION            string
#   RESOURCE_PATH         string
##
parseCommandLine() {
  # Init globals
  AWS_REGION=${AWS_DEFAULT_REGION:-""}
  AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""}
  AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-""}

  # Parse options
  local remaining=
  local secretKeyFile=
  while [[ $# > 0 ]]; do
    local key="$1"
    case $key in
      -h|--help)       printUsageAndExitWith 0;;
      -r|--region)     assertArgument $@; AWS_REGION=$2; shift;;
      -k|--key)        assertArgument $@; AWS_ACCESS_KEY_ID=$2; shift;;
      -s|--secret)     assertArgument $@; secretKeyFile=$2; shift;;
      -*)              err "Unknown option $1"
                       printUsageAndExitWith $INVALID_USAGE_EXIT_CODE;;
      *)               remaining="$remaining \"$key\"";;
    esac
    shift
  done

  # Set the non-parameters back into the positional parameters ($1 $2 ..)
  eval set -- $remaining

  # Read secret file if set
  if ! [[ -z "$secretKeyFile" ]]; then
   AWS_SECRET_ACCESS_KEY=$(processAWSSecretFile "$secretKeyFile")
  fi

  # Parse arguments
  if [[ $# != 1 ]]; then
    err "You need to specify the resource path to download e.g. /bucket/file.ext"
    printUsageAndExitWith $INVALID_USAGE_EXIT_CODE
  fi

  assertResourcePath "$1"
  RESOURCE_PATH="$1"

  # Freeze globals
  readonly AWS_REGION
  readonly AWS_ACCESS_KEY_ID
  readonly AWS_SECRET_ACCESS_KEY
  readonly RESOURCE_PATH
}

##
# Main routine
##
main() {
  parseCommandLine $@
  local get="${PROJECT_PATH}/bin/s3-get"
  local put="${PROJECT_PATH}/bin/s3-put"
  local delete="${PROJECT_PATH}/bin/s3-delete"
  local testfile="${PROJECT_PATH}/test/testfile"

  export AWS_DEFAULT_REGION=${AWS_REGION}
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY

  echo "Upload test file to $RESOURCE_PATH"
  "${put}" -T "${testfile}" "${RESOURCE_PATH}"

  echo "Download test file $RESOURCE_PATH"
  "${get}" "${RESOURCE_PATH}"

  echo "Delete test file $RESOURCE_PATH"
  "${delete}" "${RESOURCE_PATH}"
}

main $@
