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
  readonly property var currentCategory: Model.CATEGORIES[currentCategoryIndex]

  // Item state
  property int selectedIndex: 0
  readonly property var allItems: Model.itemsFor(currentCategory.id)
  readonly property var currentItem: allItems.length > 0 ? allItems[selectedIndex] : null

  onCurrentCategoryIndexChanged: {
    selectedIndex = 0
    previewAnim.restart()
  }
  onSelectedIndexChanged: previewAnim.restart()

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
    if (!root.currentItem) return
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
    contentWidth: panel.fittedContentWidth(Style.space(420))
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
          root.currentCategoryIndex = (root.currentCategoryIndex + 1) % Model.CATEGORIES.length
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
      spacing: Style.space(12)

      // ---- Top Category Tabs (BLOCKS / DIORAMAS) -------------------------
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(8)

        Repeater {
          model: Model.CATEGORIES
          delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool isSelected: root.currentCategoryIndex === index

            width: Style.space(78)
            height: Style.space(26)
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
              font.pixelSize: Style.font.caption
              font.weight: isSelected ? Font.Bold : Font.Normal
              font.letterSpacing: 1.2
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
        width: parent.width
        height: Style.space(210)

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
            anchors.margins: Style.space(12)

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
              widgetScale: 2.4
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
              widgetScale: 2.8
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
              widgetScale: 3.6
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
              widgetScale: 3.6
              blockType: root.currentItem && root.currentItem.blockType ? root.currentItem.blockType : "grass"
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

      // ---- Bottom Visual Palette (Direct click any icon/cube) -------------
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
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
                  if (itm.propType === "stairs") return "🪜"
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
