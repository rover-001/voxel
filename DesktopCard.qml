import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.Commons
import "Model.js" as Model
import "Registry.js" as Reg

// Interactive desktop surface card for ANY Voxel entity:
// Dioramas (Island, Campfire), modular Blocks, Clouds, and Animals.
// All entities support magnetic snapping to one another on the isometric grid!
Item {
  id: card

  required property var service
  required property string widgetId
  required property string widgetStyle
  required property var screen

  property real textScale: isBlock || isWord ? 3.6 : 2.2
  property real rotationAngle: 0
  property bool locked: false
  property bool selected: false
  property bool keepCentered: false
  property int elevation: 0
  property var layerWindow: null
  property bool inActiveCluster: false

  readonly property var meta: Model.findById(widgetStyle)
  readonly property string dioramaVariant: meta ? meta.variant : "block-grass"
  readonly property bool isBlock: dioramaVariant.indexOf("block-") === 0
  readonly property bool isProp: dioramaVariant.indexOf("prop-") === 0
    || dioramaVariant.indexOf("voxel-prop-") === 0
  readonly property bool isStairs: dioramaVariant.indexOf("stairs") !== -1
  readonly property bool isTree: dioramaVariant.indexOf("tree-") === 0
    || dioramaVariant.indexOf("voxel-tree-") === 0
    || dioramaVariant === "tree"
  readonly property bool isAnimal: dioramaVariant.indexOf("animal-") === 0
    || dioramaVariant.indexOf("voxel-animal-") === 0
    || dioramaVariant === "chicken"
    || dioramaVariant === "fox"
    || dioramaVariant === "cat"
    || dioramaVariant === "sheep"
    || dioramaVariant === "pig"
  readonly property bool isWord: dioramaVariant === "word-rover" || dioramaVariant === "voxel-word-rover"

  implicitWidth: diorama.width
  implicitHeight: diorama.height
  width: implicitWidth
  height: implicitHeight

  property bool isClusterDragging: false
  property bool isMagnetSnapped: false

  // Ground anchor center in desktop layer coordinates (exact integer coordinates)
  readonly property real groundCenterX: Math.round(card.x + card.width * 0.5)
  readonly property real groundCenterY: {
    if (card.isBlock) return Math.round(card.y + card.height * (1.7 / 2.4))
    if (card.isAnimal) return Math.round(card.y + card.height * 0.78)
    if (card.isTree) return Math.round(card.y + card.height * (5.0 / 6.0))
    if (card.isProp) return Math.round(card.y + card.height * 0.75)
    return Math.round(card.y + card.height * 0.72)
  }

  // Natural 3D Isometric Depth Sorting:
  // Higher elevation and lower screen Y render in front.
  // Standardized grid unit (Style.space(8) * 3.6) guarantees that modular blocks,
  // animals, and trees sort with the exact same isometric elevation height constant.
  readonly property int naturalZ: {
    var gridUnit = Style.space(8) * 3.6
    var elevBonus = card.elevation * Math.round(gridUnit * 2.0)
    var animalBoost = card.isAnimal ? 1000 : 0
    var propBoost = card.isProp ? 200 : 0
    return Math.round(card.groundCenterY + elevBonus + animalBoost + propBoost)
  }

  z: {
    // 1. Single card dragging or corner resizing: Held item floats on top
    if (resizer.active || (dragger.active && !dragger.isGroupDrag)) {
      return 200000
    }
    // 2. Active animal walking/hopping: Elevated so it is unconditionally on top of blocks it walks over
    if (card.isAnimal && diorama.item && diorama.item.isWalking) {
      return 10000 + card.naturalZ
    }
    // 3. Moving whole cluster: Lift all cluster members above background desktop items,
    // while STRICTLY preserving the relative 3D isometric depth of every block!
    if (card.isClusterDragging || (dragger.active && dragger.isGroupDrag)) {
      return 100000 + card.naturalZ
    }
    // 4. Selected card: Subtle priority without inverting physical stacking order
    if (card.selected) {
      return 500 + card.naturalZ
    }
    // 5. Natural 3D isometric depth at rest
    return card.naturalZ
  }

  transformOrigin: Item.Center
  rotation: (card.isProp || card.isBlock || card.isTree) ? 0 : card.rotationAngle

  function clampIntoScreen() {
    if (!card.screen) return
    var minVisible = Math.min(Style.space(32), Math.min(width, height) / 2)
    x = Math.max(-width + minVisible, Math.min(x, screen.width - minVisible))
    y = Math.max(-height + minVisible, Math.min(y, screen.height - minVisible))
  }

  // Discovers all connected blocks, trees, and animals in this structure via BFS flood fill
  function getConnectedCluster() {
    var myLayer = card.layerWindow
    if (!myLayer) {
      var svc = card.service || Reg.get()
      if (svc && svc._layers) {
        for (var name in svc._layers) {
          if (svc._layers[name] && svc._layers[name].cards && svc._layers[name].cards[card.widgetId]) {
            myLayer = svc._layers[name]
            break
          }
        }
      }
    }
    if (!myLayer || !myLayer.cards) return [card]

    var all = []
    for (var id in myLayer.cards) {
      if (myLayer.cards[id]) all.push(myLayer.cards[id])
    }

    function areConnected(a, b) {
      if (!a || !b || a === b) return false
      var s = Style.space(8) * Math.max(a.textScale, b.textScale)
      var dx = a.groundCenterX - b.groundCenterX
      var dy = a.groundCenterY - b.groundCenterY
      var dist = Math.hypot(dx, dy)
      var dElev = Math.abs(Number(a.elevation || 0) - Number(b.elevation || 0))

      // 1. Same elevation (adjacent blocks touching horizontally or diagonally)
      if (dElev === 0) {
        if (dist <= s * 2.18) return true
      }
      // 2. Vertical stacking (item on top of another block)
      if (dElev === 1) {
        if (Math.abs(dx) < 22 && Math.abs(Math.abs(dy) - s) < 22) return true
        if (dist <= s * 1.6) return true
      }
      return false
    }

    var visited = {}
    visited[card.widgetId] = true
    var cluster = [card]
    var queue = [card]

    while (queue.length > 0) {
      var curr = queue.shift()
      for (var i = 0; i < all.length; i++) {
        var other = all[i]
        if (!visited[other.widgetId] && areConnected(curr, other)) {
          visited[other.widgetId] = true
          cluster.push(other)
          queue.push(other)
        }
      }
    }
    return cluster
  }

  // Universal magnetic snap slot query against all other entities on the desktop.
  // Returns slot candidate with exact coordinates, elevation, and target scale.
  function getSnapSlot(candidateGCX, candidateGCY, excludeList, snapThreshold) {
    var thresh = snapThreshold || 56
    var svc = card.service || Reg.get()
    if (!svc || !svc._layers) return { found: false }

    var myLayer = card.layerWindow
    if (!myLayer) {
      for (var name in svc._layers) {
        if (svc._layers[name] && svc._layers[name].cards && svc._layers[name].cards[card.widgetId]) {
          myLayer = svc._layers[name]
          break
        }
      }
    }
    if (!myLayer || !myLayer.cards) return { found: false }

    var cards = myLayer.cards
    var excludeMap = {}
    excludeMap[card.widgetId] = true
    if (excludeList && excludeList.length) {
      for (var e = 0; e < excludeList.length; e++) {
        if (excludeList[e]) excludeMap[excludeList[e].widgetId] = true
      }
    }

    // High-performance snapshot & spatial indexing: reads cards into plain JS numbers once
    var cardList = []
    var nearbyCandidates = []
    var maxReach = thresh + 140

    for (var id in cards) {
      if (excludeMap[id]) continue
      var o = cards[id]
      if (!o) continue
      var ocx = o.groundCenterX
      var ocy = o.groundCenterY
      var oelev = Number(o.elevation || 0)
      var itemData = {
        cx: ocx,
        cy: ocy,
        elev: oelev,
        scale: o.textScale,
        isBlock: o.isBlock,
        isTree: o.isTree,
        isProp: o.isProp,
        isAnimal: o.isAnimal
      }
      cardList.push(itemData)

      // Only check slots of blocks physically within reach of the dragged card
      if (Math.abs(ocx - candidateGCX) < maxReach && Math.abs(ocy - candidateGCY) < maxReach) {
        nearbyCandidates.push(itemData)
      }
    }

    if (!nearbyCandidates.length) return { found: false }

    function isSlotOccupied(cx, cy, elev) {
      for (var i = 0; i < cardList.length; i++) {
        var c = cardList[i]
        // Never allow two entities to occupy the exact same 2D screen position (prevents clipping inside)
        if (Math.hypot(c.cx - cx, c.cy - cy) < 20) {
          return true
        }
        if (c.elev === elev && Math.hypot(c.cx - cx, c.cy - cy) < 28) {
          return true
        }
      }
      return false
    }

    var bestTargetCX = candidateGCX
    var bestTargetCY = candidateGCY
    var bestElevation = card.elevation
    var bestTargetScale = card.textScale
    var foundSnap = false
    var minDistance = thresh + 1

    for (var n = 0; n < nearbyCandidates.length; n++) {
      var other = nearbyCandidates[n]
      // Solid snap topology: ONLY snap onto building blocks (other.isBlock), never trees or props!
      if (!other.isBlock) continue

      var otherGCX = other.cx
      var otherGCY = other.cy
      var otherElev = other.elev
      var targetScale = (card.isBlock && other.isBlock) ? other.scale : card.textScale
      // Even-integer isometric unit: guarantees laser-straight, 100% even tile edges
      var s = Math.round((Style.space(8) * targetScale) / 2) * 2
      var unitStepX = s
      var unitStepY = Math.round(s * 0.5)
      var unitStackY = s

      var slots = [
        // 1. Direct stack on top (shifted up by unitStackY in screen space)
        { cx: otherGCX, cy: otherGCY - unitStackY, elev: otherElev + 1 }
      ]

      // Animals, Trees, and Props only sit on top of blocks or ground, never floating beside them
      if (!card.isAnimal && !card.isTree && !card.isProp) {
        // 4 orthogonal isometric face-adjacent neighbors (strictly same elevation)
        // 100% solid face contact with ZERO volume clipping or interpenetration
        slots.push({ cx: otherGCX + unitStepX, cy: otherGCY + unitStepY, elev: otherElev })
        slots.push({ cx: otherGCX - unitStepX, cy: otherGCY + unitStepY, elev: otherElev })
        slots.push({ cx: otherGCX + unitStepX, cy: otherGCY - unitStepY, elev: otherElev })
        slots.push({ cx: otherGCX - unitStepX, cy: otherGCY - unitStepY, elev: otherElev })
      }

      for (var sIdx = 0; sIdx < slots.length; sIdx++) {
        var sl = slots[sIdx]
        if (isSlotOccupied(sl.cx, sl.cy, sl.elev)) continue

        var d = Math.hypot(candidateGCX - sl.cx, candidateGCY - sl.cy)
        if (d < minDistance) {
          minDistance = d
          bestTargetCX = sl.cx
          bestTargetCY = sl.cy
          bestElevation = sl.elev
          bestTargetScale = targetScale
          foundSnap = true
        }
      }
    }

    if (foundSnap && minDistance <= thresh) {
      return {
        found: true,
        targetCX: bestTargetCX,
        targetCY: bestTargetCY,
        elevation: bestElevation,
        scale: bestTargetScale,
        distance: minDistance
      }
    }
    return { found: false }
  }

  // Universal magnetic snap check against all other entities on the desktop
  // Snaps blocks, trees, clouds, and animals to the shared isometric grid!
  function snapToNearbyBlocks(excludeList) {
    var myGCX = card.groundCenterX
    var myGCY = card.groundCenterY
    var snap = card.getSnapSlot(myGCX, myGCY, excludeList, 56)

    if (snap.found) {
      if (card.isBlock || card.isTree || card.isProp) {
        card.textScale = snap.scale
      }
      var currentUnit = Style.space(8) * card.textScale
      var finalW = card.isBlock ? (currentUnit * 2.4) : (card.isTree ? (currentUnit * 4.8) : (card.isProp ? (currentUnit * 3.6) : card.width))
      var finalH = card.isBlock ? (currentUnit * 2.4) : (card.isTree ? (currentUnit * 7.2) : (card.isProp ? (currentUnit * 4.4) : card.height))
      var finalAnchorY = card.isBlock ? (finalH * (1.7 / 2.4))
        : (card.isAnimal ? (finalH * 0.78)
        : (card.isTree ? (finalH * (5.0 / 6.0))
        : (card.isProp ? (finalH * 0.75) : (finalH * 0.72))))

      card.x = Math.round(snap.targetCX - finalW * 0.5)
      card.y = Math.round(snap.targetCY - finalAnchorY)
      card.elevation = snap.elevation
      snapAnim.restart()
    }
  }

  SequentialAnimation {
    id: snapAnim
    NumberAnimation {
      target: card
      property: "scale"
      from: 1.12; to: 1.0
      duration: 180
      easing.type: Easing.OutBack
    }
  }

  function settleAround() {
    card.snapToNearbyBlocks()
    card.clampIntoScreen()
    if (card.service && typeof card.service.cardMoved === "function")
      card.service.cardMoved(card.widgetId, x, y, card.elevation)
  }

  // ---- Voxel Diorama / Block / Cloud / Animal / Prop ---------------------
  VoxelDiorama {
    id: diorama
    card: card
    anchors.centerIn: parent
    variant: card.dioramaVariant
    widgetScale: card.textScale
    propRotation: Math.round(((card.rotationAngle % 360) + 360) % 360 / 90) % 4
    active: true
    accentColor: Color.accent
    fgColor: Color.foreground
  }

  readonly property bool hovered: cardHover.hovered
    || removeArea.containsMouse
    || rotateCwArea.containsMouse
    || rotateCcwArea.containsMouse
    || resizeArea.containsMouse
    || layerUpArea.containsMouse
    || layerDownArea.containsMouse
    || resizer.active

  HoverHandler {
    id: cardHover
  }

  onHoveredChanged: {
    if (card.layerWindow) {
      if (card.hovered || card.selected) card.layerWindow.cardActivated(card)
      else card.layerWindow.cardDeactivated(card)
    }
  }

  onSelectedChanged: {
    if (card.layerWindow) {
      if (card.hovered || card.selected) card.layerWindow.cardActivated(card)
      else card.layerWindow.cardDeactivated(card)
    }
  }

  // ---- Dotted selection outline (shown on hover, selected, or active cluster) --
  Shape {
    id: outline
    anchors.fill: parent
    anchors.margins: -Style.space(4)
    visible: ((card.hovered || card.selected || card.inActiveCluster) && !card.locked)
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    ShapePath {
      strokeColor: (card.hovered || card.selected)
        ? Color.accent
        : Util.alpha(Color.accent, 0.45)
      strokeWidth: (card.hovered || card.selected) ? 2.0 : 1.5
      strokeStyle: ShapePath.DashLine
      dashPattern: [3, 3]
      fillColor: "transparent"
      startX: 0; startY: 0
      PathLine { x: outline.width; y: 0 }
      PathLine { x: outline.width; y: outline.height }
      PathLine { x: 0; y: outline.height }
      PathLine { x: 0; y: 0 }
    }
  }

  // ---- Remove handle (top-right) -------------------------------------------
  Rectangle {
    id: removeDot
    z: 100
    x: card.width - removeDot.width / 2
    y: -removeDot.height / 2
    visible: (card.hovered || card.selected) && !card.locked
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: Style.space(18)
    height: Style.space(18)
    radius: width / 2
    color: Util.alpha(Color.popups.background, 0.95)
    border.width: 1
    border.color: Util.alpha(Color.foreground, 0.3)

    Text {
      anchors.centerIn: parent
      text: "✕"
      color: Color.foreground
      font.pixelSize: Style.space(10)
      font.bold: true
    }

    MouseArea {
      id: removeArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onClicked: card.removeRequested()
    }
  }

  // ---- Rotate Clockwise Button ("↻") --------------------------------------
  Rectangle {
    id: rotateCwDot
    z: 100
    x: card.width - removeDot.width / 2 - Style.space(22)
    y: -rotateCwDot.height / 2
    visible: (card.hovered || card.selected) && !card.locked
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: Style.space(18)
    height: Style.space(18)
    radius: width / 2
    color: rotateCwArea.containsMouse ? Util.alpha(Color.accent, 0.25) : Util.alpha(Color.popups.background, 0.95)
    border.width: 1
    border.color: rotateCwArea.containsMouse ? Color.accent : Util.alpha(Color.foreground, 0.3)

    Text {
      anchors.centerIn: parent
      text: "↻"
      color: rotateCwArea.containsMouse ? Color.accent : Color.foreground
      font.pixelSize: Style.space(11)
      font.bold: true
      rotation: rotateCwArea.pressed ? 45 : 0
      Behavior on rotation { NumberAnimation { duration: 120 } }
    }

    MouseArea {
      id: rotateCwArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onClicked: {
        var newAngle = ((Number(card.rotationAngle || 0) + 90) % 360 + 360) % 360
        card.rotationAngle = newAngle
        if (card.snapAnim && typeof card.snapAnim.restart === "function") {
          card.snapAnim.restart()
        }
        if (card.service && typeof card.service.cardRotated === "function") {
          card.service.cardRotated(card.widgetId, newAngle)
        } else if (card.service && typeof card.service.cardMoved === "function") {
          card.service.cardMoved(card.widgetId, card.x, card.y, card.elevation, newAngle)
        }
      }
    }
  }

  // ---- Rotate Counter-Clockwise Button ("↺") ------------------------------
  Rectangle {
    id: rotateCcwDot
    z: 100
    x: card.width - removeDot.width / 2 - Style.space(44)
    y: -rotateCcwDot.height / 2
    visible: (card.hovered || card.selected) && !card.locked
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: Style.space(18)
    height: Style.space(18)
    radius: width / 2
    color: rotateCcwArea.containsMouse ? Util.alpha(Color.accent, 0.25) : Util.alpha(Color.popups.background, 0.95)
    border.width: 1
    border.color: rotateCcwArea.containsMouse ? Color.accent : Util.alpha(Color.foreground, 0.3)

    Text {
      anchors.centerIn: parent
      text: "↺"
      color: rotateCcwArea.containsMouse ? Color.accent : Color.foreground
      font.pixelSize: Style.space(11)
      font.bold: true
      rotation: rotateCcwArea.pressed ? -45 : 0
      Behavior on rotation { NumberAnimation { duration: 120 } }
    }

    MouseArea {
      id: rotateCcwArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onClicked: {
        var newAngle = ((Number(card.rotationAngle || 0) - 90) % 360 + 360) % 360
        card.rotationAngle = newAngle
        if (card.snapAnim && typeof card.snapAnim.restart === "function") {
          card.snapAnim.restart()
        }
        if (card.service && typeof card.service.cardRotated === "function") {
          card.service.cardRotated(card.widgetId, newAngle)
        } else if (card.service && typeof card.service.cardMoved === "function") {
          card.service.cardMoved(card.widgetId, card.x, card.y, card.elevation, newAngle)
        }
      }
    }
  }

  // ---- Bring Forward / Layer Up (top-left) --------------------------------
  Rectangle {
    id: layerUpDot
    z: 100
    x: -layerUpDot.width / 2
    y: -layerUpDot.height / 2
    visible: (card.hovered || card.selected) && !card.locked
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: Style.space(18)
    height: Style.space(18)
    radius: width / 2
    color: Util.alpha(Color.popups.background, 0.95)
    border.width: 1
    border.color: Util.alpha(Color.accent, 0.6)

    Text {
      anchors.centerIn: parent
      text: "▲"
      color: Color.accent
      font.pixelSize: Style.space(9)
      font.bold: true
    }

    MouseArea {
      id: layerUpArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onClicked: {
        var s = Style.space(8) * Math.max(1.0, card.textScale)
        card.elevation += 1
        card.y -= s
        card.clampIntoScreen()
        if (card.service && typeof card.service.cardMoved === "function")
          card.service.cardMoved(card.widgetId, card.x, card.y, card.elevation)
      }
    }
  }

  // ---- Send Backward / Layer Down (bottom-left) ---------------------------
  Rectangle {
    id: layerDownDot
    z: 100
    x: -layerDownDot.width / 2
    y: card.height - layerDownDot.height / 2
    visible: (card.hovered || card.selected) && !card.locked
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: Style.space(18)
    height: Style.space(18)
    radius: width / 2
    color: Util.alpha(Color.popups.background, 0.95)
    border.width: 1
    border.color: Util.alpha(Color.foreground, 0.3)

    Text {
      anchors.centerIn: parent
      text: "▼"
      color: Util.alpha(Color.foreground, 0.7)
      font.pixelSize: Style.space(9)
      font.bold: true
    }

    MouseArea {
      id: layerDownArea
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onClicked: {
        if (card.elevation > 0) {
          var s = Style.space(8) * Math.max(1.0, card.textScale)
          card.elevation -= 1
          card.y += s
          card.clampIntoScreen()
          if (card.service && typeof card.service.cardMoved === "function")
            card.service.cardMoved(card.widgetId, card.x, card.y, card.elevation)
        }
      }
    }
  }

  // ---- Resize handle (bottom-right) — Using Whimsy's pointer DragHandler ----
  // Handles fast inward/outward motion cleanly without dropping pointer capture
  Rectangle {
    id: resizeDot
    z: 100
    x: card.width - resizeDot.width / 2
    y: card.height - resizeDot.height / 2
    visible: (card.hovered || card.selected) && !card.locked
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: Style.space(18)
    height: Style.space(18)
    radius: width / 2
    color: Util.alpha(Color.popups.background, 0.95)
    border.width: 1
    border.color: Util.alpha(Color.accent, 0.6)

    Text {
      anchors.centerIn: parent
      text: "⤡"
      color: Color.accent
      font.pixelSize: Style.space(12)
      font.bold: true
    }

    // Hover-only cursor
    MouseArea {
      id: resizeArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      cursorShape: Qt.SizeFDiagCursor
    }

    // Pointer-level DragHandler matching Whimsy:
    // Tracks continuously anywhere on screen even if cursor moves inward off the dot
    DragHandler {
      id: resizer
      target: null
      acceptedButtons: Qt.LeftButton
      enabled: !card.locked
      grabPermissions: PointerHandler.CanTakeOverFromItems
        | PointerHandler.CanTakeOverFromHandlersOfSameType

      property real startScale: 2.2
      property point startPoint

      onActiveChanged: {
        if (resizer.active) {
          card.keepCentered = false
          resizer.startScale = card.textScale
          resizer.startPoint = resizer.centroid.scenePosition
        } else if (!resizer.active) {
          card.clampIntoScreen()
          if (card.service && typeof card.service.cardResized === "function")
            card.service.cardResized(card.widgetId, card.textScale)
          if (card.service && typeof card.service.cardMoved === "function")
            card.service.cardMoved(card.widgetId, card.x, card.y, card.elevation)
          card.settleAround()
        }
      }

      onCentroidChanged: function() {
        if (!resizer.active) return
        var p = resizer.centroid.scenePosition
        var dx = p.x - resizer.startPoint.x
        var dy = p.y - resizer.startPoint.y
        var delta = dx + dy
        card.textScale = Math.max(0.6, Math.min(5.0, resizer.startScale * (1 + delta / 180)))
      }
    }
  }

  // ---- Drag to move (Single Block or Whole Connected Structure) -----------
  property point dragStartPoint
  property point dragStartPos
  property int dragStartElevation: 0
  property var activeCluster: []
  property var clusterStartPositions: ({})
  property var clusterStartElevations: ({})

  DragHandler {
    id: dragger
    target: null
    acceptedButtons: Qt.LeftButton
    enabled: !card.locked
    // Does NOT take over from resizer so corner resize grabs always win
    grabPermissions: PointerHandler.CanTakeOverFromItems

    property bool isGroupDrag: false

    onActiveChanged: {
      if (dragger.active) {
        card.keepCentered = false
        card.dragStartPoint = dragger.centroid.scenePosition
        card.dragStartPos = Qt.point(card.x, card.y)
        card.dragStartElevation = card.elevation

        // Hold Ctrl or Alt to move entire structure; otherwise move this individual block!
        var isCtrlOrAlt = (dragger.point && (dragger.point.modifiers & (Qt.ControlModifier | Qt.AltModifier)))
        dragger.isGroupDrag = !!isCtrlOrAlt

        if (dragger.isGroupDrag) {
          card.activeCluster = card.getConnectedCluster()
          var starts = {}
          var startElevs = {}
          for (var i = 0; i < card.activeCluster.length; i++) {
            var c = card.activeCluster[i]
            if (c) {
              starts[c.widgetId] = Qt.point(c.x, c.y)
              startElevs[c.widgetId] = c.elevation
              c.isClusterDragging = true
            }
          }
          card.clusterStartPositions = starts
          card.clusterStartElevations = startElevs
        } else {
          card.activeCluster = [card]
          card.clusterStartPositions = ({})
          card.clusterStartElevations = ({})
        }
      } else if (!dragger.active) {
        if (dragger.isGroupDrag && card.activeCluster && card.activeCluster.length > 1) {
          var cluster = card.activeCluster
          for (var k = 0; k < cluster.length; k++) {
            var item = cluster[k]
            if (item) {
              item.isClusterDragging = false
              item.clampIntoScreen()
              if (item.snapAnim && typeof item.snapAnim.restart === "function") {
                item.snapAnim.restart()
              }
              if (item.service && typeof item.service.cardMoved === "function") {
                item.service.cardMoved(item.widgetId, item.x, item.y, item.elevation)
              }
            }
          }
        } else {
          card.clampIntoScreen()
          if (card.snapAnim && typeof card.snapAnim.restart === "function") {
            card.snapAnim.restart()
          }
          if (card.service && typeof card.service.cardMoved === "function") {
            card.service.cardMoved(card.widgetId, card.x, card.y, card.elevation)
          }
        }
        card.activeCluster = []
        card.clusterStartPositions = ({})
        card.clusterStartElevations = ({})
        if (card.layerWindow) card.layerWindow.cardActivated(card)
      }
    }

    onCentroidChanged: function() {
      if (!dragger.active) return
      var p = dragger.centroid.scenePosition
      var dx = p.x - card.dragStartPoint.x
      var dy = p.y - card.dragStartPoint.y

      var rawX = Math.round(card.dragStartPos.x + dx)
      var rawY = Math.round(card.dragStartPos.y + dy)

      var cardAnchorY = card.isBlock ? (card.height * (1.7 / 2.4))
        : (card.isAnimal ? (card.height * 0.78)
        : (card.isTree ? (card.height * (5.0 / 6.0))
        : (card.isProp ? (card.height * 0.75) : (card.height * 0.72))))

      var rawGCX = rawX + card.width * 0.5
      var rawGCY = rawY + cardAnchorY

      // Smooth magnetic snapping with hysteresis latching (prevents stutter & oscillation)
      var snapThreshold = card.isMagnetSnapped ? 54 : 36

      if (dragger.isGroupDrag && card.activeCluster && card.activeCluster.length > 1) {
        var snapGroup = card.getSnapSlot(rawGCX, rawGCY, card.activeCluster, snapThreshold)
        var effDX = dx
        var effDY = dy
        var elevShift = 0

        if (snapGroup.found) {
          card.isMagnetSnapped = true
          var snappedX = Math.round(snapGroup.targetCX - card.width * 0.5)
          var snappedY = Math.round(snapGroup.targetCY - cardAnchorY)
          effDX = snappedX - card.dragStartPos.x
          effDY = snappedY - card.dragStartPos.y
          elevShift = snapGroup.elevation - card.dragStartElevation
        } else {
          card.isMagnetSnapped = false
        }

        for (var i = 0; i < card.activeCluster.length; i++) {
          var c = card.activeCluster[i]
          if (!c) continue
          var orig = card.clusterStartPositions[c.widgetId]
          var origElev = card.clusterStartElevations[c.widgetId]
          if (orig) {
            c.x = Math.round(orig.x + effDX)
            c.y = Math.round(orig.y + effDY)
          }
          if (origElev !== undefined) {
            c.elevation = Math.max(0, origElev + elevShift)
          }
        }
      } else {
        var snapSingle = card.getSnapSlot(rawGCX, rawGCY, [card], snapThreshold)
        if (snapSingle.found) {
          card.isMagnetSnapped = true
          card.x = Math.round(snapSingle.targetCX - card.width * 0.5)
          card.y = Math.round(snapSingle.targetCY - cardAnchorY)
          if (card.elevation !== snapSingle.elevation) card.elevation = snapSingle.elevation
          if (card.isBlock || card.isTree || card.isProp) {
            if (card.textScale !== snapSingle.scale) card.textScale = snapSingle.scale
          }
        } else {
          card.isMagnetSnapped = false
          card.x = rawX
          card.y = rawY
          if (card.elevation !== card.dragStartElevation) card.elevation = card.dragStartElevation
        }
      }
    }
  }

  function removeRequested() {
    if (card.service) card.service.removeWidget(card.widgetId)
  }
}
