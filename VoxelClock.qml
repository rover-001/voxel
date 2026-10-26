import QtQuick
import Quickshell
import qs.Commons

// Voxel Clock — 3D floating isometric voxel digits clock.
// Features:
// - Full 3D isometric voxel time digits (HH : MM) with top/left/right lighting
// - Entire date & day display underneath rendered completely in 3D isometric voxels
// - Rock-solid stationary Y axis (zero bouncing up and down)
// - Glowing neon voxel colon ticker with breathing pulse
// - 100% transparent background (zero cards or bounding boxes)
Item {
  id: root

  property real clockScale: 1
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true

  SystemClock {
    id: liveClock
    precision: SystemClock.Seconds
  }

  readonly property int hours: liveClock.date.getHours()
  readonly property int minutes: liveClock.date.getMinutes()
  readonly property int seconds: liveClock.date.getSeconds()

  readonly property string hoursStr: (hours < 10 ? "0" : "") + hours
  readonly property string minsStr: (minutes < 10 ? "0" : "") + minutes
  readonly property string dateStr: Qt.formatDateTime(liveClock.date, "ddd  d  MMM").toUpperCase()

  // Sizing
  implicitWidth: Style.space(270) * root.clockScale
  implicitHeight: Style.space(120) * root.clockScale
  width: implicitWidth
  height: implicitHeight

  onSecondsChanged: canvas.requestPaint()
  Component.onCompleted: canvas.requestPaint()
  onHoursStrChanged: canvas.requestPaint()
  onMinsStrChanged: canvas.requestPaint()
  onDateStrChanged: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()
  onFgColorChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    onAvailableChanged: if (available) requestPaint()

    // 3x5 Voxel Font Definitions (Digits 0-9 & Letters A-Z)
    readonly property var fontDefs: ({
      "0": [1,1,1, 1,0,1, 1,0,1, 1,0,1, 1,1,1],
      "1": [0,1,0, 1,1,0, 0,1,0, 0,1,0, 1,1,1],
      "2": [1,1,1, 0,0,1, 1,1,1, 1,0,0, 1,1,1],
      "3": [1,1,1, 0,0,1, 1,1,1, 0,0,1, 1,1,1],
      "4": [1,0,1, 1,0,1, 1,1,1, 0,0,1, 0,0,1],
      "5": [1,1,1, 1,0,0, 1,1,1, 0,0,1, 1,1,1],
      "6": [1,1,1, 1,0,0, 1,1,1, 1,0,1, 1,1,1],
      "7": [1,1,1, 0,0,1, 0,1,0, 0,1,0, 0,1,0],
      "8": [1,1,1, 1,0,1, 1,1,1, 1,0,1, 1,1,1],
      "9": [1,1,1, 1,0,1, 1,1,1, 0,0,1, 1,1,1],
      "A": [0,1,0, 1,0,1, 1,1,1, 1,0,1, 1,0,1],
      "B": [1,1,0, 1,0,1, 1,1,0, 1,0,1, 1,1,0],
      "C": [0,1,1, 1,0,0, 1,0,0, 1,0,0, 0,1,1],
      "D": [1,1,0, 1,0,1, 1,0,1, 1,0,1, 1,1,0],
      "E": [1,1,1, 1,0,0, 1,1,0, 1,0,0, 1,1,1],
      "F": [1,1,1, 1,0,0, 1,1,0, 1,0,0, 1,0,0],
      "G": [0,1,1, 1,0,0, 1,0,1, 1,0,1, 0,1,1],
      "H": [1,0,1, 1,0,1, 1,1,1, 1,0,1, 1,0,1],
      "I": [1,1,1, 0,1,0, 0,1,0, 0,1,0, 1,1,1],
      "J": [0,0,1, 0,0,1, 0,0,1, 1,0,1, 0,1,0],
      "K": [1,0,1, 1,1,0, 1,0,0, 1,1,0, 1,0,1],
      "L": [1,0,0, 1,0,0, 1,0,0, 1,0,0, 1,1,1],
      "M": [1,0,1, 1,1,1, 1,0,1, 1,0,1, 1,0,1],
      "N": [1,0,1, 1,1,1, 1,1,1, 1,0,1, 1,0,1],
      "O": [1,1,1, 1,0,1, 1,0,1, 1,0,1, 1,1,1],
      "P": [1,1,1, 1,0,1, 1,1,1, 1,0,0, 1,0,0],
      "Q": [1,1,1, 1,0,1, 1,0,1, 1,1,1, 0,0,1],
      "R": [1,1,0, 1,0,1, 1,1,0, 1,0,1, 1,0,1],
      "S": [0,1,1, 1,0,0, 0,1,0, 0,0,1, 1,1,0],
      "T": [1,1,1, 0,1,0, 0,1,0, 0,1,0, 0,1,0],
      "U": [1,0,1, 1,0,1, 1,0,1, 1,0,1, 1,1,1],
      "V": [1,0,1, 1,0,1, 1,0,1, 1,0,1, 0,1,0],
      "W": [1,0,1, 1,0,1, 1,0,1, 1,1,1, 1,0,1],
      "X": [1,0,1, 1,0,1, 0,1,0, 1,0,1, 1,0,1],
      "Y": [1,0,1, 1,0,1, 0,1,0, 0,1,0, 0,1,0],
      "Z": [1,1,1, 0,0,1, 0,1,0, 1,0,0, 1,1,1],
      " ": [0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0]
    })

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

      var s = Style.space(7.2) * root.clockScale
      var h = s
      var sy = s * 0.45

      var baseHex = root.accentColor.toString()
      var topHex = colorLuminance(baseHex, 0.35)
      var leftHex = baseHex
      var rightHex = colorLuminance(baseHex, -0.32)

      function drawCube(cx, cy, sVal, topC, leftC, rightC, strokeC) {
        var cs = sVal || s
        var ch = cs
        var csy = cs * 0.45

        // Top Face (Lit)
        ctx.beginPath()
        ctx.moveTo(cx, cy - ch - csy)
        ctx.lineTo(cx + cs, cy - ch)
        ctx.lineTo(cx, cy - ch + csy)
        ctx.lineTo(cx - cs, cy - ch)
        ctx.closePath()
        ctx.fillStyle = topC
        ctx.fill()
        if (strokeC) {
          ctx.strokeStyle = strokeC
          ctx.lineWidth = 0.8
          ctx.stroke()
        }

        // Left Face (Mid)
        ctx.beginPath()
        ctx.moveTo(cx - cs, cy - ch)
        ctx.lineTo(cx, cy - ch + csy)
        ctx.lineTo(cx, cy + csy)
        ctx.lineTo(cx - cs, cy)
        ctx.closePath()
        ctx.fillStyle = leftC
        ctx.fill()
        if (strokeC) {
          ctx.strokeStyle = strokeC
          ctx.lineWidth = 0.8
          ctx.stroke()
        }

        // Right Face (Shaded)
        ctx.beginPath()
        ctx.moveTo(cx, cy - ch + csy)
        ctx.lineTo(cx + cs, cy - ch)
        ctx.lineTo(cx + cs, cy)
        ctx.lineTo(cx, cy + csy)
        ctx.closePath()
        ctx.fillStyle = rightC
        ctx.fill()
        if (strokeC) {
          ctx.strokeStyle = strokeC
          ctx.lineWidth = 0.8
          ctx.stroke()
        }
      }

      // =====================================================================
      // 1. Time Digits (HH : MM) — Rock-solid stationary Y axis
      // =====================================================================
      var originX = width * 0.5
      var originY = height * 0.46

      var totalCols = 16
      var stepX = s * 1.55
      var startColX = - (totalCols * stepX) * 0.5 + s * 1.2

      var h1 = root.hoursStr.charAt(0)
      var h2 = root.hoursStr.charAt(1)
      var m1 = root.minsStr.charAt(0)
      var m2 = root.minsStr.charAt(1)

      var cubes = []

      function addDigit(digitChar, colOffset) {
        var map = fontDefs[digitChar] || fontDefs["0"]
        for (var r = 0; r < 5; r++) {
          for (var c = 0; c < 3; c++) {
            if (map[r * 3 + c]) {
              cubes.push({
                col: colOffset + c,
                row: 4 - r,
                isColon: false
              })
            }
          }
        }
      }

      addDigit(h1, 0)
      addDigit(h2, 4)

      // Colon ':' at colOffset = 8
      cubes.push({ col: 8, row: 3, isColon: true })
      cubes.push({ col: 8, row: 1, isColon: true })

      addDigit(m1, 10)
      addDigit(m2, 14)

      // Sort back-to-front by row and col
      cubes.sort(function(a, b) {
        if (a.row !== b.row) return a.row - b.row
        return a.col - b.col
      })

      for (var i = 0; i < cubes.length; i++) {
        var cb = cubes[i]
        var colX = startColX + cb.col * stepX
        var rowY = - cb.row * (s * 1.35)

        var cx = originX + colX
        var cy = originY + rowY

        var tC = topHex
        var lC = leftHex
        var rC = rightHex
        var sC = "rgba(0,0,0,0.22)"

        if (cb.isColon) {
          var colonGlow = (root.seconds % 2 === 0) ? 0.95 : 0.45
          tC = colorLuminance(baseHex, colonGlow)
          lC = colorLuminance(baseHex, colonGlow * 0.7)
          rC = colorLuminance(baseHex, colonGlow * 0.3)
          sC = "rgba(255,255,255,0.3)"
        }

        drawCube(cx, cy, s, tC, lC, rC, sC)
      }

      // =====================================================================
      // 2. Entire Day & Date Display (Below Time) — 100% 3D Isometric Voxels!
      // =====================================================================
      var sDate = s * 0.42
      var stepDateX = sDate * 1.55
      var dateStr = root.dateStr
      var dateTotalCols = dateStr.length * 4
      var startDateX = originX - (dateTotalCols * stepDateX) * 0.5 + sDate * 1.2
      var dateOriginY = height * 0.90

      var dateHex = root.fgColor ? root.fgColor.toString() : "#ECE9CC"
      var dateTop = colorLuminance(dateHex, 0.4)
      var dateLeft = dateHex
      var dateRight = colorLuminance(dateHex, -0.35)

      var dateCubes = []
      for (var ch = 0; ch < dateStr.length; ch++) {
        var charCode = dateStr.charAt(ch)
        var mapArr = fontDefs[charCode] || fontDefs[" "]
        var cOffset = ch * 4
        for (var dr = 0; dr < 5; dr++) {
          for (var dc = 0; dc < 3; dc++) {
            if (mapArr[dr * 3 + dc]) {
              dateCubes.push({
                col: cOffset + dc,
                row: 4 - dr
              })
            }
          }
        }
      }

      dateCubes.sort(function(a, b) {
        if (a.row !== b.row) return a.row - b.row
        return a.col - b.col
      })

      for (var k = 0; k < dateCubes.length; k++) {
        var dcb = dateCubes[k]
        var dcx = startDateX + dcb.col * stepDateX
        var dcy = dateOriginY - dcb.row * (sDate * 1.35)
        drawCube(dcx, dcy, sDate, dateTop, dateLeft, dateRight, "rgba(0,0,0,0.18)")
      }
    }
  }
}
