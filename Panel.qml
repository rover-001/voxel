import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "Registry.js" as Reg

// Voxel Dioramas & Blocks Selector.
// Centered pop-up on bar with top tabs for BLOCKS & DIORAMAS,
// interactive 3D preview stage, and horizontal palette swatches.
Panel {
  id: root
  moduleName: "voxel"
  ipcTarget: "voxel"
  manageIpc: true

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property color barForeground: (bar && bar.foreground) ? bar.foreground : Commons.Color.foreground

  // Category state
  property int currentCategoryIndex: 0
  readonly property var categoryList: [
    { id: "blocks", name: "BLOCKS" },
    { id: "trees", name: "TREES" },
    { id: "creatures", name: "ANIMALS" },
    { id: "props", name: "PROPS" },
    { id: "time", name: "CLOCK" },
    { id: "settings", name: "SETTINGS" }
  ]
  readonly property var currentCategory: categoryList[currentCategoryIndex]
  readonly property bool isSettingsCategory: currentCategory && currentCategory.id === "settings"

  // Item state
  property int selectedIndex: 0
  readonly property var allItems: isSettingsCategory ? [] : Model.itemsFor(currentCategory.id)
  readonly property var currentItem: allItems.length > 0 ? allItems[selectedIndex] : null

  onCurrentCategoryIndexChanged: {
    selectedIndex = 0
    if (!isSettingsCategory) previewAnim.restart()
  }
  onSelectedIndexChanged: {
    if (!isSettingsCategory) previewAnim.restart()
  }

  readonly property var voxelService: Reg.get()
    || (root.bar && root.bar.shell ? root.bar.shell.serviceFor("voxel") : null)

  function open() { root.controller.show() }
  function openFromHotkey() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.openFromHotkey() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function panelScreen() {
    if (panel && panel.screen) return panel.screen
    if (root.hostWidget && root.hostWidget.screen) return root.hostWidget.screen
    return null
  }

  function placeCurrent() {
    if (root.isSettingsCategory || !root.currentItem) return
    var svc = root.voxelService
    if (!svc) return
    var screenObj = root.panelScreen()
    svc.placeWidget(root.currentItem.id, screenObj ? screenObj.name : "")
    placeFeedbackAnim.restart()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onReturnRequested: root.placeCurrent()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dx < 0) panel.navLeft()
        else if (dx > 0) panel.navRight()
        else if (dy !== 0) {
          root.currentCategoryIndex = (root.currentCategoryIndex + (dy > 0 ? 1 : root.categoryList.length - 1)) % root.categoryList.length
        }
      }
    }

    function navLeft() {
      if (root.selectedIndex > 0) root.selectedIndex--
      else root.selectedIndex = root.allItems.length - 1
    }

    function navRight() {
      if (root.selectedIndex < root.allItems.length - 1) root.selectedIndex++
      else root.selectedIndex = 0
    }

    Column {
      id: contentColumn
      width: parent.width
      spacing: Style.space(8)

      // ---- Top Category Tabs (BLOCKS / TREES / ANIMALS / PROPS / CLOCK / SETTINGS)
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(5)

        Repeater {
          model: root.categoryList
          delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool isSelected: root.currentCategoryIndex === index

            width: Style.space(56)
            height: Style.space(24)
            radius: Style.space(6)
            color: isSelected
              ? Util.alpha(Color.accent, 0.22)
              : (catMouse.containsMouse ? Util.alpha(root.barForeground, 0.08) : "transparent")
            border.width: 1
            border.color: isSelected ? Color.accent : Util.alpha(root.barForeground, 0.12)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Text {
              anchors.centerIn: parent
              text: modelData.name
              color: isSelected ? Color.accent : Util.alpha(root.barForeground, 0.6)
              font.family: Style.font.family
              font.pixelSize: Style.space(9)
              font.weight: isSelected ? Font.Bold : Font.Normal
              font.letterSpacing: 0.8
            }

            MouseArea {
              id: catMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.currentCategoryIndex = index
            }
          }
        }
      }

      // ---- Preview Stage (Pure Visual, Zero Text) ------------------------
      Item {
        id: previewStage
        width: parent.width
        height: Style.space(135)
        visible: !root.isSettingsCategory

        Rectangle {
          id: previewContainer
          anchors.fill: parent
          radius: Style.space(14)
          scale: 1.0

          SequentialAnimation {
            id: placeFeedbackAnim
            NumberAnimation {
              target: previewContainer
              property: "scale"
              from: 0.94; to: 1.0
              duration: 160
              easing.type: Easing.OutBack
            }
          }
          color: previewAreaMouse.containsMouse
            ? Util.alpha(root.barForeground, 0.07)
            : Util.alpha(root.barForeground, 0.025)
          border.width: 1
          border.color: previewAreaMouse.containsMouse
            ? Util.alpha(Color.accent, 0.55)
            : Util.alpha(root.barForeground, 0.1)

          Behavior on color { ColorAnimation { duration: 120 } }
          Behavior on border.color { ColorAnimation { duration: 120 } }

          // Main widget render area with smooth spring fade animation
          Item {
            id: previewArea
            anchors.fill: parent
            anchors.margins: Style.space(10)

            ParallelAnimation {
              id: previewAnim
              NumberAnimation {
                target: previewArea
                property: "opacity"
                from: 0.35; to: 1.0
                duration: 180
                easing.type: Easing.OutCubic
              }
              NumberAnimation {
                target: previewArea
                property: "scale"
                from: 0.95; to: 1.0
                duration: 200
                easing.type: Easing.OutBack
              }
            }

            // Live Tree Preview
            VoxelTree {
              id: previewTree
              anchors.centerIn: parent
              visible: root.currentItem && root.currentItem.category === "trees"
              active: root.opened && visible
              widgetScale: 2.1
              treeType: root.currentItem && root.currentItem.treeType ? root.currentItem.treeType : "sakura"
              fgColor: root.barForeground
              accentColor: Color.accent
            }

            // Live Prop Preview (Bench, Lamp, Fountain, Campfire, Flowers, Fence)
            VoxelProp {
              id: previewProp
              anchors.centerIn: parent
              visible: root.currentItem && root.currentItem.category === "props"
              active: root.opened && visible
              widgetScale: 2.3
              propType: root.currentItem && root.currentItem.propType ? root.currentItem.propType : "bench"
              fgColor: root.barForeground
              accentColor: Color.accent
            }

            // Live Animal Preview (Chicken / Fox)
            VoxelAnimal {
              id: previewAnimal
              anchors.centerIn: parent
              visible: root.currentItem && root.currentItem.category === "creatures"
              active: root.opened && visible
              widgetScale: 3.2
              animalType: root.currentItem && root.currentItem.animalType ? root.currentItem.animalType : "chicken"
              fgColor: root.barForeground
              accentColor: Color.accent
            }

            // Live Block Preview
            VoxelBlock {
              id: previewBlock
              anchors.centerIn: parent
              visible: root.currentItem && root.currentItem.category === "blocks"
              active: root.opened && visible
              widgetScale: 4.8
              blockType: root.currentItem && root.currentItem.blockType ? root.currentItem.blockType : "grass"
              fgColor: root.barForeground
              accentColor: Color.accent
            }

            // Live Voxel Clock Preview
            VoxelClock {
              id: previewClock
              anchors.centerIn: parent
              visible: root.currentItem && root.currentItem.category === "time"
              active: root.opened && visible
              clockScale: 0.8
              fgColor: root.barForeground
              accentColor: Color.accent
            }
          }

          // Direct click on stage to place on desktop
          MouseArea {
            id: previewAreaMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.placeCurrent()
          }

          // Floating Left Chevron
          Rectangle {
            id: leftArrow
            anchors.left: parent.left
            anchors.leftMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(32)
            height: Style.space(32)
            radius: Style.space(8)
            color: leftArea.containsMouse
              ? Util.alpha(Color.accent, 0.22)
              : Util.alpha(root.barForeground, 0.08)
            border.width: 1
            border.color: leftArea.containsMouse
              ? Util.alpha(Color.accent, 0.45)
              : Util.alpha(root.barForeground, 0.1)
            scale: leftArea.pressed ? 0.92 : (leftArea.containsMouse ? 1.06 : 1.0)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

            Text {
              anchors.centerIn: parent
              text: "\u{2039}"
              color: root.barForeground
              font.pixelSize: Style.space(22)
              font.weight: Font.Bold
            }

            MouseArea {
              id: leftArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.navLeft()
            }
          }

          // Floating Right Chevron
          Rectangle {
            id: rightArrow
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(32)
            height: Style.space(32)
            radius: Style.space(8)
            color: rightArea.containsMouse
              ? Util.alpha(Color.accent, 0.22)
              : Util.alpha(root.barForeground, 0.08)
            border.width: 1
            border.color: rightArea.containsMouse
              ? Util.alpha(Color.accent, 0.45)
              : Util.alpha(root.barForeground, 0.1)
            scale: rightArea.pressed ? 0.92 : (rightArea.containsMouse ? 1.06 : 1.0)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

            Text {
              anchors.centerIn: parent
              text: "\u{203A}"
              color: root.barForeground
              font.pixelSize: Style.space(22)
              font.weight: Font.Bold
            }

            MouseArea {
              id: rightArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.navRight()
            }
          }
        }
      }

      // ---- Settings View (Shown when SETTINGS tab is active) ------------
      Item {
        id: settingsView
        width: parent.width
        height: Style.space(165)
        visible: root.isSettingsCategory

        Rectangle {
          anchors.fill: parent
          radius: Style.space(12)
          color: Util.alpha(root.barForeground, 0.04)
          border.width: 1
          border.color: Util.alpha(root.barForeground, 0.1)

          Column {
            anchors.centerIn: parent
            width: parent.width - Style.space(20)
            spacing: Style.space(10)

            // Section Header
            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(6)

              Text {
                text: "⚡"
                font.pixelSize: Style.space(11)
              }
              Text {
                text: "ANIMATION PRESET"
                color: root.barForeground
                font.family: Style.font.family
                font.pixelSize: Style.space(9)
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
              }
            }

            // 3-way Profile Cards: OFF | LOW | HIGH
            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(6)

              Repeater {
                model: [
                  { id: "none", label: "OFF",  icon: "⏹", badge: "Zero Lag", desc: "No animations (Static)" },
                  { id: "low",  label: "LOW",  icon: "🍃", badge: "Balanced", desc: "GPU tree sway + animal AI" },
                  { id: "high", label: "HIGH", icon: "✨", badge: "Cinematic", desc: "Full physics & particle FX" }
                ]

                delegate: Rectangle {
                  required property var modelData
                  required property int index
                  readonly property bool isCur: (root.voxelService ? root.voxelService.animationLevel : "high") === modelData.id

                  width: Style.space(106)
                  height: Style.space(48)
                  radius: Style.space(8)
                  color: isCur
                    ? Util.alpha(Color.accent, 0.24)
                    : (btnHover.containsMouse ? Util.alpha(root.barForeground, 0.08) : Util.alpha(root.barForeground, 0.03))
                  border.width: isCur ? 1.5 : 1
                  border.color: isCur ? Color.accent : Util.alpha(root.barForeground, 0.12)

                  Behavior on color { ColorAnimation { duration: 140 } }
                  Behavior on border.color { ColorAnimation { duration: 140 } }

                  Column {
                    anchors.centerIn: parent
                    spacing: Style.space(2)

                    Row {
                      anchors.horizontalCenter: parent.horizontalCenter
                      spacing: Style.space(4)
                      Text {
                        text: modelData.icon
                        font.pixelSize: Style.space(10)
                      }
                      Text {
                        text: modelData.label
                        color: isCur ? Color.accent : root.barForeground
                        font.family: Style.font.family
                        font.pixelSize: Style.space(10)
                        font.weight: isCur ? Font.Bold : Font.Normal
                        font.letterSpacing: 0.8
                      }
                    }

                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: modelData.badge
                      color: isCur ? Util.alpha(Color.accent, 0.9) : Util.alpha(root.barForeground, 0.45)
                      font.family: Style.font.family
                      font.pixelSize: Style.space(8)
                    }
                  }

                  MouseArea {
                    id: btnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.voxelService) {
                        root.voxelService.setAnimationLevel(modelData.id)
                      }
                    }
                  }
                }
              }
            }

            // Description of currently active mode
            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              height: Style.space(38)
              radius: Style.space(6)
              color: Util.alpha(Color.accent, 0.08)
              border.width: 1
              border.color: Util.alpha(Color.accent, 0.18)

              Text {
                anchors.centerIn: parent
                width: parent.width - Style.space(16)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Util.alpha(root.barForeground, 0.75)
                font.family: Style.font.family
                font.pixelSize: Style.space(9)
                text: {
                  var lvl = root.voxelService ? root.voxelService.animationLevel : "high"
                  if (lvl === "none") return "⏹ Static snapshot: all animations frozen for 0% CPU and zero GPU overhead."
                  if (lvl === "low") return "🍃 Optimized: GPU tree wind sway, animated walking pets AI, campfire & warm lantern glow."
                  return "✨ Cinematic: Full physics with falling petals, leaves, snow, smoke embers, and water spray."
                }
              }
            }
          }
        }
      }

      // ---- Bottom Visual Palette (Direct click any icon/cube) -------------
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !root.isSettingsCategory
        spacing: Style.space(6)

        Repeater {
          model: root.allItems.length

          Rectangle {
            required property int index
            readonly property bool isCur: root.selectedIndex === index
            readonly property var itm: root.allItems[index]

            width: isCur ? Style.space(34) : Style.space(28)
            height: Style.space(28)
            radius: Style.space(6)
            color: isCur
              ? Util.alpha(Color.accent, 0.25)
              : (bMouse.containsMouse ? Util.alpha(root.barForeground, 0.1) : Util.alpha(root.barForeground, 0.04))
            border.width: 1
            border.color: isCur
              ? Color.accent
              : Util.alpha(root.barForeground, 0.12)

            Behavior on width { NumberAnimation { duration: 140 } }
            Behavior on color { ColorAnimation { duration: 140 } }

            // Micro cube preview inside swatch
            Item {
              anchors.centerIn: parent
              width: Style.space(16)
              height: Style.space(16)

              Text {
                anchors.centerIn: parent
                visible: itm.category !== "blocks"
                text: {
                  if (itm.treeType === "sakura") return "🌸"
                  if (itm.treeType === "autumn") return "🍁"
                  if (itm.treeType === "pine") return "🌲"
                  if (itm.treeType === "birch") return "🎋"
                  if (itm.treeType === "oak" || itm.category === "trees") return "🌳"
                  if (itm.propType === "bench") return "🪑"
                  if (itm.propType === "lamp") return "🏮"
                  if (itm.propType === "fountain") return "⛲"
                  if (itm.propType === "campfire") return "🔥"
                  if (itm.propType === "flowers") return "🌺"
                  if (itm.propType === "fence") return "🪵"
                  if (itm.propType === "bridge") return "🌉"
                  if (itm.propType === "stepping-stones") return "🪨"
                  if (itm.animalType === "fox") return "🦊"
                  if (itm.animalType === "cat") return "🐱"
                  if (itm.animalType === "sheep") return "🐑"
                  if (itm.animalType === "pig") return "🐷"
                  return "🐔"
                }
                font.pixelSize: Style.space(12)
              }

              VoxelBlock {
                anchors.centerIn: parent
                visible: itm.category === "blocks"
                widgetScale: 0.55
                blockType: itm.blockType || "grass"
                active: true
              }
            }

            MouseArea {
              id: bMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.selectedIndex === index) {
                  root.placeCurrent()
                } else {
                  root.selectedIndex = index
                }
              }
            }
          }
        }
      }
    }
  }
}
