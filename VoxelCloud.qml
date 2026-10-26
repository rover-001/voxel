import QtQuick
import qs.Commons

// VoxelCloud — Stationary puffy 3D isometric floating cloud.
Item {
  id: root

  property real widgetScale: 2.2
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string cloudVariant: "puffy"

  implicitWidth: Style.space(56) * root.widgetScale
  implicitHeight: Style.space(34) * root.widgetScale
  width: implicitWidth
  height: implicitHeight

  readonly property real driftPhase: 0.0

  Component.onCompleted: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()
  onFgColorChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var s = Style.space(6) * root.widgetScale
      var h = s
      var sy = s * 0.5

      var driftX = Math.sin(root.driftPhase) * (s * 0.6)
      var driftY = Math.cos(root.driftPhase * 0.8) * (s * 0.25)

      var cx = width * 0.5 + driftX
      var cy = height * 0.72 + driftY

      function drawCube(x, y, sz, topC, leftC, rightC) {
        var hSz = sz
        var sySz = sz * 0.5

        // Top face
        ctx.fillStyle = topC
        ctx.beginPath()
        ctx.moveTo(x, y - hSz - sySz)
        ctx.lineTo(x + sz, y - hSz)
        ctx.lineTo(x, y - hSz + sySz)
        ctx.lineTo(x - sz, y - hSz)
        ctx.closePath()
        ctx.fill()

        // Left face
        ctx.fillStyle = leftC
        ctx.beginPath()
        ctx.moveTo(x - sz, y - hSz)
        ctx.lineTo(x, y - hSz + sySz)
        ctx.lineTo(x, y + sySz)
        ctx.lineTo(x - sz, y)
        ctx.closePath()
        ctx.fill()

        // Right face
        ctx.fillStyle = rightC
        ctx.beginPath()
        ctx.moveTo(x, y - hSz + sySz)
        ctx.lineTo(x + sz, y - hSz)
        ctx.lineTo(x + sz, y)
        ctx.lineTo(x, y + sySz)
        ctx.closePath()
        ctx.fill()
      }

      // Volumetric cloud voxels
      var cTop = "#FFFFFF"
      var cLeft = "#E2E8F0"
      var cRight = "#CBD5E1"
      var cShadowTop = "#94A3B8"
      var cShadowLeft = "#64748B"
      var cShadowRight = "#475569"

      // Base shadow / bottom layer
      drawCube(cx - s * 1.5, cy + sy * 0.5, s * 0.9, cShadowTop, cShadowLeft, cShadowRight)
      drawCube(cx, cy + sy * 0.8, s * 1.1, cShadowTop, cShadowLeft, cShadowRight)
      drawCube(cx + s * 1.4, cy + sy * 0.4, s * 0.85, cShadowTop, cShadowLeft, cShadowRight)

      // Main puffy cloud cluster (isometric sorted back-to-front)
      var cloudBlocks = [
        { gx: -2, gy: 0, gz: 0, sz: s * 0.85, top: cTop, left: cLeft, right: cRight },
        { gx: -1, gy: 0, gz: -1, sz: s * 1.1, top: cTop, left: cLeft, right: cRight },
        { gx: -1, gy: 1, gz: 0, sz: s * 1.25, top: "#FFFFFF", left: "#F8FAFC", right: "#E2E8F0" },
        { gx: 0, gy: 0, gz: 0, sz: s * 1.35, top: "#FFFFFF", left: "#F1F5F9", right: "#CBD5E1" },
        { gx: 0, gy: 1, gz: -0.5, sz: s * 1.4, top: "#FFFFFF", left: "#FFFFFF", right: "#E2E8F0" },
        { gx: 1, gy: 0, gz: -0.8, sz: s * 1.15, top: cTop, left: cLeft, right: cRight },
        { gx: 1, gy: 1, gz: 0, sz: s * 1.1, top: "#FFFFFF", left: "#F8FAFC", right: "#E2E8F0" },
        { gx: 2, gy: 0, gz: 0, sz: s * 0.8, top: cTop, left: cLeft, right: cRight },
        { gx: 0.5, gy: 0.5, gz: 1, sz: s * 0.95, top: cTop, left: cLeft, right: cRight },
        { gx: -0.8, gy: 0.4, gz: 0.8, sz: s * 0.9, top: cTop, left: cLeft, right: cRight },
      ]

      cloudBlocks.sort(function(a, b) { return (a.gx + a.gz) - (b.gx + b.gz) })

      for (var i = 0; i < cloudBlocks.length; i++) {
        var b = cloudBlocks[i]
        var bx = cx + (b.gx - b.gz) * (s * 0.8)
        var by = cy + (b.gx + b.gz) * (sy * 0.45) - b.gy * (h * 0.85)
        drawCube(bx, by, b.sz, b.top, b.left, b.right)
      }
    }
  }
}
