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
| `NoiseService` | Tar imot støy-hendelser, gir dem lydnivå (fra `Config.STANCES`) og posisjon (fra karakteren på serveren). Skriver foreløpig bare til Output | Leon | `Config`, `Remotes` |

## Controllers (klient)
| Modul | Ansvar | Eier | Bruker (avhengigheter) |
|---|---|---|---|
| `ExampleController` | Eksempel, slett senere | — | — |
| `MovementNoiseController` | Stance: C = krype av/på, hold venstre Shift = sprint. Setter `WalkSpeed` og sender et fottrinn per `STEP_INTERVAL` mens spilleren beveger seg på bakken | Leon | `Config`, `Remotes` |

## Planlagte systemer (ikke bygget ennå, utledet fra `docs/GAME_DESIGN.md`)
Forslag til oppdeling. Endres når vi bestemmer oss; flytt raden opp til tabellene over når den bygges.

| Modul | Side | Ansvar |
|---|---|---|
| `EntityService` | server | Fiendens tilstander: Patrol, Investigate, Hunt, Mimicry. Reagerer på støy fra `NoiseService` |
| `VoiceController` | klient | Måler stemmenivå hvis det lar seg gjøre (se åpne spørsmål i `PROJECT.md`) |
| `TrapService` | server | Knirkende gulv, props, ventilasjon som gir «støydekke» |
| `ObjectiveService` | server | Reparere strømnettet og rømme |
| `ItemService` | server | Gjenstander som kan kastes, walkie-talkie, lydmåler |
| `AudioController` | klient | 3D-lyd, lydbølger i gulvet, lydmåler-UI |

## Shared
| Modul | Ansvar |
|---|---|
| `Config` | Konstanter og navn begge sider bruker. Støy: `STANCES` (fart, støynivå og stegintervall per stance), `NOISE_TYPES`, `NOISE_EVENT_MIN_INTERVAL`, `NOISE_SPEED_TOLERANCE` |
| `Remotes` | Henter/lager RemoteEvents så navn alltid stemmer |

## RemoteEvents
Alle remotes hentes via `Remotes.getEvent("Navn")`. Skriv dem inn her:

| Navn | Retning | Data | Hva den gjør |
|---|---|---|---|
| `NoiseEvent` | klient → server | `noiseType: string` (nøkkel i `Config.NOISE_TYPES`, nå bare `"Footstep"`), `stance: string` (nøkkel i `Config.STANCES`: `"Crouch"`, `"Walk"`, `"Sprint"`) | Klienten melder om støy. Klienten sender aldri nivå eller posisjon |

## Dataflyt
**Støy fra bevegelse:**
`MovementNoiseController` (taster → stance → `WalkSpeed`) → hvert steg: `NoiseEvent("Footstep", stance)` → `NoiseService`:
1. Avviser ukjent type eller stance.
2. Avviser hendelser som kommer oftere enn `NOISE_EVENT_MIN_INTERVAL` per spiller.
3. Henter posisjon og horisontal fart fra `HumanoidRootPart` på serveren.
4. Farten setter en minste stance: krever spilleren å krype i gå- eller sprintfart, regnes støyen som gå eller sprint.
5. Lydnivå = `Config.STANCES[stance].NOISE` → skrives til Output (senere: sendes videre til `EntityService`).

## Regler for sikkerhet
- Serveren stoler aldri på klienten. Alle verdier fra en remote valideres på serveren.
- Penger, inventar og fremgang endres bare på serveren.
