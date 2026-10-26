// Voxel Dioramas, Modular Blocks, Creatures, Trees & Props Catalog
.pragma library

var CATEGORIES = [
  { id: "blocks", name: "BLOCKS" },
  { id: "trees", name: "TREES" },
  { id: "creatures", name: "ANIMALS" },
  { id: "props", name: "PROPS" }
];

var ITEMS = [
  // 1. Modular Building Blocks (Clip/Snap together!)
  {
    id: "voxel-block-grass",
    category: "blocks",
    variant: "block-grass",
    blockType: "grass",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-stone",
    category: "blocks",
    variant: "block-stone",
    blockType: "stone",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-wood",
    category: "blocks",
    variant: "block-wood",
    blockType: "wood",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-brick",
    category: "blocks",
    variant: "block-brick",
    blockType: "brick",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-gold",
    category: "blocks",
    variant: "block-gold",
    blockType: "gold",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-crystal",
    category: "blocks",
    variant: "block-crystal",
    blockType: "crystal",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-obsidian",
    category: "blocks",
    variant: "block-obsidian",
    blockType: "obsidian",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-lava",
    category: "blocks",
    variant: "block-lava",
    blockType: "lava",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-water",
    category: "blocks",
    variant: "block-water",
    blockType: "water",
    defaultScale: 3.6
  },
  {
    id: "voxel-block-planks",
    category: "blocks",
    variant: "block-planks",
    blockType: "planks",
    defaultScale: 3.6
  },

  // 2. Animated Voxel Animals (Chicken, Fox, Cat, Sheep, Pig)
  {
    id: "voxel-animal-chicken",
    category: "creatures",
    variant: "animal-chicken",
    animalType: "chicken"
  },
  {
    id: "voxel-animal-fox",
    category: "creatures",
    variant: "animal-fox",
    animalType: "fox"
  },
  {
    id: "voxel-animal-cat",
    category: "creatures",
    variant: "animal-cat",
    animalType: "cat"
  },
  {
    id: "voxel-animal-sheep",
    category: "creatures",
    variant: "animal-sheep",
    animalType: "sheep"
  },
  {
    id: "voxel-animal-pig",
    category: "creatures",
    variant: "animal-pig",
    animalType: "pig"
  },

  // 3. Modular Diorama Props (Bench, Lantern, Fountain, Campfire, Flowers, Fence)
  {
    id: "voxel-prop-bench",
    category: "props",
    variant: "prop-bench",
    propType: "bench",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-lamp",
    category: "props",
    variant: "prop-lamp",
    propType: "lamp",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-fountain",
    category: "props",
    variant: "prop-fountain",
    propType: "fountain",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-campfire",
    category: "props",
    variant: "prop-campfire",
    propType: "campfire",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-flowers",
    category: "props",
    variant: "prop-flowers",
    propType: "flowers",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-fence",
    category: "props",
    variant: "prop-fence",
    propType: "fence",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-waterfall",
    category: "props",
    variant: "prop-waterfall",
    propType: "waterfall",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-stairs",
    category: "props",
    variant: "prop-stairs",
    propType: "stairs",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-bridge",
    category: "props",
    variant: "prop-bridge",
    propType: "bridge",
    defaultScale: 3.6
  },
  {
    id: "voxel-prop-stepping-stones",
    category: "props",
    variant: "prop-stepping-stones",
    propType: "stepping-stones",
    defaultScale: 3.6
  },

  // 4. Animated Voxel Trees (Sakura, Oak, Autumn Maple, Pine, Birch)
  {
    id: "voxel-tree-sakura",
    category: "trees",
    variant: "tree-sakura",
    treeType: "sakura",
    defaultScale: 3.6
  },
  {
    id: "voxel-tree-oak",
    category: "trees",
    variant: "tree-oak",
    treeType: "oak",
    defaultScale: 3.6
  },
  {
    id: "voxel-tree-autumn",
    category: "trees",
    variant: "tree-autumn",
    treeType: "autumn",
    defaultScale: 3.6
  },
  {
    id: "voxel-tree-pine",
    category: "trees",
    variant: "tree-pine",
    treeType: "pine",
    defaultScale: 3.6
  },
  {
    id: "voxel-tree-birch",
    category: "trees",
    variant: "tree-birch",
    treeType: "birch",
    defaultScale: 3.6
  }
];

function findById(id) {
  for (var i = 0; i < ITEMS.length; i++) {
    if (ITEMS[i].id === id) return ITEMS[i];
  }
  return ITEMS[0];
}

function itemsFor(catId) {
  var res = [];
  for (var i = 0; i < ITEMS.length; i++) {
    if (ITEMS[i].category === catId) res.push(ITEMS[i]);
  }
  return res;
}
