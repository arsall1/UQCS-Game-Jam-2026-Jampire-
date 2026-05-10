# UQCS-Game-Jam-2026-Jampire-
Not quite a full game, but a proof of concept of how pixel art can be elegantly warped/curved to create interesting game level designs. This game also includes a Rayleigh atmospheric scattering system inspired by Sebastian Lague.

To play the game, simply download and extract the zip file, and double-click on the jampire.exe file.
The "game" folder contains all the raw lua code and asset files (prior to converting it to executable). 

This was made in LOVE2D. love2d.org
All textures were made in GIMP.
The level was designed using the Tiled Level Editor

The idea is original, however, AI (Specifically ChatGPT) was used frequently to debug the code and to find out what I was missing in my implementation of certain shaders, such as atmosphere.glsl. The code in atmosphere.glsl was inspired by the work of Sebastian Lague, though it was not plagiarised; his implementation is suited for Unity, whereas I adapted it for LOVE2D.

Note that certain texture's do not render sometimes; this was a bug I was unable to fix within the time constraints. If you rerun the game multiple times it might render those textures properlly eventually :/

