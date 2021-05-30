# EasyFPGA-RedChase

A little game made with the RZ-EasyFPGA A2.2 board!

Builds upon the project available at [EasyFPGA-VGA](https://github.com/fsmiamoto/EasyFPGA-VGA). 
You can checkout the README there for more details on how to flash the code to your board.

![Game Preview](https://media.giphy.com/media/CBPTyNnaq6yI1KIXz7/giphy.gif)

## Board interfaces

The following I/O interfaces of the board were used in this project:

- VGA: Used for displaying the game
- PS2: Attached to a keyboard for use as a input
- 7 Segment displays: Used to show the current score
- Push-buttons: Used for resetting the game

<img src="./docs/RedChase.png" height="400"/>

## Gameplay

The mechanics of the game are pretty simple:
 Avoid hitting the edges of the screen while chasing the red apple for scoring extra points.

But here's the catch, every time you score the speed of the green square increases.
As you continue to gather points, it will become increasingly difficult to catch the next
red apple and avoid the edges.

## Contributing

If you'd like to contribute with any fixes or improvements, feel free to open a PR or create an issue.
