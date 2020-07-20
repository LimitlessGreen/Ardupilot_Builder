#!/bin/bash


PLATFORM=$1


PI_TOOLS_REPO=https://github.com/raspberrypi/tools.git
PI_TOOLS_BRANCH=master

ARDUPILOT_REPO=https://github.com/ArduPilot/ardupilot.git

# Get Ardupilot
if [[ ! -d ardupilot ]]; then    
    echo "Download ardupilot"
    git clone --recursive ${ARDUPILOT_REPO}

    pushd ardupilot
        # Install dependencies
    
        if $(apt --version) ; then
        ./Tools/environment_install/install-prereqs-ubuntu.sh -y
        fi

        pip install future
fi

pushd ardupilot
    
    git fetch
    copter_branches=($(git ls-remote --tags | grep -o 'refs/tags/Copter-[0-9]*\.[0-9]*\.[0-9]*' | sort -r | head | grep -o '[^\/]*$'))
    plane_branches=($(git ls-remote --tags | grep -o 'refs/tags/ArduPlane-[0-9]*\.[0-9]*\.[0-9]*' | sort -r | head | grep -o '[^\/]*$'))
    rover_branches=($(git ls-remote --tags | grep -o 'refs/tags/Rover-[0-9]*\.[0-9]*\.[0-9]*' | sort -r | head | grep -o '[^\/]*$'))

    #Take latest branches/tags
    ARDUPILOT_COPTER_BRANCH=${copter_branches[0]}
    ARDUPILOT_PLANE_BRANCH=${plane_branches[0]}
    ARDUPILOT_ROVER_BRANCH=${rover_branches[0]}
    ARDUPILOT_SUB_BRANCH=ArduSub-stable

popd

if [[ "${PLATFORM}" == "pi" ]]; then
    if [ ! -d $(pwd)/tools ]; then
        echo "Downloading Raspberry Pi toolchain"
        git clone -b ${PI_TOOLS_BRANCH} ${PI_TOOLS_REPO} $(pwd)/tools
        export PATH=$(pwd)/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:${PATH}
        echo "Path: ${PATH}"
    else
        git pull
    fi

    ARCH=arm
    PACKAGE_ARCH=armhf
    CROSS_COMPILE=arm-linux-gnueabihf-
fi

# Build
pushd ardupilot

    waf="$PWD/modules/waf/waf-light"
    ${waf} configure --board=navio2

    git checkout ${ARDUPILOT_COPTER_BRANCH}
    git submodule update --init --recursive
    ${waf} copter

    git checkout ${ARDUPILOT_PLANE_BRANCH}
    git submodule update --init --recursive
    ${waf} plane

    git checkout ${ARDUPILOT_ROVER_BRANCH}
    git submodule update --init --recursive
    ${waf} rover

    git checkout ${ARDUPILOT_SUB_BRANCH}
    git submodule update --init --recursive
    ${waf} sub

popd