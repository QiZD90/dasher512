# Dasher512
![Dasher512](http://i.imgur.com/jRwZMcc.png?1)
## What is it?
**Dasher512** is a bootable Real Mode 16-bit game, that fits in 512 bytes.
## Gameplay
Slide from wall to wall, trying to solve a puzzle and reach the finish. The game looks like Atomix, but without atoms.
## Controls
**Arrow keys** - movement
### Levels
There are only two levels in the game right now, but their count and quality will grow.
## Testing it out
### Building
**NASM** assembler is necessary for build.
### Running it on emulator
You can use any of major emulators to run the game. Here's an example with **QEMU**:

	qemu-system-i386 build/build.bin
### Running it on real hardware
You will need a CD/DVD disk, USB stick or even a floppy and `dd`. For example, if you want to burn this to USB stick which is /dev/sdc, run a following:

    dd if=build/build.bin of=/dev/sdc
Then just reboot your PC and boot from the USB stick.
