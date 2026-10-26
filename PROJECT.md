# PROJECT.md — delt hukommelse for prosjektet

> Begge Claude-ene leser denne filen i starten av hver økt og oppdaterer den på slutten.
> Hold den kort og oppdatert. Skriv beslutninger her, ikke bare i chatten.

## Spillet
- **Navn:** Echoes of the Backstage
- **Én setning:** Du kan ikke se monsteret, bare høre det. Lag minst mulig lyd mens dere reparerer operahusets strømnett og rømmer.
- **Sjanger / stil:** Taktisk co-op lydhorror, 1–4 spillere, 1920-talls operahus i nesten full mørke
- **Full design:** se `docs/GAME_DESIGN.md`
- **Språk i spilltekst:** TODO (engelsk / norsk)
- **Første spillbare versjon (bygget, branch `leon/game-loop`):** ett rom, usynlig monster som jakter på lyd, tre sikringsskap å reparere, flasker å kaste som avledning, utgangsdør, runder med resultatskjerm.

## Folk og eierskap
| Person | Eier (systemer/mapper) | Claude-økter |
|--------|------------------------|--------------|
| Meg    | TODO                   |              |
| Kompis | TODO                   |              |

Regel: man endrer bare andres systemer etter å ha snakket sammen. Delte filer (`Config`, `Remotes`, denne filen) endres i små, raske commits.

