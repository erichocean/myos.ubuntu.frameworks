#!/bin/bash

SCHEME=$1
TARGET=$2

echo ""

if [ ${SCHEME} = "full" ] ; then
    echo
    echo "=============================================================="
    echo "===== Installing prerequest packages ========================="
    echo
    sudo aptitude -y install libffcall1-dev libffcall1 libffi-dev libxml2-dev clang libtiff-dev libjpeg-dev libicu-dev libx11-dev libxt-dev libxtst-dev libcairo2-dev liblcms1-dev gobjc-4.6 gobjc++ libxslt-dev libgnutls-dev

    read -p "Press [Enter] key to continue..."

    echo
    echo "================================================="
    echo "===== Configuring clang ========================="
    echo
    cd ../../resource/gnustep/core/make
    CC=clang ./configure
    make
    sudo make install

    read -p "Press [Enter] key to continue..."

    echo
    echo "================================================="
    echo "===== Installing libobjc2 ======================="
    echo
    cd ../../dev-libs/libobjc2
    make
    sudo make install

    read -p "Press [Enter] key to continue..."

    echo
    echo "======================================================="
    echo "===== Configuring clang again ========================="
    echo
    cd ../../core/make
    CC=clang ./configure

    read -p "Press [Enter] key to continue..."

    cd ../../../../myuikit/frameworks/
fi

cd Foundation
 
if [ ${SCHEME} = "full" ] ; then
    echo
    echo "================================================================"
    echo "===== Configuraing Foundation =================================="
    echo 

    CC=clang ./configure

    read -p "Press [Enter] key to continue..."

    sudo mkdir /usr/local/include/Foundation/
    sudo cp Headers/Foundation/*.h /usr/local/include/Foundation/
    sudo mkdir /usr/local/include/GNUstepBase/
    sudo cp Headers/GNUstepBase/*.h /usr/local/include/GNUstepBase/

    sudo mkdir /usr/local/include/CoreFoundation/
    sudo mkdir /usr/local/include/CoreGraphics/
    sudo cp ../CoreGraphics/*.h /usr/local/include/CoreGraphics/
    sudo mkdir /usr/local/include/CoreText/
    sudo mkdir /usr/local/include/IOKit/
    sudo mkdir /usr/local/include/OpenGLES/
    sudo mkdir /usr/local/include/CoreAnimation/
    sudo mkdir /usr/local/include/UIKit/

    read -p "Press [Enter] key to continue..."
fi

cd ../CoreFoundation
./install.sh ${SCHEME}
read -p "Press [Enter] key to continue..."

cd ../Foundation
if [ ${SCHEME} = "full" ] ; then
    echo
    echo "=============================================================="
    echo "===== Installing Foundation =================================="
    echo 
    sudo make clean
    make
    sudo make install
    read -p "Press [Enter] key to continue..."
fi

#if [ ${TARGET} = "x11" ] ; then
    cd ../IOKit
#else
#    cd ../IOKit/Android
#fi
./install.sh ${SCHEME} ${TARGET}
read -p "Press [Enter] key to continue..."

cd ../CoreGraphics
./install.sh ${SCHEME}
read -p "Press [Enter] key to continue..."

cd ../CoreText
./install.sh ${SCHEME}
read -p "Press [Enter] key to continue..."

#if [ ${TARGET} = "x11" ] ; then
    cd ../OpenGLES
#else
#    cd ../OpenGLES/EGL
#fi
./install.sh ${SCHEME} ${TARGET}
read -p "Press [Enter] key to continue..."

cd ../CoreAnimation
./install.sh ${SCHEME}
read -p "Press [Enter] key to continue..."

cd ../UIKit
./install.sh ${SCHEME}

