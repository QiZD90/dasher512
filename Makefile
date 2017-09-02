all:
	rm -rf build
	mkdir build
	nasm -f bin dasher.asm -o build/dasher.bin
