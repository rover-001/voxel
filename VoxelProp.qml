import QtQuick
import qs.Commons

// VoxelProp — Modular 3D isometric scenic props for desktop diorama worlds:
// - bench: Cozy wooden park bench with wrought-iron frame (rotatable 360°)
// - lamp: Vintage streetlamp with warm breathing lantern glow (generous headroom, zero clipping)
// - fountain: Cobblestone fountain with animated water ripples and splash droplets
// - campfire: Stone-ring firepit with animated flickering flames and rising embers
// - flowers: Blooming multi-colored flower bed with gentle breeze sway
// - fence: Rustic wooden post and rail barrier segment (rotatable 360°)
// - waterfall: Cascading waterfall with rushing veil, animated white-water streaks, and foot splash!
// All props share the exact even-integer voxelUnit isometric grid as VoxelBlock.
Item {
  id: root

  property real widgetScale: 3.6
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string propType: "bench"
  property int propRotation: 0

  // Unified even-integer voxel unit for seamless alignment with VoxelBlock
  readonly property real voxelUnit: Math.round((Style.space(8) * root.widgetScale) / 2) * 2

  // Expanded canvas dimensions to provide generous headroom for tall lamps and waterfall drops
  implicitWidth: Math.round((voxelUnit * 3.6) / 2) * 2
  implicitHeight: Math.round((voxelUnit * 4.4) / 2) * 2
  width: implicitWidth
  height: implicitHeight

  // ---- Animated Prop Loops -----------------------------------------------

  // Lamp: Gentle breathing lantern glow
  property real lampGlow: 0.5
  SequentialAnimation on lampGlow {
    loops: Animation.Infinite
    running: root.active && root.visible && root.propType === "lamp"
    NumberAnimation { from: 0.4; to: 0.85; duration: 1800; easing.type: Easing.InOutSine }
    NumberAnimation { from: 0.85; to: 0.55; duration: 1200; easing.type: Easing.InOutSine }
    NumberAnimation { from: 0.55; to: 0.95; duration: 1600; easing.type: Easing.InOutSine }
    NumberAnimation { from: 0.95; to: 0.4; duration: 2000; easing.type: Easing.InOutSine }
  }

  // Fountain: Continuous water ripple & droplet spray loop
  property real waterPhase: 0.0
  NumberAnimation on waterPhase {
    from: 0.0; to: 1.0
    duration: 2400
    loops: Animation.Infinite
    running: root.active && root.visible && root.propType === "fountain"
  }

  // Campfire: Fast crackling flame flicker and rising smoke
  property real flamePhase: 0.0
  NumberAnimation on flamePhase {
    from: 0.0; to: 1.0
    duration: 1200
    loops: Animation.Infinite
    running: root.active && root.visible && root.propType === "campfire"
  }

  // Flowers: Gentle breeze petal sway
  property real flowerSway: 0.0
  NumberAnimation on flowerSway {
    from: 0.0; to: Math.PI * 2
    duration: 3200
    loops: Animation.Infinite
    running: root.active && root.visible && root.propType === "flowers"
  }

  // Waterfall: Rapid water curtain and churning foam rapids loop
  property real waterfallPhase: 0.0
  NumberAnimation on waterfallPhase {
    from: 0.0; to: 1.0
    duration: 900
    loops: Animation.Infinite
    running: root.active && root.visible && root.propType === "waterfall"
  }

  onPropTypeChanged: canvas.requestPaint()
  onPropRotationChanged: canvas.requestPaint()
  onVoxelUnitChanged: canvas.requestPaint()
  onLampGlowChanged: canvas.requestPaint()
  onWaterPhaseChanged: canvas.requestPaint()
  onFlamePhaseChanged: canvas.requestPaint()
  onFlowerSwayChanged: canvas.requestPaint()
  onWaterfallPhaseChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    renderTarget: Canvas.FramebufferObject

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var s = root.voxelUnit
      var cx = Math.round(width * 0.5)
      // Ground anchor contact at 0.75 height (matches card.groundCenterY)
      var cy = Math.round(height * 0.75)
      var sy = Math.round(s * 0.5)

      // 3D Isometric Coordinate Rotation Helper (0°, 90°, 180°, 270°)
      function rotUV(u, v) {
        var r = ((Math.round(root.propRotation) % 4) + 4) % 4
        if (r === 1) return { u: -v, v: u }
        if (r === 2) return { u: -u, v: -v }
        if (r === 3) return { u: v, v: -u }
        return { u: u, v: v }
      }

      // Isometric projection helper: (u = down-right, v = down-left, w = up)
      function isoPt(u, v, w) {
        var r = rotUV(u, v)
        return {
          x: cx + (r.u - r.v) * (s * 0.5),
          y: cy + (r.u + r.v) * (sy * 0.5) - w * (s * 0.5)
        }
      }

      // Draw wall helper with automatic back-face culling & direction-based shading
      function drawWall(t1, t2, b2, b1, col, strokeC) {
        if (t2.x <= t1.x) return // Back-facing wall, culled
        ctx.beginPath()
        ctx.moveTo(t1.x, t1.y)
        ctx.lineTo(t2.x, t2.y)
        ctx.lineTo(b2.x, b2.y)
        ctx.lineTo(b1.x, b1.y)
        ctx.closePath()
        ctx.fillStyle = col
        ctx.fill()
        if (strokeC) { ctx.strokeStyle = strokeC; ctx.lineWidth = 0.6; ctx.stroke(); }
      }

      // Draw isometric 3D voxel box with full 360° rotation support
      function drawIsoBox(u, v, w, du, dv, dw, topC, leftC, rightC, strokeC) {
        var p00 = isoPt(u, v, w + dw)
        var p10 = isoPt(u + du, v, w + dw)
        var p11 = isoPt(u + du, v + dv, w + dw)
        var p01 = isoPt(u, v + dv, w + dw)

        var b00 = isoPt(u, v, w)
        var b10 = isoPt(u + du, v, w)
        var b11 = isoPt(u + du, v + dv, w)
        var b01 = isoPt(u, v + dv, w)

        // 4 Clockwise side walls (automatically rendered if front-facing)
        drawWall(p01, p11, b11, b01, (p11.y > p01.y) ? rightC : leftC, strokeC)
        drawWall(p11, p10, b10, b11, (p10.y > p11.y) ? rightC : leftC, strokeC)
        drawWall(p10, p00, b00, b10, (p00.y > p10.y) ? rightC : leftC, strokeC)
        drawWall(p00, p01, b01, b00, (p01.y > p00.y) ? rightC : leftC, strokeC)

        // Top face
        ctx.beginPath()
        ctx.moveTo(p00.x, p00.y)
        ctx.lineTo(p10.x, p10.y)
        ctx.lineTo(p11.x, p11.y)
        ctx.lineTo(p01.x, p01.y)
        ctx.closePath()
        ctx.fillStyle = topC
        ctx.fill()
        if (strokeC) { ctx.strokeStyle = strokeC; ctx.lineWidth = 0.6; ctx.stroke(); }
      }

      var stroke = "rgba(0,0,0,0.22)"

      // ====================================================================
      // 1. BENCH (ROTATABLE)
      // ====================================================================
      if (root.propType === "bench") {
        var ironTop = "#475569"
        var ironLeft = "#334155"
        var ironRight = "#1e293b"
        var woodTop = "#d97706"
        var woodLeft = "#b45309"
        var woodRight = "#78350f"

        // Legs (4 corner metal pillars)
        drawIsoBox(-0.7, -0.4, 0, 0.18, 0.18, 0.5, ironTop, ironLeft, ironRight, stroke)
        drawIsoBox( 0.5, -0.4, 0, 0.18, 0.18, 0.5, ironTop, ironLeft, ironRight, stroke)
        drawIsoBox(-0.7,  0.2, 0, 0.18, 0.18, 0.5, ironTop, ironLeft, ironRight, stroke)
        drawIsoBox( 0.5,  0.2, 0, 0.18, 0.18, 0.5, ironTop, ironLeft, ironRight, stroke)

        // Metal side braces & armrest uprights
        drawIsoBox(-0.72, -0.42, 0.45, 0.22, 0.82, 0.15, ironTop, ironLeft, ironRight, stroke)
        drawIsoBox( 0.48, -0.42, 0.45, 0.22, 0.82, 0.15, ironTop, ironLeft, ironRight, stroke)

        // Armrests
        drawIsoBox(-0.72, -0.42, 0.75, 0.2, 0.75, 0.12, ironTop, ironLeft, ironRight, stroke)
        drawIsoBox( 0.48, -0.42, 0.75, 0.2, 0.75, 0.12, ironTop, ironLeft, ironRight, stroke)

        // Backrest uprights
        drawIsoBox(-0.7, -0.4, 0.6, 0.18, 0.18, 0.8, ironTop, ironLeft, ironRight, stroke)
        drawIsoBox( 0.5, -0.4, 0.6, 0.18, 0.18, 0.8, ironTop, ironLeft, ironRight, stroke)

        // Wooden Seat Slats (3 horizontal planks)
        drawIsoBox(-0.78, -0.32, 0.52, 1.54, 0.22, 0.08, woodTop, woodLeft, woodRight, stroke)
        drawIsoBox(-0.78, -0.05, 0.52, 1.54, 0.22, 0.08, woodTop, woodLeft, woodRight, stroke)
        drawIsoBox(-0.78,  0.22, 0.52, 1.54, 0.22, 0.08, woodTop, woodLeft, woodRight, stroke)

        // Wooden Backrest Slats (2 upper planks)
        drawIsoBox(-0.78, -0.42, 0.95, 1.54, 0.12, 0.22, woodTop, woodLeft, woodRight, stroke)
        drawIsoBox(-0.78, -0.42, 1.25, 1.54, 0.12, 0.22, woodTop, woodLeft, woodRight, stroke)
      }

      // ====================================================================
      // 2. LAMP (LANTERN POST with NO CLIPPING & ROTATABLE)
      // ====================================================================
      else if (root.propType === "lamp") {
        var stoneT = "#64748b"
        var stoneL = "#475569"
        var stoneR = "#334155"
        var metalT = "#334155"
        var metalL = "#1e293b"
        var metalR = "#0f172a"
        var goldT = "#fef08a"
        var goldL = "#facc15"
        var goldR = "#ca8a04"

        // Stone Base
        drawIsoBox(-0.4, -0.4, 0, 0.8, 0.8, 0.25, stoneT, stoneL, stoneR, stroke)
        drawIsoBox(-0.3, -0.3, 0.25, 0.6, 0.6, 0.2, stoneT, stoneL, stoneR, stroke)

        // Iron Post Shaft
        drawIsoBox(-0.14, -0.14, 0.45, 0.28, 0.28, 1.6, metalT, metalL, metalR, stroke)

        // Capital / Collar
        drawIsoBox(-0.25, -0.25, 2.05, 0.5, 0.5, 0.18, metalT, metalL, metalR, stroke)

        // Lantern Cage Base
        drawIsoBox(-0.4, -0.4, 2.23, 0.8, 0.8, 0.14, metalT, metalL, metalR, stroke)

        // Glowing Lantern Glass Core (Pulsing warm amber glow)
        var glowAlpha = 0.55 + root.lampGlow * 0.45
        var glowR = s * (1.1 + root.lampGlow * 0.25)
        var lanternCenter = isoPt(0, 0, 2.7)

        // Radial warm light emission (ample headroom inside 4.4s canvas)
        var radGrad = ctx.createRadialGradient(lanternCenter.x, lanternCenter.y, s * 0.2, lanternCenter.x, lanternCenter.y, glowR)
        radGrad.addColorStop(0, "rgba(254, 240, 138, " + (0.45 * glowAlpha) + ")")
        radGrad.addColorStop(0.5, "rgba(251, 191, 36, " + (0.25 * glowAlpha) + ")")
        radGrad.addColorStop(1, "rgba(245, 158, 11, 0)")
        ctx.fillStyle = radGrad
        ctx.beginPath()
        ctx.arc(lanternCenter.x, lanternCenter.y, glowR, 0, Math.PI * 2)
        ctx.fill()

        // Glowing Core Cube
        drawIsoBox(-0.25, -0.25, 2.37, 0.5, 0.5, 0.55, goldT, goldL, goldR, null)

        // 4 Metal Lantern Corner Struts
        drawIsoBox(-0.4, -0.4, 2.37, 0.12, 0.12, 0.55, metalT, metalL, metalR, stroke)
        drawIsoBox( 0.28, -0.4, 2.37, 0.12, 0.12, 0.55, metalT, metalL, metalR, stroke)
        drawIsoBox(-0.4,  0.28, 2.37, 0.12, 0.12, 0.55, metalT, metalL, metalR, stroke)
        drawIsoBox( 0.28,  0.28, 2.37, 0.12, 0.12, 0.55, metalT, metalL, metalR, stroke)

        // Lantern Roof Cap (Pyramidal tiers)
        drawIsoBox(-0.44, -0.44, 2.92, 0.88, 0.88, 0.16, metalT, metalL, metalR, stroke)
        drawIsoBox(-0.32, -0.32, 3.08, 0.64, 0.64, 0.16, metalT, metalL, metalR, stroke)
        drawIsoBox(-0.16, -0.16, 3.24, 0.32, 0.32, 0.16, metalT, metalL, metalR, stroke)
        drawIsoBox(-0.06, -0.06, 3.40, 0.12, 0.12, 0.18, metalT, metalL, metalR, stroke)
      }

      // ====================================================================
      // 3. FOUNTAIN
      // ====================================================================
      else if (root.propType === "fountain") {
        var fBaseT = "#94a3b8"
        var fBaseL = "#64748b"
        var fBaseR = "#475569"
        var waterT = "#38bdf8"
        var waterL = "#0284c7"
        var waterR = "#0369a1"

        // Outer Stone Basin Base
        drawIsoBox(-0.85, -0.85, 0, 1.7, 1.7, 0.45, fBaseT, fBaseL, fBaseR, stroke)

        // Water surface inside basin
        drawIsoBox(-0.7, -0.7, 0.38, 1.4, 1.4, 0.08, waterT, waterL, waterR, null)

        // Central Stone Pedestal Tier
        drawIsoBox(-0.35, -0.35, 0.45, 0.7, 0.7, 0.5, fBaseT, fBaseL, fBaseR, stroke)

        // Upper Small Water Bowl
        drawIsoBox(-0.45, -0.45, 0.95, 0.9, 0.9, 0.22, fBaseT, fBaseL, fBaseR, stroke)
        drawIsoBox(-0.35, -0.35, 1.12, 0.7, 0.7, 0.06, waterT, waterL, waterR, null)

        // Spout Finial
        drawIsoBox(-0.12, -0.12, 1.17, 0.24, 0.24, 0.3, fBaseT, fBaseL, fBaseR, stroke)

        // Animated Water Ripples on Basin
        var ripplePt = isoPt(0, 0, 0.46)
        for (var rIdx = 0; rIdx < 2; rIdx++) {
          var rProgress = (root.waterPhase + rIdx * 0.5) % 1.0
          var rRadius = s * (0.2 + rProgress * 0.7)
          var rAlpha = Math.sin(rProgress * Math.PI) * 0.65

          ctx.save()
          ctx.beginPath()
          ctx.translate(ripplePt.x, ripplePt.y)
          ctx.scale(1.0, 0.5)
          ctx.arc(0, 0, rRadius, 0, Math.PI * 2)
          ctx.strokeStyle = "rgba(224, 242, 254, " + rAlpha + ")"
          ctx.lineWidth = 1.2
          ctx.stroke()
          ctx.restore()
        }

        // Animated Splash Droplets springing from spout
        var dropDirs = [
          { u:  0.25, v:  0.05 },
          { u: -0.25, v: -0.05 },
          { u:  0.05, v:  0.25 },
          { u: -0.05, v: -0.25 }
        ]
        for (var d = 0; d < dropDirs.length; d++) {
          var dProg = (root.waterPhase * 2.0 + d * 0.25) % 1.0
          var dHeight = 1.47 + Math.sin(dProg * Math.PI) * 0.35 - (dProg > 0.5 ? (dProg - 0.5) * 0.6 : 0)
          var dPos = isoPt(dropDirs[d].u * dProg, dropDirs[d].v * dProg, dHeight)

          ctx.fillStyle = "rgba(240, 249, 255, " + (1.0 - dProg * 0.6) + ")"
          ctx.beginPath()
          ctx.arc(dPos.x, dPos.y, s * 0.08, 0, Math.PI * 2)
          ctx.fill()
        }
      }

      // ====================================================================
      // 4. CAMPFIRE
      // ====================================================================
      else if (root.propType === "campfire") {
        var rockT = "#94a3b8"
        var rockL = "#64748b"
        var rockR = "#475569"
        var cLogT = "#92400e"
        var cLogL = "#78350f"
        var cLogR = "#451a03"

        // Stone Ring (8 perimeter rocks)
        var stones = [
          [-0.7, -0.2], [-0.5, -0.6], [0.0, -0.7], [0.5, -0.6],
          [ 0.7, -0.1], [ 0.5,  0.4], [0.0,  0.6], [-0.5,  0.4]
        ]
        for (var sI = 0; sI < stones.length; sI++) {
          drawIsoBox(stones[sI][0] - 0.14, stones[sI][1] - 0.14, 0, 0.28, 0.28, 0.22, rockT, rockL, rockR, stroke)
        }

        // Inner glowing ember bed
        drawIsoBox(-0.4, -0.4, 0, 0.8, 0.8, 0.1, "#f97316", "#ea580c", "#c2410c", null)

        // Crossed Firewood Logs
        drawIsoBox(-0.6, -0.14, 0.08, 1.2, 0.28, 0.18, cLogT, cLogL, cLogR, stroke)
        drawIsoBox(-0.14, -0.6, 0.20, 0.28, 1.2, 0.18, cLogT, cLogL, cLogR, stroke)

        // Animated Dancing Flame Voxels
        var flame1 = Math.sin(root.flamePhase * Math.PI * 4) * 0.08
        var flame2 = Math.cos(root.flamePhase * Math.PI * 6) * 0.08

        // Red outer flame
        drawIsoBox(-0.35 + flame1, -0.35 + flame2, 0.28, 0.7, 0.7, 0.55, "#ef4444", "#dc2626", "#b91c1c", null)

        // Orange middle flame
        drawIsoBox(-0.25 - flame2, -0.25 + flame1, 0.50, 0.5, 0.5, 0.65, "#f97316", "#ea580c", "#c2410c", null)

        // Yellow flame tip & core
        drawIsoBox(-0.15 + flame2, -0.15 - flame1, 0.75, 0.3, 0.3, 0.70, "#facc15", "#eab308", "#ca8a04", null)

        // Warm radial light aura around fire
        var fireCenter = isoPt(0, 0, 0.6)
        var fireGlowR = s * (1.2 + Math.sin(root.flamePhase * Math.PI * 8) * 0.15)
        var fGrad = ctx.createRadialGradient(fireCenter.x, fireCenter.y, s * 0.1, fireCenter.x, fireCenter.y, fireGlowR)
        fGrad.addColorStop(0, "rgba(254, 215, 170, 0.4)")
        fGrad.addColorStop(0.5, "rgba(249, 115, 22, 0.2)")
        fGrad.addColorStop(1, "rgba(220, 38, 38, 0)")
        ctx.fillStyle = fGrad
        ctx.beginPath()
        ctx.arc(fireCenter.x, fireCenter.y, fireGlowR, 0, Math.PI * 2)
        ctx.fill()

        // Rising smoke ember particles
        for (var em = 0; em < 3; em++) {
          var emProg = (root.flamePhase + em * 0.33) % 1.0
          var emH = 1.3 + emProg * 1.5
          var emWobbleX = Math.sin(emProg * Math.PI * 2 + em) * 0.2
          var emPt = isoPt(emWobbleX, 0, emH)
          var emAlpha = Math.sin(emProg * Math.PI) * 0.7

          ctx.fillStyle = "rgba(254, 240, 138, " + emAlpha + ")"
          ctx.beginPath()
          ctx.arc(emPt.x, emPt.y, s * (0.05 + emProg * 0.04), 0, Math.PI * 2)
          ctx.fill()
        }
      }

      // ====================================================================
      // 5. FLOWERS (GARDEN BLOOM)
      // ====================================================================
      else if (root.propType === "flowers") {
        var soilT = "#5c2e0b"
        var soilL = "#451a03"
        var soilR = "#2e1202"
        var leafT = "#22c55e"
        var leafL = "#16a34a"
        var leafR = "#15803d"

        // Raised Garden Soil Bed
        drawIsoBox(-0.7, -0.7, 0, 1.4, 1.4, 0.18, soilT, soilL, soilR, stroke)

        // Lush Foliage clumps
        drawIsoBox(-0.6, -0.5, 0.16, 0.5, 0.5, 0.2, leafT, leafL, leafR, stroke)
        drawIsoBox( 0.1, -0.6, 0.16, 0.5, 0.5, 0.2, leafT, leafL, leafR, stroke)
        drawIsoBox(-0.3,  0.1, 0.16, 0.6, 0.5, 0.2, leafT, leafL, leafR, stroke)

        var sway = Math.sin(root.flowerSway) * 0.08

        // Flower 1: Vibrant Red Poppy (Center)
        var stem1U = 0.0 + sway
        var stem1V = -0.1
        drawIsoBox(stem1U - 0.05, stem1V - 0.05, 0.3, 0.1, 0.1, 0.6, leafT, leafL, leafR, null)
        drawIsoBox(stem1U - 0.22, stem1V - 0.22, 0.85, 0.44, 0.44, 0.22, "#f43f5e", "#e11d48", "#be123c", stroke)
        drawIsoBox(stem1U - 0.1, stem1V - 0.1, 1.05, 0.2, 0.2, 0.1, "#facc15", "#eab308", "#ca8a04", null)

        // Flower 2: Bright Yellow Tulip (Left)
        var stem2U = -0.45 - sway * 0.7
        var stem2V = -0.3
        drawIsoBox(stem2U - 0.04, stem2V - 0.04, 0.3, 0.08, 0.08, 0.45, leafT, leafL, leafR, null)
        drawIsoBox(stem2U - 0.18, stem2V - 0.18, 0.72, 0.36, 0.36, 0.28, "#fde047", "#facc15", "#ca8a04", stroke)

        // Flower 3: Blue Cornflower / Orchid (Right)
        var stem3U = 0.4 + sway * 0.9
        var stem3V = 0.2
        drawIsoBox(stem3U - 0.04, stem3V - 0.04, 0.3, 0.08, 0.08, 0.52, leafT, leafL, leafR, null)
        drawIsoBox(stem3U - 0.18, stem3V - 0.18, 0.78, 0.36, 0.36, 0.24, "#38bdf8", "#0284c7", "#0369a1", stroke)

        // Flower 4: Purple Violet (Front)
        var stem4U = -0.15 + sway * 0.5
        var stem4V = 0.4
        drawIsoBox(stem4U - 0.04, stem4V - 0.04, 0.25, 0.08, 0.08, 0.35, leafT, leafL, leafR, null)
        drawIsoBox(stem4U - 0.16, stem4V - 0.16, 0.58, 0.32, 0.32, 0.2, "#c084fc", "#a855f7", "#7e22ce", stroke)
      }

      // ====================================================================
      // 6. FENCE (POST AND RAIL BARRIER - ROTATABLE)
      // ====================================================================
      else if (root.propType === "fence") {
        var fWoodT = "#d97706"
        var fWoodL = "#b45309"
        var fWoodR = "#78350f"

        // Post 1 (Left vertical post)
        drawIsoBox(-0.75, -0.14, 0, 0.28, 0.28, 1.25, fWoodT, fWoodL, fWoodR, stroke)
        drawIsoBox(-0.70, -0.10, 1.25, 0.18, 0.18, 0.12, fWoodT, fWoodL, fWoodR, stroke)

        // Post 2 (Right vertical post)
        drawIsoBox( 0.47, -0.14, 0, 0.28, 0.28, 1.25, fWoodT, fWoodL, fWoodR, stroke)
        drawIsoBox( 0.52, -0.10, 1.25, 0.18, 0.18, 0.12, fWoodT, fWoodL, fWoodR, stroke)

        // Lower Connecting Rail
        drawIsoBox(-0.75, -0.06, 0.38, 1.5, 0.12, 0.18, fWoodT, fWoodL, fWoodR, stroke)

        // Upper Connecting Rail
        drawIsoBox(-0.75, -0.06, 0.82, 1.5, 0.12, 0.18, fWoodT, fWoodL, fWoodR, stroke)
      }

      // ====================================================================
      // 7. WATERFALL (CASCADING WATER VEIL & FOAM RAPIDS - ROTATABLE!)
      // ====================================================================
      else if (root.propType === "waterfall") {
        var wTop = "#38bdf8"
        var wLeft = "#0284c7"
        var wRight = "#0369a1"
        var wFoam = "#e0f2fe"

        // Upper water inflow stream across the top block face
        drawIsoBox(-0.7, -0.7, 0, 1.4, 1.4, 0.12, wTop, wLeft, wRight, null)

        // Animated surface currents on inflow stream
        var streamOffset = (root.waterfallPhase * s * 0.4)
        var sP1 = isoPt(-0.5, -0.3 + (root.waterfallPhase * 0.4), 0.13)
        var sP2 = isoPt( 0.3, -0.3 + (root.waterfallPhase * 0.4), 0.13)
        ctx.strokeStyle = "rgba(255, 255, 255, 0.65)"
        ctx.lineWidth = 1.2
        ctx.beginPath()
        ctx.moveTo(sP1.x, sP1.y)
        ctx.lineTo(sP2.x, sP2.y)
        ctx.stroke()

        // Cliff crest / curling water spillway lip
        drawIsoBox(-0.75, 0.55, 0.02, 1.5, 0.22, 0.16, "#7dd3fc", wLeft, wRight, null)

        // Cascading vertical water curtain pouring DOWN 1.6 block units below the rim
        drawIsoBox(-0.75, 0.72, -1.6, 1.5, 0.14, 1.66, "#7dd3fc", "#0284c7", "#0369a1", null)

        // Animated rushing white-water streaks cascading down the fall
        for (var strk = 0; strk < 4; strk++) {
          var strkProg = (root.waterfallPhase * 2.2 + strk * 0.25) % 1.0
          var strkU = -0.55 + strk * 0.35
          var strkW = 0.1 - strkProg * 1.65
          var strkPt1 = isoPt(strkU, 0.79, strkW)
          var strkPt2 = isoPt(strkU, 0.79, strkW - 0.35)

          ctx.strokeStyle = "rgba(255, 255, 255, 0.85)"
          ctx.lineWidth = 1.8
          ctx.beginPath()
          ctx.moveTo(strkPt1.x, strkPt1.y)
          ctx.lineTo(strkPt2.x, strkPt2.y)
          ctx.stroke()
        }

        // Churning Splash Pool & Mist Clouds at the base of the waterfall
        drawIsoBox(-0.85, 0.60, -1.65, 1.7, 0.6, 0.14, wFoam, "#38bdf8", "#0284c7", null)

        // Bouncing water splash droplets & mist
        for (var sp = 0; sp < 4; sp++) {
          var spProg = (root.waterfallPhase * 2.5 + sp * 0.25) % 1.0
          var spU = -0.4 + sp * 0.26 + Math.sin(spProg * Math.PI) * 0.15
          var spV = 0.85 + Math.cos(spProg * Math.PI) * 0.15
          var spH = -1.55 + Math.sin(spProg * Math.PI) * 0.4
          var spPt = isoPt(spU, spV, spH)

          ctx.fillStyle = "rgba(240, 249, 255, " + (1.0 - spProg * 0.6) + ")"
          ctx.beginPath()
          ctx.arc(spPt.x, spPt.y, s * (0.06 + (1.0 - spProg) * 0.04), 0, Math.PI * 2)
          ctx.fill()
        }

        // Expanding foam ripple rings at the base
        var bPt = isoPt(0, 0.85, -1.6)
        var fProg = (root.waterfallPhase + 0.3) % 1.0
        var fRadius = s * (0.25 + fProg * 0.6)
        var fAlpha = Math.sin(fProg * Math.PI) * 0.75
        ctx.save()
        ctx.beginPath()
        ctx.translate(bPt.x, bPt.y)
        ctx.scale(1.0, 0.5)
        ctx.arc(0, 0, fRadius, 0, Math.PI * 2)
        ctx.strokeStyle = "rgba(255, 255, 255, " + fAlpha + ")"
        ctx.lineWidth = 1.4
        ctx.stroke()
        ctx.restore()
      }
    }
  }
}
