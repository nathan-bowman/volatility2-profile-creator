#!/bin/bash
#
# vol2-profile-creator - Nathan Bowman
# https://github.com/nathan-bowman/volatility2-profile-creator
#
# Use this script to create a volatility2 profile
# 
# Refactored code from Hal Pomeranz (https://github.com/halpomeranz/lmg)

# Check for root
if [[ $EUID != 0 ]]; then
    echo This script must run as root!
    exit 255;
fi

## Vars
# **** use export so Makefile has access to the vars ****
export KVER=$(uname -r)                    # e.g., "3.2.0-41-generic"
export CPU=$(uname -m)                     # typically "x86_64" or "i686"
HOST=$(hostname)
TIMESTAMP=$(date '+%F_%H.%M.%S')    # YYYY-MM-DD_hh.mm.ss
TARGETDIR="profile"

while getopts "d:h" opt; do
  case $opt in
      d)
	  TARGETDIR=$OPTARG
	  ;;
      h)
	  echo "Usage: $0 [-d outputdir]"
	  exit 0
	  ;;
  esac
done

# Figure out where the tool is being run from and create an absolute pathname.
#
TOOLDIR=$(dirname $0)
[[ $(echo $TOOLDIR | cut -c1) != "/" ]] && TOOLDIR=$(pwd)/$TOOLDIR
export TOOLDIR=$(echo $TOOLDIR | sed 's/\/\.*$//')
TARGETDIR=${TARGETDIR:=$TOOLDIR}

# Create absolute pathnames for TARGETDIR 
[[ $(echo $TARGETDIR | cut -c1) != "/" ]] && TARGETDIR=$(pwd)/$TARGETDIR
TARGETDIR=$(echo $TARGETDIR | sed 's/\/\.*$//')

if [ ! -d ${TARGETDIR} ]; then
    mkdir -p ${TARGETDIR} 
fi

# We want a copy of the local bash executable so we can find the offset
# of the history data structure.
echo -n Grabbing a copy of /bin/bash...
cp /bin/bash ${TARGETDIR}/${HOST}-${TIMESTAMP}-bash
echo Done!


# Generate a volatilityrc prototype. Use with:
#    vol.py --conf-file=/path/to/capture/dir/volatilityrc
echo -n Writing volatilityrc to ${TARGETDIR}...
ARCH=x$(echo ${CPU} | sed 's/.*\(..\)/\1/')
PROFILE=$(echo Linux-${HOST}-${TIMESTAMP}-profile${ARCH} | sed 's/\./_/g')
cat >${TARGETDIR}/volatilityrc <<EOF
[DEFAULT]
PLUGINS=${CAPTUREDIR}
PROFILE=${PROFILE}
EOF
echo Done!

# Build module.c against kernel headers found on local system and
# with System.map from local /boot directory.
make -f ${TOOLDIR}/volatility/Makefile -C ${TOOLDIR}/volatility/ clean dwarf

# Profile ends up in $CAPTUREDIR with memory image
zip ${TARGETDIR}/${HOST}-${TIMESTAMP}-profile.zip ${TOOLDIR}/volatility/module.dwarf /boot/System.map-$KVER

# Clean up
rm -f ${TOOLDIR}/volatility/module.dwarf

# Some debugs
echo
echo "## DEBUG ##"
echo "TOOLDIR: ${TOOLDIR}"
echo "TARGETDIR: ${TARGETDIR}"
echo "KVER: ${KVER}"
echo "CPU: ${CPU}"
echo "HOST: ${HOST}"
echo "TIMESTAMP: ${TIMESTAMP}"
echo "Profile: ${TARGETDIR}/${HOST}-${TIMESTAMP}-profile.zip"
