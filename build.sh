#!/bin/bash

rm -rf build
mkdir build

nasm dasher.asm -f bin -o build/build.bin