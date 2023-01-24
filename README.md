# NES Game

A game for the Nintendo Entertainment System (NES). Based on Pikuma's *NES
Programming with 6502 Assembly* course.

The game is assembled and linked using ```ca65``` and ```ld65``` respectively,
both of which are part of the [cc65](https://www.cc65.org/) project. To build
the project, simply run ```make``` in the project directory. The game can then
be played by opening the ```build/game.nes``` file in a NES emulator such as
[FCEUX](https://fceux.com/web/home.html).

## Toolchain

- cc65 2.18
- make 4.2.1

## Weblinks

- [Pikuma: NES Programming with 6502 Assembly
](https://pikuma.com/courses/nes-game-programming-tutorial)
- [NESdev Wiki](https://www.nesdev.org/wiki/Nesdev_Wiki)