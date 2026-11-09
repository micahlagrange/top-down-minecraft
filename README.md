# Topsoil

A top-down tile sandbox: walk a small hand-shaped map of grass and stone, tunnel into the rock outcrop in the middle and dig out the coal, iron and gold hidden in it. Made with LÖVE and played in the browser through love.js.

The grass half grows trees: chop them for wood, and sometimes an apple falls out. A hunger bar drains over about three minutes; eat an apple to refill it, or at empty you walk and mine at half speed.

Walk with WASD or the arrow keys and hold Space, or hold the mouse on a block or tree, to mine or chop it. F (or Q) eats an apple. On a phone, drag on the left half of the screen to walk, hold MINE (CHOP when facing a tree), or hold a block, and tap EAT.

## Run it

- Desktop: `love .` with LÖVE 11.4.
- Tests: `pip install lupa`, then `python tst/run.py`.
- Web build: `python -m makelove`, then `python tools/patch_lovejs.py makelove-build/lovejs/topsoil-lovejs.zip`.
- Screenshots: set `TOPSOIL_AUTOPLAY=1` and run `love .`; `tst/autoplay.lua` walks into the rock, mines, saves `shot-N.png` to the save folder and quits.

CI (`.github/workflows`) tests every push and publishes the love.js build to itch from `main`.
