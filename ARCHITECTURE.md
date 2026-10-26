# ARCHITECTURE.md — kart over prosjektet

> Oppdater denne når du legger til, endrer eller fjerner et system. Dette er filen som lar Claude se sammenhengen.

## Mappestruktur (Rojo)
| Mappe i repo | Hvor den havner i Roblox | Hva den inneholder |
|---|---|---|
| `src/first/` | `ReplicatedFirst.First` | Det som må kjøre før resten av spillet er lastet: lasteskjermen og `UiTheme` |
| `src/shared/` | `ReplicatedStorage.Shared` | Moduler brukt av både server og klient (`Config`, `Remotes`) |
| `src/server/` | `ServerScriptService.Server` | `Main.server.luau` + `Services/` (all serverlogikk) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | `Main.client.luau` + `Controllers/` (UI, input, kamera) |
| `art/` | (ikke synket) | Kildefiler for kunst: `art/map/` (operahuset i Blender + eksport) og `art/stagehand/` (monsterets mesh og rigg) |

## Slik lastes systemer
- `Main.server.luau` require-er hver ModuleScript i `Services/` og kaller `init()`.
- `Main.client.luau` gjør det samme for `Controllers/`.
- Nytt system = ny fil i riktig mappe med en `init()`-funksjon.

## Services (server)
| Modul | Ansvar | Eier | Bruker (avhengigheter) |
|---|---|---|---|
| `RoundService` | Runde-loopen: spawner alle, avgjør utfallet for hver spiller (rømt eller tatt, ingen respawn), viser resultat i `RESULT_TIME` sekunder og starter ny runde. Setter `Players.CharacterAutoLoads = false` | Leon | `Config`, `ObjectiveService`, `ItemService`, `EntityService` |
| `ObjectiveService` | Sikringsskap (tag `FuseBox`): hold E i `REPAIR_TIME` sekunder for å reparere. Reparasjon lager støy. Når alle er fikset, åpnes utgangsdøren (tag `ExitDoor`) | Leon | `Config`, `NoiseService` |
| `ItemService` | Flasker som kan kastes: plukkes opp ved `BottleSpawn`, kastes med `ThrowEvent`, flyr i en bue (simulert på serveren) og knuses med høy støy der de lander | Leon | `Config`, `Remotes`, `NoiseService` |
| `NoiseService` | Tar imot støy-hendelser og gir dem lydnivå (fra `Config.STANCES`) og posisjon (fra karakteren på serveren). `emit(position, level, source)` lar serveren lage støy selv. Lyttere melder seg på med `onNoise(fn)` | Leon | `Config`, `Remotes` |
| `EntityService` | Det usynlige monsteret: Patrol (mellom patruljepunkter), Investigate og Hunt. Hører støy innenfor `level` studs, har 3D-fottrinn og dreper spillere innenfor `CATCH_RANGE`. `reset()` setter det tilbake til patruljering ved ny runde. Mimicry er ikke bygget | Leon | `Config`, `NoiseService`, `EntityModel` |
| `EntityService/EntityModel` | Bygger kroppen til «The Stagehand». Bruker den riggede AI-meshen fra `Config.ENTITY.MESH` (lastet med `AssetService:CreateMeshPartAsync`) og legger på beinene fra `StagehandRig`. Feiler den, brukes en reservekropp bygget av deler. Alt er sveiset til en ankret `Root` | Leon | `Config`, `StagehandRig` |
| `EntityService/StagehandRig` | Tabell over de 18 beinene i riggen (navn, forelder, CFrame) og `addBones(meshPart)`. Riggen ligger dermed i git som tekst | Leon | — |
| `MapService` | Bygger operahuset fra `MapService/MapLayout` (deler med tagger, lys), lager spawnet fra `PlayerSpawn`-markøren (og slår av andre SpawnLocations), publiserer startskjermkameraet som `workspace`-attributtet `MenuCamera` og setter mørk belysning | Leon | `Config`, `MapLayout` |
| `MapService/MapLayout` | **Generert** av `art/map/export_map.py` fra `art/map/opera_house.blend`. Skal ikke redigeres for hånd | Leon | — |

