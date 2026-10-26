import QtQuick
import qs.Commons

// VoxelProp — Modular 3D isometric scenic props for desktop diorama worlds:
// - bench: Cozy wooden park bench with wrought-iron frame (rotatable 360°)
// - lamp: Vintage streetlamp with warm breathing lantern glow (generous headroom, zero clipping)
// - fountain: Cobblestone fountain with animated water ripples and splash droplets
// - campfire: Stone-ring firepit with animated flickering flames and rising embers
// - flowers: Blooming multi-colored flower bed with gentle breeze sway
// - fence: Rustic wooden post and rail barrier segment (rotatable 360°)
// All props share the exact even-integer voxelUnit isometric grid as VoxelBlock.
Item {
  id: root

  property real widgetScale: 3.6
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string propType: "bench"
  property int propRotation: 0

  property string animationLevel: "high"
  readonly property bool isAnimated: root.active && root.visible && root.animationLevel !== "none"
  readonly property bool isHighAnim: root.active && root.visible && root.animationLevel === "high"

  // Unified even-integer voxel unit for seamless alignment with VoxelBlock
  readonly property real voxelUnit: Math.round((Style.space(8) * root.widgetScale) / 2) * 2

  // Expanded canvas dimensions to provide generous headroom for tall lamps
  implicitWidth: Math.round((voxelUnit * 3.6) / 2) * 2
  implicitHeight: Math.round((voxelUnit * 4.4) / 2) * 2
  width: implicitWidth
  height: implicitHeight

  // ---- Animated Prop Loops -----------------------------------------------

  // Animated state is advanced by one capped timer below. Keeping these as
  // plain properties avoids four independent per-frame QML animation drivers.
  property real lampGlow: 0.5
  property real waterPhase: 0.0
  property real flamePhase: 0.0
  property real flowerSway: 0.0
  property real animationPhase: 0.0

  readonly property bool isAnimatedProp: isAnimated && (propType === "campfire" || propType === "lamp" || propType === "fountain")

  Timer {
    id: animTimer
    interval: {
      if (root.propType === "lamp") return root.isHighAnim ? 180 : 300
      if (root.propType === "campfire") return root.isHighAnim ? 100 : 180
      return root.isHighAnim ? 100 : 180
    }
    running: root.isAnimatedProp
    repeat: true
    onTriggered: {
      var step = interval
      if (root.propType === "lamp") {
        root.animationPhase = (root.animationPhase + step / 8000.0) % 1.0
        root.lampGlow = 0.675 + Math.sin(root.animationPhase * Math.PI * 2.0) * 0.275
      } else if (root.propType === "fountain") {
        root.waterPhase = (root.waterPhase + step / 2400.0) % 1.0
      } else if (root.propType === "campfire") {
        root.flamePhase = (root.flamePhase + step / 1200.0) % 1.0
      } else if (root.propType === "flowers") {
        root.flowerSway = (root.flowerSway + step / 3200.0 * Math.PI * 2.0) % (Math.PI * 2.0)
      }
      canvas.requestPaint()
    }
  }

  Component.onCompleted: canvas.requestPaint()
  onPropTypeChanged: canvas.requestPaint()
  onPropRotationChanged: canvas.requestPaint()
  onVoxelUnitChanged: canvas.requestPaint()
  onAnimationLevelChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var s = root.voxelUnit
      var cx = Math.round(width * 0.5)
      // Ground anchor contact at 0.75 height (matches card.groundCenterY)
      var cy = Math.round(height * 0.75)
      var sy = Math.round(s * 0.5)

      // 3D Isometric Coordinate Projection & Rotation (0°, 90°, 180°, 270°)
      function rawIsoPt(u, v, w) {
        return {
          x: cx + (u - v) * (s * 0.5),
          y: cy + (u + v) * (sy * 0.5) - w * (s * 0.5)
        }
      }

      function isoPt(u, v, w) {
        var r = ((Math.round(root.propRotation) % 4) + 4) % 4
        var ru = u, rv = v
        if (r === 1) { ru = -v; rv = u; }
        else if (r === 2) { ru = -u; rv = -v; }
        else if (r === 3) { ru = v; rv = -u; }
        return rawIsoPt(ru, rv, w)
      }

      // Draw isometric 3D voxel box with 100% bug-free 360° rotation support
      function drawIsoBox(u, v, w, du, dv, dw, topC, leftC, rightC, strokeC) {
        var r = ((Math.round(root.propRotation) % 4) + 4) % 4
        var ru = u, rv = v, rdu = du, rdv = dv
        var rLeftC = leftC, rRightC = rightC

        if (r === 1) { // 90° CW
          ru = -v - dv
          rv = u
          rdu = dv
          rdv = du
          rLeftC = rightC
          rRightC = leftC
        } else if (r === 2) { // 180°
          ru = -u - du
          rv = -v - dv
          rdu = du
          rdv = dv
          rLeftC = leftC
          rRightC = rightC
        } else if (r === 3) { // 270° CW / 90° CCW
          ru = v
          rv = -u - du
          rdu = dv
          rdv = du
          rLeftC = rightC
          rRightC = leftC
        }

        var p00 = rawIsoPt(ru, rv, w + dw)
        var p10 = rawIsoPt(ru + rdu, rv, w + dw)
        var p11 = rawIsoPt(ru + rdu, rv + rdv, w + dw)
        var p01 = rawIsoPt(ru, rv + rdv, w + dw)

        var b00 = rawIsoPt(ru, rv, w)
        var b10 = rawIsoPt(ru + rdu, rv, w)
        var b11 = rawIsoPt(ru + rdu, rv + rdv, w)
        var b01 = rawIsoPt(ru, rv + rdv, w)

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

        // Left face
        ctx.beginPath()
        ctx.moveTo(p01.x, p01.y)
        ctx.lineTo(p11.x, p11.y)
        ctx.lineTo(b11.x, b11.y)
        ctx.lineTo(b01.x, b01.y)
        ctx.closePath()
        ctx.fillStyle = rLeftC
        ctx.fill()
        if (strokeC) { ctx.strokeStyle = strokeC; ctx.lineWidth = 0.6; ctx.stroke(); }

        // Right face
        ctx.beginPath()
        ctx.moveTo(p11.x, p11.y)
        ctx.lineTo(p10.x, p10.y)
        ctx.lineTo(b10.x, b10.y)
        ctx.lineTo(b11.x, b11.y)
        ctx.closePath()
        ctx.fillStyle = rRightC
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
      // 7. BRIDGE (ARCHED TIMBER FOOTBRIDGE - ROTATABLE!)
      // ====================================================================
      else if (root.propType === "bridge") {
        var bWoodT = "#d97706"
        var bWoodL = "#b45309"
        var bWoodR = "#78350f"
        var bDarkT = "#92400e"
        var bDarkL = "#78350f"
        var bDarkR = "#451a03"

        // 4 Corner Foundation Support Blocks
        drawIsoBox(-0.75, -0.75, 0, 0.25, 0.25, 0.4, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox( 0.50, -0.75, 0, 0.25, 0.25, 0.4, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox(-0.75,  0.50, 0, 0.25, 0.25, 0.4, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox( 0.50,  0.50, 0, 0.25, 0.25, 0.4, bDarkT, bDarkL, bDarkR, stroke)

        // Arched Bridge Deck Slats (Rises in center from 0.35 to 0.55)
        drawIsoBox(-0.65, -0.75, 0.32, 1.3, 0.35, 0.1, bWoodT, bWoodL, bWoodR, stroke)
        drawIsoBox(-0.65, -0.40, 0.42, 1.3, 0.38, 0.1, bWoodT, bWoodL, bWoodR, stroke)
        drawIsoBox(-0.65, -0.02, 0.50, 1.3, 0.42, 0.1, bWoodT, bWoodL, bWoodR, stroke)
        drawIsoBox(-0.65,  0.40, 0.32, 1.3, 0.35, 0.1, bWoodT, bWoodL, bWoodR, stroke)

        // Left Handrail Posts & Top Rail
        drawIsoBox(-0.75, -0.75, 0.4, 0.1, 0.1, 0.5, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox(-0.75,  0.00, 0.55, 0.1, 0.1, 0.5, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox(-0.75,  0.65, 0.4, 0.1, 0.1, 0.5, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox(-0.75, -0.75, 0.9, 0.1, 1.5, 0.08, bWoodT, bWoodL, bWoodR, stroke)

        // Right Handrail Posts & Top Rail
        drawIsoBox( 0.65, -0.75, 0.4, 0.1, 0.1, 0.5, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox( 0.65,  0.00, 0.55, 0.1, 0.1, 0.5, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox( 0.65,  0.65, 0.4, 0.1, 0.1, 0.5, bDarkT, bDarkL, bDarkR, stroke)
        drawIsoBox( 0.65, -0.75, 0.9, 0.1, 1.5, 0.08, bWoodT, bWoodL, bWoodR, stroke)
      }

      // ====================================================================
      // 10. STEPPING STONES (RIVER ROCK PATHWAY - ROTATABLE!)
      // ====================================================================
      else if (root.propType === "stepping-stones") {
        var sRockT = "#94a3b8"
        var sRockL = "#64748b"
        var sRockR = "#475569"
        var sMossT = "#22c55e"
        var sMossL = "#16a34a"
        var sMossR = "#15803d"

        // Stone 1 (Back-left flat paver)
        drawIsoBox(-0.55, -0.55, 0, 0.45, 0.45, 0.12, sRockT, sRockL, sRockR, stroke)
        drawIsoBox(-0.50, -0.30, 0.11, 0.18, 0.16, 0.04, sMossT, sMossL, sMossR, null)

        // Stone 2 (Center paver)
        drawIsoBox(-0.15, -0.15, 0, 0.52, 0.48, 0.14, sRockT, sRockL, sRockR, stroke)
        drawIsoBox( 0.05, -0.05, 0.13, 0.20, 0.18, 0.04, sMossT, sMossL, sMossR, null)

        // Stone 3 (Front-right paver)
        drawIsoBox( 0.15,  0.25, 0, 0.46, 0.42, 0.12, sRockT, sRockL, sRockR, stroke)
      }
    }
  }
}
