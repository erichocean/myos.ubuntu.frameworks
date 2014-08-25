
source ../../common-install.sh

echo "================================================================="
echo "===== Installing OpenGLES ======================================="
echo

if [ ${SCHEME} = "full" ] ; then
#    sudo aptitude install -y libgl1-mesa-dev
    sudo aptitude -y install mesa-utils libgl1-mesa-dev-lts-quantal
#    sudo aptitude install -y libgles1-mesa-dev
fi

if [ ${SCHEME} = "clean" ] || [ ${SCHEME} = "full" ] ; then
    make clean
    sudo cp *.h /usr/local/include/OpenGLES
fi

make
sudo make install

