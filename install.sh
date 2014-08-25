#!/bin/bash

SCHEME=x$1
if [ ${SCHEME} = "x" ] ; then
    SCHEME=x
else
    SCHEME=$1
fi

TARGET=x$2
if [ ${TARGET} = "x" ] ; then
    TARGET=x11
else
    TARGET=$2
fi

./scheme-install.sh ${SCHEME} ${TARGET}

sudo ldconfig

