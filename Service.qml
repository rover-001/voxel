import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Registry.js" as Reg

// Singleton service managing Voxel desktop dioramas.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string statePath: home + "/.local/state/omarchy/voxel/widgets.json"

  property var widgets: []
  property var _layers: ({})
  property bool _initialized: false

  readonly property int widgetCount: widgets.length

  Component.onCompleted: {
    Reg.set(root)
    console.log("[voxel] service online")
  }

  IpcHandler {
    target: "voxel.service"

    function status(): string {
      return JSON.stringify({
        widgets: root.widgets,
        initialized: root._initialized
      })
    }

    function place(style: string): string {
      root.placeWidget(style, root.primaryScreenName())
      return "ok"
    }

    function remove(id: string): string {
      root.removeWidget(id)
      return "ok"
    }

    function clear(): string {
      root.clearAll()
      return "ok"
    }
  }

  function screenByName(name) {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) {
      if (screens[i] && screens[i].name === name) return screens[i]
    }
    return screens.length > 0 ? screens[0] : null
  }

  function primaryScreenName() {
    var screens = Quickshell.screens
    return screens.length > 0 && screens[0] ? screens[0].name : ""
  }

  function generateId() {
    return "vox_" + Date.now().toString(36) + Math.floor(Math.random() * 1e4).toString(36)
  }

  function findClearSpawnPoint(scrW, scrH) {
    // Primary staging zone: comfortably below the floating sky islands in the open lower area
    var targetY = Math.round(scrH * 0.72)
    var targetX = Math.round(scrW * 0.5 - 34)
    var clearance = 76

    function isOccupied(x, y) {
      for (var i = 0; i < root.widgets.length; i++) {
        var w = root.widgets[i]
        if (!w) continue
        if (Math.hypot(Number(w.x || 0) - x, Number(w.y || 0) - y) < clearance) {
          return true
        }
      }
      return false
    }

    if (!isOccupied(targetX, targetY)) {
      return { x: targetX, y: targetY }
    }

    // Search outwards horizontally and vertically in open staging area
    var stepX = 72
    var stepY = 56
    for (var ring = 1; ring <= 20; ring++) {
      for (var dx = -ring; dx <= ring; dx++) {
        for (var dy = -1; dy <= 2; dy++) {
          var candX = targetX + dx * stepX
          var candY = targetY + dy * stepY
          if (candX >= 80 && candX <= scrW - 140 && candY >= 100 && candY <= scrH - 120) {
            if (!isOccupied(candX, candY)) {
              return { x: candX, y: candY }
            }
          }
        }
      }
    }

    return { x: targetX, y: targetY }
  }

  function placeWidget(styleId, screenName) {
    var scrName = String(screenName || root.primaryScreenName())
    var scrObj = root.screenByName(scrName)
    var scrW = scrObj ? scrObj.width : 1920
    var scrH = scrObj ? scrObj.height : 1080

    var isBlock = styleId && (styleId.indexOf("block-") !== -1 || styleId.indexOf("voxel-block-") !== -1)
    var isTree = styleId && (styleId.indexOf("tree-") !== -1 || styleId.indexOf("voxel-tree-") !== -1)
    var isClock = styleId && (styleId.indexOf("clock") !== -1)
    var defaultScale = isClock ? 1.0 : ((isBlock || isTree) ? 3.6 : 2.2)

    // Find a clean, completely unoccupied placement point away from existing islands
    var pt = root.findClearSpawnPoint(scrW, scrH)

    var entry = {
      id: generateId(),
      style: String(styleId || "voxel-block-grass"),
      screen: scrName,
      x: pt.x,
      y: pt.y,
      scale: defaultScale,
      elevation: 0,
      locked: false,
      rotation: 0
    }
    var list = root.widgets.slice()
    list.push(entry)
    root.widgets = list
    root.materializeEntry(entry)
    root.save()
  }

  function cardMoved(id, nx, ny, elev, rot) {
    var list = root.widgets.slice()
    var changed = false
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id) {
        list[i].x = Math.round(nx)
        list[i].y = Math.round(ny)
        if (typeof elev !== "undefined") list[i].elevation = Number(elev || 0)
        if (typeof rot !== "undefined") list[i].rotation = Number(rot || 0)
        changed = true
        break
      }
    }
    if (!changed) return
    root.widgets = list
    root.save()
  }

  function cardRotated(id, rot) {
    rot = Number(rot) || 0
    var list = root.widgets.slice()
    var changed = false
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id && Number(list[i].rotation || 0) !== rot) {
        list[i].rotation = rot
        changed = true
        break
      }
    }
    if (!changed) return
    root.widgets = list
    root.save()
  }

  function cardResized(id, scale) {
    scale = Math.max(0.6, Math.min(5.0, Number(scale) || 2.2))
    var list = root.widgets.slice()
    var changed = false
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id && Number(list[i].scale || 2.2) !== scale) {
        list[i].scale = scale
        changed = true
        break
      }
    }
    if (!changed) return
    root.widgets = list
    root.save()
  }

  function removeWidget(id) {
    var list = []
    for (var i = 0; i < root.widgets.length; i++) {
      if (root.widgets[i].id !== id) list.push(root.widgets[i])
    }
    if (list.length === root.widgets.length) return
    root.widgets = list
    for (var name in root._layers) {
      if (root._layers[name]) root._layers[name].removeCard(id)
    }
    root.save()
  }

  function removeWidgets(idList) {
    if (!idList || !idList.length) return
    var idMap = {}
    for (var k = 0; k < idList.length; k++) idMap[idList[k]] = true
    var list = []
    for (var i = 0; i < root.widgets.length; i++) {
      if (!idMap[root.widgets[i].id]) list.push(root.widgets[i])
    }
    if (list.length === root.widgets.length) return
    root.widgets = list
    for (var name in root._layers) {
      if (root._layers[name]) {
        for (var id in idMap) {
          root._layers[name].removeCard(id)
        }
      }
    }
    root.save()
  }

  function clearAll() {
    root.widgets = []
    for (var name in root._layers) {
      var l = root._layers[name]
      for (var id in l.cards) l.removeCard(id)
    }
    root.save()
  }

  // ---- Layer Lifecycle ----

  property Component _layerComponent: Qt.createComponent(
    Qt.resolvedUrl("DesktopWidget.qml"), Component.PreferSynchronous)

  function ensureLayer(screenName) {
    var name = String(screenName || root.primaryScreenName())
    var existing = root._layers[name]
    if (existing) return existing
    if (root._layerComponent.status !== Component.Ready) {
      console.warn("[voxel] DesktopWidget component not ready:", root._layerComponent.errorString())
      return null
    }
    var layer = root._layerComponent.createObject(null, {
      service: root,
      screenName: name
    })
    if (!layer) {
      console.warn("[voxel] DesktopWidget createObject failed")
      return null
    }
    root._layers[name] = layer
    return layer
  }

  function materializeEntry(entry) {
    if (!entry) return
    var layer = root.ensureLayer(entry.screen)
    if (!layer) return
    if (layer.cards[entry.id]) layer.updateWidget(entry)
    else layer.addWidget(entry)
  }

  // ---- Persistence ----

  function canonical() {
    return JSON.stringify({ widgets: root.widgets }, null, 2)
  }

  function loadFromText(text) {
    var raw = String(text || "").trim()
    if (!raw) return
    var parsed = null
    try {
      parsed = JSON.parse(raw)
    } catch (e) {
      return
    }
    var arr = parsed ? (parsed.widgets || parsed) : []
    if (!Array.isArray(arr)) return

    var list = []
    for (var i = 0; i < arr.length; i++) {
      var e = arr[i]
      if (!e || !e.id || !e.style) continue
      list.push({
        id: String(e.id),
        style: String(e.style),
        screen: String(e.screen || ""),
        x: Number(e.x) || 0,
        y: Number(e.y) || 0,
        scale: Math.max(0.6, Math.min(5.0, Number(e.scale || 2.2))),
        elevation: Number(e.elevation || 0),
        locked: e.locked === true,
        rotation: Number(e.rotation) || 0
      })
    }

    // Skip redundant reloads triggered by our own writes.
    if (root.widgets.length === list.length && root.canonical() === JSON.stringify({ widgets: list }, null, 2)) {
      root._initialized = true
      return
    }

    root._initialized = true

    // Reconcile removed widgets
    for (var name in root._layers) {
      var layer = root._layers[name]
      for (var id in layer.cards) {
        var still = false
        for (var k = 0; k < list.length; k++) {
          if (list[k].id === id && list[k].screen === name) {
            still = true
            break
          }
        }
        if (!still) layer.removeCard(id)
      }
    }

    root.widgets = list
    list.forEach(function(entry) {
      Qt.callLater(function() { root.materializeEntry(entry) })
    })
  }

  function save() {
    if (!root._initialized) return
    if (saveTimer.running) return
    saveTimer.restart()
  }

  function flushSave() {
    if (saveProc.running) {
      saveTimer.restart()
      return
    }
    saveProc.command = ["sh", "-c",
      'd=$(dirname -- "$1"); mkdir -p -- "$d"; printf "%s" "$2" > "$1"',
      "voxel-save", root.statePath, root.canonical()]
    saveProc.running = true
  }

  Timer {
    id: saveTimer
    interval: 200
    onTriggered: root.flushSave()
  }

  Process {
    id: saveProc
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadFromText(text())
    onLoadFailed: {
      root._initialized = true
      root.widgets = []
    }
  }
}
