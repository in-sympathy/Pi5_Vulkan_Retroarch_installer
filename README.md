Welcome!

Due to reinstalling an operating system on my Raspberry Pi 5 from time to time and then having to reinstall RetroArch from source manually every time I decided to automate this process a little with this simple bash script. It will do the following for you:
1. Ask if you have any ROM and Core files you want to use with RetroArch and offer you to manually copy those files into the corresponding ROM and Cores folders it'll create for you if needed.
2. Check if you have a previously installed RetroArch via apt and remove it along with any unnecessary packages.
3. Download RetroArch source files from an official GitHub repo.
4. Install all the necessary dependencies so you could have Vulkan, Pulse Audio and joystick support.
5. List all available RetroArch versions so you could choose the one you want to build. I tested it with v1.8.4 and v1.9.9 - the latter is recommeded.  
6. Build RetroArch properly to work on a Pi 5 with Vulkan and Wayland.
7. Offer to restore your RetroArch config, ROM and Cores from a backup if you have it.
8. Offer to remove downloaded RetroArch repository files from GitHub after successful build.
9. Launch and try RetroArch. 
10. Enjoy 🙌🏻
