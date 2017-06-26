# Dasher512
![Dasher512](http://i.imgur.com/jRwZMcc.png?1)
## What is it?
*Dasher512* is a bootable Real Mode 16-bit game, that fits 512 bytes.
## Gameplay
Slide from wall to wall, trying to solve a puzzle and reach the finish. The game looks like Atomix, but without atoms.
## Controls
*W/A/S/D* - movement
### Levels
There are only four levels in the game right now, but their count and quality will grow.
## Testing it out
### Building
You will need NASM assembler to assemble sources. Run:
	nasm dasher.asm -f bin -o build/build.bin
Alternatively, you can run on *nix hosts:
	./build.sh
### Running it on emulator
You can use any of major emulators to run a game. Here's an example with `qemu`:
	qemu-system-i386 build/build.bin
Or if you are on *nix host and have `qemu` installed, you can run:
	./run.sh
### Running it on real hardware
You will need a CD/DVD disk, USB stick or even floppy and `dd`. For example, if you want to burn this to USB stick which is /dev/sdc, run following:
	dd if=build/build.bin of=/dev/sdc
Then just reboot your PC and boot from USB stick.