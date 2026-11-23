# Story 2.7 : Lire son état dans le HUD

Status: review

## Story

En tant que joueur,
je veux voir mes cœurs, mon armure et mes emplacements d'objet d'un coup d'œil,
afin de ne jamais quitter le combat des yeux.

Exigences : FR33, AR22 (epics.md, Story 2.7). GDD : cœurs de départ 3 (6 demi-cœurs), plafond 12 cœurs armure comprise, armure = demi-cœurs bleus perdus en premier (gdd.md, « Santé et armure »). Architecture : HUD dans `UI` (CanvasLayer de `Main`), `ui/hud/`, lit l'état par signaux, ne modifie jamais le gameplay (l. 696) ; couches AR19 : HUD au-dessus du combat.

## Critères d'acceptation

1. **Bande** : le HUD occupe la bande de 24 px (`Const.HUD_BAND_HEIGHT`) en haut de l'écran, sur toute la largeur, hors de la zone jouable (la salle commence à y = 24).
2. **Contenu** : cœurs (pleins, demis, vides selon les PV max), armure en demi-cœurs bleus à la suite des cœurs, Éclats à 0, emplacements vides de l'objet actif et du consommable, et une place réservée à la jauge de lucidité (rien dedans, la jauge est celle de la 3.1).
3. **Mise à jour par signaux** : un coup reçu, une armure ajoutée, un soin, un redémarrage de partie mettent le HUD à jour sans que le HUD lise ni modifie le jeu autrement que par signaux.
4. **Lisibilité d'un coup** (report de 2.1) : un coup reçu fait flasher la rangée de cœurs (blanc bref) ; les cœurs perdus sont visibles immédiatement.
5. **Panneau F1** (report de 2.1) : il ne recouvre plus la bande de HUD (il commence sous la bande).
6. Textes par `tr()` et `strings.csv` ; thème et police pixel de 1.6 ; aucun état de jeu écrit par le HUD.

## Tâches

