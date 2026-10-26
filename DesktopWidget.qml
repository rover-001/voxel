import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Per-screen bottom layer hosting placed Voxel dioramas, blocks, clouds, and animals.
PanelWindow {
  id: desktopLayer

  required property var service
  required property string screenName
  property var cards: ({})
  property string selectedId: ""
  property Component cardComponent: Qt.createComponent(
    Qt.resolvedUrl("DesktopCard.qml"), Component.PreferSynchronous)

  // Cluster Selection & Dragging System
  property var activeCluster: []
  property var activeHoveredCard: null
  property rect clusterBounds: Qt.rect(0, 0, 0, 0)
  property bool isMovingCluster: false
  property int hoveredBorderStrips: 0
  readonly property bool outerBorderHovered: hoveredBorderStrips > 0
  readonly property real clusterPadding: 26
  property point clusterDragStartPoint
  property var clusterStartPositions: ({})

  function checkAndRestartClearTimer() {
    if (desktopLayer.isMovingCluster) return
    if (desktopLayer.selectedId && desktopLayer.cards[desktopLayer.selectedId]) return
    if (desktopLayer.activeHoveredCard) return
    if (desktopLayer.outerBorderHovered) return
    if (clusterOverlay && clusterOverlay.isHovered) return
    clearClusterTimer.restart()
  }

  function updateClusterBounds() {
    if (!desktopLayer.activeCluster || desktopLayer.activeCluster.length === 0) {
      desktopLayer.clusterBounds = Qt.rect(0, 0, 0, 0)
      return
    }
    var minX = 999999, minY = 999999, maxX = -999999, maxY = -999999
    for (var i = 0; i < desktopLayer.activeCluster.length; i++) {
      var c = desktopLayer.activeCluster[i]
      if (!c) continue
      if (c.x < minX) minX = c.x
      if (c.y < minY) minY = c.y
      if (c.x + c.width > maxX) maxX = c.x + c.width
      if (c.y + c.height > maxY) maxY = c.y + c.height
    }
    var pad = desktopLayer.clusterPadding
    desktopLayer.clusterBounds = Qt.rect(minX - pad, minY - pad, (maxX - minX) + pad * 2, (maxY - minY) + pad * 2)
  }

  property var clusterStartElevations: ({})
  property rect clusterDragStartBounds: Qt.rect(0, 0, 0, 0)
  property bool isClusterMagnetSnapped: false

  function startClusterDrag(scenePos) {
    desktopLayer.isMovingCluster = true
    desktopLayer.isClusterMagnetSnapped = false
    clearClusterTimer.stop()
    desktopLayer.clusterDragStartPoint = scenePos
    desktopLayer.clusterDragStartBounds = Qt.rect(
      desktopLayer.clusterBounds.x,
      desktopLayer.clusterBounds.y,
      desktopLayer.clusterBounds.width,
      desktopLayer.clusterBounds.height
    )
    var starts = {}
    var startElevs = {}
    for (var i = 0; i < desktopLayer.activeCluster.length; i++) {
      var c = desktopLayer.activeCluster[i]
      if (c) {
        starts[c.widgetId] = Qt.point(c.x, c.y)
        startElevs[c.widgetId] = c.elevation
        c.isClusterDragging = true
      }
    }
    desktopLayer.clusterStartPositions = starts
    desktopLayer.clusterStartElevations = startElevs
  }

  function updateClusterDrag(scenePos) {
    if (!desktopLayer.isMovingCluster) return
    var dx = scenePos.x - desktopLayer.clusterDragStartPoint.x
    var dy = scenePos.y - desktopLayer.clusterDragStartPoint.y
    var cluster = desktopLayer.activeCluster || []
    if (!cluster.length) return

    var rootCard = cluster[0]
    var origRoot = desktopLayer.clusterStartPositions[rootCard.widgetId]
    if (!origRoot) return

    var rootCardAnchorY = rootCard.isBlock ? (rootCard.height * (1.7 / 2.4))
      : (rootCard.isAnimal ? (rootCard.height * 0.78)
      : (rootCard.isTree ? (rootCard.height * (5.0 / 6.0))
      : (rootCard.isProp ? (rootCard.height * 0.75) : (rootCard.height * 0.72))))

    var rawRootX = origRoot.x + dx
    var rawRootY = origRoot.y + dy
    var rawRootGCX = rawRootX + rootCard.width * 0.5
    var rawRootGCY = rawRootY + rootCardAnchorY

    var effDX = dx
    var effDY = dy
    var elevShift = 0

    // Live magnetic snapping while holding: preview exact snap slot in real-time with hysteresis
    if (typeof rootCard.getSnapSlot === "function") {
      var snapThresh = desktopLayer.isClusterMagnetSnapped ? 54 : 36
      var snap = rootCard.getSnapSlot(rawRootGCX, rawRootGCY, cluster, snapThresh)
      if (snap.found) {
        desktopLayer.isClusterMagnetSnapped = true
        var snappedRootX = Math.round(snap.targetCX - rootCard.width * 0.5)
        var snappedRootY = Math.round(snap.targetCY - rootCardAnchorY)
        effDX = snappedRootX - origRoot.x
        effDY = snappedRootY - origRoot.y
        var rootOrigElev = desktopLayer.clusterStartElevations[rootCard.widgetId] || 0
        elevShift = snap.elevation - rootOrigElev
      } else {
        desktopLayer.isClusterMagnetSnapped = false
      }
    }

    for (var i = 0; i < cluster.length; i++) {
      var c = cluster[i]
      if (!c) continue
      var orig = desktopLayer.clusterStartPositions[c.widgetId]
      var origElev = desktopLayer.clusterStartElevations[c.widgetId]
      if (orig) {
        c.x = Math.round(orig.x + effDX)
        c.y = Math.round(orig.y + effDY)
      }
      if (origElev !== undefined) {
        c.elevation = Math.max(0, origElev + elevShift)
      }
    }

    // Smoothly shift cluster bounding box without expensive loop re-computation
    desktopLayer.clusterBounds = Qt.rect(
      Math.round(desktopLayer.clusterDragStartBounds.x + effDX),
      Math.round(desktopLayer.clusterDragStartBounds.y + effDY),
      desktopLayer.clusterDragStartBounds.width,
      desktopLayer.clusterDragStartBounds.height
    )
  }

  function endClusterDrag() {
    var cluster = desktopLayer.activeCluster || []
    for (var k = 0; k < cluster.length; k++) {
      if (cluster[k]) cluster[k].isClusterDragging = false
    }

    if (cluster.length > 0) {
      for (var j = 0; j < cluster.length; j++) {
        var item = cluster[j]
        if (item) {
          item.clampIntoScreen()
          if (item.snapAnim && typeof item.snapAnim.restart === "function") {
            item.snapAnim.restart()
          }
          if (item.service && typeof item.service.cardMoved === "function") {
            item.service.cardMoved(item.widgetId, item.x, item.y, item.elevation)
          }
        }
      }
    }

    desktopLayer.isMovingCluster = false
    desktopLayer.isClusterMagnetSnapped = false
    desktopLayer.updateClusterBounds()
    desktopLayer.checkAndRestartClearTimer()
  }

  function cardActivated(c) {
    if (!c || desktopLayer.isMovingCluster) return
    desktopLayer.activeHoveredCard = c
    clearClusterTimer.stop()
    var cl = c.getConnectedCluster()
    if (!cl || cl.length === 0) cl = [c]
    desktopLayer.activeCluster = cl
    for (var id in desktopLayer.cards) {
      var card = desktopLayer.cards[id]
      if (card) {
        card.inActiveCluster = (cl.indexOf(card) !== -1)
      }
    }
    desktopLayer.updateClusterBounds()
  }

  function cardDeactivated(c) {
    if (desktopLayer.activeHoveredCard === c) {
      desktopLayer.activeHoveredCard = null
      desktopLayer.checkAndRestartClearTimer()
    }
  }

  function clearCluster() {
    if (desktopLayer.isMovingCluster) return
    if (desktopLayer.selectedId && desktopLayer.cards[desktopLayer.selectedId]) return
    desktopLayer.activeCluster = []
    for (var id in desktopLayer.cards) {
      var card = desktopLayer.cards[id]
      if (card) card.inActiveCluster = false
    }
    desktopLayer.clusterBounds = Qt.rect(0, 0, 0, 0)
  }

  function removeCluster() {
    var cluster = desktopLayer.activeCluster || []
    if (!cluster.length) return
    var ids = []
    for (var i = 0; i < cluster.length; i++) {
      if (cluster[i]) ids.push(cluster[i].widgetId)
    }
    desktopLayer.clearCluster()
    if (desktopLayer.service) {
      if (typeof desktopLayer.service.removeWidgets === "function") {
        desktopLayer.service.removeWidgets(ids)
      } else {
        for (var j = 0; j < ids.length; j++) desktopLayer.service.removeWidget(ids[j])
      }
    }
  }

  function rotateCluster(direction) {
    var dir = (direction === undefined || direction === null) ? 1 : direction
    var cluster = desktopLayer.activeCluster || []
    if (!cluster || !cluster.length) {
      if (desktopLayer.activeHoveredCard) cluster = [desktopLayer.activeHoveredCard]
      else return
    }

    clearClusterTimer.stop()

    // Single item rotation (single block or prop like bench, lamp, fence, waterfall)
    if (cluster.length === 1) {
      var singleItem = cluster[0]
      var rotStep = dir > 0 ? 90 : -90
      var newAngle = ((Number(singleItem.rotationAngle || 0) + rotStep) % 360 + 360) % 360
      singleItem.rotationAngle = newAngle
      if (singleItem.snapAnim && typeof singleItem.snapAnim.restart === "function") {
        singleItem.snapAnim.restart()
      }
      if (singleItem.service && typeof singleItem.service.cardRotated === "function") {
        singleItem.service.cardRotated(singleItem.widgetId, newAngle)
      } else if (singleItem.service && typeof singleItem.service.cardMoved === "function") {
        singleItem.service.cardMoved(singleItem.widgetId, singleItem.x, singleItem.y, singleItem.elevation, newAngle)
      }
      desktopLayer.updateClusterBounds()
      desktopLayer.checkAndRestartClearTimer()
      return
    }

    var s = Math.round((Style.space(8) * Math.max(1.0, cluster[0].textScale)) / 2) * 2

    // Compute cluster center in horizontal ground plane
    var sumX = 0
    var sumFlatY = 0
    for (var i = 0; i < cluster.length; i++) {
      var c = cluster[i]
      sumX += c.groundCenterX
      sumFlatY += (c.groundCenterY + (Number(c.elevation || 0) * s))
    }
    var cx = sumX / cluster.length
    var flatCY = sumFlatY / cluster.length

    // Compute new positions simultaneously: exact 2:1 isometric orthogonal linear transform
    // Preserves inter-block distances with 100% mathematical invariance (zero drift/disconnection)
    var newCoords = []
    for (var j = 0; j < cluster.length; j++) {
      var card = cluster[j]
      var bFlatY = card.groundCenterY + (Number(card.elevation || 0) * s)
      var rx = card.groundCenterX - cx
      var ry = bFlatY - flatCY

      var nx, nFlatY
      if (dir > 0) {
        // 90° Clockwise isometric rotation
        nx = cx + (-2 * ry)
        nFlatY = flatCY + (0.5 * rx)
      } else {
        // 90° Counter-Clockwise (opposite way) isometric rotation
        nx = cx + (2 * ry)
        nFlatY = flatCY - (0.5 * rx)
      }

      var cardAnchorY = card.isBlock ? (card.height * (1.7 / 2.4))
        : (card.isAnimal ? (card.height * 0.78)
        : (card.isTree ? (card.height * (5.0 / 6.0))
        : (card.isProp ? (card.height * 0.75) : (card.height * 0.72))))

      var targetGCY = nFlatY - (Number(card.elevation || 0) * s)
      var finalX = Math.round(nx - card.width * 0.5)
      var finalY = Math.round(targetGCY - cardAnchorY)

      newCoords.push({ x: finalX, y: finalY })
    }

    // Apply new positions simultaneously to all cards, and rotate props/blocks
    var rotDelta = dir > 0 ? 90 : -90
    for (var k = 0; k < cluster.length; k++) {
      var item = cluster[k]
      item.x = newCoords[k].x
      item.y = newCoords[k].y
      var itemAngle = ((Number(item.rotationAngle || 0) + rotDelta) % 360 + 360) % 360
      item.rotationAngle = itemAngle
      item.clampIntoScreen()

      if (item.snapAnim && typeof item.snapAnim.restart === "function") {
        item.snapAnim.restart()
      }

      if (item.service && typeof item.service.cardMoved === "function") {
        item.service.cardMoved(item.widgetId, item.x, item.y, item.elevation, itemAngle)
      }
    }

    desktopLayer.updateClusterBounds()
    desktopLayer.checkAndRestartClearTimer()
  }

  Timer {
    id: clearClusterTimer
    interval: 350
    repeat: false
    onTriggered: {
      if (desktopLayer.selectedId && desktopLayer.cards[desktopLayer.selectedId]) return
      if (!desktopLayer.activeHoveredCard && !desktopLayer.isMovingCluster && !desktopLayer.outerBorderHovered && (!clusterOverlay || !clusterOverlay.isHovered)) {
        desktopLayer.clearCluster()
      }
    }
  }

  visible: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  screen: service ? service.screenByName(screenName) : null

  WlrLayershell.namespace: "voxel-widget"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  MouseArea {
    id: clearSelectArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: {
      desktopLayer.selectedId = ""
      desktopLayer.clearCluster()
    }
  }

  onSelectedIdChanged: {
    for (var id in desktopLayer.cards) {
      var c = desktopLayer.cards[id]
      if (c) c.selected = (id === desktopLayer.selectedId)
    }
    if (desktopLayer.selectedId && desktopLayer.cards[desktopLayer.selectedId]) {
      cardActivated(desktopLayer.cards[desktopLayer.selectedId])
    }
  }

  function setSelected(id) {
    desktopLayer.selectedId = id
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // ---- Outer Dotted Outline & Direct Border Drag Frame for Connected Blocks
  // z: 500000 ensures cluster action buttons and outer border draggers take precedence on border,
  // while the empty central opening allows all mouse clicks/drags to pass straight through to cards!
  Item {
    id: clusterOverlay
    visible: desktopLayer.clusterBounds.width > 0 && desktopLayer.activeCluster.length > 0
    x: desktopLayer.clusterBounds.x
    y: desktopLayer.clusterBounds.y
    width: desktopLayer.clusterBounds.width
    height: desktopLayer.clusterBounds.height
    z: 500000

    readonly property real pad: desktopLayer.clusterPadding
    readonly property bool isHovered: overlayHover.hovered

    // Pass-through hover tracking over entire cluster bounds so outline never flickers or drops
    HoverHandler {
      id: overlayHover
      onHoveredChanged: {
        if (overlayHover.hovered) {
          clearClusterTimer.stop()
        } else {
          desktopLayer.checkAndRestartClearTimer()
        }
      }
    }

    // Outer Dotted Border
    Shape {
      id: clusterOutline
      anchors.fill: parent

      ShapePath {
        strokeColor: (desktopLayer.outerBorderHovered || desktopLayer.isMovingCluster)
          ? Color.accent
          : Util.alpha(Color.accent, 0.75)
        strokeWidth: (desktopLayer.outerBorderHovered || desktopLayer.isMovingCluster) ? 2.5 : 2.0
        strokeStyle: ShapePath.DashLine
        dashPattern: [6, 4]
        fillColor: "transparent"
        startX: 0; startY: 0
        PathLine { x: clusterOverlay.width; y: 0 }
        PathLine { x: clusterOverlay.width; y: clusterOverlay.height }
        PathLine { x: 0; y: clusterOverlay.height }
        PathLine { x: 0; y: 0 }
      }
    }

    // Interactive outer border frame:
    // Captures mouse only along the outer border band (pad=26px).
    // The central opening has NO items, so clicks/drags inside hit the individual blocks directly!
    component BorderFrameStrip: Item {
      Rectangle {
        anchors.fill: parent
        color: (desktopLayer.outerBorderHovered || desktopLayer.isMovingCluster)
          ? Util.alpha(Color.accent, 0.08)
          : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
      }

      HoverHandler {
        id: hHandler
        cursorShape: Qt.SizeAllCursor
        onHoveredChanged: {
          if (hHandler.hovered) {
            desktopLayer.hoveredBorderStrips++
            clearClusterTimer.stop()
          } else {
            desktopLayer.hoveredBorderStrips = Math.max(0, desktopLayer.hoveredBorderStrips - 1)
            desktopLayer.checkAndRestartClearTimer()
          }
        }
      }

      DragHandler {
        id: bDragger
        target: null
        acceptedButtons: Qt.LeftButton
        grabPermissions: PointerHandler.CanTakeOverFromItems

        onActiveChanged: {
          if (bDragger.active) desktopLayer.startClusterDrag(bDragger.centroid.scenePosition)
          else desktopLayer.endClusterDrag()
        }

        onCentroidChanged: {
          if (bDragger.active) desktopLayer.updateClusterDrag(bDragger.centroid.scenePosition)
        }
      }
    }

    // Top border strip (leaves room for top-right cluster action buttons)
    BorderFrameStrip {
      x: 0; y: 0
      width: Math.max(0, parent.width - Style.space(98)); height: clusterOverlay.pad
    }

    // Bottom border strip
    BorderFrameStrip {
      x: 0; y: parent.height - clusterOverlay.pad
      width: parent.width; height: clusterOverlay.pad
    }

    // Left border strip (full height for seamless corner coverage)
    BorderFrameStrip {
      x: 0; y: 0
      width: clusterOverlay.pad; height: parent.height
    }

    // Right border strip (starts below the top-right button zone)
    BorderFrameStrip {
      x: parent.width - clusterOverlay.pad; y: clusterOverlay.pad
      width: clusterOverlay.pad; height: Math.max(0, parent.height - clusterOverlay.pad)
    }

    // ---- Cluster Action Controls (Top-Right of outer dotted line) ------------
    Row {
      id: clusterActionsRow
      z: 1000
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: -Style.space(13)
      anchors.rightMargin: -Style.space(4)
      spacing: Style.space(6)

      // 1. Rotate Opposite Way / Counter-Clockwise Button ("↺")
      Rectangle {
        id: clusterRotateCcwBtn
        width: Style.space(24)
        height: Style.space(24)
        radius: width / 2
        color: rotateCcwArea.containsMouse
          ? Util.alpha(Color.accent, 0.25)
          : Util.alpha(Color.popups.background, 0.96)
        border.width: 1.5
        border.color: rotateCcwArea.containsMouse
          ? Color.accent
          : Util.alpha(Color.accent, 0.7)
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Text {
          anchors.centerIn: parent
          text: "↺"
          color: rotateCcwArea.containsMouse ? Color.accent : Color.foreground
          font.pixelSize: Style.space(13)
          font.bold: true
          rotation: rotateCcwArea.pressed ? -45 : 0
          Behavior on rotation { NumberAnimation { duration: 120 } }
        }

        MouseArea {
          id: rotateCcwArea
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          preventStealing: true

          onEntered: {
            desktopLayer.hoveredBorderStrips++
            clearClusterTimer.stop()
          }
          onExited: {
            desktopLayer.hoveredBorderStrips = Math.max(0, desktopLayer.hoveredBorderStrips - 1)
            desktopLayer.checkAndRestartClearTimer()
          }
          onClicked: desktopLayer.rotateCluster(-1)
        }
      }

      // 2. Rotate Clockwise Button ("↻")
      Rectangle {
        id: clusterRotateCwBtn
        width: Style.space(24)
        height: Style.space(24)
        radius: width / 2
        color: rotateCwArea.containsMouse
          ? Util.alpha(Color.accent, 0.25)
          : Util.alpha(Color.popups.background, 0.96)
        border.width: 1.5
        border.color: rotateCwArea.containsMouse
          ? Color.accent
          : Util.alpha(Color.accent, 0.7)
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Text {
          anchors.centerIn: parent
          text: "↻"
          color: rotateCwArea.containsMouse ? Color.accent : Color.foreground
          font.pixelSize: Style.space(13)
          font.bold: true
          rotation: rotateCwArea.pressed ? 45 : 0
          Behavior on rotation { NumberAnimation { duration: 120 } }
        }

        MouseArea {
          id: rotateCwArea
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          preventStealing: true

          onEntered: {
            desktopLayer.hoveredBorderStrips++
            clearClusterTimer.stop()
          }
          onExited: {
            desktopLayer.hoveredBorderStrips = Math.max(0, desktopLayer.hoveredBorderStrips - 1)
            desktopLayer.checkAndRestartClearTimer()
          }
          onClicked: desktopLayer.rotateCluster(1)
        }
      }

      // 3. Remove Entire Connected Structure Button ("✕")
      Rectangle {
        id: clusterRemoveBtn
        width: Style.space(24)
        height: Style.space(24)
        radius: width / 2
        color: removeArea.containsMouse
          ? Util.alpha("#ef4444", 0.25)
          : Util.alpha(Color.popups.background, 0.96)
        border.width: 1.5
        border.color: removeArea.containsMouse
          ? "#ef4444"
          : Util.alpha(Color.foreground, 0.35)
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Text {
          anchors.centerIn: parent
          text: "✕"
          color: removeArea.containsMouse ? "#ef4444" : Color.foreground
          font.pixelSize: Style.space(11)
          font.bold: true
        }

        MouseArea {
          id: removeArea
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          preventStealing: true

          onEntered: {
            desktopLayer.hoveredBorderStrips++
            clearClusterTimer.stop()
          }
          onExited: {
            desktopLayer.hoveredBorderStrips = Math.max(0, desktopLayer.hoveredBorderStrips - 1)
            desktopLayer.checkAndRestartClearTimer()
          }
          onClicked: desktopLayer.removeCluster()
        }
      }
    }
  }

  function addWidget(entry) {
    if (!entry || desktopLayer.cards[entry.id]) return
    if (!cardComponent || cardComponent.status !== Component.Ready) {
      console.warn("[voxel] cardComponent not ready:", cardComponent ? cardComponent.errorString() : "null")
      return
    }

    var card = cardComponent.createObject(desktopLayer.contentItem, {
      layerWindow: desktopLayer,
      service: desktopLayer.service,
      widgetId: entry.id,
      widgetStyle: entry.style,
      screen: desktopLayer.screen,
      textScale: Number(entry.scale || ((entry.style && (entry.style.indexOf("block-") !== -1 || entry.style.indexOf("tree-") !== -1)) ? 3.6 : 2.2)),
      rotationAngle: Number(entry.rotation || 0),
      elevation: Number(entry.elevation || 0),
      locked: !!entry.locked,
      x: Number(entry.x || 0),
      y: Number(entry.y || 0)
    })

    if (!card) {
      console.warn("[voxel] failed to instantiate card for", entry.id)
      return
    }

    desktopLayer.cards[entry.id] = card
  }

  function removeCard(id) {
    var c = desktopLayer.cards[id]
    if (!c) return
    delete desktopLayer.cards[id]
    c.destroy()
    if (desktopLayer.selectedId === id) desktopLayer.selectedId = ""
    desktopLayer.clearCluster()
  }

  function updateWidget(entry) {
    var c = desktopLayer.cards[entry.id]
    if (!c) return
    c.textScale = Number(entry.scale || ((entry.style && (entry.style.indexOf("block-") !== -1 || entry.style.indexOf("tree-") !== -1)) ? 3.6 : 2.2))
    c.x = Number(entry.x || 0)
    c.y = Number(entry.y || 0)
    c.elevation = Number(entry.elevation || 0)
    c.locked = !!entry.locked
  }
}
