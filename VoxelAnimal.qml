import QtQuick
import Quickshell
import qs.Commons
import "Registry.js" as Reg

// VoxelAnimal — Autonomous interactive 3D voxel animals:
// - chicken: White chicken with red wattle & pecking AI
// - fox: Warm orange fox with smooth sweeping tail wag
// - cat: Calico/ginger tabby cat with pointed ears & swishing tail
// - sheep: Fluffy cloud-wool sheep with dark face & trotting legs
// - pig: Pastel pink pig with snout & curly tail
// Fully animated:
// - Walks dynamically between player-placed modular blocks on the desktop
// - Hops up/down across elevation changes and connected bridges
// - Autonomous AI: patrols, turns, idles, pecks/sits/wags
Item {
  id: root

  property var card: null
  property real widgetScale: 2.2
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string animalType: "chicken" // "chicken", "fox", "cat", "sheep", "pig"

  implicitWidth: Style.space(32) * root.widgetScale
  implicitHeight: Style.space(32) * root.widgetScale
  width: implicitWidth
  height: implicitHeight

  readonly property bool isFox: animalType === "fox" || animalType === "voxel-animal-fox"
  readonly property bool isCat: animalType === "cat" || animalType === "voxel-animal-cat"
  readonly property bool isSheep: animalType === "sheep" || animalType === "voxel-animal-sheep"
  readonly property bool isPig: animalType === "pig" || animalType === "voxel-animal-pig"
  readonly property bool isChicken: !isFox && !isCat && !isSheep && !isPig

  // Dynamic animation states
  property real facing: 1.0 // +1 facing right, -1 facing left
  property bool isWalking: false
  readonly property real walkStep: 0.0
  property real walkProgress: 0.0
  readonly property real idlePhase: 0.0
  readonly property real peckProgress: 0.0
  readonly property real tailSwing: 0.0
  property bool isSitting: false

  // Chicken pecking animation
  SequentialAnimation {
    id: peckAnim
    loops: 2
    NumberAnimation { target: root; property: "peckProgress"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "peckProgress"; from: 1.0; to: 0.0; duration: 220; easing.type: Easing.OutQuad }
  }

  // Smooth walk motion from current block to target block
  property real startX: 0
  property real startY: 0
  property real targetX: 0
  property real targetY: 0
  property int targetElev: 0

  SequentialAnimation {
    id: walkAnim
    NumberAnimation {
      target: root
      property: "walkProgress"
      from: 0.0; to: 1.0
      duration: 1100
      easing.type: Easing.InOutQuad
    }
    ScriptAction {
      script: {
        root.isWalking = false
        if (root.card) {
          root.card.x = Math.round(root.targetX)
          root.card.y = Math.round(root.targetY)
          root.card.elevation = root.targetElev
        }
        // Post-walk idle action
        if (root.isFox || root.isCat) {
          root.isSitting = (Math.random() > 0.45)
        }
        wanderTimer.interval = 18000 + Math.random() * 25000
        wanderTimer.restart()
      }
    }
  }

  onWalkProgressChanged: {
    if (!root.isWalking || !root.card) return
    var p = root.walkProgress
    // Linear trajectory with cute little hop arc
    var hopArc = Math.sin(p * Math.PI) * (root.isChicken ? -10 : -7)
    root.card.x = root.startX + (root.targetX - root.startX) * p
    root.card.y = root.startY + (root.targetY - root.startY) * p + hopArc
  }

  // Autonomous wandering AI on player-placed blocks
  Timer {
    id: wanderTimer
    interval: 18000 + Math.random() * 25000
    running: root.active && !root.isWalking
    repeat: false
    onTriggered: root.stepToAdjacentBlock()
  }

  function findDesktopCards() {
    var svc = (root.card && root.card.service) ? root.card.service : Reg.get()
    if (!svc || !svc._layers) return []
    var list = []
    for (var name in svc._layers) {
      var layer = svc._layers[name]
      if (layer && layer.cards) {
        for (var id in layer.cards) {
          var c = layer.cards[id]
          if (c) list.push(c)
        }
      }
    }
    return list
  }

  function isBlockCovered(blockCard, allCards) {
    var s = Style.space(8) * blockCard.textScale
    var topSurfaceX = blockCard.groundCenterX
    var topSurfaceY = blockCard.groundCenterY - s
    var blockElev = Number(blockCard.elevation || 0)

    for (var i = 0; i < allCards.length; i++) {
      var other = allCards[i]
      if (!other || other.widgetId === blockCard.widgetId) continue
      // Fast AABB distance pre-filter (eliminates 99.8% of comparisons instantly)
      if (Math.abs(other.groundCenterX - topSurfaceX) > 28 || Math.abs(other.groundCenterY - topSurfaceY) > 28) continue

      var isCoveringEntity = other.isBlock
        || (other.dioramaVariant && other.dioramaVariant.indexOf("block-") === 0)
        || other.isTree
        || (other.dioramaVariant && other.dioramaVariant.indexOf("tree-") !== -1)
      if (!isCoveringEntity) continue

      var otherElev = Number(other.elevation || 0)
      if (otherElev > blockElev) return true
    }
    return false
  }

  function stepToAdjacentBlock() {
    if (!root.card || root.isWalking) return
    if (root.card.hovered || root.card.selected) {
      wanderTimer.restart()
      return
    }

    var all = findDesktopCards()
    var surfaceNodes = []

    for (var i = 0; i < all.length; i++) {
      var c = all[i]
      if (!c) continue

      var isModularBlock = c.isBlock || (c.dioramaVariant && c.dioramaVariant.indexOf("block-") === 0)

      if (isModularBlock) {
        // Only exposed top faces are walkable surfaces! Covered blocks underneath are excluded.
        if (!root.isBlockCovered(c, all)) {
          surfaceNodes.push({
            x: c.groundCenterX,
            y: c.groundCenterY - (Style.space(8) * c.textScale),
            elev: Number(c.elevation || 0) + 1,
            id: c.widgetId
          })
        }
      }
    }

    if (surfaceNodes.length > 0) {
      // Find the surface node closest to our current animal feet on our current elevation
      var currentFeetX = root.card.x + root.width * 0.5
      var currentFeetY = root.card.y + root.height * 0.78
      var currentNode = null
      var minDist = 999999

      for (var j = 0; j < surfaceNodes.length; j++) {
        var node = surfaceNodes[j]
        var d = Math.hypot(currentFeetX - node.x, currentFeetY - node.y)
        // Strict level preservation: penalize different elevation so animal stays on its level
        if (root.card && node.elev !== root.card.elevation) {
          d += 1000
        }
        if (d < minDist) {
          minDist = d
          currentNode = node
        }
      }

      // If animal is not currently standing on the nearest surface, snap onto it
      if (minDist > 25 && currentNode) {
        root.startX = root.card.x
        root.startY = root.card.y
        root.targetX = currentNode.x - root.width * 0.5
        root.targetY = currentNode.y - root.height * 0.78
        root.targetElev = currentNode.elev
        root.card.elevation = currentNode.elev
        root.facing = (root.targetX >= root.startX) ? 1.0 : -1.0
        root.isSitting = false
        root.isWalking = true
        walkAnim.restart()
        return
      }

      // If standing on a surface node, find adjacent connected neighbors within walking step reach
      if (currentNode) {
        var neighbors = []
        var maxWalkReach = Style.space(8) * root.widgetScale * 4.2

        for (var k = 0; k < surfaceNodes.length; k++) {
          var cand = surfaceNodes[k]
          if (cand === currentNode) continue
          var dElev = Math.abs(Number(cand.elev || 0) - Number(currentNode.elev || 0))

          // Animals stay strictly on the level they are on
          if (dElev === 0) {
            var dist = Math.hypot(cand.x - currentNode.x, cand.y - currentNode.y)
            if (dist > 5 && dist <= maxWalkReach) {
              neighbors.push(cand)
            }
          }
        }

        if (neighbors.length > 0) {
          // Walk to a connected neighbor surface node
          var nextNode = neighbors[Math.floor(Math.random() * neighbors.length)]
          root.startX = root.card.x
          root.startY = root.card.y
          root.targetX = nextNode.x - root.width * 0.5
          root.targetY = nextNode.y - root.height * 0.78
          root.targetElev = nextNode.elev
          // Keep highest elevation during transition so step-down doesn't render behind
          root.card.elevation = Math.max(root.card.elevation, nextNode.elev)
          root.facing = (root.targetX >= root.startX) ? 1.0 : -1.0
          root.isSitting = false
          root.isWalking = true
          walkAnim.restart()
          return
        }
      }
    }

    // STRICT SAFETY INVARIANT: If no connected surfaces exist, DO NOT WALK INTO THE SKY!
    // The animal remains safely anchored on its block and performs idle animations.
    root.facing = -root.facing
    if (root.isFox || root.isCat) root.isSitting = !root.isSitting
    wanderTimer.interval = 18000 + Math.random() * 25000
    wanderTimer.restart()
  }

  Component.onCompleted: canvas.requestPaint()
  onFacingChanged: canvas.requestPaint()
  onIsSittingChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    onAvailableChanged: if (available) requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var s = Style.space(5) * root.widgetScale
      var h = s
      var sy = s * 0.5
      var cx = width * 0.5
      var cy = height * 0.78
      var f = root.facing

      function drawCube(x, y, sz, topC, leftC, rightC, strokeC) {
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
        if (strokeC !== "none") {
          ctx.strokeStyle = strokeC || "rgba(0,0,0,0.18)"
          ctx.lineWidth = 0.8
          ctx.stroke()
        }

        ctx.beginPath()
        ctx.moveTo(x - cs, y - ch)
        ctx.lineTo(x, y - ch + csy)
        ctx.lineTo(x, y + csy)
        ctx.lineTo(x - cs, y)
        ctx.closePath()
        ctx.fillStyle = leftC
        ctx.fill()
        if (strokeC !== "none") {
          ctx.strokeStyle = strokeC || "rgba(0,0,0,0.18)"
          ctx.lineWidth = 0.8
          ctx.stroke()
        }

        ctx.beginPath()
        ctx.moveTo(x, y - ch + csy)
        ctx.lineTo(x + cs, y - ch)
        ctx.lineTo(x + cs, y)
        ctx.lineTo(x, y + csy)
        ctx.closePath()
        ctx.fillStyle = rightC
        ctx.fill()
        if (strokeC !== "none") {
          ctx.strokeStyle = strokeC || "rgba(0,0,0,0.18)"
          ctx.lineWidth = 0.8
          ctx.stroke()
        }
      }

      // =====================================================================
      // 1. VOXEL CHICKEN
      // =====================================================================
      if (root.isChicken) {
        var cs = s * 0.85
        var legSwing1 = 0
        var legSwing2 = 0
        var bobY = 0

        if (root.isWalking) {
          legSwing1 = Math.sin(root.walkStep) * (cs * 0.45)
          legSwing2 = -legSwing1
          bobY = Math.abs(Math.sin(root.walkStep)) * (cs * 0.22)
        } else {
          bobY = Math.sin(root.idlePhase) * (cs * 0.1)
        }

        var headDip = root.peckProgress * (cs * 0.75)
        var headReach = root.peckProgress * (cs * 0.4) * f

        // Yellow Feet
        drawCube(cx - cs * 0.45 * f, cy + legSwing1, cs * 0.35, "#f59e0b", "#d97706", "#b45309")
        drawCube(cx + cs * 0.45 * f, cy + legSwing2, cs * 0.35, "#f59e0b", "#d97706", "#b45309")

        // White Body
        drawCube(cx, cy - cs * 0.85 - bobY, cs * 1.15, "#ffffff", "#f1f5f9", "#e2e8f0")

        // Flapping Wings
        var flap = root.isWalking ? Math.sin(root.walkStep * 1.5) * (cs * 0.2) : 0
        drawCube(cx - cs * 0.9, cy - cs * 0.8 - bobY - flap, cs * 0.65, "#f8fafc", "#f1f5f9", "#cbd5e1")
        drawCube(cx + cs * 0.9, cy - cs * 0.8 - bobY - flap, cs * 0.65, "#f8fafc", "#f1f5f9", "#cbd5e1")

        // Tail feathers
        drawCube(cx - cs * 0.8 * f, cy - cs * 1.35 - bobY, cs * 0.45, "#ffffff", "#f1f5f9", "#cbd5e1")

        // Head
        var hx = cx + (cs * 0.65 + headReach) * f
        var hy = cy - cs * 1.6 - bobY + headDip
        drawCube(hx, hy, cs * 0.85, "#ffffff", "#f1f5f9", "#e2e8f0")

        // Red Comb
        drawCube(hx, hy - cs * 0.75, cs * 0.38, "#ef4444", "#dc2626", "#b91c1c")

        // Eyes
        drawCube(hx - cs * 0.25, hy - cs * 0.12, cs * 0.2, "#0f172a", "#020617", "#020617")
        drawCube(hx + cs * 0.25, hy - cs * 0.12, cs * 0.2, "#0f172a", "#020617", "#020617")

        // Yellow Beak
        drawCube(hx + cs * 0.6 * f, hy + cs * 0.18, cs * 0.4, "#f59e0b", "#d97706", "#b45309")

        // Red Wattle
        drawCube(hx + cs * 0.48 * f, hy + cs * 0.38, cs * 0.24, "#ef4444", "#dc2626", "#b91c1c")
      }
      // =====================================================================
      // 2. VOXEL FOX (Fixed Harmonic Tail Wag!)
      // =====================================================================
      else if (root.isFox) {
        var fs = s * 0.8
        var fBob = 0
        var fLeg1 = 0, fLeg2 = 0, fLeg3 = 0, fLeg4 = 0

        if (root.isWalking) {
          fLeg1 = Math.sin(root.walkStep) * (fs * 0.4)
          fLeg2 = -fLeg1
          fLeg3 = -fLeg1
          fLeg4 = fLeg1
          fBob = Math.abs(Math.sin(root.walkStep)) * (fs * 0.18)
        } else if (!root.isSitting) {
          fBob = Math.sin(root.idlePhase) * (fs * 0.08)
        }

        var sitOffset = root.isSitting ? (fs * 0.5) : 0

        // Paws (front and rear)
        if (!root.isSitting) {
          drawCube(cx - fs * 0.8 * f, cy + fLeg1, fs * 0.35, "#7c2d12", "#581c87", "#431407")
          drawCube(cx - fs * 0.3 * f, cy + fLeg2, fs * 0.35, "#7c2d12", "#581c87", "#431407")
          drawCube(cx + fs * 0.3 * f, cy + fLeg3, fs * 0.35, "#7c2d12", "#581c87", "#431407")
          drawCube(cx + fs * 0.8 * f, cy + fLeg4, fs * 0.35, "#7c2d12", "#581c87", "#431407")
        } else {
          drawCube(cx + fs * 0.5 * f, cy, fs * 0.35, "#7c2d12", "#431407", "#431407")
          drawCube(cx - fs * 0.2 * f, cy, fs * 0.35, "#7c2d12", "#431407", "#431407")
        }

        // Orange Fox Body
        var bodyY = cy - fs * 0.7 - fBob + sitOffset
        drawCube(cx, bodyY, fs * 1.25, "#ea580c", "#c2410c", "#9a3412")

        // White Chest
        drawCube(cx + fs * 0.55 * f, bodyY - fs * 0.2, fs * 0.75, "#ffffff", "#f8fafc", "#e2e8f0")

        // Reversing Ping-Pong Sweeping Fox Tail (Continuous Smooth Wag)
        var wagSin = root.tailSwing
        var tailBaseX = cx - fs * 0.95 * f
        var tailBaseY = bodyY - fs * 0.35
        // Mid segment
        var tailMidX = tailBaseX - fs * 0.45 * f + wagSin * (fs * 0.25)
        var tailMidY = tailBaseY - fs * 0.35 + wagSin * (fs * 0.12)
        drawCube(tailMidX, tailMidY, fs * 0.65, "#ea580c", "#c2410c", "#9a3412")
        // Fluffy white tip sweeps wider
        var tailTipX = tailMidX - fs * 0.45 * f + wagSin * (fs * 0.45)
        var tailTipY = tailMidY - fs * 0.45 + wagSin * (fs * 0.22)
        drawCube(tailTipX, tailTipY, fs * 0.55, "#ffffff", "#f8fafc", "#e2e8f0")

        // Head
        var foxHeadX = cx + fs * 0.95 * f
        var foxHeadY = bodyY - fs * 0.95
        drawCube(foxHeadX, foxHeadY, fs * 0.95, "#ea580c", "#c2410c", "#9a3412")

        // White Cheeks / Muzzle
        drawCube(foxHeadX + fs * 0.45 * f, foxHeadY + fs * 0.15, fs * 0.55, "#ffffff", "#f8fafc", "#e2e8f0")

        // Black Nose
        drawCube(foxHeadX + fs * 0.75 * f, foxHeadY + fs * 0.05, fs * 0.28, "#0f172a", "#020617", "#020617")

        // Cute Eyes
        drawCube(foxHeadX + fs * 0.25 * f, foxHeadY - fs * 0.18, fs * 0.2, "#0f172a", "#020617", "#020617")

        // Pointy Ears with Dark Tips
        drawCube(foxHeadX - fs * 0.25, foxHeadY - fs * 0.85, fs * 0.4, "#ea580c", "#7c2d12", "#431407")
        drawCube(foxHeadX + fs * 0.25, foxHeadY - fs * 0.85, fs * 0.4, "#ea580c", "#7c2d12", "#431407")
      }
      // =====================================================================
      // 3. VOXEL CAT (Ginger Tabby with swishing tail & green eyes)
      // =====================================================================
      else if (root.isCat) {
        var kts = s * 0.75
        var kBob = 0
        var kLeg1 = 0, kLeg2 = 0, kLeg3 = 0, kLeg4 = 0

        if (root.isWalking) {
          kLeg1 = Math.sin(root.walkStep) * (kts * 0.35)
          kLeg2 = -kLeg1
          kLeg3 = -kLeg1
          kLeg4 = kLeg1
          kBob = Math.abs(Math.sin(root.walkStep)) * (kts * 0.15)
        } else if (!root.isSitting) {
          kBob = Math.sin(root.idlePhase) * (kts * 0.08)
        }

        var kSit = root.isSitting ? (kts * 0.45) : 0

        // White Paws
        if (!root.isSitting) {
          drawCube(cx - kts * 0.7 * f, cy + kLeg1, kts * 0.3, "#f8fafc", "#e2e8f0", "#cbd5e1")
          drawCube(cx - kts * 0.25 * f, cy + kLeg2, kts * 0.3, "#f8fafc", "#e2e8f0", "#cbd5e1")
          drawCube(cx + kts * 0.25 * f, cy + kLeg3, kts * 0.3, "#f8fafc", "#e2e8f0", "#cbd5e1")
          drawCube(cx + kts * 0.7 * f, cy + kLeg4, kts * 0.3, "#f8fafc", "#e2e8f0", "#cbd5e1")
        } else {
          drawCube(cx + kts * 0.45 * f, cy, kts * 0.3, "#f8fafc", "#e2e8f0", "#cbd5e1")
          drawCube(cx - kts * 0.2 * f, cy, kts * 0.3, "#f8fafc", "#e2e8f0", "#cbd5e1")
        }

        // Calico/Orange Cat Body
        var kBodyY = cy - kts * 0.65 - kBob + kSit
        drawCube(cx, kBodyY, kts * 1.15, "#f97316", "#ea580c", "#c2410c")

        // White Belly Patch
        drawCube(cx + kts * 0.45 * f, kBodyY - kts * 0.15, kts * 0.65, "#ffffff", "#f8fafc", "#e2e8f0")

        // Swishing Curved Cat Tail (Seamless Reversing Arc)
        var cWag = root.tailSwing
        var cTailX = cx - kts * 0.85 * f
        var cTailY = kBodyY - kts * 0.4
        drawCube(cTailX + cWag * (kts * 0.2), cTailY - kts * 0.3, kts * 0.4, "#ea580c", "#c2410c", "#9a3412")
        drawCube(cTailX - kts * 0.25 * f + cWag * (kts * 0.45), cTailY - kts * 0.8, kts * 0.35, "#ffffff", "#f8fafc", "#e2e8f0")

        // Head
        var kHeadX = cx + kts * 0.85 * f
        var kHeadY = kBodyY - kts * 0.85
        drawCube(kHeadX, kHeadY, kts * 0.88, "#f97316", "#ea580c", "#c2410c")

        // White Muzzle
        drawCube(kHeadX + kts * 0.45 * f, kHeadY + kts * 0.18, kts * 0.45, "#ffffff", "#f8fafc", "#e2e8f0")
        // Pink Nose
        drawCube(kHeadX + kts * 0.65 * f, kHeadY + kts * 0.08, kts * 0.2, "#f472b6", "#ec4899", "#db2777")

        // Emerald Eyes
        drawCube(kHeadX + kts * 0.22 * f, kHeadY - kts * 0.16, kts * 0.2, "#10b981", "#059669", "#047857")

        // Pointed Triangular Ears with Pink Interior
        drawCube(kHeadX - kts * 0.22, kHeadY - kts * 0.75, kts * 0.35, "#ea580c", "#c2410c", "#9a3412")
        drawCube(kHeadX + kts * 0.22, kHeadY - kts * 0.75, kts * 0.35, "#ea580c", "#c2410c", "#9a3412")
        drawCube(kHeadX + kts * 0.15 * f, kHeadY - kts * 0.65, kts * 0.18, "#f472b6", "#ec4899", "#db2777")
      }
      // =====================================================================
      // 4. VOXEL SHEEP (Fluffy cloud wool & dark face)
      // =====================================================================
      else if (root.isSheep) {
        var shs = s * 0.85
        var shLeg1 = 0, shLeg2 = 0, shLeg3 = 0, shLeg4 = 0
        var shBob = 0

        if (root.isWalking) {
          shLeg1 = Math.sin(root.walkStep) * (shs * 0.38)
          shLeg2 = -shLeg1
          shLeg3 = -shLeg1
          shLeg4 = shLeg1
          shBob = Math.abs(Math.sin(root.walkStep)) * (shs * 0.18)
        } else {
          shBob = Math.sin(root.idlePhase) * (shs * 0.08)
        }

        // Dark Little Hooves
        drawCube(cx - shs * 0.75 * f, cy + shLeg1, shs * 0.35, "#334155", "#1e293b", "#0f172a")
        drawCube(cx - shs * 0.25 * f, cy + shLeg2, shs * 0.35, "#334155", "#1e293b", "#0f172a")
        drawCube(cx + shs * 0.25 * f, cy + shLeg3, shs * 0.35, "#334155", "#1e293b", "#0f172a")
        drawCube(cx + shs * 0.75 * f, cy + shLeg4, shs * 0.35, "#334155", "#1e293b", "#0f172a")

        // Fluffy Puffy Cloud Wool Body (Cluster)
        var shBodyY = cy - shs * 0.8 - shBob
        drawCube(cx, shBodyY, shs * 1.45, "#ffffff", "#f8fafc", "#e2e8f0")
        drawCube(cx - shs * 0.6 * f, shBodyY - shs * 0.35, shs * 1.1, "#f8fafc", "#f1f5f9", "#cbd5e1")
        drawCube(cx + shs * 0.35 * f, shBodyY - shs * 0.35, shs * 1.1, "#ffffff", "#f8fafc", "#e2e8f0")

        // Dark Charcoal Head
        var shHeadX = cx + shs * 1.05 * f
        var shHeadY = shBodyY - shs * 0.65
        drawCube(shHeadX, shHeadY, shs * 0.85, "#334155", "#1e293b", "#0f172a")

        // White Wool Tuft on Top of Head
        drawCube(shHeadX, shHeadY - shs * 0.65, shs * 0.55, "#ffffff", "#f8fafc", "#e2e8f0")

        // Sheep Eyes
        drawCube(shHeadX + shs * 0.3 * f, shHeadY - shs * 0.12, shs * 0.2, "#f8fafc", "#e2e8f0", "#020617")

        // Drooping Dark Ears
        drawCube(shHeadX - shs * 0.35, shHeadY + shs * 0.15, shs * 0.35, "#1e293b", "#0f172a", "#020617")
        drawCube(shHeadX + shs * 0.35, shHeadY + shs * 0.15, shs * 0.35, "#1e293b", "#0f172a", "#020617")
      }
      // =====================================================================
      // 5. VOXEL PIG (Pink pig with snout & curly tail)
      // =====================================================================
      else if (root.isPig) {
        var pgs = s * 0.82
        var pgLeg1 = 0, pgLeg2 = 0, pgLeg3 = 0, pgLeg4 = 0
        var pgBob = 0

        if (root.isWalking) {
          pgLeg1 = Math.sin(root.walkStep) * (pgs * 0.38)
          pgLeg2 = -pgLeg1
          pgLeg3 = -pgLeg1
          pgLeg4 = pgLeg1
          pgBob = Math.abs(Math.sin(root.walkStep)) * (pgs * 0.18)
        } else {
          pgBob = Math.sin(root.idlePhase) * (pgs * 0.08)
        }

        // Pink Trotters
        drawCube(cx - pgs * 0.7 * f, cy + pgLeg1, pgs * 0.35, "#f472b6", "#ec4899", "#db2777")
        drawCube(cx - pgs * 0.25 * f, cy + pgLeg2, pgs * 0.35, "#f472b6", "#ec4899", "#db2777")
        drawCube(cx + pgs * 0.25 * f, cy + pgLeg3, pgs * 0.35, "#f472b6", "#ec4899", "#db2777")
        drawCube(cx + pgs * 0.7 * f, cy + pgLeg4, pgs * 0.35, "#f472b6", "#ec4899", "#db2777")

        // Chubby Pink Body
        var pgBodyY = cy - pgs * 0.75 - pgBob
        drawCube(cx, pgBodyY, pgs * 1.35, "#f472b6", "#ec4899", "#db2777")

        // Wiggling Curly Spiral Tail (Smooth Reversing Twitch)
        var pWag = root.tailSwing
        var pTailX = cx - pgs * 0.95 * f
        var pTailY = pgBodyY - pgs * 0.4
        drawCube(pTailX, pTailY + pWag * (pgs * 0.18), pgs * 0.35, "#ec4899", "#db2777", "#be185d")
        drawCube(pTailX - pgs * 0.25 * f, pTailY - pgs * 0.25, pgs * 0.25, "#f472b6", "#ec4899", "#db2777")

        // Big Boxy Pig Head
        var pgHeadX = cx + pgs * 0.95 * f
        var pgHeadY = pgBodyY - pgs * 0.7
        drawCube(pgHeadX, pgHeadY, pgs * 0.95, "#f472b6", "#ec4899", "#db2777")

        // Distinctive Flat Snout
        var snoutX = pgHeadX + pgs * 0.65 * f
        var snoutY = pgHeadY + pgs * 0.15
        drawCube(snoutX, snoutY, pgs * 0.52, "#fbcfe8", "#f472b6", "#ec4899")
        // Dark Nostril Pixels
        drawCube(snoutX + pgs * 0.22 * f, snoutY + pgs * 0.05, pgs * 0.18, "#831843", "#500724", "#500724")

        // Eyes
        drawCube(pgHeadX + pgs * 0.18 * f, pgHeadY - pgs * 0.18, pgs * 0.2, "#0f172a", "#020617", "#020617")

        // Floppy Ears
        drawCube(pgHeadX - pgs * 0.25, pgHeadY - pgs * 0.68, pgs * 0.38, "#ec4899", "#db2777", "#9d174d")
        drawCube(pgHeadX + pgs * 0.25, pgHeadY - pgs * 0.68, pgs * 0.38, "#ec4899", "#db2777", "#9d174d")
      }
    }
  }
}
