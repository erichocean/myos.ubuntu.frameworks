
source ../common-install.sh

echo
echo "================================================================="
echo "===== Installing CoreGraphics ==================================="
echo

if [ ${SCHEME} = "clean" ] || [ ${SCHEME} = "full" ] ; then
    make clean
    sudo cp *.h /usr/local/include/CoreGraphics
fi

make
sudo make install

