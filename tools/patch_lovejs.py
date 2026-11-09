#!/usr/bin/env python3
"""Make the love.js page fill the browser window.

makelove's love.js template centres a fixed-size canvas under a heading. On a
phone and in itch's embed the canvas should be the whole viewport (less the
safe-area insets), with no page scrolling or pinch zoom, so the game gets a
resize event and lays its HUD and touch controls out for that screen.

Usage: patch_lovejs.py <path-to-lovejs-zip-or-index.html>
"""
import io
import sys
import zipfile

STYLE = """
<style>
  html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #141418; }
  html { box-sizing: border-box; padding: env(safe-area-inset-top, 0px) env(safe-area-inset-right, 0px) env(safe-area-inset-bottom, 0px) env(safe-area-inset-left, 0px); }
  center, center > div { width: 100%; height: 100%; margin: 0; padding: 0; }
  h1, footer { display: none; }
  #canvas { display: block; width: 100%; height: 100%; touch-action: none; visibility: hidden; }
  #loadingCanvas { position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%); max-width: 100%; max-height: 100%; }
</style>
</head>"""

# The canvas can change size without the window doing so; tell the game.
RESIZE = """
<script>
(function () {
  var c = document.getElementById('canvas'), last = '';
  function check() {
    var r = c.getBoundingClientRect(), k = Math.round(r.width) + 'x' + Math.round(r.height);
    if (k !== last) { last = k; window.dispatchEvent(new Event('resize')); }
  }
  if (window.ResizeObserver) new ResizeObserver(check).observe(c);
  window.addEventListener('orientationchange', function () { setTimeout(check, 300); });
  setInterval(check, 1000);
})();
</script>
</body>"""


def patch_html(html: str) -> str:
    if 'touch-action: none' in html:
        return html
    html = html.replace('</head>', STYLE, 1)
    html = html.replace('</body>', RESIZE, 1)
    return html.replace('maximum-scale=1">', 'maximum-scale=1, user-scalable=no, viewport-fit=cover">', 1)


def patch_zip(path: str) -> None:
    with zipfile.ZipFile(path) as zin:
        entries = [(i, zin.read(i.filename)) for i in zin.infolist()]
    out = io.BytesIO()
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zout:
        for info, data in entries:
            if info.filename.endswith('index.html'):
                data = patch_html(data.decode('utf-8')).encode('utf-8')
            zout.writestr(info, data)
    with open(path, 'wb') as f:
        f.write(out.getvalue())


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    if path.endswith('.zip'):
        patch_zip(path)
    else:
        with open(path, encoding='utf-8') as f:
            html = f.read()
        with open(path, 'w', encoding='utf-8') as f:
            f.write(patch_html(html))
    print('patched', path)


if __name__ == '__main__':
    main()
