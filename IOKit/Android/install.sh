
echo "================================================================="
echo "===== Installing IOKit =========================================="
echo

if [ $1 = "clean" ] || [ $1 = "full" ] ; then
    make clean
    sudo cp *.h /usr/local/include/IOKit
fi

make
sudo make install

