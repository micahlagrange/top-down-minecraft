# Topsoil

A top-down tile sandbox: walk a small hand-shaped map of grass and stone, tunnel into the rock outcrop in the middle and dig out the coal, iron and gold hidden in it. Made with LÖVE and played in the browser through love.js.

Walk with WASD or the arrow keys and hold Space, or hold the mouse on a block, to mine it. On a phone, drag on the left half of the screen to walk and hold MINE, or hold a block, to mine.

## Run it

- Desktop: `love .` with LÖVE 11.4.
- Tests: `pip install lupa`, then `python tst/run.py`.
- Web build: `python -m makelove`, then `python tools/patch_lovejs.py makelove-build/lovejs/topsoil-lovejs.zip`.
- Screenshots: set `TOPSOIL_AUTOPLAY=1` and run `love .`; `tst/autoplay.lua` walks into the rock, mines, saves `shot-N.png` to the save folder and quits.

CI (`.github/workflows`) tests every push and publishes the love.js build to itch from `main`.
