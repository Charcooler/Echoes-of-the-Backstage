# PROJECT.md — delt hukommelse for prosjektet

> Begge Claude-ene leser denne filen i starten av hver økt og oppdaterer den på slutten.
> Hold den kort og oppdatert. Skriv beslutninger her, ikke bare i chatten.

## Spillet
- **Navn:** TODO
- **Én setning:** TODO (hva gjør spilleren?)
- **Sjanger / stil:** TODO
- **Språk i spilltekst:** TODO (engelsk / norsk)
- **Mål for første spillbare versjon:** TODO

## Folk og eierskap
| Person | Eier (systemer/mapper) | Claude-økter |
|--------|------------------------|--------------|
| Meg    | TODO                   |              |
| Kompis | TODO                   |              |

Regel: man endrer bare andres systemer etter å ha snakket sammen. Delte filer (`Config`, `Remotes`, denne filen) endres i små, raske commits.

## Status
### Ferdig
- Prosjektstruktur med Rojo (server / client / shared)

### Pågår
- (ingenting ennå)

### Neste
- [ ] Bestemme spillidé og fylle ut seksjonen over
- [ ] Første system (f.eks. spillerdata, første mekanikk)

## Beslutninger (nyeste øverst)
| Dato | Beslutning | Hvorfor |
|------|-----------|---------|
| 2026-10-26 | Rojo + GitHub, egne moduler per system | Slik at begge Claude-ene ser hele prosjektet |

## Åpne spørsmål
- (ingen)

## Slik jobber vi (rutine)
**Start av økt:** `git pull`, les `PROJECT.md` og `ARCHITECTURE.md`.
**Slutt av økt:** be Claude oppdatere `PROJECT.md` (status + beslutninger) og `ARCHITECTURE.md` (nye moduler/remotes), så `git commit` og `git push`.

**Git-tips:**
- Hver jobber på sin egen branch (`navn/feature`), merge til `main` når det virker.
- Små commits, ofte. Pull før du starter.
- Roblox-filer (`.rbxl`) sjekkes ikke inn, bare koden i `src/`.
