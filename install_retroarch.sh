#!/bin/bash
if [[ -d "ROM" ]]; then
  echo "$(tput setaf 6) Let's save some time :) $(tput sgr0)"
  echo "$(tput setaf 2)'ROM' folder was found. Please put all your ROM files in it$(tput sgr0)"
else
  mkdir ROM
  echo "$(tput setaf 3) Creating a 'ROM' folder. Please put all your ROM files in it $(tput sgr0)"
fi
read -p "$(tput setaf 3) If you copied all your ROM files - type 'Yy' and press Enter: $(tput sgr0)" copy_rom

if [[ $copy_rom =~ ^[Yy]$ ]]; then
  echo "$(tput setaf 2) Great, proceeding with the installation $(tput sgr0)"
  echo ""
#else
#  echo "$(tput setaf 1) Aborting installation $(tput sgr0)"
#  exit 1
fi

if [[ -d "Cores" ]]; then
  echo "$(tput setaf 2) 'Cores' folder was found. Please put all your core files in it $(tput sgr0)"
else
  mkdir Cores
  echo "$(tput setaf 3) Creating a 'Cores' folder. Please put all your core files in it $(tput sgr0)"
fi
read -p "$(tput setaf 3) If you copied all your CORE files - type 'Yy' and press Enter: $(tput sgr0)" copy_cores

if [[ $copy_cores =~ ^[Yy]$ ]]; then
  echo "$(tput setaf 2) Great, proceeding with the installation $(tput sgr0)"
  echo ""
#else
#  echo "$(tput setaf 1) Aborting installation $(tput sgr0)"
#  exit 1
fi

echo "$(tput setaf 3) Checking for any previous builds... $(tput sgr0)"
package_name="retroarch"
if dpkg -l "$package_name" >/dev/null 2>&1; then
  echo "$(tput setaf 1) Some other version of RetroArch is installed. Trying to remove: $(tput sgr0)"
  sudo apt update && sudo apt remove retroarch -y && sudo apt autoremove -y
  sleep 3
else
  echo "$(tput setaf 2) RetroArch is not installed. Proceeding with the build $(tput sgr0)"
  sleep 3
fi

echo "$(tput setaf 3) Checking for old configs... $(tput sgr0)"
if [[ -d "/home/$USER/.config/retroarch/" ]]; then
  read -p "$(tput setaf 1) Found existing configuration. Remove? (y/N): $(tput sgr0)" old_config_removal
  if [[ $old_config_removal =~ ^[Yy]$ ]]; then
    sudo rm -rf "/home/$USER/.config/retroarch/"
    echo "$(tput setaf 2) Old config files were successfully removed $(tput sgr0)"
  else
    echo "$(tput setaf 2) Keeping existing configuration. Please remove manually if you experience any issues via $(tput setaf 1)'sudo rm -rf /home/$USER/.config/retroarch/'  $(tput sgr0)"
    sleep 3
  fi
fi
  
echo "$(tput setaf 3) Preparing to clone from GitHub $(tput sgr0)"
if [ ! -d "RetroArch" ]; then
  echo "$(tput setaf 2) Previously cloned files were not found - cloning from GitHub $(tput sgr0)"
  git clone https://github.com/libretro/RetroArch.git
else
  echo "$(tput setaf 1) Found previously cloned files - removing previous builds $(tput sgr0)"
  cd RetroArch && sudo make uninstall
  cd .. && sudo rm -rf RetroArch
  echo "$(tput setaf 3) Cloning from GitHub $(tput sgr0)"
  git clone https://github.com/libretro/RetroArch.git
fi

echo "$(tput setaf 3) Installing the necessary packages: $(tput sgr0)"
sudo apt update && sudo apt install -y git rsync xboxdrv joystick jstest-gtk build-essential libudev-dev libegl-dev libgles-dev libx11-xcb-dev libpulse-dev libasound2-dev libvulkan-dev mesa-vulkan-drivers
sudo apt build-dep -y retroarch

