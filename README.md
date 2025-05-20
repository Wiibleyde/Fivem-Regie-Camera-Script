# FiveM Regie Camera Script

## Description
This script allows you to define multiple cameras in your FiveM server and switch between them using simples controls. It is designed to be used in a "regie" or production environment, where you may want to switch between different camera angles or views.

## Features
- Define multiple cameras with different positions and rotations
- Switch between cameras using keyboard controls
- Define multi types of cameras:
    - Static cameras
    - Traveling cameras
    - Drone cameras

## Installation
1. Download the script from the repository.
2. Place the contents in the `resources` folder of your FiveM server in a folder named `wiibleyde_camera_regie`.
3. Add `ensure wiibleyde_camera_regie` to your `server.cfg` file.

## Configuration
All the configuration is done in the `config.lua` file. You can define your cameras and their properties there. (It's easy to understand, just look at the example in the file)

## Controls
- `E` - **On the zone**: Switch to entering regie mode
- `BACKSPACE` - **In the regie**: Switch to exiting regie mode
- `ARROW RIGHT` - Switch to the next camera
- `ARROW LEFT` - Switch to the previous camera
- `MOUSE WHEEL` - Zoom in/out
- `MOUSE MOVE` - Move the camera
- Traveling cameras:
    - `ENTER` - Start the camera movement
- Drone cameras:
    - `W` - Move forward
    - `S` - Move backward
    - `A` - Move left
    - `D` - Move right
    - `SHIFT` - Move up
    - `CTRL` - Move down

## License
This script is licensed under the GNU General Public License v3.0. You can use, modify, and distribute it under the same license. See the [LICENSE](LICENSE) file for more details.

## Credits
- [wiibleyde](https://github.com/wiibleyde)
- [FiveM](https://fivem.net/)
- [GTA V](https://www.rockstargames.com/games/V)