## Controllers (klient)
| Modul | Ansvar | Eier | Bruker (avhengigheter) |
|---|---|---|---|
| `MovementNoiseController` | Stance: C = krype av/på, hold venstre Shift = sprint. Setter `WalkSpeed` og den lokale attributten `Stance`, og sender et fottrinn per `STEP_INTERVAL` mens spilleren beveger seg | Leon | `Config`, `Remotes` |
| `ThrowController` | Kaster flasken dit kameraet ser: F, gamepad R2 eller en knapp på skjermen (ContextActionService). Er bare aktiv når spilleren har en flaske | Leon | `Remotes` |
| `RoundHudController` | Runde-HUD i art deco-stil: mål øverst («Repair the fuse boxes 1 / 3»), hint når du har en flaske, og resultatskjerm (YOU ESCAPED / IT HEARD YOU) med nedtelling | Leon | `UiTheme` |
| `NoiseHudController` | Debug-HUD nede til venstre: stance og støynivå | Leon | `Config` |
| `SpectateController` | Tilskuermodus: når du har rømt eller er tatt, følger kameraet en lagkamerat som fortsatt spiller (venstre/høyre, D-pad eller knapper på skjermen) | Leon | `UiTheme` |
| `EntityAnimationController` | Animerer monsterets skjelett lokalt på hver klient (`Bone.Transform`): gange med knær og armsving, foroverbøyd sprint i Hunt, pust og hoderykk når det står stille | Leon | `Config` |
| `StartScreenController` | Tittelskjerm: kamera mot scenen, fløyelsgardiner, tittel og ENTER-knapp. Holder karakteren i ro og skjuler Roblox-UI til spilleren trykker ENTER, så åpnes gardinene | Leon | `UiTheme` |

## ReplicatedFirst (klient, kjører før alt annet)
| Modul | Ansvar | Eier |
|---|---|---|
| `LoadingScreen` (LocalScript) | Erstatter Roblox' lasteskjerm. Vises til spillet er lastet (minst 3 s), og toner så ut over startskjermen | Leon |
| `UiTheme` | Visuell stil for all UI: farger (svart, gull, krem, fløyel), fonter (Bodoni og Garamond), solstråler, art deco-ramme og lydmåler-søyler | Leon |

## Planlagte systemer (ikke bygget ennå, utledet fra `docs/GAME_DESIGN.md`)
Forslag til oppdeling. Endres når vi bestemmer oss; flytt raden opp til tabellene over når den bygges.

| Modul | Side | Ansvar |
|---|---|---|
| `VoiceController` | klient | Måler stemmenivå hvis det lar seg gjøre (se åpne spørsmål i `PROJECT.md`) |
| `TrapService` | server | Knirkende gulv, props, ventilasjon som gir «støydekke» |
| (utvide `ItemService`) | server | Walkie-talkie og lydmåler |
| `AudioController` | klient | 3D-lyd, lydbølger i gulvet, lydmåler-UI |

## Shared
| Modul | Ansvar |
|---|---|
| `Config` | Konstanter og navn begge sider bruker: `STANCES`, støygrenser, `ENTITY` (farter, `HUNT_NOISE`, `CATCH_RANGE`, `LINGER_TIME`, `DEBUG_VISIBLE`, `MESH`), `ROUND` (`REPAIR_TIME`, `REPAIR_NOISE`, `REPAIR_NOISE_INTERVAL`, `RESULT_TIME`), `THROW` (`RANGE`, `NOISE`, `COOLDOWN`), `SOUNDS` (lyd-ID-er for monsterets skritt og pust, knust flaske, reparasjon og fikset skap) og alle tag-navn |
| `Remotes` | Henter/lager RemoteEvents så navn alltid stemmer |

## RemoteEvents
Alle remotes hentes via `Remotes.getEvent("Navn")`. Skriv dem inn her:

| Navn | Retning | Data | Hva den gjør |
|---|---|---|---|
| `NoiseEvent` | klient → server | `noiseType: string` (nøkkel i `Config.NOISE_TYPES`, nå bare `"Footstep"`), `stance: string` (`"Crouch"`, `"Walk"`, `"Sprint"`) | Klienten melder om fottrinn. Klienten sender aldri nivå eller posisjon |
| `ThrowEvent` | klient → server | `direction: Vector3` (kameraets retning, omtrent lengde 1) | Kaster flasken spilleren holder. Serveren sjekker flaske, cooldown og at retningen er gyldig, og regner ut kastet fra spillerens hode |

## Dataflyt
**Runden:**
`RoundService` starter runden: `ObjectiveService.reset()`, `ItemService.reset()`, `EntityService.reset()`, setter `RoundState = "Playing"` og spawner alle. Spillerne reparerer sikringsskapene (`ObjectiveService` → `FusesFixed`). Når alle er fikset → `ExitOpen = true` og døren forsvinner. En spiller i `ExitZone` får `Outcome = "Escaped"` og karakteren fjernes. En spiller som dør får `Outcome = "Caught"`. Når alle har et utfall → `RoundState = "Ended"`, `NextRoundAt` settes, og en ny runde starter etter `RESULT_TIME` sekunder.

**Støy:**
- Fottrinn: `MovementNoiseController` → `NoiseEvent("Footstep", stance)` → `NoiseService` avviser ukjent type eller stance og spam, henter posisjon og fart fra serveren, og bruker farten som minste stance → `emit`.
- Reparasjon: `ObjectiveService` → `emit(skapets posisjon, REPAIR_NOISE)` hvert `REPAIR_NOISE_INTERVAL` mens noen holder E.
- Flaske: `ThrowController` → `ThrowEvent(retning)` → `ItemService` simulerer kastet → `emit(landingspunkt, THROW.NOISE)`.
- `NoiseService.emit` → alle `onNoise`-lyttere (nå `EntityService`).

