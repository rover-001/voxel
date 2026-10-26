import QtQuick
import qs.Commons

// A single, large voxel word. Keeping the letters in one card makes the
// baseline and spacing deterministic instead of relying on five loose cards.
Item {
  id: root

  property real widgetScale: 4.2
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true

  readonly property real unit: Math.round((Style.space(8) * root.widgetScale) / 2) * 2
  readonly property int cellWidth: 5
  readonly property int cellGap: 1
  readonly property int wordColumns: 5 * cellWidth + 4 * cellGap
  readonly property real depth: unit * 0.34

  // 5x7 glyphs are intentionally chunky: they remain readable on a busy
  // wallpaper and leave a clear gap between every letter.
  readonly property var glyphs: [
    ["11110", "10001", "10001", "11110", "10100", "10010", "10001"], // R
    ["10001", "10001", "10001", "10001", "10001", "10001", "01110"], // O
    ["11110", "10001", "10001", "11110", "10000", "10000", "10000"], // V
    ["10001", "10001", "10001", "10101", "10101", "11011", "10001"], // E
    ["11111", "00100", "00100", "00100", "00100", "00100", "00100"]  // R
  ]

  implicitWidth: wordColumns * unit + depth * 2
  implicitHeight: 7 * unit + depth * 2
  width: implicitWidth
  height: implicitHeight

  onWidgetScaleChanged: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    renderTarget: Canvas.FramebufferObject

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var s = root.unit
      var ox = Math.round(root.depth)
      var oy = Math.round(root.depth)
      var top = root.accentColor ? root.accentColor.toString() : "#38bdf8"
      var left = "#1d4ed8"
      var right = "#1e3a8a"

      function cube(x, y) {
        var d = root.depth
        ctx.fillStyle = top
        ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + s, y)
        ctx.lineTo(x + s + d, y - d * 0.5); ctx.lineTo(x + d, y - d * 0.5)
        ctx.closePath(); ctx.fill()
        ctx.fillStyle = left
        ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + d, y - d * 0.5)
        ctx.lineTo(x + d, y + s - d * 0.5); ctx.lineTo(x, y + s)
        ctx.closePath(); ctx.fill()
        ctx.fillStyle = right
        ctx.beginPath(); ctx.moveTo(x + s, y); ctx.lineTo(x + s + d, y - d * 0.5)
        ctx.lineTo(x + s + d, y + s - d * 0.5); ctx.lineTo(x + s, y + s)
        ctx.closePath(); ctx.fill()
      }

      for (var letter = 0; letter < root.glyphs.length; letter++) {
        var glyph = root.glyphs[letter]
        var colOffset = letter * (root.cellWidth + root.cellGap)
        for (var row = 0; row < glyph.length; row++) {
          for (var col = 0; col < glyph[row].length; col++) {
            if (glyph[row][col] === "1") cube(ox + (colOffset + col) * s, oy + row * s)
          }
        }
      }
    }
  }
}
