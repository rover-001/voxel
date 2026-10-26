# Voxel — Isometric Desktop Diorama & Sandbox World Builder for Omarchy

A 3D isometric voxel sandbox and diorama desktop plugin for Omarchy / Quickshell. Build floating islands, towns, forests, and scenic landscapes directly on your desktop wallpaper.

## Features

- **Snappable Modular Blocks**:
  - Grass, Stone, Wood, Brick, Gold, Crystal, Obsidian, and Lava.
  - Live magnetic snapping while holding/dragging with zero interpenetration or seam gaps.
  - 3D cluster rotation (CW `↻` & CCW `↺`) with exact isometric coordinate preservation.
- **Animated Voxel Trees**:
  - Sakura (cherry blossom wind drift & falling petals), Oak (swaying branches & acorns), Autumn Maple (gust whirlwinds & foliage), Alpine Pine (cold spire breeze & snow flurries), Birch (quivering leaves & pollen).
  - Perfect integer harmonic animation loops with zero end-of-cycle snapping.
- **Autonomous Wandering Animals**:
  - Chickens, Foxes, Cats, Sheep, and Pigs.
  - Real-time pathfinding across block surfaces, edge detection, obstacle avoidance, and hopping.
- **Scenic Diorama Props**:
  - Wooden Park Bench (with wrought-iron side frames and polished slats).
  - Streetlamp / Lantern Post (with warm amber breathing lantern glow).
  - Cobblestone Fountain (with animated water ripple waves and splash droplets).
  - Campfire (with dancing flame voxels and rising embers).
  - Flower Garden (with blooming poppies, tulips, orchids, and gentle breeze sway).
  - Rustic Fence (wooden post and rail barriers).
- **Cluster Manipulation**:
  - Multi-block selection outline with cluster drag, layer elevation shifting, 2:1 isometric rotation, and bulk removal.
- **Zero Desktop Distortion**:
  - Even-integer coordinate quantization ensures razor-sharp 100% even tile edges.

## Installation

Symlink or place in your Omarchy plugins directory:
```bash
ln -s ~/Projects/voxel ~/.config/omarchy/plugins/voxel
omarchy restart shell
```

## License
MIT
