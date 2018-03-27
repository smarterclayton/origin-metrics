#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

STARTTIME=$(date +%s)
source_root=$(dirname "${0}")/..

prefix="openshift/origin-"
version="latest"
verbose=false
dev_build=false
build_args=""
options=""
help=false

for args in "$@"
do
  case $args in
      --prefix=*)
        prefix="${args#*=}"
        ;;
      --version=*)
        version="${args#*=}"
        ;;
      --no-cache)
        options="${options} --no-cache"
        ;;
      --verbose)
        verbose=true
        ;;
     --dev)
        dev_build=true
        ;;
     --help)
        help=true
        ;;
  esac
done

# allow ENV to take precedent over switches
prefix="${PREFIX:-$prefix}"
version="${OS_TAG:-$version}" 

if [ "$help" = true ]; then
  echo "Builds the docker images for metrics"
  echo
  echo "Options: "
  echo "  --prefix=PREFIX"
  echo "  The prefix to use for the image names."
  echo "  default: openshift/origin-"
  echo
  echo "  --version=VERSION"
  echo "  The version used to tag the image"
  echo "  default: latest"
  echo 
  echo "  --no-cache"
  echo "  If set will perform the build without a cache."
  echo
  echo "  --verbose"
  echo "  Enables printing of the commands as they run."
  echo
  echo "  --dev"
  echo "  Specifies that this is a dev build."
  echo
  echo "  --help"
  echo "  Prints this help message"
  echo
  exit 0
fi

if [ "$dev_build" = true ]; then
  build_args="--build-arg DEV_BUILD=true"
fi

if [ "$verbose" = true ]; then
  set -x
fi

for component in deployer heapster hawkular-metrics hawkular-metrics-schema cassandra; do
  BUILD_STARTTIME=$(date +%s)
  comp_path=$source_root/$component/
  docker_tag=${prefix}metrics-${component}:${version}
  echo
  echo
  echo "--- Building component '$comp_path' with docker tag '$docker_tag' ---"
  docker build ${options} ${build_args} -t $docker_tag $comp_path
  BUILD_ENDTIME=$(date +%s); echo "--- $docker_tag took $(($BUILD_ENDTIME - $BUILD_STARTTIME)) seconds ---"
  echo
  echo
done

echo
echo
echo "++ Active images"
docker images | grep ${prefix}metrics | grep ${version} | sort
echo


ret=$?; ENDTIME=$(date +%s); echo "$0 took $(($ENDTIME - $STARTTIME)) seconds"; exit "$ret"
