#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing micro-xrce-dds-agent"

service_uninstall dds-agent

#sudo snap install micro-xrce-dds-agent --edge

cd
sudo snap remove micro-xrce-dds-agent #Removing the snap restricted version of the DDS-Agent
git clone https://github.com/eProsima/Micro-XRCE-DDS-Agent.git #Building DDS-Agent from Source
cd Micro-XRCE-DDS-Agent
mkdir build && cd build
cmake ..
make
sudo make install

service_add_manifest dds-agent

service_install dds-agent
