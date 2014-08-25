
source ../common-install.sh

echo
echo "================================================================="
echo "===== Installing CoreAnimation =================================="
echo

if [ ${SCHEME} = "clean" ] || [ ${SCHEME} = "full" ] ; then
    make clean
    sudo cp *.h /usr/local/include/CoreAnimation
fi

make
sudo make install

