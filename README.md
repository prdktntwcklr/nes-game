# NES Game

A game for the Nintendo Entertainment System (NES). Based on Pikuma's *NES
Programming with 6502 Assembly* course. The game is assembled and linked using
```ca65``` and ```ld65``` respectively, both of which are part of the
[cc65](https://www.cc65.org/) project.

## Building the Project

If you have [Docker](https://www.docker.com/) running on your machine, the
easiest way to build the project is to open the workspace file in
[Visual Studio Code](https://code.visualstudio.com/) with the
[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
extension activated. This will allow you to work on the project in a development
environment that comes with all the required packages pre-installed. You can
then simply build the nes file by running a pressing
```Ctrl + Shift + B``` to start the build task.

## Playing the Game

The game can be played by opening the ```build/game.nes``` file in a NES
emulator such as [FCEUX](https://fceux.com/web/home.html).

## Toolchain

- cc65 2.18
- make 4.2.1

## Weblinks

- [Pikuma: NES Programming with 6502 Assembly
](https://pikuma.com/courses/nes-game-programming-tutorial)
- [NESdev Wiki](https://www.nesdev.org/wiki/Nesdev_Wiki)