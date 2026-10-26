import QtQuick
import Quickshell
import qs.Commons

// VoxelTree — Modular 3D isometric animated voxel trees designed to be planted
// on modular blocks or desktop surfaces with zero clipping and distinct animation personalities.
// Varieties:
// - sakura: Soft pink blossom clusters with breathing pulse & 3D tumbling falling sakura petals
// - oak: Majestic heavy branch sway, rustle waves, fluttering leaves & bouncing acorns
// - autumn: Brisk autumn wind gusts with swaying canopy & swirling whirlwind of maple leaves
// - pine: Alpine cold wind needle spire flex, snow caps & drifting frost/snow flurries
// - birch: Quivering aspen high-frequency foliage shimmer, charcoal notches & floating pollen motes
Item {
  id: root

  property real widgetScale: 3.6
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string treeType: "sakura" // "sakura", "oak", "autumn", "pine", "birch"

  // Unified even-integer voxel unit shared across modular Blocks, Trees, and Animals
  readonly property real voxelUnit: Math.round((Style.space(8) * root.widgetScale) / 2) * 2

  // Expanded dimensions with generous headroom to guarantee ZERO clipping at top and bottom
  implicitWidth: voxelUnit * 4.8
  implicitHeight: voxelUnit * 7.2
  width: implicitWidth
  height: implicitHeight

  readonly property bool isSakura: treeType === "sakura" || treeType === "voxel-tree-sakura"
  readonly property bool isOak: treeType === "oak" || treeType === "voxel-tree-oak"
  readonly property bool isAutumn: treeType === "autumn" || treeType === "voxel-tree-autumn"
  readonly property bool isPine: treeType === "pine" || treeType === "voxel-tree-pine"
  readonly property bool isBirch: treeType === "birch" || treeType === "voxel-tree-birch"

  // -------------------------------------------------------------------------
  // 1. UNIQUE PROCEDURAL ANIMATION CYCLES PER TREE TYPE
  // -------------------------------------------------------------------------

  readonly property real sakuraBreeze: 0.0
  readonly property real sakuraPetalPhase: 0.0
  readonly property real oakSway: 0.0
  readonly property real acornPhase: 0.0
  readonly property real autumnGust: 0.0
  readonly property real autumnLeafPhase: 0.0
  readonly property real pineSpirePhase: 0.0
  readonly property real snowFlurryPhase: 0.0
  readonly property real birchShimmer: 0.0
  readonly property real pollenPhase: 0.0

  // Interactive rustle bounce pulse on hover/click
  property real rustlePulse: 0.0
  SequentialAnimation {
    id: rustleAnim
    NumberAnimation { target: root; property: "rustlePulse"; from: 0.0; to: 1.0; duration: 80; easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "rustlePulse"; from: 1.0; to: 0.0; duration: 260; easing.type: Easing.OutBack }
  }

  Component.onCompleted: canvas.requestPaint()
  onTreeTypeChanged: canvas.requestPaint()
  onRustlePulseChanged: canvas.requestPaint()
  onVoxelUnitChanged: canvas.requestPaint()

  // Particle seeds with integer loop speeds & harmonic drift frequencies for 100% seamless looping
  readonly property var petalSeeds: [
    { xo: -0.9, yo: 0.05, spd: 1, wAmp: 1.2, wFreq: 4, sz: 1.1, c: 0 },
    { xo:  0.7, yo: 0.18, spd: 2, wAmp: 1.4, wFreq: 4, sz: 0.9, c: 1 },
    { xo: -0.3, yo: 0.36, spd: 1, wAmp: 1.0, wFreq: 6, sz: 1.2, c: 2 },
    { xo:  1.2, yo: 0.52, spd: 2, wAmp: 1.5, wFreq: 4, sz: 0.8, c: 0 },
    { xo: -1.3, yo: 0.68, spd: 1, wAmp: 1.3, wFreq: 4, sz: 1.0, c: 1 },
    { xo:  0.3, yo: 0.84, spd: 2, wAmp: 1.6, wFreq: 6, sz: 1.1, c: 2 },
    { xo: -0.6, yo: 0.12, spd: 1, wAmp: 1.1, wFreq: 4, sz: 0.9, c: 0 },
    { xo:  1.0, yo: 0.32, spd: 1, wAmp: 1.3, wFreq: 6, sz: 1.2, c: 1 },
    { xo: -1.1, yo: 0.58, spd: 2, wAmp: 1.4, wFreq: 4, sz: 0.8, c: 2 },
    { xo:  0.5, yo: 0.74, spd: 1, wAmp: 1.2, wFreq: 4, sz: 1.0, c: 0 },
    { xo: -0.2, yo: 0.90, spd: 2, wAmp: 1.3, wFreq: 4, sz: 1.0, c: 1 },
    { xo:  0.9, yo: 0.44, spd: 1, wAmp: 1.5, wFreq: 4, sz: 0.9, c: 2 }
  ]

  Canvas {
    id: canvas
    anchors.fill: parent
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var s = root.voxelUnit
      var cx = width * 0.5
      // Ground anchor base at 5/6 height giving generous headroom top and bottom
      var cy = height * (5.0 / 6.0)

      var rustle = 0
      if (root.rustlePulse > 0.01) {
        rustle = Math.sin(root.rustlePulse * Math.PI * 4) * (s * 0.22 * root.rustlePulse)
      }

      function drawCube(x, y, szW, szH, topC, leftC, rightC, strokeC) {
        var sw = szW || s
        var sh = szH || sw
        var sy = sw * 0.5

        ctx.beginPath()
        ctx.moveTo(x, y - sh - sy)
        ctx.lineTo(x + sw, y - sh)
        ctx.lineTo(x, y - sh + sy)
        ctx.lineTo(x - sw, y - sh)
        ctx.closePath()
        ctx.fillStyle = topC
        ctx.fill()
        ctx.strokeStyle = strokeC || "rgba(0,0,0,0.22)"
        ctx.lineWidth = 0.8
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(x - sw, y - sh)
        ctx.lineTo(x, y - sh + sy)
        ctx.lineTo(x, y + sy)
        ctx.lineTo(x - sw, y)
        ctx.closePath()
        ctx.fillStyle = leftC
        ctx.fill()
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(x, y - sh + sy)
        ctx.lineTo(x + sw, y - sh)
        ctx.lineTo(x + sw, y)
        ctx.lineTo(x, y + sy)
        ctx.closePath()
        ctx.fillStyle = rightC
        ctx.fill()
        ctx.stroke()
      }

      // =====================================================================
      // 1. TRUNK, ORGANIC FLARING ROOTS, GROUND SHADOW & WOODLAND SCATTER
      // =====================================================================
      var trunkTopC = "#a16207"
      var trunkLeftC = "#78350f"
      var trunkRightC = "#451a03"
      var mossTop = "#4ade80"
      var mossLeft = "#22c55e"
      var mossRight = "#16a34a"

      if (root.isBirch) {
        trunkTopC = "#f8fafc"
        trunkLeftC = "#e2e8f0"
        trunkRightC = "#cbd5e1"
        mossTop = "#a3e635"
        mossLeft = "#84cc16"
        mossRight = "#65a30d"
      } else if (root.isPine) {
        trunkTopC = "#713f12"
        trunkLeftC = "#582f0e"
        trunkRightC = "#3b1e08"
        mossTop = "#10b981"
        mossLeft = "#059669"
        mossRight = "#047857"
      } else if (root.isAutumn) {
        trunkTopC = "#9a3412"
        trunkLeftC = "#7c2d12"
        trunkRightC = "#431407"
        mossTop = "#eab308"
        mossLeft = "#ca8a04"
        mossRight = "#a16207"
      }

      // Sturdy proportional trunk dimensions
      var trunkW = s * 0.62
      var trunkH = s * 0.65

      // 1A. Ambient Isometric Ground Contact Shadow (locks the tree firmly to the block)
      ctx.save()
      ctx.beginPath()
      ctx.moveTo(cx, cy - s * 0.42)
      ctx.lineTo(cx + s * 1.0, cy)
      ctx.lineTo(cx, cy + s * 0.42)
      ctx.lineTo(cx - s * 1.0, cy)
      ctx.closePath()
      ctx.fillStyle = "rgba(15, 23, 42, 0.22)"
      ctx.fill()
      ctx.restore()

      // 1B. Species-Specific Ground Scatter & Woodland Details
      if (root.isSakura) {
        var pCols = ["#fbcfe8", "#f472b6", "#fda4af"]
        // Blossom carpet on block surface
        drawCube(cx - s * 0.60, cy + s * 0.08, s * 0.22, s * 0.10, pCols[0], pCols[1], pCols[2], "none")
        drawCube(cx + s * 0.56, cy - s * 0.08, s * 0.24, s * 0.10, pCols[1], pCols[2], pCols[0], "none")
        drawCube(cx - s * 0.25, cy + s * 0.26, s * 0.20, s * 0.08, pCols[2], pCols[0], pCols[1], "none")
        drawCube(cx + s * 0.36, cy + s * 0.24, s * 0.22, s * 0.10, pCols[0], pCols[1], pCols[2], "none")
        drawCube(cx - s * 0.06, cy - s * 0.26, s * 0.18, s * 0.08, pCols[1], pCols[2], pCols[0], "none")
        drawCube(cx + s * 0.62, cy + s * 0.12, s * 0.20, s * 0.08, pCols[2], pCols[0], pCols[1], "none")
        // Soft moss cushions
        drawCube(cx - s * 0.44, cy - s * 0.10, s * 0.26, s * 0.14, "#4ade80", "#22c55e", "#16a34a", "none")
      } else if (root.isAutumn) {
        var aLeafCols = ["#fef08a", "#f97316", "#ef4444", "#ca8a04"]
        // Harvest leaf carpet
        drawCube(cx - s * 0.62, cy + s * 0.10, s * 0.24, s * 0.10, aLeafCols[0], aLeafCols[1], aLeafCols[2], "none")
        drawCube(cx + s * 0.58, cy - s * 0.08, s * 0.26, s * 0.12, aLeafCols[1], aLeafCols[2], aLeafCols[3], "none")
        drawCube(cx - s * 0.28, cy + s * 0.26, s * 0.22, s * 0.10, aLeafCols[2], aLeafCols[3], aLeafCols[1], "none")
        drawCube(cx + s * 0.36, cy + s * 0.24, s * 0.24, s * 0.10, aLeafCols[3], aLeafCols[1], aLeafCols[0], "none")
        drawCube(cx - s * 0.08, cy - s * 0.28, s * 0.20, s * 0.08, aLeafCols[1], aLeafCols[2], aLeafCols[0], "none")
      } else if (root.isOak) {
        // Deep emerald moss cushions
        drawCube(cx - s * 0.52, cy + s * 0.10, s * 0.28, s * 0.15, "#22c55e", "#16a34a", "#15803d", "none")
        drawCube(cx + s * 0.50, cy + s * 0.08, s * 0.28, s * 0.15, "#22c55e", "#16a34a", "#15803d", "none")
        // Woodland Mushroom (white stalk + red spotted cap)
        drawCube(cx - s * 0.64, cy + s * 0.06, s * 0.10, s * 0.16, "#f8fafc", "#e2e8f0", "#cbd5e1")
        drawCube(cx - s * 0.64, cy + s * 0.06 - s * 0.14, s * 0.20, s * 0.10, "#ef4444", "#dc2626", "#b91c1c")
        // Miniature second mushroom
        drawCube(cx - s * 0.52, cy - s * 0.04, s * 0.08, s * 0.12, "#f8fafc", "#e2e8f0", "#cbd5e1")
        drawCube(cx - s * 0.52, cy - s * 0.04 - s * 0.10, s * 0.16, s * 0.08, "#f87171", "#ef4444", "#dc2626")
        // Acorn lying by roots
        var gAcornSz = s * 0.12
        drawCube(cx + s * 0.44, cy - s * 0.18, gAcornSz * 1.2, gAcornSz * 0.6, "#78350f", "#451a03", "#291002")
        drawCube(cx + s * 0.44, cy - s * 0.12, gAcornSz, gAcornSz * 0.8, "#d97706", "#b45309", "#92400e")
      } else if (root.isPine) {
        // Alpine dark needle bed & stones
        drawCube(cx - s * 0.50, cy + s * 0.10, s * 0.28, s * 0.14, "#065f46", "#064e3b", "#022c22", "none")
        drawCube(cx + s * 0.52, cy - s * 0.08, s * 0.26, s * 0.14, "#065f46", "#064e3b", "#022c22", "none")
        // Crisp snow dusting on ground
        drawCube(cx - s * 0.26, cy + s * 0.24, s * 0.24, s * 0.10, "#ffffff", "#e0f2fe", "#bae6fd", "none")
        drawCube(cx + s * 0.38, cy + s * 0.22, s * 0.22, s * 0.10, "#ffffff", "#e0f2fe", "#bae6fd", "none")
        // Little pinecone
        drawCube(cx + s * 0.42, cy - s * 0.16, s * 0.16, s * 0.20, "#582f0e", "#3b1e08", "#241103")
      } else if (root.isBirch) {
        // Spring chartreuse moss
        drawCube(cx - s * 0.52, cy + s * 0.08, s * 0.28, s * 0.15, "#84cc16", "#65a30d", "#4d7c0f", "none")
        drawCube(cx + s * 0.50, cy + s * 0.18, s * 0.26, s * 0.14, "#84cc16", "#65a30d", "#4d7c0f", "none")
        drawCube(cx - s * 0.08, cy - s * 0.24, s * 0.22, s * 0.12, "#a3e635", "#84cc16", "#65a30d", "none")
      }

      // 1C. Back Root Runners (North-West and North-East, rendered behind central trunk)
      // NW root knee & toe
      drawCube(cx - s * 0.28, cy - s * 0.14, trunkW * 0.56, trunkH * 0.46, trunkTopC, trunkLeftC, trunkRightC)
      drawCube(cx - s * 0.48, cy - s * 0.22, trunkW * 0.40, trunkH * 0.28, trunkTopC, trunkLeftC, trunkRightC)
      // NE root knee & toe
      drawCube(cx + s * 0.28, cy - s * 0.14, trunkW * 0.56, trunkH * 0.46, trunkTopC, trunkLeftC, trunkRightC)
      drawCube(cx + s * 0.48, cy - s * 0.22, trunkW * 0.40, trunkH * 0.28, trunkTopC, trunkLeftC, trunkRightC)

      // 1D. Main Trunk Base Segment (Solid & Broad)
      var trunkY1 = cy
      drawCube(cx, trunkY1, trunkW, trunkH, trunkTopC, trunkLeftC, trunkRightC)
      if (root.isBirch) {
        drawCube(cx + trunkW * 0.26, trunkY1 - trunkH * 0.25, trunkW * 0.32, trunkH * 0.18, "#1e293b", "#0f172a", "#020617")
        drawCube(cx - trunkW * 0.22, trunkY1 - trunkH * 0.55, trunkW * 0.28, trunkH * 0.16, "#1e293b", "#0f172a", "#020617")
      }

      // 1E. Front Root Runners (South-West, South-East & Front-Center, anchoring the base)
      // SW root knee & toe
      drawCube(cx - s * 0.34, cy + s * 0.12, trunkW * 0.62, trunkH * 0.52, trunkTopC, trunkLeftC, trunkRightC)
      drawCube(cx - s * 0.56, cy + s * 0.20, trunkW * 0.44, trunkH * 0.30, trunkTopC, trunkLeftC, trunkRightC)
      // SE root knee & toe
      drawCube(cx + s * 0.34, cy + s * 0.12, trunkW * 0.62, trunkH * 0.52, trunkTopC, trunkLeftC, trunkRightC)
      drawCube(cx + s * 0.56, cy + s * 0.20, trunkW * 0.44, trunkH * 0.30, trunkTopC, trunkLeftC, trunkRightC)
      // Front-Center tap root
      drawCube(cx, cy + s * 0.18, trunkW * 0.52, trunkH * 0.36, trunkTopC, trunkLeftC, trunkRightC)

      // 1F. Organic Root Collar Moss Accents
      drawCube(cx - s * 0.22, cy + s * 0.08, s * 0.20, s * 0.14, mossTop, mossLeft, mossRight, "none")
      drawCube(cx + s * 0.24, cy + s * 0.10, s * 0.20, s * 0.14, mossTop, mossLeft, mossRight, "none")
      if (root.isPine) {
        // Snow patches dusted on roots
        drawCube(cx - s * 0.32, cy + s * 0.08 - trunkH * 0.48, s * 0.22, s * 0.08, "#ffffff", "#e0f2fe", "#bae6fd", "none")
        drawCube(cx + s * 0.32, cy + s * 0.08 - trunkH * 0.48, s * 0.22, s * 0.08, "#ffffff", "#e0f2fe", "#bae6fd", "none")
      }

      // 1G. Tapered Trunk Segments (Middle & Upper)
      var trunkY2 = trunkY1 - trunkH
      drawCube(cx, trunkY2, trunkW * 0.88, trunkH, trunkTopC, trunkLeftC, trunkRightC)
      if (root.isBirch) {
        drawCube(cx - trunkW * 0.22, trunkY2 - trunkH * 0.30, trunkW * 0.34, trunkH * 0.18, "#1e293b", "#0f172a", "#020617")
        drawCube(cx + trunkW * 0.20, trunkY2 - trunkH * 0.65, trunkW * 0.28, trunkH * 0.16, "#1e293b", "#0f172a", "#020617")
      }

      var trunkY3 = trunkY2 - trunkH
      drawCube(cx, trunkY3, trunkW * 0.78, trunkH, trunkTopC, trunkLeftC, trunkRightC)

      var canopyBaseY = trunkY3 - trunkH * 0.4

      // =====================================================================
      // 2. FOLIAGE CANOPIES (Distinct Visuals & Physics Per Tree)
      // =====================================================================

      // ---------------------------------------------------------------------
      // TREE 1: SAKURA (Cherry Blossom Breathing & Tumbling Petals)
      // ---------------------------------------------------------------------
      if (root.isSakura) {
        var sTop = "#fbcfe8"
        var sLeft = "#f472b6"
        var sRight = "#db2777"
        var sTop2 = "#fce7f3"
        var sLeft2 = "#f9a8d4"
        var sRight2 = "#e11d48"

        // Gentle breathing swell & soft breeze sway
        var breezeSway = Math.sin(root.sakuraBreeze) * (s * 0.08) + rustle
        var breathe = 1.0 + Math.sin(root.sakuraBreeze * 1.5) * 0.04

        var lY = canopyBaseY + breezeSway * 0.4
        drawCube(cx - s * 0.9 * breathe + breezeSway * 0.3, lY + s * 0.2, s * 0.72 * breathe, s * 0.65 * breathe, sTop, sLeft, sRight)
        drawCube(cx + s * 0.9 * breathe + breezeSway * 0.3, lY + s * 0.2, s * 0.72 * breathe, s * 0.65 * breathe, sTop, sLeft, sRight)
        drawCube(cx + breezeSway * 0.5, lY, s * 1.15 * breathe, s * 0.85 * breathe, sTop2, sLeft2, sRight2)

        var mY = lY - s * 0.85
        drawCube(cx - s * 0.7 * breathe + breezeSway * 0.6, mY, s * 0.78 * breathe, s * 0.75 * breathe, sTop, sLeft, sRight)
        drawCube(cx + s * 0.7 * breathe + breezeSway * 0.6, mY, s * 0.78 * breathe, s * 0.75 * breathe, sTop2, sLeft2, sRight2)
        drawCube(cx + breezeSway * 0.75, mY - s * 0.2, s * 1.25 * breathe, s * 0.95 * breathe, sTop, sLeft, sRight)

        var uY = mY - s * 0.95
        drawCube(cx - s * 0.4 * breathe + breezeSway * 0.9, uY, s * 0.68 * breathe, s * 0.65 * breathe, sTop2, sLeft2, sRight2)
        drawCube(cx + s * 0.4 * breathe + breezeSway * 0.9, uY, s * 0.68 * breathe, s * 0.65 * breathe, sTop, sLeft, sRight)
        drawCube(cx + breezeSway * 1.1, uY - s * 0.3, s * 0.92 * breathe, s * 0.82 * breathe, sTop2, sLeft2, sRight2)

        // Crown blossom
        drawCube(cx + breezeSway * 1.25, uY - s * 0.92, s * 0.55 * breathe, s * 0.55 * breathe, "#ffffff", sTop2, sLeft2)

        // Live Falling Sakura Petals with 3D Tumbling Flip
        var petalCols = ["#fbcfe8", "#f472b6", "#fda4af", "#fb7185"]
        var startH = canopyBaseY - s * 2.2
        var endH = cy + s * 0.6
        var totalDist = endH - startH

        for (var i = 0; i < root.petalSeeds.length; i++) {
          var pSeed = root.petalSeeds[i]
          var pt = (root.sakuraPetalPhase * pSeed.spd + pSeed.yo) % 1.0

          var drift = Math.sin(pt * Math.PI * pSeed.wFreq + pSeed.xo) * (s * 0.45 * pSeed.wAmp)
          var px = cx + (pSeed.xo * s * 1.2) + drift + breezeSway * 0.6
          var py = startH + pt * totalDist

          var alpha = 1.0
          if (pt < 0.12) alpha = pt / 0.12
          else if (pt > 0.88) alpha = (1.0 - pt) / 0.12

          var sz = s * 0.14 * pSeed.sz
          var col = petalCols[pSeed.c % petalCols.length]

          ctx.save()
          ctx.translate(px, py)
          ctx.rotate(pt * Math.PI * 4 + pSeed.xo)
          // 3D tumbling paper flip (even multiple of PI ensures smooth loop wrap)
          ctx.scale(Math.cos(pt * Math.PI * 4 + pSeed.xo), 1.0)
          ctx.globalAlpha = Math.max(0, Math.min(1, alpha))

          ctx.beginPath()
          ctx.moveTo(0, -sz)
          ctx.lineTo(sz * 1.2, 0)
          ctx.lineTo(0, sz * 0.9)
          ctx.lineTo(-sz * 1.2, 0)
          ctx.closePath()
          ctx.fillStyle = col
          ctx.fill()
          ctx.restore()
        }

      // ---------------------------------------------------------------------
      // TREE 2: OAK (Heavy Branch Sway & Falling Acorns + Fluttering Leaves)
      // ---------------------------------------------------------------------
      } else if (root.isOak) {
        var oTop = "#4ade80"
        var oLeft = "#22c55e"
        var oRight = "#15803d"

        var oakAngle = Math.sin(root.oakSway) * (s * 0.1) + rustle
        // Integer harmonic ensures zero derivative pop at oakSway loop boundary
        var leafWave = Math.sin(root.oakSway * 2.0) * (s * 0.04)

        var olY = canopyBaseY + oakAngle * 0.4
        drawCube(cx - s * 0.85 + oakAngle * 0.3 - leafWave, olY + s * 0.1, s * 0.75, s * 0.68, oTop, oLeft, oRight)
        drawCube(cx + s * 0.85 + oakAngle * 0.3 + leafWave, olY + s * 0.1, s * 0.75, s * 0.68, oTop, oLeft, oRight)
        drawCube(cx + oakAngle * 0.5, olY, s * 1.2, s * 0.9, oTop, oLeft, oRight)

        var omY = olY - s * 0.88
        drawCube(cx - s * 0.6 + oakAngle * 0.6, omY - leafWave, s * 0.75, s * 0.72, oTop, oLeft, oRight)
        drawCube(cx + s * 0.6 + oakAngle * 0.6, omY + leafWave, s * 0.75, s * 0.72, oTop, oLeft, oRight)
        drawCube(cx + oakAngle * 0.75, omY - s * 0.2, s * 1.28, s * 0.98, oTop, oLeft, oRight)

        var ouY = omY - s * 0.95
        drawCube(cx + oakAngle * 1.1, ouY - s * 0.3, s * 0.92, s * 0.82, oTop, oLeft, oRight)

        // Bouncing Acorn Drop Animation (100% continuous periodic lifecycle envelope: buds -> falls -> bounces -> settles -> fades)
        var acT = root.acornPhase
        var acAlpha = 1.0
        var acScale = 1.0
        var acX = cx - s * 0.45
        var acY = canopyBaseY + s * 0.05

        if (acT < 0.15) {
          // 1. Budding on canopy branch (fades and scales up from 0)
          var growT = acT / 0.15
          acAlpha = growT
          acScale = 0.2 + 0.8 * growT
        } else if (acT < 0.75) {
          // 2. Falling with gravity acceleration
          var fallT = (acT - 0.15) / 0.60
          var fallEase = fallT * fallT
          acX = (cx - s * 0.45) + Math.sin(fallT * Math.PI) * (s * 0.20)
          acY = (canopyBaseY + s * 0.05) + fallEase * (cy - (canopyBaseY + s * 0.05))
        } else if (acT < 0.88) {
          // 3. Crisp bounce on ground
          var bounceT = (acT - 0.75) / 0.13
          var bounceH = Math.sin(bounceT * Math.PI) * (s * 0.22)
          acX = (cx - s * 0.45) + (s * 0.10) + bounceT * (s * 0.08)
          acY = cy - bounceH
        } else {
          // 4. Settles and smoothly fades into earth (alpha -> 0 at acT = 1.0)
          var fadeT = (acT - 0.88) / 0.12
          acX = (cx - s * 0.45) + (s * 0.18)
          acY = cy
          acAlpha = 1.0 - fadeT
          acScale = 1.0 - fadeT * 0.25
        }

        if (acAlpha > 0.01) {
          ctx.save()
          ctx.globalAlpha = Math.max(0, Math.min(1, acAlpha))
          var acSz = s * 0.16 * acScale
          drawCube(acX, acY - acSz, acSz * 1.2, acSz * 0.6, "#78350f", "#451a03", "#291002") // Acorn Cap
          drawCube(acX, acY, acSz, acSz * 0.8, "#d97706", "#b45309", "#92400e") // Acorn Nut
          ctx.restore()
        }

      // ---------------------------------------------------------------------
      // TREE 3: AUTUMN MAPLE (Dynamic Wind Gusts & Swirling Leaf Whirlwind)
      // ---------------------------------------------------------------------
      } else if (root.isAutumn) {
        var aTop = "#fef08a"
        var aLeft = "#f97316"
        var aRight = "#ea580c"
        var aTop2 = "#f97316"
        var aLeft2 = "#ef4444"
        var aRight2 = "#b91c1c"

        // Dynamic wind gust leans the canopy dynamically
        var gustLean = (root.autumnGust * s * 0.28) + rustle
        var gustLift = Math.sin(root.autumnGust * Math.PI) * (s * 0.08)

        var alY = canopyBaseY - gustLift + gustLean * 0.3
        drawCube(cx - s * 0.85 + gustLean * 0.3, alY + s * 0.15, s * 0.72, s * 0.65, aTop, aLeft, aRight)
        drawCube(cx + s * 0.85 + gustLean * 0.3, alY + s * 0.15, s * 0.72, s * 0.65, aTop2, aLeft2, aRight2)
        drawCube(cx + gustLean * 0.5, alY, s * 1.15, s * 0.85, aTop, aLeft, aRight)

        var amY = alY - s * 0.85
        drawCube(cx - s * 0.65 + gustLean * 0.6, amY, s * 0.78, s * 0.75, aTop2, aLeft2, aRight2)
        drawCube(cx + s * 0.65 + gustLean * 0.6, amY, s * 0.78, s * 0.75, aTop, aLeft, aRight)
        drawCube(cx + gustLean * 0.75, amY - s * 0.2, s * 1.25, s * 0.95, aTop2, aLeft2, aRight2)

        var auY = amY - s * 0.95
        drawCube(cx - s * 0.35 + gustLean * 0.9, auY, s * 0.65, s * 0.65, aTop, aLeft, aRight)
        drawCube(cx + s * 0.35 + gustLean * 0.9, auY, s * 0.65, s * 0.65, aTop2, aLeft2, aRight2)
        drawCube(cx + gustLean * 1.1, auY - s * 0.3, s * 0.88, s * 0.8, aTop, aLeft, aRight)

        // Swirling Autumn Leaf Whirlwind
        var aColors = ["#fef08a", "#f97316", "#ef4444", "#ca8a04", "#dc2626"]
        var aStartH = canopyBaseY - s * 2.0
        var aEndH = cy + s * 0.6
        var aTotalDist = aEndH - aStartH

        for (var j = 0; j < root.petalSeeds.length; j++) {
          var aSeed = root.petalSeeds[j]
          var at = (root.autumnLeafPhase * aSeed.spd + aSeed.yo) % 1.0

          // Sweeping whirlwind path: wide horizontal drift during gusts (harmonic 4*PI ensures zero wrap jerk)
          var gustSweep = root.autumnGust * (s * 0.7)
          var aDrift = Math.sin(at * Math.PI * 4.0 + aSeed.xo) * (s * 0.5 * aSeed.wAmp)
          var ax = cx + (aSeed.xo * s * 1.1) + aDrift + gustSweep
          var ay = aStartH + at * aTotalDist

          var aAlpha = 1.0
          if (at < 0.12) aAlpha = at / 0.12
          else if (at > 0.88) aAlpha = (1.0 - at) / 0.12

          var aSz = s * 0.15 * aSeed.sz
          var aCol = aColors[aSeed.c % aColors.length]

          ctx.save()
          ctx.translate(ax, ay)
          ctx.rotate(at * Math.PI * 6 + aSeed.xo)
          ctx.scale(Math.cos(at * Math.PI * 4), 1.0)
          ctx.globalAlpha = Math.max(0, Math.min(1, aAlpha))

          ctx.beginPath()
          ctx.moveTo(0, -aSz * 1.1)
          ctx.lineTo(aSz * 1.1, 0)
          ctx.lineTo(0, aSz * 0.8)
          ctx.lineTo(-aSz * 1.1, 0)
          ctx.closePath()
          ctx.fillStyle = aCol
          ctx.fill()
          ctx.restore()
        }

      // ---------------------------------------------------------------------
      // TREE 4: PINE (Alpine Spire Flex & Drifting Snow/Frost Flurries)
      // ---------------------------------------------------------------------
      } else if (root.isPine) {
        var pTop = "#10b981"
        var pLeft = "#059669"
        var pRight = "#047857"

        // Alpine wind sway: top spire sways much faster than rigid lower tiers
        var spireSway = Math.sin(root.pineSpirePhase) * (s * 0.12) + rustle

        // Tier 1 (Broad bottom)
        var pt1 = canopyBaseY + s * 0.2 + spireSway * 0.2
        drawCube(cx + spireSway * 0.2, pt1, s * 1.35, s * 0.6, pTop, pLeft, pRight)
        // Snow fleck on tier 1 corner
        drawCube(cx - s * 1.1 + spireSway * 0.2, pt1 - s * 0.2, s * 0.35, s * 0.2, "#ffffff", "#e0f2fe", "#bae6fd")

        // Tier 2 (Middle)
        var pt2 = pt1 - s * 0.65
        drawCube(cx + spireSway * 0.45, pt2, s * 1.05, s * 0.6, pTop, pLeft, pRight)
        drawCube(cx + s * 0.85 + spireSway * 0.45, pt2 - s * 0.2, s * 0.3, s * 0.2, "#ffffff", "#e0f2fe", "#bae6fd")

        // Tier 3 (Upper)
        var pt3 = pt2 - s * 0.65
        drawCube(cx + spireSway * 0.8, pt3, s * 0.75, s * 0.58, pTop, pLeft, pRight)

        // Tier 4 (Apex Spire)
        var pt4 = pt3 - s * 0.62
        drawCube(cx + spireSway * 1.15, pt4, s * 0.48, s * 0.55, "#34d399", pTop, pLeft)
        drawCube(cx + spireSway * 1.35, pt4 - s * 0.48, s * 0.25, s * 0.4, "#ffffff", "#6ee7b7", "#34d399")

        // Alpine Snow Flurry Particles (4*PI harmonic guarantees smooth rotation wrap)
        var sStartH = pt4 - s * 0.6
        var sEndH = cy + s * 0.5
        var sTotalDist = sEndH - sStartH

        for (var k = 0; k < root.petalSeeds.length; k++) {
          var sSeed = root.petalSeeds[k]
          var st = (root.snowFlurryPhase * sSeed.spd + sSeed.yo) % 1.0

          var sDrift = Math.sin(st * Math.PI * 4 + sSeed.xo) * (s * 0.35)
          var sx = cx + (sSeed.xo * s * 1.1) + sDrift + spireSway * 0.4
          var sy = sStartH + st * sTotalDist

          var sAlpha = 1.0
          if (st < 0.15) sAlpha = st / 0.15
          else if (st > 0.85) sAlpha = (1.0 - st) / 0.15

          var sSz = s * 0.08 * sSeed.sz

          ctx.save()
          ctx.translate(sx, sy)
          ctx.rotate(st * Math.PI * 4)
          ctx.globalAlpha = Math.max(0, Math.min(1, sAlpha))

          // Diamond snow flake
          ctx.beginPath()
          ctx.moveTo(0, -sSz)
          ctx.lineTo(sSz, 0)
          ctx.lineTo(0, sSz)
          ctx.lineTo(-sSz, 0)
          ctx.closePath()
          ctx.fillStyle = (k % 3 === 0) ? "#ffffff" : "#e0f2fe"
          ctx.fill()
          ctx.restore()
        }

      // ---------------------------------------------------------------------
      // TREE 5: BIRCH (Quivering Aspen Shimmer & Rising Golden Pollen Motes)
      // ---------------------------------------------------------------------
      } else {
        var bTop = "#bef264"
        var bLeft = "#84cc16"
        var bRight = "#4d7c0f"

        // High frequency quivering shimmer with exact integer harmonics for seamless 1.2s looping
        var shimmer1 = Math.sin(root.birchShimmer * 2.0) * (s * 0.04) + rustle
        var shimmer2 = Math.cos(root.birchShimmer * 1.5) * (s * 0.04)

        var blY = canopyBaseY
        drawCube(cx - s * 0.7 + shimmer1, blY, s * 0.68, s * 0.65, bTop, bLeft, bRight)
        drawCube(cx + s * 0.7 + shimmer2, blY, s * 0.68, s * 0.65, bTop, bLeft, bRight)
        drawCube(cx + shimmer1 * 0.5, blY - s * 0.1, s * 1.1, s * 0.85, bTop, bLeft, bRight)

        var bmY = blY - s * 0.85
        drawCube(cx - s * 0.5 + shimmer2, bmY, s * 0.72, s * 0.7, bTop, bLeft, bRight)
        drawCube(cx + s * 0.5 + shimmer1, bmY, s * 0.72, s * 0.7, bTop, bLeft, bRight)
        drawCube(cx + shimmer2 * 0.6, bmY - s * 0.2, s * 1.15, s * 0.95, bTop, bLeft, bRight)

        var buY = bmY - s * 0.95
        drawCube(cx + shimmer1 * 0.8, buY - s * 0.3, s * 0.85, s * 0.78, bTop, bLeft, bRight)

        // Golden Spring Pollen / Dandelion Motes (Floating upwards and swirling seamlessly)
        var pStartH = cy + s * 0.3
        var pEndH = buY - s * 1.2
        var pTotalDist = pStartH - pEndH

        for (var m = 0; m < root.petalSeeds.length; m++) {
          var pSeed2 = root.petalSeeds[m]
          var pmt = (root.pollenPhase * pSeed2.spd + pSeed2.yo) % 1.0

          // Motes rise upwards on thermal breezes with 4*PI harmonic drift!
          var pmx = cx + (pSeed2.xo * s * 1.3) + Math.sin(pmt * Math.PI * 4.0 + pSeed2.xo) * (s * 0.35)
          var pmy = pStartH - pmt * pTotalDist

          var pmAlpha = 1.0
          if (pmt < 0.15) pmAlpha = pmt / 0.15
          else if (pmt > 0.85) pmAlpha = (1.0 - pmt) / 0.15

          var pmSz = s * 0.07 * pSeed2.sz

          ctx.save()
          ctx.translate(pmx, pmy)
          ctx.globalAlpha = Math.max(0, Math.min(0.9, pmAlpha))

          ctx.beginPath()
          ctx.arc(0, 0, pmSz, 0, Math.PI * 2)
          ctx.fillStyle = (m % 2 === 0) ? "#fef08a" : "#d9f99d"
          ctx.fill()
          ctx.restore()
        }
      }
    }
  }

  // Interactive rustle on mouse press
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: rustleAnim.restart()
  }
}
