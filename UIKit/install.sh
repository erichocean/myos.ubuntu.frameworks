
source ../common-install.sh

echo
echo "=============================================================="
echo "===== Installing UIKit ======================================="
echo

if [ ${SCHEME} = "clean" ] || [ ${SCHEME} = "full" ] ; then
    sudo make clean
    sudo cp *.h /usr/local/include/UIKit
fi

make
sudo make install