echo "$(tput setaf 3) Listing available RetroArch versions (tags): $(tput sgr0)"
cd RetroArch
sleep 3
available_versions=$(git tag -l)
echo "$(tput setaf 4) $available_versions $(tput sgr0)"
# Get user input for desired version
read -p "$(tput setaf 3) Choose desired version (e.g. v1.9.9): $(tput sgr0)" desired_version
# Check if entered version exists
if ! grep -q "$desired_version" <<< "$available_versions"; then
  echo "$(tput setaf 1) Error: Invalid version. Please choose from the listed options. $(tput sgr0)"
  exit 1
fi
# Switch to the selected version
git checkout "$desired_version"
echo "$(tput setaf 2) Switched to RetroArch version $desired_version. $(tput sgr0)"
sleep 3

echo "$(tput setaf 6) Building and installing Retroarch from source for the Pi 5 with Vulkan support $(tput sgr0)"
sleep 3
echo "$(tput setaf 3) Configuring RetroArch to use Vulkan, Udev and Pulse Audio and disabling X11 and FFMPEG: $(tput sgr0)"
sleep 3
sudo ./configure --enable-vulkan --enable-pulse --enable-ssl --enable-udev --disable-x11 --disable-ffmpeg

echo "$(tput setaf 3) Making it with all available cores: $(tput sgr0)"
sleep 3
sudo make -j$(nproc)

echo "$(tput setaf 2) Make successful. Installing RetroArch: $(tput sgr0)"
sleep 3
sudo make install
cd ..

if [[ -f "/usr/local/bin/retroarch" ]]; then
  echo "$(tput setaf 2) Installation successful! $(tput sgr0)"
  echo "$(tput setaf 3) Initialising RetroArch $(tput sgr0)"
  timeout 3s retroarch

  read -p "$(tput setaf 1) Do you want to restore your config file? (y/N): $(tput sgr0)" config
  if [[ $config =~ ^[Yy]$ ]]; then
    cp "$PWD/retroarch.cfg" "/home/$USER/.config/retroarch/"
    echo "$(tput setaf 2) Config copied successfully $(tput sgr0)"
  fi

  read -p "$(tput setaf 1) Do you want to restore your cores? (y/N): $(tput sgr0)" cores
  if [[ $cores =~ ^[Yy]$ ]]; then
    rsync -av "$PWD/Cores/" "/home/$USER/.config/retroarch/cores/"
    echo "$(tput setaf 2) Cores copied $(tput sgr0)"
  fi

  read -p "$(tput setaf 1) Do you want to restore your ROM files? (y/N): $(tput sgr0)" rom 
  if [[ $rom =~ ^[Yy]$ ]]; then
    rsync -av "$PWD/ROM/" "/home/$USER/.config/retroarch/downloads/"
    echo "$(tput setaf 2) ROMs copied successfully $(tput sgr0)"
  fi
  
  read -p "$(tput setaf 1) Do you want to delete downloaded RetroArch repository files from GitHub? (y/N): $(tput sgr0)" cleanup 
  if [[ $cleanup =~ ^[Yy]$ ]]; then
    if [[ -d "RetroArch" ]]; then
      echo "$(tput setaf 1) Removing GitHub downloads $(tput sgr0)"
      sudo rm -rf "$PWD/RetroArch/"
    else
      echo "$(tput setaf 3) GitHub downloads were not found - moving on $(tput sgr0)"
    fi
  else
    echo "$(tput setaf 3) Ok then, keeping all of the files in place $(tput sgr0)"
  fi

  read -p "$(tput setaf 6) Do you want to launch RetroArch? (y/N): $(tput sgr0)" launch
  if [[ $launch =~ ^[Yy]$ ]]; then
    retroarch
  else
    echo "$(tput setaf 3) Later then :) $(tput sgr0)"
  fi
else
  "$(tput setaf 1) Built may have encountered errors. Try fixing them and run the script again. $(tput sgr0)"
fi
exit 0