#!/bin/bash
if [[ -d "ROM" ]]; then
  echo "Let's save you even more time :) "
  echo "'ROM' folder was found. Please put all your ROM files in it"
else
  mkdir ROM
  echo ""
  echo "Creating a 'ROM' folder. Please put all your ROM files in it"
fi
read -p "If you copied all your ROM files - type 'Yy' and press Enter: " copy_rom

if [[ $copy_rom =~ ^[Yy]$ ]]; then
  echo "Great, proceeding with the installation"
else
  exit 1
fi

if [[ -d "Cores" ]]; then
  echo ""
  echo "'Cores' folder was found. Please put all your core files in it"
else
  mkdir Cores
  echo ""
  echo "Creating a 'Cores' folder. Please put all your core files in it"
fi
read -p "If you copied all your core files - type 'Yy' and press Enter: " copy_cores

if [[ $copy_cores =~ ^[Yy]$ ]]; then
  echo "Great, proceeding with the installation"
else
  exit 1
fi

echo "------"
echo "Checking for any previous builds"
package_name="retroarch"
if dpkg -l "$package_name" >/dev/null 2>&1; then
  echo "Some other version of RetroArch is installed. Trying to remove:"
  sudo apt update && sudo apt remove retroarch -y && sudo apt autoremove -y
  sleep 3
else
  echo "RetroArch is not installed. Proceeding with the build"
  sleep 3
fi

echo "------"
echo "Clone RetroArch repository (if not already present)"
if [ ! -d RetroArch ]; then
  git clone https://github.com/libretro/RetroArch.git
else
  cd RetroArch && sudo make uninstall
  cd .. && sudo rm -rf RetroArch
  git clone https://github.com/libretro/RetroArch.git
fi

echo "------"
echo "Installing the necessary packages: "
sudo apt update && sudo apt install -y git rsync xboxdrv joystick jstest-gtk build-essential libudev-dev libegl-dev libgles-dev libx11-xcb-dev libpulse-dev libasound2-dev libvulkan-dev mesa-vulkan-drivers
sudo apt build-dep -y retroarch

echo "------"
echo "Listing available RetroArch versions (tags): "
cd RetroArch
sleep 3
available_versions=$(git tag -l)
echo "$available_versions"
# Get user input for desired version
read -p "Enter the desired version (e.g. v1.9.9): " desired_version
# Check if entered version exists
if ! grep -q "$desired_version" <<< "$available_versions"; then
  echo "Error: Invalid version. Please choose from the listed options."
  exit 1
fi
# Switch to the selected version
git checkout "$desired_version"
echo "Switched to RetroArch version $desired_version."
sleep 3

echo "------"
echo "Building and installing Retroarch from source for the Pi 5 with Vulkan support: "
echo "------"
echo "Configuring RetroArch to use Vulkan, Udev and Pulse Audio and disabling X11 and FFMPEG:"
sleep 3
sudo ./configure --enable-vulkan --enable-pulse --enable-ssl --enable-udev --disable-x11 --disable-ffmpeg

echo "------"
echo "Making it with all cores:"
sleep 3
sudo make -j$(nproc)

echo "------"
echo "Make successful. Installing RetroArch:"
sleep 3
sudo make install

echo "------"
echo "Installation successful!"
cd ..
echo "Initialising RetroArch"
timeout 3s retroarch

read -p "Do you want to restore your config file? (y/N): " config
if [[ $config =~ ^[Yy]$ ]]; then
  cp "$PWD/retroarch.cfg" "/home/$USER/.config/retroarch/"
fi

read -p "Do you want to restore your cores? (y/N): " cores
if [[ $cores =~ ^[Yy]$ ]]; then
  rsync -av "$PWD/Cores/" "/home/$USER/.config/retroarch/cores/"
fi

read -p "Do you want to restore your ROM files? (y/N): " rom 
if [[ $rom =~ ^[Yy]$ ]]; then
  rsync -av "$PWD/ROM/" "/home/$USER/.config/retroarch/downloads/"
fi

read -p "Do you want to launch RetroArch? (y/N): " launch
if [[ $launch =~ ^[Yy]$ ]]; then
  retroarch
else
  echo "Ok then :)"
fi

exit 0