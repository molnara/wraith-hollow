# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wraith Hollow is a 3D game built with Godot 4.5 (Mono/.NET edition) using the Forward Plus renderer.

## Running the Project

Use the Godot MCP tools to interact with the project:
- `mcp__godot__run_project` - Run the game
- `mcp__godot__launch_editor` - Open in Godot editor
- `mcp__godot__stop_project` - Stop running game

## Architecture

### Directory Structure
- `player/` - Player character with 3rd person controls
- `enemies/` - Enemy characters, each in their own subdirectory with `.tscn` scene, `.glb` models, and textures
- `main.tscn` - Main game scene with player, ground, and lighting

### Player System
- **Player** (`player/player.tscn`) - CharacterBody3D with 3rd person camera
  - WASD movement, Shift to sprint, Space to jump, Escape to toggle mouse capture
  - SpringArm3D camera rig with mouse look
  - Placeholder capsule mesh (blue)

### Input Actions
- `move_forward/backward/left/right` - WASD keys
- `sprint` - Left Shift
- `ui_accept` - Jump (Space)
- `ui_cancel` - Toggle mouse capture (Escape)

### Enemies
- **Skeleton Warrior** (`enemies/skeleton_warrior/`) - Animated skeleton enemy with sword and shield
  - Uses BoneAttachment3D for weapon placement on skeleton rig
  - Has AnimationPlayer for animations
  - Follows player using simple movement script

## Working with Large Files

`skeleton_warrior.tscn` is very large (317KB, ~82K tokens) due to embedded GLB animation data. Do not read the whole file. Instead:
- Use Grep to search for specific sections (e.g., `[node name=`, `[ext_resource`)
- Use `head`/`tail` bash commands to read specific line ranges
- Use Read tool with `offset` and `limit` parameters

## Godot Conventions

- Scene files: `.tscn`
- Scripts: `.gd` (GDScript) or `.cs` (C#)
- 3D models: `.glb` (GLTF binary)
- Resources are referenced via `res://` paths
- Import files (`.import`) are auto-generated, do not edit manually
