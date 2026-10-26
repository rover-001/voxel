import QtQuick
import qs.Commons

// VoxelCloud — Animated puffy 3D isometric floating cloud.
// Gently drifts back and forth with soft volumetric shadows.
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

  property real driftPhase: 0
  NumberAnimation on driftPhase {
    from: 0; to: Math.PI * 2
    duration: 4000
    loops: Animation.Infinite
    running: root.active && root.visible
  }

  onDriftPhaseChanged: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    renderTarget: Canvas.FramebufferObject

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
        var cs = sz || s
        var ch = cs
        var csy = cs * 0.5

        ctx.beginPath()
        ctx.moveTo(x, y - ch - csy)
        ctx.lineTo(x + cs, y - ch)
        ctx.lineTo(x, y - ch + csy)
        ctx.lineTo(x - cs, y - ch)
        ctx.closePath()
        ctx.fillStyle = topC
        ctx.fill()
        ctx.strokeStyle = "rgba(0,0,0,0.12)"
        ctx.lineWidth = 0.8
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(x - cs, y - ch)
        ctx.lineTo(x, y - ch + csy)
        ctx.lineTo(x, y + csy)
        ctx.lineTo(x - cs, y)
        ctx.closePath()
        ctx.fillStyle = leftC
        ctx.fill()
        ctx.strokeStyle = "rgba(0,0,0,0.12)"
        ctx.lineWidth = 0.8
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(x, y - ch + csy)
        ctx.lineTo(x + cs, y - ch)
        ctx.lineTo(x + cs, y)
        ctx.lineTo(x, y + csy)
        ctx.closePath()
        ctx.fillStyle = rightC
        ctx.fill()
        ctx.strokeStyle = "rgba(0,0,0,0.12)"
        ctx.lineWidth = 0.8
        ctx.stroke()
      }

      function toIso(gx, gy, gz) {
        var ix = cx + (gx - gz) * (s * 1.3)
        var iy = cy - gy * (s * 1.1) + (gx + gz) * (s * 0.65)
        return { x: ix, y: iy }
      }

      // Cloud cubes cluster
      var cloudBlocks = [
        // Base tier
        { gx: -1.2, gy: 0, gz:  0.0, col: "#ffffff" },
        { gx: -0.6, gy: 0, gz: -0.6, col: "#f8fafc" },
        { gx:  0.0, gy: 0, gz:  0.0, col: "#ffffff" },
        { gx:  0.6, gy: 0, gz:  0.6, col: "#f8fafc" },
        { gx:  1.2, gy: 0, gz:  0.0, col: "#f1f5f9" },
        { gx:  0.0, gy: 0, gz: -0.8, col: "#e2e8f0" },
        { gx: -0.6, gy: 0, gz:  0.6, col: "#f8fafc" },
        // Middle puff tier
        { gx: -0.6, gy: 1.0, gz: 0.0, col: "#ffffff" },
        { gx:  0.0, gy: 1.0, gz: 0.0, col: "#ffffff" },
        { gx:  0.6, gy: 1.0, gz: 0.0, col: "#ffffff" },
        { gx:  0.0, gy: 1.0, gz:-0.4, col: "#ffffff" },
        // Top crown puff
        { gx:  0.0, gy: 1.9, gz: 0.0, col: "#ffffff" }
      ]

      cloudBlocks.sort(function(a, b) { return (a.gx + a.gz) - (b.gx + b.gz) })

      for (var i = 0; i < cloudBlocks.length; i++) {
        var b = cloudBlocks[i]
        var pt = toIso(b.gx, b.gy, b.gz)
        drawCube(pt.x, pt.y, s * 0.9, "#ffffff", b.col, "#cbd5e1")
      }
    }
  }
}
