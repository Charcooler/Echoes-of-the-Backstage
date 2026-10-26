# CLAUDE.md

Roblox-spill laget av to personer, som begge bruker Claude. Dette er et Rojo-prosjekt: koden ligger som filer i `src/`, ikke i Studio.

## Les først
1. `PROJECT.md` — spillidé, status, beslutninger, hvem eier hva
2. `ARCHITECTURE.md` — moduler, remotes og dataflyt

## Regler
- Kode og kommentarer på engelsk. Dokumentasjon (`PROJECT.md`, `ARCHITECTURE.md`) på norsk. Svar brukeren på norsk.
- Følg `.claude/skills/roblox-luau/SKILL.md` for kodestil og mønstre.
- Bruk bare navn og verdier som allerede finnes i `Config` og `ARCHITECTURE.md`. Finn ikke på nye navn for ting som finnes.
- Ett system per fil. Ikke lag ett stort script.
- Ikke endre systemer som den andre eier (se tabellen i `PROJECT.md`) uten å si fra til brukeren.
- Ikke finn på kommandoer eller Roblox-API-er. Er du usikker, si det.

## Når du er ferdig med en oppgave
- Oppdater `ARCHITECTURE.md` hvis du la til/endret moduler eller remotes.
- Oppdater `PROJECT.md` (status + beslutninger).
- Foreslå en commit-melding.

## Valgfritt: kunnskapsgraf med Graphify
Når repoet er stort nok, kan Graphify bygge en graf over prosjektet (`graphify install`, deretter `/graphify .` i Claude Code). Sjekk først at Luau støttes. Se `README.md`. Grafen erstatter ikke `PROJECT.md`.
