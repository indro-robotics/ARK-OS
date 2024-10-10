ARK-OS is a collection of software packages that provide common tools for drone systems. These software packages are installed as systemd user services and provide useful features such as mavlink routing, video streaming, automatic log upload, firmware updating and more.

# Getting started
Run the install script on the device. This script will prompt you Y/N to install various software. You can skip the interactive prompt by copying the **default.env** file and renaming it **user.env**. You can adjust the options in the **user.env**.
```
./install.sh
```
This script can be safely run multiple times to update your system.

#### Supported targets
- **ARK Jetson Carrier** <br> https://arkelectron.com/product/ark-jetson-pab-carrier/
- **ARK Pi6X Flow** <br> https://arkelectron.com/product/ark-pi6x-flow/


## Services
When running the **install.sh** script you will be prompted to install the below services. The services are installed as [systemd user services](https://www.unixsysadmin.com/systemd-user-services/) and conform to the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/index.html). If yo

### Jetson and Pi

**mavlink-router.service** <br>
This service enables mavlink-router to route mavlink packets between endpoints. The **platform/`target`/main.conf** file defines these endpoints and is installed at **~/.local/share/mavlink-router/main.conf**. The USB on the FMU is connected directly to the companion for a reliable high speed chip to chip connection.

**dds-agent.service** <br>
Bridges PX4 uORB pub/sub with ROS2. This service starts the DDS agent which connects with the PX4 uXRCE-DDS-Client. The FMU `Telem1` port is connected directly to the Jetson UART. This service depends on the `systemd-timesyncd` service to synchronize system time with an accurate remote reference time source.

**logloader.service** <br>
This service downloads log files from the SD card of the flight controller via MAVLink and optionally uploads them to [PX4 Flight Review](https://review.px4.io/). <br>

**flight-review.service** <br>
This service hosts a local PX4 Flight Review server on port 5006 <br>

**rtsp-server.service** <br>
This service provides an RTSP server via gstreamer using a Pi cam at **rtsp://`target`.local:8554/fpv** <br>

**polaris.service** <br>
This service receives RTCM corrections from the PointOne GNSS Corrections service and publishes them via MAVLink.

**ark-ui-backend.service** <br>
This service provides an express backend for the ark-ui configuration UI. The ARK UI is hosted via nginx at **`target`.local** and provides tools such as firmware updating, wifi hotspot configuration, log viewing (coming soon), and more.

**hotspot-control.service** <br>
This service creates a hotspot after booting if the device is unable to auto connect to a network. You can then use the ARK UI to configure your network.

### Jetson only

**rid-transmitter.service** <br>
This service starts the RemoteIDTransmitter service which broadcasts RemoteID data via Bluetooth.

**jetson-can.service** <br>
This service enables the Jetson CAN interface.

**jetson-clocks.service** <br>
This service sets the Jetson clocks to their maximum rate.
