# Roblox Co-op Game

Roblox-spill laget av to personer med Rojo og Claude. Se `PROJECT.md` for spillidé og status.

## Kom i gang
1. Installer [Rojo](https://rojo.space) (CLI + Studio-plugin). Enklest via Rokit: `rokit add rojo-rbx/rojo`.
2. Klon repoet: `git clone <repo-url>` og gå inn i mappen.
3. Start Rojo: `rojo serve`
4. Åpne en tom Baseplate i Roblox Studio, trykk **Connect** i Rojo-plugin. Koden synkroniseres inn.
5. Trykk Play. Du skal se `[ExampleService] ready` og `[ExampleController] ready` i Output.

Bygg en fil om du trenger: `rojo build -o game.rbxl`

## Struktur
```
src/
  shared/    -> ReplicatedStorage.Shared (Config, Remotes)
  server/    -> ServerScriptService.Server (Main + Services/)
  client/    -> StarterPlayerScripts.Client (Main + Controllers/)
PROJECT.md       delt hukommelse (status, beslutninger, hvem gjør hva)
ARCHITECTURE.md  kart over moduler og remotes
CLAUDE.md        regler som Claude leser automatisk
.claude/skills/  Luau-skill med kodestil
```

## Arbeidsflyt med to personer og Claude
- Hver sin branch, små commits, `git pull` før du starter.
- Samarbeid i Studio samtidig? Bruk Team Create for bygging, og Git/Rojo for kode. Ikke rediger samme script begge steder.
- Start økten med å la Claude lese `PROJECT.md` og `ARCHITECTURE.md`. Avslutt med «oppdater PROJECT.md og ARCHITECTURE.md».

## Valgfritt: Graphify
Verktøy som bygger en kunnskapsgraf over prosjektet i Claude Code (`graphify install`, så `/graphify .`). Sjekk at Luau er støttet før du satser på det.
