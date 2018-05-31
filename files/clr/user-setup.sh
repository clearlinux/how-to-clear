#!/bin/bash

SCRIPT=$(/usr/bin/basename $0)
PEM=""
SERVERCA=""
CLIENTCA=""
WORKSPACE="clearlinux"
PACKAGE_REPOS=

help() {
  printf "%s\n" >&2 "Usage: $SCRIPT [options]" \
    "" \
    "Options:" \
    "" \
    "-d --directory NAME: Set up workspace in the given directory." \
    "-a --clone-packages: Clone all package repos." \
    "-j --jobs [NUM]: Clone repos with NUM jobs. If NUM is not given, it is set to the available CPU count." \
    "" \
    "-k --client-cert PEM_FILE: Enable client user cert for koji configuration; requires a PEM file argument" \
    "-s --server-ca PEM_FILE: Enable server CA cert for koji configuration; requires a PEM file argument" \
    "-c --client-ca PEM_FILE: Enable client CA cert for koji configuration; requires a PEM file argument" \
    ""
}

error() {
  echo -e "Error: $1\n" >&2
  help
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    "--help"|"-h")
      help
      exit 0
      ;;
    "--client-cert"|"-k")
      shift
      PEM="$(realpath $1)"
      ;;
    "--server-ca"|"-s")
      shift
      SERVERCA="$(realpath $1)"
      ;;
    "--client-ca"|"-c")
      shift
      CLIENTCA="$(realpath $1)"
      ;;
    "--jobs"|"-j")
      if echo "$2" | grep -qx "[1-9][0-9]*"; then
        shift
        JOBS="$1"
      elif [ -f /proc/cpuinfo ]; then
        JOBS=$(grep -Ec '^processor.*:.*[0-9]+$' /proc/cpuinfo)
      fi
      ;;
    "--directory"|"-d")
      [ -z "$2" ] && error "Must supply a directory name to the -d option"
      [ "${2:0:1}" = "-" ] && error "Directory name cannot begin with \"-\""
      shift
      WORKSPACE="$1"
      ;;
    "--clone-packages"|"-a")
      PACKAGE_REPOS=1
      ;;
    *)
      help
      exit 1
      ;;
  esac
  shift
done


if [ -z "$PEM" ] && [ -z "$SERVERCA" ] && [ -z "$CLIENTCA" ]; then
  USE_KOJI=
else
  if [ -z "$PEM" ] || [ -z "$SERVERCA" ] || [ -z "$CLIENTCA" ]; then
    error "Must specify all three command line options (or none)"
  fi
  if [ ! -f "$PEM" ]; then
    error "Missing koji client PEM key file"
  fi
  if [ ! -f "$SERVERCA" ]; then
    error "Missing koji server CA PEM file"
  fi
  if [ ! -f "$CLIENTCA" ]; then
    error "Missing koji client CA PEM file"
  fi
  USE_KOJI="yes"
fi

if [ -n "$JOBS" ]; then
  JOBS_ARG="-j $JOBS"
fi

if [ -d "$WORKSPACE" ]; then
  error "Directory \"$WORKSPACE\" already exists. \
Either remove this workspace, or use a different workspace name."
fi

required_progs() {
  local bindir="/usr/bin"
  for f in git mock rpm rpmbuild ; do
    [ ! -x "${bindir}/${f}" ] && missing+="${f} "
  done
  [ "$PEM" ] && [ ! -x /usr/bin/koji ] && missing+="koji "
  if [ -n "$missing" ]; then
    echo "Install the following programs and re-run this script:" >&2
    echo $missing >&2
    echo 'All programs should be provided in the "os-clr-on-clr" bundle.' >&2
    exit 1
  fi
}

required_progs

echo "Initializing development workspace in \"$WORKSPACE\" . . ."

mkdir "$WORKSPACE"
cd "$WORKSPACE"

echo "Setting up common repo . . ."
mkdir projects
git clone https://github.com/clearlinux/common projects/common
if [ $? -ne 0 ]; then
  echo "Failed to clone common repo." >&2
  exit 1
fi

# Finish setup for packages/projects hierarchy
ln -sf projects/common/Makefile.toplevel Makefile
mkdir -p packages/common
ln -sf ../../projects/common/Makefile.common packages/common/Makefile.common

if [ "$USE_KOJI" ]; then
  echo "Setting up koji certs . . ."
  mkdir -p ~/.koji
  cp "$PEM" ~/.koji/client.crt
  cp "$CLIENTCA" ~/.koji/clientca.crt
  cp "$SERVERCA" ~/.koji/serverca.crt

  if [ ! -f /etc/koji.conf ]; then
    echo "Setting up koji config . . ."
    sudo cp projects/common/conf/koji.conf /etc
  fi
fi

echo "Adding user to kvm group . . ."
sudo usermod -a -G kvm $USER

echo "Cloning special project repositories . . ."
make ${JOBS_ARG} clone-projects

if [ -n "$PACKAGE_REPOS" ]; then
  echo "Cloning all package repositories . . ."
  make ${JOBS_ARG} clone-packages
fi

echo "Creating mix workspace . . ."
mkdir -p mix

if [ "$USE_KOJI" ]; then
  echo "Testing koji installation . . ."
  if koji moshimoshi; then
    echo -en "\n************************\n\n"
    echo "Koji installed and configured successfully"
  else
    echo -en "\n************************\n\n"
    echo "Error with koji installation or configuration" >&2
    exit 1
  fi
fi

echo -en "\n************************\n"

echo "Workspace has been set up in \"$WORKSPACE\""
if [ -z "$PACKAGE_REPOS" ]; then
  echo "NOTE: To clone all package repos, run \"cd $WORKSPACE; make [-j NUM] clone-packages\""
  echo "NOTE: To clone a single package repo with NAME, run \"cd $WORKSPACE; make clone_NAME\""
fi
echo 'NOTE: logout and log back in to finalize the setup process'


# vi: ft=sh sw=2 et sts=2
