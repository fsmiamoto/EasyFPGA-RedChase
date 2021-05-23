# EasyFPGA-RedChase

A little game made with the RZ-EasyFPGA A2.2 board!

Builds upon the project available at [EasyFPGA-VGA](https://github.com/fsmiamoto/EasyFPGA-VGA). 
You can checkout the README there for more details on how to flash the code to your board.

[Game Preview](https://user-images.githubusercontent.com/20388082/119267430-eda61200-bbc4-11eb-8854-7cf4896520ca.mp4)

## Board interfaces

The following I/O interfaces of the board were used in this project:

<table>
<td>
   <ul>
      <li>VGA: Used for displaying the game</li>
      <li>PS2: Attached to a keyboard for use as a input</li>
      <li>7 Segment displays: Used to show the current score</li>
      <li>Push-buttons: Used for resetting the game.</li>
   </ul>
</td>
<td>
   <img src="./docs/interfaces.jpg" height="400"/>
</td>
</table>

## Gameplay

The mechanics of the game are pretty simple:
 Avoid hitting the edges of the screen while chasing the red apple for scoring extra points.

But here's the catch, every time you score the speed of the green square increases.
As you continue to gather points, it will become increasingly difficult to catch the next
red apple and avoid the edges.

## Contributing

If you'd like to contribute with any fixes or improvements, feel free to open a PR or create an issue.