## Status
### Ferdig
- Prosjektstruktur med Rojo (server / client / shared)
- Spilldesign lagt inn i `docs/GAME_DESIGN.md`
- Støy-demo (branch `leon/noise-demo`): `NoiseService`, `MovementNoiseController` og remoten `NoiseEvent`. Testet i Studio: gå = 30, sprint = 80, krype = 0. Ugyldige argumenter og spam blir avvist.
- Spillbar mini-demo (branch `leon/entity-demo`): mørkt testrom (`DemoRoomService`), usynlig monster med Patrol, Investigate og Hunt og 3D-fottrinn (`EntityService`), og debug-HUD (`NoiseHudController`). Testet i Studio: sprint → Hunt → spilleren blir tatt.
- Lasteskjerm og startskjerm (branch `leon/start-screen`) i art deco-stil: gull på svart, solstråler, røde fløyelsgardiner og lydmåler-søyler. Testet i Studio: lasteskjerm → startskjerm → ENTER åpner gardinene.
- Monsterets kropp «The Stagehand» (`EntityModel`), med et glimt av kroppen når den tar noen.
- AI-generert monstermesh (Roblox' mesh-generator i Studio): høy, utmagret skikkelse i frakk med kobbertrakt som hode. Animasjon etter tilstand: gange, lener seg fremover i Hunt, puster og rykker med hodet når den lytter. Utkastene ligger i `ServerStorage.GeneratedMonsterDrafts` i Leons place-fil (ikke i git).
- Monsteret er rigget i Blender (`art/stagehand/rig_stagehand.py`) og animeres med skjelett: ekte gange med knær og armsving, foroverbøyd jakt, pust og hoderykk. Testet i Studio.
- **Spill-loopen** (branch `leon/game-loop`): runder (`RoundService`), sikringsskap og utgangsdør (`ObjectiveService`), flasker du kaster som avledning (`ItemService`, `ThrowController`, remoten `ThrowEvent`) og runde-HUD med resultatskjerm (`RoundHudController`). Testet i Studio, hele veien: flaske → monsteret jakter dit, 3 skap → døren åpnes → ut → «YOU ESCAPED» → ny runde. Tatt → «IT HEARD YOU» → ny runde. Eksempelmodulene er fjernet.

### Pågår
- (ingenting ennå)

### Neste
- [ ] Spilltest med flere spillere (co-op) og juster balansen i `Config.ROUND` / `Config.THROW` / `Config.ENTITY`
- [ ] Tilskuermodus for spillere som er tatt eller har rømt (nå står kameraet stille)
- [ ] Ekte lyder: knust glass, reparasjon, monsterets fottrinn og pust (nå brukes Roblox' innebygde lyder)
- [ ] Bestemme språk i spilltekst
- [ ] Fordele eierskap av systemene (se `ARCHITECTURE.md`, planlagte systemer)
- [ ] Avklare de tekniske spørsmålene under (mikrofon, lyd, Mimicry) før vi bygger på dem
- [ ] Ekte kart bygget i Studio (med taggene `EntityPatrolPoint`, `FuseBox`, `ExitDoor`, `ExitZone`, `BottleSpawn`) som erstatter `DemoRoomService`
- [ ] Monsteret går i rett linje gjennom props. Bytt til PathfindingService når kartet har flere rom eller etasjer.
- [ ] Monsterets posisjon replikeres til klientene, så en juksende klient kan finne det. Vurder å skjule det på serveren.
- [ ] Skru av `Config.ENTITY.DEBUG_VISIBLE` når vi er ferdige med å teste
- [ ] Vurdere om fottrinn bør regnes ut helt på serveren. I dag kan en juksende klient la være å sende `NoiseEvent` og dermed være stille.

## Beslutninger (nyeste øverst)
| Dato | Beslutning | Hvorfor |
|------|-----------|---------|
| 2026-10-26 | Spill-loop: reparer 3 sikringsskap (hold E i 5 s, lager støy) → døren bak scenen åpnes → rømm. Tatt = ute til neste runde (ingen respawn). Ny runde når alle er ferdige | Kjernen fra `GAME_DESIGN.md` (reparere strømnettet og rømme) i minste spillbare form |
| 2026-10-26 | Reparasjonsstøy er nivå 25, ikke 40 | Med 40 kom monsteret før reparasjonen var ferdig, og det var nesten umulig å spille alene |
| 2026-10-26 | Flasker kastes med serversimulering: klienten sender bare retning, serveren sjekker flaske og cooldown og regner ut landingspunktet. Knust flaske = støy 70 (Hunt) | Avledning er signaturmekanikken i designet. Klienten kan ikke velge hvor støyen havner |
| 2026-10-26 | Rundestatus deles med attributter (`workspace` og spiller), ikke egne remotes | Replikeres automatisk og er enkelt å lese i HUD-en |
| 2026-10-26 | Monsteret rigges med Blender-skript (egne vektregler, ikke automatiske vekter) og animeres med kode på klienten via `Bone.Transform` | De automatiske vektene rev opp frakken. Kodeanimasjon krever ingen opplastede animasjoner, koster ingen nettverkstrafikk og er lett å justere |
| 2026-10-26 | Riggens bein bygges fra en tabell i `StagehandRig`, ikke fra en `.rbxm` | Alt blir tekst i git, og vi slipper Rojos problemer med MeshParts |
| 2026-10-26 | Monsterets kropp er en AI-generert mesh, lagret som asset-ID-er i `Config.ENTITY.MESH`. Kroppen av deler er reserve | Ser mye bedre ut. Asset-ID-er i koden gjør at modellen kommer med i git |
| 2026-10-26 | Monsteret: «The Stagehand», en høy, lutende scenearbeider med grammofontrakt som hode. Bygget av deler i kode (`EntityModel`) | Lyd er hele identiteten. Kode kommer med i git. Kan byttes mot en modell fra Studio (`.rbxm`) senere |
| 2026-10-26 | Startskjermen fryser karakteren med `Anchored` lokalt, ikke med `PlayerModule` | Denne Studio-versjonen har ingen `PlayerModule` i PlayerScripts |
| 2026-10-26 | Menystil: 1920-talls art deco (gull og svart, solstråler, doble rammer), røde fløyelsgardiner og lydmåler-søyler som kjennetegn. Fargene og fontene ligger i `UiTheme` | Passer operahuset og lyd-temaet. Gjenbrukes i all UI |
| 2026-10-26 | Menytekst foreløpig på engelsk | Spilltekstspråk er ikke bestemt. Engelsk er lett å bytte |
| 2026-10-26 | `src/first` → `ReplicatedFirst.First` i Rojo | Lasteskjermen må ligge i ReplicatedFirst for å vises før spillet er lastet |
| 2026-10-26 | Støynivå = hørselsradius i studs for monsteret. Nivå ≥ 60 gir Hunt, lavere gir Investigate | Enkelt å forstå og justere i `Config` |
| 2026-10-26 | Monsteret løper litt saktere enn sprint (22 mot 26) | Du kan rømme, men sprinten holder det på sporet ditt |
| 2026-10-26 | Monsterets fottrinn bruker `rbxasset://sounds/action_footsteps_plastic.mp3`, som følger med Roblox | Ingen opplasting eller asset-ID nødvendig. Byttes mot egen lyd senere |
| 2026-10-26 | Testkartet lages i kode (`DemoRoomService`) | Kommer med i git, så begge får det. `.rbxl` sjekkes ikke inn |
| 2026-10-26 | `NoiseEvent` sender bare type og stance. Serveren bestemmer nivå og posisjon | Klienten skal ikke kunne velge hvor eller hvor høyt den lager lyd |
| 2026-10-26 | Serveren bruker farten den selv ser som minste stance | Hindrer at noen påstår at de kryper mens de løper |
| 2026-10-26 | Taster: C = krype av/på, hold venstre Shift = sprint | Enkle å teste. Kan byttes senere (f.eks. til Input Action System) |
| 2026-10-26 | Støyverdier: krype 0, gå 30, sprint 80 (fart 8/16/26) ligger i `Config.STANCES` | Én plass å justere balansen |
| 2026-10-26 | Spillet er «Echoes of the Backstage» (co-op lydhorror) | Se `docs/GAME_DESIGN.md` |
| 2026-10-26 | Rojo + GitHub, egne moduler per system | Slik at begge Claude-ene ser hele prosjektet |

## Åpne spørsmål (må sjekkes i Roblox-dokumentasjonen, ikke antas)
- **Mikrofonstøy:** Kan spillet måle volumet på spillernes mikrofon, og hva kreves av spilleren (stemmechat er begrenset til verifiserte brukere)? Hva gjør vi for spillere uten stemmechat?
- **HRTF / 3D-lyd:** Hva støtter Roblox faktisk av romlig lyd, og kan vi kreve noe bestemt?
- **Mimicry:** Å spille av spillernes egne stemmer er trolig ikke mulig eller tillatt. Alternativ: ferdiglagde forvrengte lyder.
- **Usynlig fiende:** Hvordan lar vi serveren styre fienden (pathfinding) ut fra lyd, uten at klienten kan juksemake?

## Slik jobber vi (rutine)
**Start av økt:** `git pull`, les `PROJECT.md` og `ARCHITECTURE.md`.
**Slutt av økt:** be Claude oppdatere `PROJECT.md` (status + beslutninger) og `ARCHITECTURE.md` (nye moduler/remotes), så `git commit` og `git push`.

**Git-tips:**
- Hver jobber på sin egen branch (`navn/feature`), merge til `main` når det virker.
- Små commits, ofte. Pull før du starter.
- Roblox-filer (`.rbxl`) sjekkes ikke inn, bare koden i `src/`.
