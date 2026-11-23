# Story 2.7 : Lire son état dans le HUD

Status: done

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

### Review Findings

Revue de code du 2026-11-23 (`gds-code-review`, mode complet, trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor ; diff `2a219f4..c0caae6 -- game/ _bmad-output/game-architecture.md`). Les CA 1 à 6 sont respectés (Acceptance Auditor). Points demandés, vérifiés sans défaut : resynchronisation à la relance (HUD connecté une fois dans `Main`, chaque nouveau `Player` émet son état initial, ajout du HUD avant `_start_run()`, l'ancien `Run` retiré avant l'ajout du nouveau : aucune image avec un état périmé, signal en primitives donc sans référence à un joueur libéré, pas de fuite) ; ordre d'émission d'un coup mortel `Health.changed` → `player_health_changed(0, …)` → `died` → `player_hit` (flash) → `run_ended` (cœurs justes à chaque étape ; soin au max, dégât 0 ou coup refusé : aucune émission) ; HUD en lecture seule (aucune écriture d'état, `MOUSE_FILTER_IGNORE` partout) ; mise en page à 6 + 18 d'armure (12 icônes) : cœurs x 6..113, jauge 240..400, Éclats 524..585, emplacements 594..634, tout dans y 0..23 ; clé `UI_HUD_SHARDS` présente pour la seule langue (fr) ; panneau F1 à y 28..329 sur 360. Le ralenti passe par `GameClock`, pas `Engine.time_scale` : le flash garde sa durée. Contrôles de `game/.scratch` non audités (pipeline allégé). 6 patchs, 0 décision (2 tranchées, voir décisions 10 et 11), 1 report, 13 rejetés.

- [x] [Review][Patch] **Réticule invisible dans la bande de HUD** [game/player/reticle.gd:56-63, :7] — Souris au-dessus de y = 24 (ou visée au stick près du mur du haut) : la bande opaque recouvre le réticule et le curseur système est masqué, le joueur perd son viseur (régression de 2.7). Correctif (décision 10) : dans `_process`, entre le calcul de `target` et `global_position = target.floor()`, ajouter `var canvas: Transform2D = get_viewport().get_canvas_transform()` / `var screen: Vector2 = canvas * target` / `screen.y = maxf(screen.y, Const.HUD_BAND_HEIGHT + CENTER_GAP + BRANCH_LENGTH) # the whole reticle stays below the HUD band (display only: aim is unchanged)` / `target = canvas.affine_inverse() * screen`. Ligne 7 : remplacer « moves to the HUD layer with story 2.7 » par « stays in the world, drawn below the HUD band (story 2.7) ». Mettre à jour le commentaire de `Z_INDEX_ENEMY_BULLETS` (game/core/constants.gd:58) : « …the HUD canvas layer draws above it, so the reticle keeps out of the band ».
- [x] [Review][Patch] **La surcouche F3 cache la rangée de cœurs** [game/debug/perf_overlay.tscn:17, :19] — Le `Label` couvre x 4..300, y 2..40 et se dessine au-dessus du HUD (`move_child(hud, 0)`) : cœurs entièrement masqués et 60 px de la place de lucidité. Correctif (décision 11) : `offset_top = 28.0`, `offset_bottom = 66.0`.
- [x] [Review][Patch] **Rangée de cœurs sur un demi-pixel** [game/ui/hud/hud.gd:30] — `(24 - 7) / 2.0` = 8.5 : les `draw_rect` 1x1 du masque tombent sur des bords de pixel (rendu dépendant du rastériseur, AR22) ; les autres éléments sont sur des entiers. Correctif : ligne précédente `@warning_ignore("integer_division")` puis `_hearts.position = Vector2(MARGIN, (Const.HUD_BAND_HEIGHT - HeartRow.ICON_SIZE.y) / 2)` (y = 8).
- [x] [Review][Patch] **Une traduction absente rend le HUD sourd** [game/ui/hud/hud.gd:50-53] — Si `UI_HUD_SHARDS` manque à la traduction chargée (`.translation` régénéré, nouvelle langue), `tr()` rend la clé et `"UI_HUD_SHARDS" % 0` est une erreur d'exécution qui interrompt `_ready()` avant les deux `connect()` : cœurs vides toute la session. Correctif : déplacer `Events.player_health_changed.connect(...)` et `Events.player_hit.connect(...)` juste après `add_child(_hearts)` (ligne 31), avant la construction des emplacements et du libellé.
- [x] [Review][Patch] **`shards` public sans mise à jour du libellé** [game/ui/hud/hud.gd:15, :91] — Écrire `hud.shards = n` laisse « 0 » affiché et contourne la règle « le HUD lit par signaux ». Correctif : `var _shards: int = 0 # static 0 until epic 5 (decision 4), then set from an Events signal` et ligne 91 `% _shards` (aucun autre lecteur dans `game/` hors `.scratch` ; `t_hud` lit `shards_text()`).
- [x] [Review][Patch] **HUD typé `Node` dans `Main`** [game/main/main.gd:35] — Typage statique partout (architecture), comme `_wake_screen` / `_pause_menu`. Correctif : `var hud: Hud = HUD_SCENE.instantiate() as Hud`.
- [x] [Review][Defer] **Plus de 12 icônes possibles : armure ou cœurs tronqués en silence ; dernier réceptacle impair dessiné comme un cœur entamé** [game/ui/hud/heart_row.gd:46-58] — deferred, latent (PV max toujours pairs et plafond 24 aujourd'hui) ; à régler par la story 5.1 (Dent qui tombe, −1 cœur max).

Correctifs appliqués le 2026-11-23 : les 6 patchs sont faits et vérifiés (`run_all.sh` en mode normal : ALL PASS, 728 contrôles ; `--quit-after 120` sans erreur ; contrôles ajoutés à `t_hud` pour le réticule sous la bande, souris et stick, et la surcouche F3).

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
10. **(Revue) Réticule caché sous la bande de HUD** : la bande opaque (couche `UI`) recouvre le réticule (monde, z 100) dès que la souris ou la visée au stick passe au-dessus de y = 24 ; le curseur système étant masqué, le joueur n'a plus de viseur. Choix : **borner l'affichage du réticule sous la bande** (espace écran), plutôt qu'une `CanvasLayer` dédiée ou un curseur système dans la bande — Raison : affichage seul (la visée reste celle de la souris), une ligne, facile à défaire ; corrige la décision 7 sur ce point.
11. **(Revue) Surcouche F3 sous la bande, comme le panneau F1** : le CA 5 ne nomme que F1, mais le report de 2.1 visait les surcouches de debug qui couvrent la bande ; F3 (présent dans toutes les versions) cache la rangée de cœurs — Raison : même intention, coût nul.

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
