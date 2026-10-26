import QtQuick
import Quickshell
import qs.Commons

// VoxelDiorama — Lightweight Host for 3D isometric voxel entities.
// Uses a dynamic Loader so each card only instantiates its specific visual component.
Item {
  id: root

  property var card: null
  property real widgetScale: 3.6
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string variant: "block-grass"
  property int propRotation: 0

  readonly property bool isClock: variant === "clock" || variant === "voxel-clock"
  readonly property bool isTree: variant.indexOf("tree-") === 0
    || variant.indexOf("voxel-tree-") === 0
    || variant === "tree"
  readonly property bool isCloud: variant === "cloud" || variant === "voxel-cloud"
  readonly property bool isProp: variant.indexOf("prop-") === 0
    || variant.indexOf("voxel-prop-") === 0
  readonly property bool isAnimal: variant.indexOf("animal-") === 0
    || variant.indexOf("voxel-animal-") === 0
    || variant === "chicken"
    || variant === "fox"
    || variant === "cat"
    || variant === "sheep"
    || variant === "pig"

  readonly property bool isBlock: !isTree && !isCloud && !isAnimal && !isProp && !isClock
  readonly property bool isWalking: isAnimal && faceLoader.item ? faceLoader.item.isWalking : false

  readonly property string treeType: {
    if (variant.indexOf("sakura") !== -1) return "sakura"
    if (variant.indexOf("autumn") !== -1) return "autumn"
    if (variant.indexOf("pine") !== -1) return "pine"
    if (variant.indexOf("birch") !== -1) return "birch"
    return "oak"
  }

  readonly property string animalType: {
    if (variant.indexOf("fox") !== -1) return "fox"
    if (variant.indexOf("cat") !== -1) return "cat"
    if (variant.indexOf("sheep") !== -1) return "sheep"
    if (variant.indexOf("pig") !== -1) return "pig"
    return "chicken"
  }

  readonly property string propType: {
    if (variant.indexOf("lamp") !== -1) return "lamp"
    if (variant.indexOf("fountain") !== -1) return "fountain"
    if (variant.indexOf("campfire") !== -1) return "campfire"
    if (variant.indexOf("flowers") !== -1) return "flowers"
    if (variant.indexOf("fence") !== -1) return "fence"
    if (variant.indexOf("bridge") !== -1) return "bridge"
    if (variant.indexOf("stepping-stones") !== -1) return "stepping-stones"
    return "bench"
  }

  readonly property string blockType: {
    if (variant.indexOf("block-") === 0) return variant.substring(6)
    if (variant.indexOf("voxel-block-") === 0) return variant.substring(12)
    return "grass"
  }

  width: faceLoader.item ? faceLoader.item.width : 0
  height: faceLoader.item ? faceLoader.item.height : 0

  Loader {
    id: faceLoader
    anchors.centerIn: parent
    asynchronous: false
    sourceComponent: {
      if (root.isClock) return clockComp
      if (root.isTree) return treeComp
      if (root.isCloud) return cloudComp
      if (root.isAnimal) return animalComp
      if (root.isProp) return propComp
      return blockComp
    }
  }

  Component {
    id: clockComp
    VoxelClock {
      clockScale: root.widgetScale
      fgColor: root.fgColor
      accentColor: root.accentColor
      active: root.active
    }
  }

  Component {
    id: treeComp
    VoxelTree {
      widgetScale: root.widgetScale
      treeType: root.treeType
      fgColor: root.fgColor
      accentColor: root.accentColor
      active: root.active
    }
  }

  Component {
    id: cloudComp
    VoxelCloud {
      widgetScale: root.widgetScale
      fgColor: root.fgColor
      accentColor: root.accentColor
      active: root.active
    }
  }

  Component {
    id: animalComp
    VoxelAnimal {
      card: root.card
      widgetScale: root.widgetScale
      animalType: root.animalType
      fgColor: root.fgColor
      accentColor: root.accentColor
      active: root.active
    }
  }

  Component {
    id: propComp
    VoxelProp {
      widgetScale: root.widgetScale
      propType: root.propType
      propRotation: root.propRotation
      fgColor: root.fgColor
      accentColor: root.accentColor
      active: root.active
    }
  }

  Component {
    id: blockComp
    VoxelBlock {
      widgetScale: root.widgetScale
      blockType: root.blockType
      fgColor: root.fgColor
      accentColor: root.accentColor
      active: root.active
    }
  }
}
