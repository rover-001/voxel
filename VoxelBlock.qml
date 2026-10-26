import QtQuick
import qs.Commons

// VoxelBlock — Single modular 3D isometric building block with magnetic snap grid.
// Textures: grass, stone, wood, brick, gold, obsidian, crystal, lava.
// 100% harmonized voxel grid unit: s = Style.space(8) * widgetScale.
Item {
  id: root

  property real widgetScale: 3.6
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string blockType: "grass"

  // Unified even-integer voxel unit for razor-sharp, 100% even isometric seams
  readonly property real voxelUnit: Math.round((Style.space(8) * root.widgetScale) / 2) * 2

  implicitWidth: Math.round((voxelUnit * 2.4) / 2) * 2
  implicitHeight: Math.round((voxelUnit * 2.4) / 2) * 2
  width: implicitWidth
  height: implicitHeight

  onBlockTypeChanged: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()
  onFgColorChanged: canvas.requestPaint()
  onVoxelUnitChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    renderTarget: Canvas.FramebufferObject

    function colorLuminance(hex, lum) {
      hex = String(hex).replace(/[^0-9a-f]/gi, '')
      if (hex.length < 6) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2]
      lum = lum || 0
      var rgb = "#", c, i
      for (i = 0; i < 3; i++) {
        c = parseInt(hex.substr(i*2, 2), 16)
        c = Math.round(Math.min(Math.max(0, c + (c * lum)), 255)).toString(16)
        rgb += ("00" + c).substr(c.length)
      }
      return rgb
    }

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var s = root.voxelUnit
      var h = s
      var sy = Math.round(s * 0.5)
      var cx = Math.round(width * 0.5)
      var cy = Math.round(height * (1.7 / 2.4))

      // Palettes for block types
      var topC = "#22c55e"
      var leftC = "#16a34a"
      var rightC = "#15803d"
      var isGrass = false

      if (root.blockType === "grass") {
        topC = "#22c55e"
        leftC = "#78350f"
        rightC = "#451a03"
        isGrass = true
      } else if (root.blockType === "stone") {
        topC = "#94a3b8"
        leftC = "#64748b"
        rightC = "#475569"
      } else if (root.blockType === "wood") {
        topC = "#d97706"
        leftC = "#92400e"
        rightC = "#78350f"
      } else if (root.blockType === "brick") {
        topC = "#ef4444"
        leftC = "#b91c1c"
        rightC = "#991b1b"
      } else if (root.blockType === "gold") {
        topC = "#fef08a"
        leftC = "#facc15"
        rightC = "#ca8a04"
      } else if (root.blockType === "crystal") {
        var acc = root.accentColor ? root.accentColor.toString() : "#38bdf8"
        topC = colorLuminance(acc, 0.4)
        leftC = acc
        rightC = colorLuminance(acc, -0.3)
      } else if (root.blockType === "obsidian") {
        topC = "#312e81"
        leftC = "#1e1b4b"
        rightC = "#0f172a"
      } else if (root.blockType === "lava") {
        topC = "#f97316"
        leftC = "#ea580c"
        rightC = "#c2410c"
      }

      var strokeC = "rgba(0,0,0,0.25)"

      // Top face
      ctx.beginPath()
      ctx.moveTo(cx, cy - h - sy)
      ctx.lineTo(cx + s, cy - h)
      ctx.lineTo(cx, cy - h + sy)
      ctx.lineTo(cx - s, cy - h)
      ctx.closePath()
      ctx.fillStyle = topC
      ctx.fill()
      ctx.strokeStyle = strokeC
      ctx.lineWidth = 0.8
      ctx.stroke()

      // Left face
      ctx.beginPath()
      ctx.moveTo(cx - s, cy - h)
      ctx.lineTo(cx, cy - h + sy)
      ctx.lineTo(cx, cy + sy)
      ctx.lineTo(cx - s, cy)
      ctx.closePath()
      ctx.fillStyle = leftC
      ctx.fill()
      ctx.strokeStyle = strokeC
      ctx.lineWidth = 0.8
      ctx.stroke()

      // Right face
      ctx.beginPath()
      ctx.moveTo(cx, cy - h + sy)
      ctx.lineTo(cx + s, cy - h)
      ctx.lineTo(cx + s, cy)
      ctx.lineTo(cx, cy + sy)
      ctx.closePath()
      ctx.fillStyle = rightC
      ctx.fill()
      ctx.strokeStyle = strokeC
      ctx.lineWidth = 0.8
      ctx.stroke()

      // Grass top overhang rim
      if (isGrass) {
        ctx.beginPath()
        ctx.moveTo(cx - s, cy - h)
        ctx.lineTo(cx, cy - h + sy)
        ctx.lineTo(cx, cy - h + sy + s * 0.28)
        ctx.lineTo(cx - s, cy - h + s * 0.28)
        ctx.closePath()
        ctx.fillStyle = "#16a34a"
        ctx.fill()

        ctx.beginPath()
        ctx.moveTo(cx, cy - h + sy)
        ctx.lineTo(cx + s, cy - h)
        ctx.lineTo(cx + s, cy - h + s * 0.28)
        ctx.lineTo(cx, cy - h + sy + s * 0.28)
        ctx.closePath()
        ctx.fillStyle = "#15803d"
        ctx.fill()
      }
    }
  }
}
