
source ../common-install.sh

TARGET=x$2
if [ ${TARGET} = "x" ] ; then
    TARGET=x11
else
    TARGET=$2
fi

if [ ${TARGET} = "x11" ] ; then
    cd GLX
else
    cd EGL
fi
./install.sh ${SCHEME}
cd ../

