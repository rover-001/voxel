import QtQuick
import Quickshell
import qs.Commons

// VoxelDiorama — Host for 3D isometric voxel trees, building blocks, clouds, and animals:
// - tree-*: Animated 3D Voxel Trees (Sakura, Oak, Autumn Maple, Pine, Birch)
// - cloud: Animated Puffy 3D Cloud
// - animal-*: Autonomous wandering voxel animals (Chicken, Fox, Cat, Sheep, Pig)
// - block-*: Modular snappable voxel building blocks
// 100% transparent floating background.
Item {
  id: root

  property var card: null
  property real widgetScale: 3.6
  property color fgColor: Color.foreground
  property color accentColor: Color.accent
  property bool active: true
  property string variant: "block-grass"
  property int propRotation: 0

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

  readonly property bool isBlock: !isTree && !isCloud && !isAnimal && !isProp

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
    if (variant.indexOf("waterfall") !== -1) return "waterfall"
    return "bench"
  }

  readonly property string blockType: {
    if (variant.indexOf("block-") === 0) return variant.substring(6)
    if (variant.indexOf("voxel-block-") === 0) return variant.substring(12)
    return "grass"
  }

  width: {
    if (isTree) return treeFace.width
    if (isCloud) return cloudFace.width
    if (isAnimal) return animalFace.width
    if (isProp) return propFace.width
    return blockFace.width
  }

  height: {
    if (isTree) return treeFace.height
    if (isCloud) return cloudFace.height
    if (isAnimal) return animalFace.height
    if (isProp) return propFace.height
    return blockFace.height
  }

  VoxelTree {
    id: treeFace
    anchors.centerIn: parent
    visible: root.isTree
    active: root.active && visible
    widgetScale: root.widgetScale
    treeType: root.treeType
    fgColor: root.fgColor
    accentColor: root.accentColor
  }

  VoxelCloud {
    id: cloudFace
    anchors.centerIn: parent
    visible: root.isCloud
    active: root.active && visible
    widgetScale: root.widgetScale
    fgColor: root.fgColor
    accentColor: root.accentColor
  }

  VoxelAnimal {
    id: animalFace
    card: root.card
    anchors.centerIn: parent
    visible: root.isAnimal
    active: root.active && visible
    widgetScale: root.widgetScale
    animalType: root.animalType
    fgColor: root.fgColor
    accentColor: root.accentColor
  }

  VoxelProp {
    id: propFace
    anchors.centerIn: parent
    visible: root.isProp
    active: root.active && visible
    widgetScale: root.widgetScale
    propType: root.propType
    propRotation: root.propRotation
    fgColor: root.fgColor
    accentColor: root.accentColor
  }

  VoxelBlock {
    id: blockFace
    anchors.centerIn: parent
    visible: root.isBlock
    active: root.active && visible
    widgetScale: root.widgetScale
    blockType: root.blockType
    fgColor: root.fgColor
    accentColor: root.accentColor
  }
}
