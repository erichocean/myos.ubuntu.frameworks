
source ../common-install.sh

TARGET=x$2
if [ ${TARGET} = "x" ] ; then
    TARGET=x11
else
    TARGET=$2
fi

if [ ${TARGET} = "x11" ] ; then
    cd X11
else
    cd Android
fi

./install.sh ${SCHEME}

cd ../