**Monsteret:**
Støy med nivå over 0 høres hvis monsteret er innenfor `level` studs (krype 0, reparasjon 25, gå 30, flaske 70, sprint 80).
- Nivå ≥ `HUNT_NOISE`, eller allerede i Hunt → **Hunt**: løper mot lyden med `HUNT_SPEED`.
- Ellers → **Investigate**: går mot lyden med `INVESTIGATE_SPEED`.
- Fremme ved lyden: står og lytter i `LINGER_TIME` sekunder, og går så til **Patrol** mellom patruljepunktene.
- Er en spiller innenfor `CATCH_RANGE`, settes `Health = 0`.

Monsteret er modellen `Entity` i `workspace`. `Root` er ankret og flyttes med `CFrame` hver frame, og kroppen er sveiset fast til den. `Root` har en `Sound` som spiller fottrinn i 3D. Med `DEBUG_VISIBLE = false` er kroppen usynlig og vises bare i 1,5 sekunder når monsteret tar noen.

**Tags og attributter:**
| Navn | Type | Satt av | Lest av |
|---|---|---|---|
| `EntityPatrolPoint`, `FuseBox`, `ExitDoor`, `ExitZone`, `BottleSpawn`, `PlayerSpawn` (`Config.*_TAG`) | CollectionService-tagger | `MapService` (fra `rbx_tag` i Blender) | `EntityService`, `ObjectiveService`, `RoundService`, `ItemService`, `MapService` |
| `MenuCamera` | Attributt på `workspace` (CFrame) | `MapService` | `StartScreenController` |
| `RoundState`, `NextRoundAt` | Attributter på `workspace` | `RoundService` | `RoundHudController` |
| `FusesFixed`, `FusesTotal`, `ExitOpen` | Attributter på `workspace` | `ObjectiveService` | `RoundService`, `RoundHudController` |
| `Outcome` (`"Escaped"`/`"Caught"`) | Attributt på spilleren | `RoundService` | `RoundHudController` |
| `HasBottle` | Attributt på spilleren | `ItemService` | `ThrowController`, `RoundHudController` |
| `Stance` | Attributt på `LocalPlayer`, bare lokalt | `MovementNoiseController` | `NoiseHudController` (aldri serveren) |
| `Rigged`, `State`, `Moving` | Attributter på modellen `Entity` | `EntityService`/`EntityModel` | `EntityAnimationController` |

**Kartet (`art/map/`), Blender som baneredigerer:**
`build_opera_map.py` bygger operahuset i Blender og lagrer `opera_house.blend`. Etter det er `.blend` kilden: rediger i Blender, og kjør `blender opera_house.blend -b --python export_map.py`. Eksporten skriver `src/server/Services/MapService/MapLayout.luau` og testbilder i `art/map/preview/`.
Konvensjoner i `.blend`: objekter med `rbx = "part"` blir Roblox-deler (`rbx_class`, `rbx_shape`, `rbx_material`, `rbx_collide`, `rbx_transparency`, `rbx_tag`, objektfargen = Roblox-fargen). `rbx = "marker"` er usynlige taggede deler (patruljepunkter, flasker, spawn, utgangssone). `rbx = "light"` blir PointLight/SpotLight, og kameraet `MenuCamera` blir startskjermkameraet. 1 Blender-enhet = 1 stud. Blender Z opp → Roblox Y opp, og alt løftes 20 studs så kjelleren havner over baseplaten.
Nivåer (Blender Z): sal 0, orkestergrav −4, scene/korridor/rom 4, gangbroer 22, kjeller −14, sisterne −18.

**Monsterets bevegelse:** `EntityService` regner ut stier med `PathfindingService` (agent 3 bred, 9 høy, kan klatre stiger og «hoppe» ned trappetrinn) og går langs waypoints. Mens en ny sti regnes ut, fortsetter monsteret på den gamle. Kan det ikke nå målet, blir det stående og lytte.

**Monsterets kunst og rigg (`art/stagehand/`):**
`stagehand.gltf` (eksportert fra Studio) → `rig_stagehand.py` i Blender (skjelett, vekter, testbilder i `preview/`) → `stagehand_rigged.glb` → Studio: File → Import 3D. Ved ny rigg må du oppdatere mesh- og tekstur-ID i `Config.ENTITY.MESH` og beintabellen i `StagehandRig` med verdiene fra den importerte modellen.

## Regler for sikkerhet
- Serveren stoler aldri på klienten. Alle verdier fra en remote valideres på serveren.
- Penger, inventar og fremgang endres bare på serveren.
- Prompt-handlinger (reparere, plukke opp) sjekker avstand og rundestatus på serveren i tillegg til motorens egen sjekk.
