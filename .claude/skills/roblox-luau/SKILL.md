---
name: roblox-luau
description: Conventions and patterns for writing Luau code in this Roblox Rojo project (server/client/shared structure, services, remotes, naming). Use whenever writing or changing game code here.
---

# Roblox Luau conventions for this project

## Structure
- `src/shared` → ReplicatedStorage.Shared, `src/server` → ServerScriptService.Server, `src/client` → StarterPlayerScripts.Client.
- One system per file. Server systems live in `src/server/Services/`, client systems in `src/client/Controllers/`.
- A system is a ModuleScript that returns a table with an `init()` function. Entry scripts load them automatically.

## Style
- Files use the `.luau` extension. Use `--!strict` in new shared/server modules when practical.
- Naming: `PascalCase` for modules and services, `camelCase` for functions and variables, `UPPER_SNAKE_CASE` for constants.
- Get services with `game:GetService("...")` at the top of the file.
- Prefer `task.wait`, `task.spawn`, `task.delay` over the deprecated `wait`, `spawn`, `delay`.
- Use string interpolation (`` `Hello {name}` ``) and generalized iteration (`for _, v in tbl do`).
- Keep functions small. Comment the why, not the what.

## Networking
- Get remotes only through `Remotes.getEvent("Name")` from `src/shared/Remotes`.
- Every remote is listed in `ARCHITECTURE.md` (name, direction, data).
- The server never trusts the client: validate every argument (type, range, ownership) before using it.
- Money, inventory and progress change on the server only. The client only displays and requests.

## Checklist before finishing
- [ ] No new global state; no large monolithic scripts
- [ ] Remotes validated on server
- [ ] `ARCHITECTURE.md` updated (modules, remotes)
- [ ] `PROJECT.md` updated (status, decisions)
