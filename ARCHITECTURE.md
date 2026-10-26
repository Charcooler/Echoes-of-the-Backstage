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
| `NoiseService` | Tar imot støy-hendelser, gir dem lydnivå (fra `Config.STANCES`) og posisjon (fra karakteren på serveren). Skriver til Output og sender videre til lyttere via `NoiseService.onNoise(fn)` | Leon | `Config`, `Remotes` |
| `EntityService` | Det usynlige monsteret: Patrol (mellom patruljepunkter), Investigate og Hunt. Hører støy innenfor `level` studs, har 3D-fottrinn og dreper spillere innenfor `CATCH_RANGE`. Mimicry er ikke bygget | Leon | `Config`, `NoiseService` |
| `DemoRoomService` | Midlertidig testkart laget i kode: mørkt rom, scene, kasser, nødlys og patruljepunkter. Erstattes av et ekte kart | Leon | `Config` |

## Controllers (klient)
| Modul | Ansvar | Eier | Bruker (avhengigheter) |
|---|---|---|---|
| `ExampleController` | Eksempel, slett senere | — | — |
| `MovementNoiseController` | Stance: C = krype av/på, hold venstre Shift = sprint. Setter `WalkSpeed` og den lokale attributten `Stance` på spilleren, og sender et fottrinn per `STEP_INTERVAL` mens spilleren beveger seg på bakken | Leon | `Config`, `Remotes` |
| `NoiseHudController` | Debug-HUD nede til venstre: stance, støynivå og taster. Leser attributten `Stance` | Leon | `Config` |

## Planlagte systemer (ikke bygget ennå, utledet fra `docs/GAME_DESIGN.md`)
Forslag til oppdeling. Endres når vi bestemmer oss; flytt raden opp til tabellene over når den bygges.

| Modul | Side | Ansvar |
|---|---|---|
| `VoiceController` | klient | Måler stemmenivå hvis det lar seg gjøre (se åpne spørsmål i `PROJECT.md`) |
| `TrapService` | server | Knirkende gulv, props, ventilasjon som gir «støydekke» |
| `ObjectiveService` | server | Reparere strømnettet og rømme |
| `ItemService` | server | Gjenstander som kan kastes, walkie-talkie, lydmåler |
| `AudioController` | klient | 3D-lyd, lydbølger i gulvet, lydmåler-UI |

## Shared
| Modul | Ansvar |
|---|---|
| `Config` | Konstanter og navn begge sider bruker. Støy: `STANCES` (fart, støynivå og stegintervall per stance), `NOISE_TYPES`, `NOISE_EVENT_MIN_INTERVAL`, `NOISE_SPEED_TOLERANCE`. Monster: `ENTITY` (farter, `HUNT_NOISE`, `CATCH_RANGE`, `LINGER_TIME`, `DEBUG_VISIBLE`) og `PATROL_POINT_TAG` |
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
5. Lydnivå = `Config.STANCES[stance].NOISE` → skrives til Output og sendes til alle `onNoise`-lyttere.

**Monsteret:**
`NoiseService.onNoise` → `EntityService`. Støy med nivå over 0 høres hvis monsteret er innenfor `level` studs (gå = 30, sprint = 80, krype høres aldri).
- Nivå ≥ `HUNT_NOISE`, eller allerede i Hunt → **Hunt**: løper mot lyden med `HUNT_SPEED`.
- Ellers → **Investigate**: går mot lyden med `INVESTIGATE_SPEED`.
- Fremme ved lyden: står og lytter i `LINGER_TIME` sekunder, og går så til **Patrol** mellom deler med taggen `PATROL_POINT_TAG`.
- Er en spiller innenfor `CATCH_RANGE`, settes `Health = 0`.

Monsteret er en ankret, usynlig part i `workspace` (rød og halvgjennomsiktig når `DEBUG_VISIBLE = true`), med en `Sound` som spiller fottrinn i 3D.

**Tags og attributter:**
| Navn | Type | Satt av | Lest av |
|---|---|---|---|
| `EntityPatrolPoint` (`Config.PATROL_POINT_TAG`) | CollectionService-tag | `DemoRoomService` (senere: kartet i Studio) | `EntityService` |
| `Stance` | Attributt på `LocalPlayer`, bare lokalt | `MovementNoiseController` | `NoiseHudController` (aldri serveren) |

## Regler for sikkerhet
- Serveren stoler aldri på klienten. Alle verdier fra en remote valideres på serveren.
- Penger, inventar og fremgang endres bare på serveren.
