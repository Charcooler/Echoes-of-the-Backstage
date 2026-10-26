# ARCHITECTURE.md — kart over prosjektet

> Oppdater denne når du legger til, endrer eller fjerner et system. Dette er filen som lar Claude se sammenhengen.

## Mappestruktur (Rojo)
| Mappe i repo | Hvor den havner i Roblox | Hva den inneholder |
|---|---|---|
| `src/shared/` | `ReplicatedStorage.Shared` | Moduler brukt av både server og klient (`Config`, `Remotes`) |
| `src/server/` | `ServerScriptService.Server` | `Main.server.luau` + `Services/` (all serverlogikk) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | `Main.client.luau` + `Controllers/` (UI, input, kamera) |

## Slik lastes systemer
- `Main.server.luau` require-er hver ModuleScript i `Services/` og kaller `init()`.
- `Main.client.luau` gjør det samme for `Controllers/`.
- Nytt system = ny fil i riktig mappe med en `init()`-funksjon.

## Services (server)
| Modul | Ansvar | Eier | Bruker (avhengigheter) |
|---|---|---|---|
| `ExampleService` | Eksempel, slett senere | — | — |

## Controllers (klient)
| Modul | Ansvar | Eier | Bruker (avhengigheter) |
|---|---|---|---|
| `ExampleController` | Eksempel, slett senere | — | — |

## Planlagte systemer (ikke bygget ennå, utledet fra `docs/GAME_DESIGN.md`)
Forslag til oppdeling. Endres når vi bestemmer oss; flytt raden opp til tabellene over når den bygges.

| Modul | Side | Ansvar |
|---|---|---|
| `NoiseService` | server | Tar imot støy-hendelser (gåing, sprint, kast, stemme) og gir dem et lydnivå og en posisjon |
| `EntityService` | server | Fiendens tilstander: Patrol, Investigate, Hunt, Mimicry. Reagerer på støy fra `NoiseService` |
| `MovementNoiseController` | klient | Stance (krype/gå/sprint) og hvor mye støy hvert steg lager |
| `VoiceController` | klient | Måler stemmenivå hvis det lar seg gjøre (se åpne spørsmål i `PROJECT.md`) |
| `TrapService` | server | Knirkende gulv, props, ventilasjon som gir «støydekke» |
| `ObjectiveService` | server | Reparere strømnettet og rømme |
| `ItemService` | server | Gjenstander som kan kastes, walkie-talkie, lydmåler |
| `AudioController` | klient | 3D-lyd, lydbølger i gulvet, lydmåler-UI |

Planlagt remote: `NoiseEvent` (klient til server: type og styrke; serveren bestemmer posisjon selv).

## Shared
| Modul | Ansvar |
|---|---|
| `Config` | Konstanter og navn begge sider bruker |
| `Remotes` | Henter/lager RemoteEvents så navn alltid stemmer |

## RemoteEvents
Alle remotes hentes via `Remotes.getEvent("Navn")`. Skriv dem inn her:

| Navn | Retning | Data | Hva den gjør |
|---|---|---|---|
| (ingen ennå) | | | |

## Dataflyt
(Beskriv kort hvordan hovedsystemene snakker sammen når de finnes, f.eks. «Klient trykker knapp → Remote X → ServiceY validerer → oppdaterer data → sender oppdatering tilbake».)

## Regler for sikkerhet
- Serveren stoler aldri på klienten. Alle verdier fra en remote valideres på serveren.
- Penger, inventar og fremgang endres bare på serveren.
