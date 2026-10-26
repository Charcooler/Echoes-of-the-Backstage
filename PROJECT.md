# PROJECT.md — delt hukommelse for prosjektet

> Begge Claude-ene leser denne filen i starten av hver økt og oppdaterer den på slutten.
> Hold den kort og oppdatert. Skriv beslutninger her, ikke bare i chatten.

## Spillet
- **Navn:** Echoes of the Backstage
- **Én setning:** Du kan ikke se monsteret, bare høre det. Lag minst mulig lyd mens dere reparerer operahusets strømnett og rømmer.
- **Sjanger / stil:** Taktisk co-op lydhorror, 1–4 spillere, 1920-talls operahus i nesten full mørke
- **Full design:** se `docs/GAME_DESIGN.md`
- **Språk i spilltekst:** TODO (engelsk / norsk)
- **Mål for første spillbare versjon:** TODO. Forslag (ikke bestemt): ett rom, én usynlig fiende med Patrol og Hunt, støy fra gåing/sprint, og ett mål å gjøre.

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

### Pågår
- (ingenting ennå)

### Neste
- [ ] Bestemme språk i spilltekst og mål for første spillbare versjon
- [ ] Fordele eierskap av systemene (se `ARCHITECTURE.md`, planlagte systemer)
- [ ] Avklare de tekniske spørsmålene under (mikrofon, lyd, Mimicry) før vi bygger på dem
- [ ] Koble `NoiseService` til `EntityService` (signal i stedet for bare print) når fienden bygges
- [ ] Vurdere om fottrinn bør regnes ut helt på serveren. I dag kan en juksende klient la være å sende `NoiseEvent` og dermed være stille.

## Beslutninger (nyeste øverst)
| Dato | Beslutning | Hvorfor |
|------|-----------|---------|
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