- [x] `Events.player_health_changed(half_hearts, max_half_hearts, armor)` (primitives), émis par `Player` sur `Health.changed` et une fois à la mise en place (état initial d'une nouvelle partie).
- [x] `ui/hud/hud.tscn` + `hud.gd` : fond de bande, `HeartRow`, `LucidityGaugeSlot`, Éclats (icône + nombre), deux `HudSlot` vides. Écoute `Events.player_health_changed` et `Events.player_hit`.
- [x] `ui/hud/heart_row.gd` : dessin en code (masque de pixels 8x7), `set_state()`, `flash()`.
- [x] `Main` instancie le HUD dans `UI`, avant les surcouches de debug et les menus (ils restent au-dessus).
- [x] Panneau F1 : `offset_top` sous la bande. Commentaires de `Const` mis à jour.
- [x] Clé `UI_HUD_SHARDS` dans `strings.csv`.
- [x] Vérifications headless (`.scratch/t_hud.gd`, ajoutée à `run_all.sh`), lancement `--quit-after 120` propre, capture WSLg.

## État du code concerné

- `Health` (`combat/health.gd`) : `half_hearts`, `max_half_hearts`, `armor` ; signal local `changed` (après chaque coup, soin, armure) puis `died`.
- `Player._on_hurtbox_damage_received` émet `Events.player_hit(lost, source)` après `apply_damage` ; `Run` émet `run_ended`.
- `Main` : `UI` (CanvasLayer) contient `PerfOverlay`, le panneau F1 (debug) puis les menus. `Run` est recréé à chaque relance : le HUD, enfant de `Main`, survit et se resynchronise par le signal initial du nouveau `Player`.
- La caméra de l'arène est déjà décalée pour laisser la bande libre ; rien à changer côté salle.
- Pas d'Éclats, d'objet ni de consommable dans le code (epic 5) : le HUD les affiche statiquement (0 et vides).

## Pièges

- `Player._ready` s'exécute avant le HUD si celui-ci était ajouté après `_start_run()` : le HUD est donc ajouté **avant** `_start_run()` dans `Main._ready`.
- `Health.changed` est émis avant `died` : le HUD voit 0 PV avant l'écran de réveil, c'est voulu.
- Le flash utilise `delta` réel (`_process`) : le HUD n'est pas gelé par `Main._freeze` (il est hors de `ActiveScene`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Nouveau signal global `Events.player_health_changed`** plutôt que le HUD qui s'accroche au `Health` du joueur — Raison : le `Run` (donc le joueur) est recréé à chaque partie, le HUD vit dans `Main` ; un signal sur le bus évite tout chemin de nœud (règle : `ui/` lit par signaux).
2. **Icônes dessinées en code** (masque de pixels, couleurs provisoires dans `ui/hud/`) — Raison : pas d'art avant l'epic 7 (7.2 fixera la palette).
3. **Armure** : 1 point = un demi-cœur bleu, deux points = un cœur bleu plein, affichés après les cœurs sur la même rangée ; au plus 12 icônes (plafond GDD).
4. **Éclats** : « 0 » statique avec `tr(&"UI_HUD_SHARDS")` (valeur `%d`), sans signal (la monnaie arrive avec l'epic 5). Emplacements d'objet actif et de consommable : cadres vides, sans touche affichée (les touches arrivent avec l'epic 5).
5. **Place de la jauge de lucidité** : un cadre discret de 160x8 px au centre de la bande, sans contenu ni signal ; la 3.1 la remplira.
6. **Lisibilité d'un coup** : flash blanc de 0,25 s de la rangée de cœurs, rien d'autre (pas d'écran rouge) — Raison : suffisant pour la lecture ; le jugement en plein combat reste **NON ÉVALUÉ** (étape humaine).
7. **Réticule** : reste enfant du joueur (z 100) ; le `CanvasLayer` du HUD passe déjà au-dessus. Pas de déplacement dans le HUD (commentaire de `Const` corrigé).
8. **Panneau F1** déplacé sous la bande (`offset_top` 28) plutôt que de réduire le HUD.
9. **HUD non masqué pendant le test de charge F5** (la scène de test remplace le `Run`, l'état affiché reste le dernier connu) — outil de debug, sans enjeu.

## Vérifications prévues (`.scratch/t_hud.gd`, sur `main.tscn`)

- Le HUD existe dans `UI`, rectangle de la bande = (0, 0, 640, 24), tous ses éléments dans la bande.
- État initial : 6 PV max, 6 PV → 3 cœurs pleins, 0 armure, Éclats « 0 », 2 emplacements vides, place de lucidité présente.
- Après un coup (invulnérabilité F1 coupée) : cœurs mis à jour, flash actif puis éteint ; armure +1 : une icône bleue demie ; soin ; mort puis relance : HUD resynchronisé (6/6).
- Le HUD ne change aucun état : `Health` identique avant/après la lecture, aucune écriture dans le jeu (revue de code).
- F1 : le panneau commence à y >= 24.

## Fichiers prévus

`game/ui/hud/{hud.gd,hud.tscn,heart_row.gd,hud_slot.gd}`, `game/autoloads/events.gd`, `game/player/player.gd`, `game/main/main.gd`, `game/debug/debug_panel.tscn`, `game/core/constants.gd`, `game/localization/strings.csv`, `game/.scratch/t_hud.*` (non versionné).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `Events.player_health_changed` émis par `Player` (sur `Health.changed` et à l'état initial) ; `Hud` (`ui/hud/`) dans la couche `UI` de `Main`, ajouté en premier (sous les surcouches). Cœurs et armure dessinés en code (`HeartRow`), cadres vides (`HudSlot`) pour la lucidité et les deux emplacements, Éclats « 0 » via `tr(&"UI_HUD_SHARDS")`.
- Un coup fait flasher la rangée 0,25 s (`Events.player_hit`). Panneau F1 descendu sous la bande (`offset_top` 28).
- Vérifié : `.scratch/t_hud.gd` 20 ok (bande 640x24, éléments dans la bande, état initial, coup, armure, soin, mort puis relance, F1 sous la bande, un seul HUD) ; `run_all.sh` en mode normal : ALL PASS, 723 ok, FAILS=0 ; capture WSLg : bande lisible (cœurs, demi-cœur bleu, jauge vide au centre, Éclats, deux cadres).
- **NON ÉVALUÉ** (humain) : lisibilité d'un coup en plein combat (flash de 0,25 s), taille des cœurs (8x7 px) à l'échelle réelle.
- Aucun écart aux décisions ci-dessus.

### File List

- `game/ui/hud/hud.gd`, `hud.tscn`, `heart_row.gd`, `hud_slot.gd` (+ `.uid`) (NEW)
- `game/autoloads/events.gd`, `game/player/player.gd`, `game/main/main.gd`, `game/debug/debug_panel.tscn`, `game/core/constants.gd`, `game/localization/strings.csv` (UPDATE)
- ce fichier, `sprint-status.yaml`, `deferred-work.md` (UPDATE)
