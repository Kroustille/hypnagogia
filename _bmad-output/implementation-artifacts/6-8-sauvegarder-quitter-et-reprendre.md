# Story 6.8 : Sauvegarder, quitter et reprendre

Status: in-progress

## Story

En tant que joueur,
je veux quitter en pleine run et reprendre au début de la salle,
afin de ne pas perdre une nuit entamée.

Exigences : FR64, AR18 (`run.json`), P3 (epics.md, Story 6.8). Architecture : P3 « Reprise en début de salle » (`RunSnapshot`, `SaveService.write_run`), D12 (`run.json` écrit à l'entrée de chaque salle, effacé à la reprise et en fin de run), règle « tout état qui survit à une salle implémente `to_dict()` / `from_dict()` ; les objets sont référencés par leur `id` ». GDD : reprise au début de la salle en cours, sauvegarde effacée dès la reprise ; en cas de crash, début de la dernière salle entrée.

**Dépend de : 6.7** (`SaveService.write_json/read_json`, quarantaine, `Notice`, `RunOptions.unlocks`), **6.6** (`wake_minute`), 6.5 (`Main` démarre dans la chambre : l'invite de reprise passe avant), 6.4 (fin de run : effacement), 4.7 (`RunRng`, déterminisme), 5.x (objets, consommable, actif, stocks de salle).

Hors périmètre : sauvegarde en cours de salle (jamais), plusieurs emplacements, sauvegarde dans le nuage.

## Critères d'acceptation

1. **Instantané à l'entrée de salle** : à chaque entrée dans une salle de l'étage (départ compris), **avant** les tirages de la salle (trésor, boutique) et avant l'apparition des ennemis, `Run` construit un `RunSnapshot` : version, seed (40 bits) et `seeded`, `unlocks`, étage, cellule d'entrée et côté d'entrée, carte (cellules visitées et vidées), heure du réveil, état du joueur (demi-cœurs, max, armure, perte de maximum pour les objets, lucidité), Éclats, objets (ids dans l'ordre, `max_half_hearts_paid`, charge de l'actif), consommable, **stocks des salles visitées** (offres : type, id, position, prix, prise, armée, quantité, charge — les décisions de 5.x en dépendent), **états de tous les flux RNG** créés jusque-là. `SaveService.write_run(snapshot)` l'écrit dans `user://run.json` de façon atomique. Aucun instantané hors mode `FLOOR` (arène, salle de débogage).
2. **Référence par `id`** : aucun objet, ennemi ou nœud n'est sérialisé ; `to_dict()` / `from_dict()` existent sur chaque morceau d'état (`RunSnapshot`, `RunState`, `FloorMap`, `RoomStock`, `Health` pour son état, `RunRng` pour ses flux). Les ids inconnus à la relecture (objet retiré d'une version) sont ignorés avec un `Log.warn`, la reprise se fait quand même.
3. **« Sauvegarder et quitter »** : en run (mode `FLOOR`), le bouton du menu pause porte ce nom (`UI_PAUSE_SAVE_QUIT`) et ferme le jeu, `run.json` conservé (c'est l'instantané de la dernière entrée de salle, à jour). Hors run (chambre, arène, débogage) le bouton reste « Quitter » (`UI_PAUSE_QUIT`) et ne laisse rien. Un arrêt brutal (crash, fermeture forcée) laisse le dernier instantané : même reprise.
4. **Invite de reprise au lancement** : si `run.json` existe, `Main` lit et valide le fichier **avant** la chambre : lisible → fenêtre « Reprendre la nuit ? » (`Reprendre` focalisé / `Nouvelle nuit`) ; **Reprendre** reconstruit la run, **efface `run.json`** et rejoue la salle depuis son début ; **Nouvelle nuit** efface `run.json` et ouvre la chambre. Illisible (JSON invalide, version future, seed hors bornes, cellule hors du plan) : renommé `run.json.corrupt`, `Notice` localisée, chambre.
5. **Reprise à l'identique** : la run reconstruite a le même plan d'étage (même seed, mêmes `unlocks` : `to_text()` égal), la même carte, le même joueur, les mêmes flux RNG ; la salle repart de son début avec les mêmes ennemis (mêmes vagues, mêmes marqueurs), les mêmes renforts/reflets et les mêmes tirages de trésor/boutique/butin que lors de la première entrée. L'entrée se fait par le même côté, au même point.
6. **Fin de run** : une mort ou une victoire efface `run.json` (dans `Run`, avant `run_ended`) ; une nouvelle run (relance, seed saisie, chambre) efface aussi un `run.json` d'une nuit abandonnée avant d'écrire le sien.
7. **Test d'intégration de reprise** : sauvegarde à l'entrée d'une salle, puis reprise : l'état du joueur et **les états des flux RNG sont identiques** (comparés champ par champ et après un aller-retour JSON). Le même test vérifie les 64 bits : un état de flux au-delà de 2^53 survit.
8. **Échec d'écriture** : l'écriture de `run.json` qui échoue est journalisée (`Log.error`), la run continue ; aucune interruption du jeu (architecture, gestion des erreurs).

## Tâches

- [x] `run/run_snapshot.gd` (`RefCounted`, `to_dict()`, `static from_dict()`, `validate() -> String`, `schema_version`) ; `SaveService.write_run/read_run/delete_run/has_run` (s'appuie sur `write_json/read_json` de 6.7), `run.json.corrupt` ; migration par version (table vide).
- [x] `core/run_rng.gd` : `export_states() -> Dictionary` (clé `"nom:étage"` → état en **chaîne décimale**) et `restore_states(d)` ; `run/run_state.gd`, `run/floor_map.gd`, `economy/room_stock.gd` : `to_dict/from_dict` (cellules en `[x, y]`).
- [x] `combat/health.gd` : `export_state()` / `restore_state(d)` (demi-cœurs, max, armure, maximum perdu) ; `player/lucidity.gd` : `set_value()` existe, y ajouter la restauration du tier de salle (`begin_room()` se charge du reste).
- [x] `run/run.gd` : `_write_snapshot(cell, entry_side)` appelée en tête de `_enter_cell` (avant `stock_of`/`_stock_treasure`/`_stock_shop`/`mark_entered`) ; `_start_floor_from(snapshot)` (voir État du code) ; effacement aux deux fins de run ; `RunOptions.resume: RunSnapshot`.
- [x] `main/main.gd` : `_boot()` (invite → reprise ou chambre), `_on_pause_menu_quit_requested()`, effacement dans `_start_run()` pour toute run **non reprise**. `ui/menus/resume_prompt.tscn/.gd` ; `pause_menu` : libellé selon `Main` (`open(seed, focus, in_run)`).
- [x] `strings.csv` : `UI_PAUSE_SAVE_QUIT`, `UI_RESUME_TITLE`, `UI_RESUME_YES`, `UI_RESUME_NO`, `UI_RESUME_CORRUPT`.
- [x] Tests.

## État du code concerné

- `Run._start_floor()` : `ensure_floor()` → `floor_map.layout` → `RoomLoader` (départ immédiat, autres en arrière-plan) → `_enter_cell(layout.start, -1)`. `_enter_cell` : charge la scène, construit `RoomOptions`, **`stock_of(cell)` tire le stock** (trésor/boutique par `_stock_treasure`/`_stock_shop` sur les flux `treasure`/`shop`), `room.setup`, place le joueur, `mark_entered`. `_swap_room` (sous le noir d'une transition) appelle `_enter_cell` puis `_announce_room` ; l'écriture du fichier s'y fait donc sous le fondu (léger, quelques ko).
- `Run.rng` (`RunRng`) : flux créés **paresseusement** par `stream(nom, étage)` (`_streams` : clé `"nom:étage"`). Un flux jamais créé n'a pas d'état à sauver : il repart de `(seed, nom, étage)`, donc identique.
- Le plan dépend de la seed et du pool filtré par `unlocks` seulement (`ensure_floor`, flux `layout`/`rooms`) ; **il consomme ces flux** : à la reprise, générer d'abord, **puis** `restore_states` (les états sauvés sont postérieurs à la génération).
- `Player._on_item_added` (`player.gd:714`) applique le **coût en maximum** d'un objet (`health.lose_max`, `OwnedItem.max_half_hearts_paid`) quand on l'ajoute au `Loadout` : rejouer les objets **réapplique** ces coûts. Restaurer la santé **après** les objets avec `Health.restore_state` (qui écrase maximum, demi-cœurs, armure, maximum perdu), et réécrire `max_half_hearts_paid` par objet.
- Objets : `ItemCatalog.by_id`, `ConsumableCatalog.by_id`, `BuildCarrier.acquire(def, charge)` (émet `item_acquired` + bannière : à éviter ; utiliser `Loadout.add(def, charge)` / `set_active(def, charge)` / `set_consumable(def)` qui ne les émettent pas). Les états de pouvoir en cours (café, recharges, ralentis) **ne sont pas** sauvés : une salle rejouée repart propre.
- `RoomStock.Offer` : `kind`, `item`/`consumable`, `position`, `taken`, `price`, `armed`, `amount`, `charge` ; `Run.stocks` est indexé par cellule seule (un seul étage au MVP).
- `Main._on_pause_menu_quit_requested()` appelle `_release_for_quit()` puis `get_tree().quit()` ; la fermeture de fenêtre (`NOTIFICATION_WM_CLOSE_REQUEST`) ne touche pas aux fichiers.
- `Telemetry` ignore les sauvegardes.

## Pièges

- **Précision JSON** : `RandomNumberGenerator.state` est un entier 64 bits ; `JSON.stringify` l'écrit comme un nombre flottant et perd les bits au-delà de 2^53 : **stocker les états en chaînes décimales** (`str(state)` / `String.to_int()`), jamais en `int` JSON. Même précaution pour tout entier susceptible d'être grand (la seed de 40 bits passe, mais l'écrire en chaîne aussi).
- Ordre de reprise : générer le plan → `restore_states` → restaurer carte, stocks, joueur → `_enter_cell`. Restaurer avant de générer fausse les flux `layout`/`rooms` et change le plan.
- L'instantané est construit **avant** `stock_of()` : sinon l'état du flux trésor/boutique et l'absence de stock ne correspondent plus (la salle ne retirerait pas la même offre). Pour une salle déjà visitée, le stock existe et est sauvé tel quel.
- Un `Dictionary[Vector2i, ...]` typé se sérialise cellule par cellule (`[x, y]`) ; à la lecture, valider `Array` de 2 entiers, rejeter le reste (fichier modifié à la main).
- `Health.restore_state` n'émet pas `died` ; il émet `changed` pour que le HUD se mette à jour (`Events.player_health_changed`). Ordre : joueur prêt (`Run._ready` après ses enfants), HUD déjà branché.
- La reprise passe par `run_started` (HUD, télémétrie, carte) : ne pas la court-circuiter ; `run_seeded` porte la seed d'origine, `seeded` conservé.
- Un `run.json` pointant une cellule qui n'est pas dans le plan régénéré (pool changé entre deux versions) : `validate()` le détecte (`failure`), quarantaine, pas de crash.
- Pause menu : « Sauvegarder et quitter » ne **réécrit** rien (l'instantané d'entrée est déjà le bon, c'est le sens du GDD : reprise au début de la salle). Écrire de nouveau l'état au moment de quitter serait une triche (sauvegarder en pleine salle).
- Les tests ne doivent jamais toucher le vrai `user://` : `SaveService.set_directory()` (6.7).

## Tests (GUT)

- `unit/run/test_run_snapshot` : aller-retour `to_dict` → JSON texte → `from_dict` égal ; `validate()` refuse seed invalide, cellule hors plan, version future ; id d'objet inconnu ignoré ; états RNG au-delà de 2^53 conservés ; `RunRng.restore_states` reprend la même séquence qu'un flux non interrompu.
- `unit/save/test_run_file` : `write_run`/`read_run`/`delete_run`/`has_run`, quarantaine `run.json.corrupt`, écriture atomique.
- `integration/run/test_resume` : plan réel, quelques salles traversées avec objets, consommable, actif chargé à moitié, cœurs perdus, Dent (coût en maximum), armure, Éclats ; instantané à l'entrée d'une salle ; **nouvelle `Run` reprise** : joueur, carte, stocks, plan (`to_text()`) et états RNG égaux ; mêmes types d'ennemis et mêmes positions de vague ; le tirage du Miroir de la salle est identique à la première entrée ; `run.json` effacé après la reprise puis réécrit à l'entrée.
- `integration/run/test_save_quit` : `run.json` existe après le départ ; effacé à la mort et à la victoire ; effacé par une nouvelle run ; absent en mode arène.
- `integration/ui/test_resume_prompt` : invite si le fichier existe, `Nouvelle nuit` l'efface, fichier cassé : `Notice` et chambre ; libellé « Sauvegarder et quitter » en run, « Quitter » dans la chambre.

## Sources

epics.md (Story 6.8) ; GDD, Quitter en pleine run (limite acceptée : save-scum) ; architecture P3, D12, « Persistance des données » ; deferred-work : stocks de salle à la reprise, `Run.stocks`/carte au changement d'étage (non traités, voir décision 6), seed dans `run started`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Les stocks des salles visitées sont sérialisés** (ligne ajoutée à l'architecture D12 : `run.json` contient les `RoomStock`). Sans eux, un objet laissé au sol ou une boutique à moitié achetée reviendraient différents (deferred « Stocks des salles à la reprise »).
2. **Instantané pris en tête de `_enter_cell`**, avant tout tirage de la salle, pour que la salle rejouée refasse les mêmes tirages.
3. **« Sauvegarder et quitter » ne réécrit rien** et ne diffère de « Quitter » que par le libellé et l'intention (le dernier instantané suffit, comme après un crash).
4. **Invite de reprise avant la chambre** ; refuser efface la sauvegarde (la GDD ne propose qu'une nuit en cours).
5. **Les états de pouvoir en cours (café, ralentis, minuteries) ne sont pas sauvés** : une salle rejouée repart de zéro.
6. **`Run.stocks` et la carte restent indexés par cellule seule** (pas d'étage dans l'index) : le MVP n'a qu'un étage ; `floor_index` est sauvé pour que l'acte 1 fasse évoluer le format par migration. Voir deferred-work.
7. **États RNG, seed et grands entiers en chaînes décimales** dans le JSON.
8. **Une run seedée se sauvegarde et se reprend comme une autre** (`seeded` conservé : elle n'écrira toujours rien dans le profil).
9. **Un `run.json` d'une version de format plus récente est quarantainé**, jamais lu à moitié.

### Review Findings

Lignes de `d7d8b04`.

- [ ] [Review][Patch] HUD vide après une reprise : `_restore_from` (dans `_start_floor`) remplit les cases actif et consommable avant `run_started`, que `Hud._on_events_run_started` vide ; l'actif reste utilisable mais sans icône ni barre de charge jusqu'au prochain événement [game/run/run.gd:225-228 ; game/ui/hud/hud.gd:196] — à la fin de `_announce_restored_items()` : `var active: OwnedItem = loadout.active`, `if active != null: Events.active_item_changed.emit(active.def.id, active.charge, active.charge_max)` ; `if loadout.consumable != null: Events.consumable_changed.emit(loadout.consumable.id, loadout.consumable.name_key)` ; test : écouter ces deux signaux après `start_resume`.
- [ ] [Review][Patch] Une nuit seedée reprise enregistre le succès `synergy_three` (AR29) : `loadout.add()` pendant `_restore_from` déclenche `synergy_activated` avant `run_seeded` ; `Achievements._seeded` vaut encore `false` (et `_seed_code` `""`) ⇒ `_obtain()` écrit `profile.json` [game/progression/achievements.gd:70 ; game/run/run.gd:203-211] — dans `_on_synergy_activated` : `if _seed_code.is_empty(): return` (aucun `run_seeded` reçu pour cette run : ce sont des synergies rejouées, déjà comptées) ; test : reprise seedée avec `fall_3` atteinte ⇒ pas de succès.
- [ ] [Review][Patch] Bannières et son de synergie rejoués à chaque reprise : `BuildCarrier` neuf (`_announced` vide, `_acquiring` faux) ⇒ `_announce_pending()` pour chaque synergie restaurée [game/items/build_carrier.gd:214-231 ; game/run/run.gd:203-211] — ajouter `BuildCarrier.restore_item(def: ItemDef, charge: int) -> OwnedItem` : `_acquiring = true`, `loadout.set_active(def, charge)` / `loadout.add(def)`, puis `_to_announce.clear()` et `_acquiring = false` (les synergies restent dans `_announced`) ; l'utiliser dans `_restore_from`.
- [ ] [Review][Patch] Télémétrie : une nuit reprise sous un palier autre que Lucide est comptée Lucide : `lucidity.restore_value` émet `lucidity_tier_changed` avant `run_started` (ignoré, `_tier == -1`), puis `run_started` remet `_tier = 0` [game/run/run.gd:218, 225] — dans `_announce_restored_items()` : `if _player.lucidity.live_tier != Lucidity.Tier.LUCID: Events.lucidity_tier_changed.emit(_player.lucidity.live_tier, Lucidity.Tier.LUCID)`.
- [ ] [Review][Patch] `run.json` survit au repli sur l'arène : l'instantané est écrit en tête de `_enter_cell`, avant le chargement de la scène ; si elle ne charge pas, la run passe à l'arène (« Quitter ») mais le fichier reste ⇒ chaque lancement propose de reprendre, repasse à l'arène et réécrit le même fichier (AC 1, AC 3) [game/run/run.gd:504 `_fall_back_to_arena` ; game/run/run.gd:170-188 branches d'échec de `_start_floor`] — `SaveService.delete_run()` dans `_fall_back_to_arena()` et avant chaque `return false` de `_start_floor` (plan invalide, `validate`, `_enter_cell` faux).
- [ ] [Review][Patch] Un changement du pool de salles n'est pas détecté : `FloorGenerator` tire la forme sur le flux `layout` sans le pool, seules les salles (flux `rooms`) changent ; `validate()` ne contrôle que l'existence des cellules ⇒ salles visitées remplacées, offres sauvées posées dans d'autres salles, `cleared` sur des salles jamais jouées (AC 4) [game/run/run_snapshot.gd:34-56, 62-84, 88-131, 137-157] — `var plan: String` = `run.floor_layout.signature().sha256_text()` dans `capture` ; `"plan"` dans `to_dict` ; `from_dict` exige une `String` ; `validate(layout)` : `if layout.signature().sha256_text() != plan: return "the floor of the seed changed"` ; test : modifier `plan` ⇒ quarantaine + `Notice`.
- [ ] [Review][Patch] Quarantaine ratée de `run.json` annoncée comme réussie : `read_run` ignore le retour de `quarantine()` et met `CORRUPT` (même défaut que celui corrigé en 6.7 dans `read_json`) [game/autoloads/save_service.gd:104-105] — `last_read_status = Status.CORRUPT if quarantine(path) else Status.UNREADABLE`.
- [ ] [Review][Patch] `pre_run.gd` n'arrête pas vraiment la suite : `quit(1)` est différé, GUT lance les tests avant et `SaveService` pointe encore `user://` [game/tests/support/pre_run.gd:15-16] — appeler `abort()` (GutHookScript, lu par `gut.gd:763`) avant `quit(1)`.

## Dev Agent Record

### Notes de complétion

Implémenté : `RunSnapshot` (versionné, migrations vides, `validate(layout)`), `SaveService.write_run/read_run/delete_run/has_run`, `to_dict/from_dict` sur `RunState`, `FloorMap`, `RoomStock`, `RunRng.export_states/restore_states` (états en chaînes décimales), `Health.export_state/restore_state`, `Lucidity.restore_value`. `Run` écrit l'instantané en tête de `_enter_cell` (mode `FLOOR` seulement), reprend via `RunOptions.resume` (plan généré, puis flux, carte, stocks, objets, consommable, santé, lucidité), efface `run.json` à la mort et à la victoire. `Main._boot()` lit et valide `run.json` avant la chambre (plan régénéré pour vérifier les cellules), `ResumePrompt` (Reprendre / Nouvelle nuit), « Sauvegarder et quitter » en run flottant.

Vérifié : `tools/run_tests.sh` 829 verts (dont `test_resume` : même plan, même santé/objets/charge/consommable/stocks, mêmes états RNG et mêmes ennemis aux mêmes positions après reprise, tirage trésor identique), `run_all.sh` normal, `--quit-after 120`. NON ÉVALUÉ (humain) : le texte et la lisibilité de l'invite de reprise, le ressenti du retour au début de salle.

Reports traités : stocks de salles sérialisés ; durée et objets d'une run reprise (durée = `RunState.play_seconds`, comptée par `Run._process`, donc hors pause ; objets réémis sur le bus après `run_started`) ; `pre_run.gd` n'ouvre plus `user://` en repli (arrêt de la suite) et `post_run.gd` supprime le dossier temporaire. Correctifs de revue de la 6.7 appliqués dans deux commits à part.

### Décisions prises sans Kroustille (suite)

10. **Cellule `current` de la carte non validée** (c'est (0, 0) avant la première salle) : seule la cellule à rejouer, les visitées, vidées et les stocks sont contrôlées contre le plan.
11. **Le plan est régénéré deux fois** au lancement avec reprise (validation dans `Main`, puis `Run`) : `Run.plan_for` statique, coût de quelques ms, évite de lancer une run sur un fichier invalide.
12. **L'invite s'ouvre sur la chambre gelée** (la chambre est le décor), uniquement quand `Main.start_in_bedroom` ; les checks qui démarrent directement une run effacent `run.json` comme toute nouvelle run.
13. **Durée de la nuit = temps de jeu** (`play_seconds`), plus l'horloge murale : `Achievements` la lit sur la `Run` (repli horloge murale sans run).
14. **Les objets restaurés sont réémis sur `item_acquired`** (télémétrie et succès de ce lancement) sans bannière.
15. **L'échec de `store_string` (6.7) n'a pas de test** : impossible à provoquer sans disque plein.
16. **(revue) Progrès de la salle perdu par « Sauvegarder et quitter »** (ennemis tués, achats, dégâts subis depuis l'entrée) : voulu (GDD, décision 3), le save-scum est une limite acceptée par la GDD. Écarté.
17. **(revue) États d'objets entre salles non sauvés** (café en cours, bonus de Chute libre, Ailes de papier suspendues) : décision 5 confirmée, écarté.
18. **(revue) Quitter pendant le délai de victoire rejoue le boss** : même limite que la décision 15 de la 6.7 (≈ 2 s), acceptée, écarté.
19. **(revue) Changement du pool de salles entre deux versions** : la forme de l'étage ne dépend pas du pool (flux `layout`), seules les salles changent ; `validate()` ne le voit pas. Traité en patch (empreinte du plan), pas en report : peu coûteux et c'est l'intention de l'AC 4.
20. **(revue) Reproduction exacte vérifiée** par un test jetable (3 seeds, sauvegarde à l'entrée de la 2e salle, puis 2 à 3 salles jusqu'au boss avec ennemis tués, comparées après reprise : flux RNG, stocks, Éclats, santé, objets, ennemis et positions) : 0 écart.

### Liste des fichiers

`game/run/{run_snapshot,run,run_state,run_options,floor_map}.gd`, `game/core/run_rng.gd`, `game/economy/room_stock.gd`, `game/combat/health.gd`, `game/player/lucidity.gd`, `game/autoloads/save_service.gd`, `game/progression/achievements.gd`, `game/main/main.gd`, `game/ui/menus/{pause_menu,resume_prompt}.gd/.tscn`, `game/localization/strings.csv`, tests (`unit/run/test_run_snapshot`, `unit/save/test_run_file`, `integration/run/{test_resume,test_save_quit}`, `integration/ui/test_resume_prompt`, `support/{room_harness,pre_run,post_run}`, `.gutconfig.json`).

### Journal des modifications

- 2026-11-24 : instantané de salle, reprise, invite, sauvegarder et quitter ; statut `review`.
- 2026-11-24 : revue de code (3 couches) : 8 patchs, 4 reports ; statut `in-progress`.
