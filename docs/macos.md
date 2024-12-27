***Note:** I'm using macOS Sonoma (14.2.1) on a 2022 MacBook Air (M2 processor). I don't know if it would work the same way on Macs with M3/4 and intel, you have to test it. The steps I did were as follows:*

## Install dependencies with homebrew
xquartz
ninja
luajit


## Install vcpkg

cd ~ && git clone https://github.com/microsoft/vcpkg
cd ~/vcpkg && ./bootstrap-vcpkg.sh
cd ~

## Download the source

git clone https://github.com/tibia-oce/otclient.git
cd otclient

## Configure xcode and build with Ninja

Even though you have clang installed, it’s still possible that CMake isn’t picking up the required tools. Run:
```
sudo xcode-select --switch /Library/Developer/CommandLineTools
```

```
cd ~/Repos/otclient
rm -rf build
mkdir build && cd build
cmake -G "Ninja" -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build .  
```
