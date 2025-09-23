#!/bin/bash
echo "Installing micro-xrce-dds-agent"
cd $HOME              # Ensure home directory as working location

# Remove the snap-restricted DDS-Agent if present
sudo snap remove micro-xrce-dds-agent

# Clone the Micro XRCE DDS Agent repository directly into $HOME
git clone --recurse-submodules https://github.com/eProsima/Micro-XRCE-DDS-Agent.git

cd Micro-XRCE-DDS-Agent
mkdir build && cd build
cmake ..
make
sudo make install

