# Story 4.2 : Jouer une salle prédessinée

Status: in-progress

## Story

En tant que joueur,
je veux des salles dessinées à la main, avec leurs obstacles, leurs vagues et des portes qui se ferment,
afin que chaque salle ait sa propre personnalité.

Exigences : FR35, FR36, AR16 (epics.md, Story 4.2). Architecture : D10 (format des salles), D14 (`RoomSlot`), « Salles et génération ».

**Dépend de : 4.1** (framework : tests d'intégration de la salle et du validateur). Les stories 4.3 à 4.11 s'appuient sur les noms et le format posés ici.

Hors périmètre : trous (4.3), meubles et déclencheurs (4.4), pathfinding (4.5), grandes salles et caméra qui suit (4.6), étage (4.7), changement de salle (4.8). Ici une seule salle est jouée à la fois, choisie depuis le panneau F1 ; l'arène du jalon A reste le jeu par défaut.

## Critères d'acceptation

1. **Classe `Room`** (`rooms/room.gd`) : la logique générique d'`Arena` (apparitions, `begin_room()`, danger, renfort, `BulletManager` des deux camps, chiffres de dégâts, effets de lucidité, tremblement, `alive_enemy_count()`, `kill_all_enemies()`) en est extraite. `Arena extends Room` garde ce qui lui est propre (décor construit en code, cibles d'entraînement, `WAVE_LIST`, `waves_enabled` statique) : **les scènes `.scratch` continuent de passer sans réécriture**.
2. **`room_base.tscn`** (racine `Room`) : `TileMapLayer` `Floor`, `Walls`, `LowObstacles`, `HighObstacles`, `Pits` (noms uniques), nœuds `Enemies`, `Camera`, `EnemySpawns`, `ReinforcementSpawns`, `Doors`, `Furnitures`, `Triggers`. Métadonnées exportées par `Room` : `room_type` (START, COMBAT, TREASURE, SHOP, NIGHTMARE), `phase` (`&"onset"`), `size_kind` (SCREEN ; WIDE et TALL arrivent avec la 4.6). Une salle standard mesure 36×19 tuiles jouables dans un cadre de murs, tileset `rooms/tilesets/onset.tres` provisoire (sol, mur, obstacle haut, obstacle bas, trou ; couches physiques `WALLS`, `HIGH_OBSTACLES`, `LOW_OBSTACLES`, sans collision pour le trou).
3. **Marqueurs** : `EnemySpawn` (`Marker2D` : `enemy: EnemyDef`, `wave: int` à partir de 0), `ReinforcementSpawn` (groupe `Const.GROUP_REINFORCEMENT_SPAWN`), `Door` (`rooms/door.gd`, `side` N/E/S/W, position canonique fixe par côté : milieu du côté, 2 tuiles de large). `Furniture` et `Trigger` : classes créées ici, vides et sans effet (la 4.4 les remplit).
4. **Vagues depuis les marqueurs** : à l'entrée, la salle construit une `WaveList` en mémoire depuis ses `EnemySpawn` (vague = valeur de `wave`, ordre des marqueurs = ordre de l'arbre, `spawn_slots` en tuiles) et la donne à `WaveRunner`. `WaveList.loop` (défaut vrai : l'arène ne change pas) : faux pour une salle prédessinée, le runner s'arrête après la dernière vague vidée.
5. **Entrée en salle de combat** : `begin_room()` est appelé une fois à l'entrée (danger figé au palier du moment, renfort réarmé), les portes se ferment, les ennemis paraissent vague par vague. Les vagues suivantes appellent la nouvelle `begin_wave(defs)` (met à jour les ennemis prévus pour le type du renfort, ne remet à zéro ni la lucidité de salle ni le renfort).
6. **Salle vidée** : à la dernière vague vidée, `Events.room_cleared(room, tier)` est émis **une fois** (pas à chaque vague, contrairement à l'arène en boucle), puis les portes s'ouvrent. Une salle sans `EnemySpawn` (départ, trésor, boutique) n'appelle pas `begin_room()` et reste ouverte.
7. **Obstacles** : bas = laissent passer les tirs des deux camps (déjà le cas : seuls `Walls` et `HighObstacles` sont des couches solides du `BulletManager`), hauts = les arrêtent. Test d'intégration des deux cas, joueur et ennemi.
8. **Portes** : une porte fermée remet des tuiles de mur à son emplacement dans `Walls` (donc murs physiques, tirs arrêtés, Glissement bloqué par le rayon sans code en plus) ; ouverte, elle les retire ; scellée (pas de voisin), elle reste mur. Pas de franchissement en 4.2 (la 4.8 ajoute le passage).
9. **Choix depuis F1** : `Events.run_requested(mode, seed_value, seeded, room_path)` (nouveau signal) relance une `Run` ; `RunOptions` (`run/run_options.gd`, `mode` ARENA ou ROOM, `room_path`). F1 « salle suivante du pool » parcourt `rooms/pool/onset/` ; `Run` en mode ROOM instancie cette salle dans `RoomSlot`. Défaut inchangé : ARENA.
10. **`validate_rooms.gd`**, lancé par `tools/validate_rooms.sh` (scène headless qui parcourt `rooms/pool/**` puis `get_tree().quit(code)`) : signale une salle aux dimensions invalides (tuiles jouables ≠ attendu pour sa `size_kind`, ou cellule hors cadre), sans porte, avec un `EnemySpawn` à moins de 3 tuiles d'une porte (même scellée en puissance), sans `ReinforcementSpawn` (sauf type NIGHTMARE, START, TREASURE, SHOP), un `EnemySpawn` sans `enemy`, un ennemi sur un mur, un obstacle ou un trou ; code de sortie non nul si une salle est invalide, une ligne par problème. La logique de contrôle est une classe pure `RoomValidator` testée par GUT sur des salles fautives de `tests/fixtures/rooms/`.
11. **Pool de départ** : `onset_combat_001` (2 vagues, obstacles bas et hauts), `onset_combat_002` (3 vagues, mélange des 4 ennemis), `onset_combat_003` (une vague, pas d'obstacle). Les autres salles du pool arrivent avec 4.3 à 4.7 puis 4.10.
12. **Outil de construction** : `tools/build_room.sh <source.txt>` (scène headless `rooms/validator/room_builder.tscn`) écrit une salle `.tscn` depuis un texte ASCII (`art_source/rooms/<nom>.txt`) : en-tête `type: combat`, `size: screen`, grille de la zone jouable (`.` sol, `#` mur, `H` obstacle haut, `L` obstacle bas, `P` trou) puis lignes `spawn <ennemi> <vague> <x> <y>`, `reinforce <x> <y>`, `door <N|E|S|W>`, `furniture <genre> <x> <y>`, `trigger <genre> <x> <y>`. La `.tscn` générée est la vérité du jeu et reste éditable dans Godot ; le texte sert aux agents.

## Tâches

- [x] Extraire `Room` d'`Arena` (git mv logique, `Arena extends Room`). Remplacer les types `Arena` par `Room` dans `WaveRunner`, `DebugPanel`, `Run`, `Main`. `Const.ROOM_TILES` reste la taille d'un écran ; `Room.playable_tiles()` la dérive de `size_kind` (SCREEN seul pour l'instant) et remplace les usages de `Const.ROOM_TILES` dans `_spawn_bounds`, `player_spawn_position`, `_check_screen_layout`, `_setup_lucidity_fx`.
- [x] `WaveList.loop`, `WaveRunner` : une seule `room_cleared` à la fin d'une liste sans boucle, `begin_room` à la première vague puis `begin_wave`, état terminé (plus aucune apparition). `Room.begin_wave()`.
- [x] `rooms/room_base.tscn`, `rooms/tilesets/onset.tres` (images générées par script comme `_solid_image`), `rooms/door.gd/.tscn`, `rooms/markers/{enemy_spawn,reinforcement_spawn,trigger}.gd`, `rooms/furniture.gd`, `data/tuning/room_tuning.tres` + `RoomTuning` (`Tuning.ROOM` : largeur de porte en tuiles, distance d'entrée du joueur) .
- [x] `RoomInfo` (RefCounted, `generation/room_info.gd` : `id`, `path`, `room_type`, `size_kind`, `doors: Array[int]`) avec `static from_scene(PackedScene)` : instancie, lit, libère (sert au validateur ici, au générateur en 4.7).
- [x] `RunOptions`, `Events.run_requested`, `Main._start_run(options)`, `Run.setup(options)` avant `add_child`. `Run` en ROOM : `setup` de la salle comme pour l'arène (joueur, `rng`).
- [x] `RoomValidator` (pur), `validate_rooms.gd/.tscn`, `tools/validate_rooms.sh`, `tools/build_room.sh`, builder, les trois salles.
- [x] `tests/support/room_harness.gd` : instancie une `Run` en mode ROOM, `await ticks(n)` (priorité physique 200, comme `th.gd`), accès à la salle, au joueur, aux ennemis. `tests/integration/rooms/test_room_waves.gd`, `test_room_doors.gd`, `test_room_obstacles.gd`, `tests/unit/rooms/test_room_validator.gd`.
- [x] `run_all.sh` du `.scratch` une fois à la fin ; `--quit-after 120` propre.

### Review Findings

Revue de code 2026-11-24 (Opus, trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor), sur `21b7a96..acf0b83` hors fichiers de la 4.1 (`c65d11a`). Lignes = HEAD `acf0b83`. 8 correctifs, 11 reports, 3 décisions, 9 rejets. Rien de perdu d'`Arena` (vagues, obstacles, danger, renfort, poussée de l'Éveil, tremblement, `LucidityFx`) ; aucun test GUT ne dépend du temps réel ni de l'audio avec `--fixed-fps 60` ; les `.tscn` du pool se reconstruisent à l'identique depuis `art_source/` (aux identifiants près, voir reports).

- [ ] [Review][Patch] **F1 `-` sur la dernière vague d'une salle peinte rejoue la vague 0** [`game/rooms/waves/wave_runner.gd:72-76`] : `_waves[_next_index % size]` avec `_next_index == size`. Dans `force_next_wave()`, après `_room.kill_all_enemies()` : `if not _list.loop and _next_index >= _waves.size(): _finish(); return`, puis `_start_next_wave()`.
- [ ] [Review][Patch] **Une apparition déplacée peut tomber dans un mur intérieur ou sur un trou** [`game/rooms/room.gd:709-717`] : `_overlaps_obstacle()` ne lit que `HighObstacles`/`LowObstacles` ; l'outil ASCII permet `#` et `P` dans la zone jouable. Ajouter `_walls.get_cell_source_id(cell) != -1` et la couche `%Pits` (mise en cache au `_ready`, nulle dans l'arène) au test. À faire sur le `room.gd` de la 4.3 (modifié en parallèle).
- [ ] [Review][Patch] **Une vague sans apparition consomme le seul renfort de la salle** [`game/rooms/room.gd:316-319`] : `cancel_pending_reinforcements()` vide la file mais laisse `_reinforcement_used = true` ; `begin_wave()` ne réarme pas, donc plus de renfort pour les vagues suivantes. `var dropped: bool = not _pending.is_empty()` avant `_clear_pending()`, puis `if dropped: _reinforcement_used = false`.
- [ ] [Review][Patch] **Emplacements décalés quand un marqueur est écarté** [`game/rooms/room.gd:498-503`, `game/rooms/waves/wave_runner.gd:154-163`] : `_make_wave_list()` ajoute un emplacement par marqueur, `WaveRunner._validate()` écarte les entrées sans `enemy`/`scene` et tronque au-delà de `MAX_WAVE_ENEMIES` sans avancer `_slot_cursor` : les ennemis suivants paraissent sur le marqueur d'un autre. Dans `_make_wave_list()`, sauter (`continue`) les marqueurs dont `enemy == null or enemy.scene == null` (ni entrée ni emplacement) ; dans `RoomValidator._check_enemies`, signaler une vague de plus de `WaveRunner.MAX_WAVE_ENEMIES` marqueurs.
- [ ] [Review][Patch] **Trous de sol et cadre incomplet non détectés** [`game/rooms/validator/room_validator.gd:51-59`, `game/rooms/validator/room_builder.gd` `_paint`] : seul le rectangle englobant du `Floor` est comparé ; une ligne ASCII trop courte laisse une case sans sol ni mur, une tuile de cadre retirée dans Godot ouvre une brèche. Validateur : exiger `floor_layer.get_used_cells().size() == playable.x * playable.y` et une tuile `Walls` sur chaque case du bord du cadre (les portes y sont des murs dans le `.tscn`, décision 10). Outil : erreur si une ligne de grille ≠ `playable.x` caractères ou si le nombre de lignes ≠ `playable.y`.
- [ ] [Review][Patch] **`ReinforcementSpawn`, côtés de porte en double et case du joueur non contrôlés** [`game/rooms/validator/room_validator.gd:96-106`] : les marqueurs de renfort sont seulement comptés (un `reinforce 36 2` hors grille passe). Leur appliquer le contrôle « dans la zone jouable, ni mur, ni obstacle, ni trou » d'`EnemySpawn` (factoriser la boucle des `blockers`) ; signaler deux `Door` du même côté (une scellée et une ouverte partagent les cellules) ; signaler une case de `room.player_spawn_position()` occupée par un mur, un obstacle ou un trou (le joueur paraît au centre jusqu'à la 4.8).
- [ ] [Review][Patch] **Les outils de salle écrivent la télémétrie de l'utilisateur** [`tools/build_room.sh`, `tools/validate_rooms.sh`] : ils lancent une scène avec les autoloads sans isoler `XDG_DATA_HOME` (chaque appel crée un `user://telemetry/*.json` réel). Exporter un `XDG_DATA_HOME` temporaire (`mktemp -d`, nettoyé par `trap`) comme `tools/run_tests.sh` ; citer `"$OUTPUT"` dans `build_room.sh:16`.
- [ ] [Review][Patch] **`var name` masque `Node.name`** [`game/rooms/validator/room_builder.gd:58`] : `RoomBuilder extends Node` (avertissement `SHADOWED_VARIABLE_BASE_CLASS`). Renommer en `room_name`.

## État du code concerné

- `rooms/arena/arena.gd` (769 lignes) porte tout : à découper sans changer le comportement (les 26 scènes `.scratch` le vérifient). `_build_tiles` (code) reste dans `Arena`.
- `WaveRunner.setup(room: Arena, list)`, boucle toujours, appelle `begin_room(planned)` à chaque vague et émet `room_cleared` à chaque vague vidée : ce comportement reste celui de l'arène (`loop = true`).
- `Run._ready` charge `ARENA_SCENE` sans condition ; `Main._start_run()` sans argument ; F5 (`debug_load_test`) et F1 touchent `Main`/`Run`.
- `Const.GROUP_ROOM`, `GROUP_REINFORCEMENT_SPAWN` existent. `Arena._pick_reinforcement_position()` lit le groupe : il continue de marcher avec `ReinforcementSpawn`.
- `deferred-work.md` (« renfort pendant la pause si aucun ennemi n'a pu paraître ») : traité ici, car une salle peinte peut avoir une vague sans apparition valide : vider la file de renfort quand le runner saute une vague.

## Noms partagés de l'epic 4 (à ne pas contredire)

`Room`, `RoomInfo`, `RoomValidator`, `Door` (`Side` N/E/S/W, `State` SEALED/CLOSED/OPEN), `EnemySpawn`, `ReinforcementSpawn`, `Furniture`, `Trigger`, `Tuning.ROOM`, `RunOptions` (4.2) ; `PitGuard`, `Player.enter_room/leave_room` (4.3) ; `FurnitureDef`, `Telegraph.cancel`, `Enemy.dazzle` (4.4) ; `RoomNav` (4.5) ; `RoomCamera` (4.6) ; `RunState`, `FloorDef`, `FloorLayout`, `FloorGenerator`, `RoomCatalog` (4.7) ; `FloorMap`, `Transition` (4.8) ; `FloorMapView` (4.9). **Une salle est un seul nœud de la grille de l'étage**, quelle que soit sa taille ; ses portes sont à des positions canoniques par côté.

## Pièges

- `TileMapLayer.set_cell/erase_cell` met les corps physiques à jour en différé : appeler `walls.update_internals()` après avoir fermé ou ouvert une porte, sinon la porte n'est pas solide le tick même (et le rayon de Glissement la traverse).
- Un `TileSet` partagé à plusieurs `TileMapLayer` : une couche physique par type de collision (indices 0, 1, 2 = WALLS, HIGH, LOW) ; chaque tuile n'a de polygone que dans sa couche. Créer les couches physiques **avant** d'ajouter les sources (déjà noté dans `_build_tiles`).
- Les marqueurs sont des nœuds de la scène instanciée : lire leur `position` en coordonnées de salle (la salle est à l'origine du monde) et passer en tuiles pour `spawn_slots` ; le `WaveRunner` multiplie par `TILE_SIZE`.
- `Room._ready()` ne doit lancer le runner qu'après les `BulletManager` et les tuiles (ordre existant d'`Arena._ready`) ; en mode ROOM la salle vient d'un `PackedScene` : `setup()` avant `add_child()`, comme `Arena`.
- `DirAccess.get_files_at()` ne garantit pas l'ordre : trier les chemins (le générateur de la 4.7 en dépend pour le déterminisme).
- Une scène headless de validation doit appeler `get_tree().quit(code)` après `await` d'une frame (sinon `--scene` ne rend jamais la main).

## Vérifications prévues (GUT, versionnées)

Vagues par marqueurs dans l'ordre ; une seule `room_cleared` ; portes fermées à l'entrée, ouvertes après ; porte fermée arrête un tir joueur, un tir ennemi et un rayon de Glissement ; obstacle bas laisse passer, obstacle haut arrête (deux camps) ; `RoomValidator` : une salle fautive par règle, la bonne passe ; `validate_rooms.sh` renvoie 0 sur le pool, non nul avec une salle fautive ajoutée temporairement. `.scratch` : toutes les scènes passent.

## Fichiers prévus

`rooms/room.gd`, `rooms/room_base.tscn`, `rooms/door.gd/.tscn`, `rooms/furniture.gd`, `rooms/markers/*.gd`, `rooms/tilesets/onset.tres`, `rooms/pool/onset/onset_combat_00{1,2,3}.tscn`, `rooms/validator/*`, `generation/room_info.gd`, `run/run_options.gd`, `core/room_tuning.gd`, `data/tuning/room_tuning.tres`, `tools/*.sh`, `art_source/rooms/*.txt`, `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Salles produites par un outil ASCII → `.tscn`** (le GDD/D10 parle de salles « dessinées » dans Godot) : les agents ne peuvent pas peindre ; les `.tscn` restent la vérité et sont éditables à la main.
2. **`Arena` devient une sous-classe de `Room`** plutôt que d'être renommée : les scènes `.scratch` ne bougent pas.
3. **Positions de portes canoniques** (milieu de chaque côté, 2 tuiles de large) : le générateur n'a qu'un côté à connaître, la porte d'arrivée se calcule sans lecture de scène.
4. **Portes = tuiles de `Walls`** (fermée/scellée) retirées à l'ouverture : tirs, Glissement et ennemis les respectent sans code spécifique.
5. **`room_cleared` une seule fois par salle prédessinée** ; l'arène en boucle garde une émission par vague.
6. **`RunOptions` + `Events.run_requested`** comme unique entrée de relance (F1 maintenant, menus en 4.11).
7. **Salles sans renfort acceptées** pour START, TREASURE, SHOP et NIGHTMARE (le GDD interdit le renfort au cauchemar, et ces salles n'ont pas d'ennemi).

8. **`Door.Side` se déclare `Door.Side` dans les annotations** : `Side` est aussi une énumération globale de Godot (`SIDE_TOP`…), et `@export var side: Side` y résolvait ; le nom `Door.Side` du contrat de l'epic est inchangé.
9. **Portes à l'état OPEN au chargement, fermées dès l'entrée dans une salle qui a des `EnemySpawn`** (pas après `start_delay`) : une salle de combat est fermée dès que le joueur y est ; `begin_room()` referme (sans effet). `Door.seal()` est la seule voie vers SCELLÉE, appelée par le générateur (4.7) ; en 4.2 aucune salle n'a de voisin et les portes s'ouvrent donc toutes à la fin.
10. **Cadre complet peint par l'outil, les portes y percent leur trou à l'exécution** : le `.tscn` contient des murs sur les cellules de porte ; `Door.attach()` les retire à `OPEN`. Ainsi la salle ouverte dans Godot montre un cadre plein et la porte reste un nœud, pas une cellule à dessiner.
11. **Rythme des salles peintes dans `RoomTuning`** (`first_wave_delay` 1 s, `wave_pause` 2 s, mêmes valeurs que l'arène) plutôt que dans chaque salle ; une salle ne peut pas encore les surcharger.
12. **Vague sautée (aucun ennemi n'a pu paraître) : renfort annoncé annulé** (`Room.cancel_pending_reinforcements()`), pour l'arène aussi : clôt l'entrée de `deferred-work.md` sur le renfort pendant la pause.
13. **`RunOptions` mémorisées par `Main`** : un redémarrage (écran de réveil, F5 de retour) rejoue la dernière demande (la même salle en mode ROOM) ; sans demande, l'arène. F1 : touche `R` (salle suivante du pool, triée par chemin, circulaire).
14. **Pas de `Pits` dans `Arena`** : `Room` lit `%Pits` seulement s'il existe (`get_node_or_null`), l'arène du jalon A n'en a pas ; la 4.3 s'en servira.
15. **Fixtures et validateur** : les salles fautives sont des `.tscn` construites par l'outil ASCII (`tests/fixtures/rooms/*.txt`), plus deux mutations en code pour les cellules hors cadre ; règle ajoutée au validateur : une salle COMBAT sans aucun `EnemySpawn` est refusée. `tools/validate_rooms.sh` accepte un dossier (`res://…`) pour les tests.
16. **`tools/run_tests.sh` passe `--fixed-fps 60`** (fichier de la 4.1) : les tests d'intégration attendent des secondes de jeu (1 s avant la première vague, 2 s entre les vagues) ; le temps virtuel les fait tourner en 3 s au lieu de 25 s. Les ticks restent des ticks.
17. **Le harnais n'utilise pas `add_child_autofree`** : GUT libérait le harnais depuis sa propre émission de `ticked` (« locked object »). `release()` en `after_each`.

18. **Revue : distance porte–apparition mesurée au centre de la porte** (et non à sa cellule la plus proche) : règle documentée et testée, le pool est à 4 tuiles ou plus ; la 4.8 la revisitera avec la distance d'entrée du joueur.
19. **Revue : ordre de fin de salle gardé** (`end_room()` ouvre les portes, puis `room_cleared`) au lieu de l'ordre littéral du CA 6 : un écouteur voit une salle déjà gagnée (`is_cleared()` vrai, portes ouvertes), ce qu'attendront la récompense (epic 5) et le changement de salle (4.8).
20. **Revue : salles du pool aplaties** (copie complète de `room_base.tscn`, pas de scène héritée) : un nœud ajouté à la base plus tard se propage en reconstruisant les salles depuis `art_source/rooms/*.txt` (le texte reste la source des agents, une retouche à la main dans Godot doit être reportée dans le texte). Identifiants instables reportés (`deferred-work.md`).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- **`Room` extraite d'`Arena`** (`rooms/room.gd`) : apparitions, `begin_room()`/`begin_wave()`/`end_room()`, danger, renfort, `BulletManager`, chiffres, effets, tremblement, portes. `Arena extends Room` garde le décor en code, les cibles, `WAVE_LIST`, `waves_enabled`, via cinq points d'extension (`_build_decor`, `_waves_wanted`, `_make_wave_list`, `_register_static_hurtboxes`, `_log_name`). Les scènes `.scratch` n'ont pas été touchées.
- **Vagues par marqueurs** : `Room._make_wave_list()` groupe les `EnemySpawn` par valeur de `wave` (ordre croissant, ordre de l'arbre dans une vague), `loop = false`. `WaveRunner` : `begin_room` à la première vague puis `begin_wave`, une seule `room_cleared` (puis état `DONE`), une vague sautée annule le renfort annoncé et termine la salle si c'était la dernière.
- **Portes** : `Door` pose ou retire des tuiles de mur dans `Walls` (`update_internals()` aussitôt) : tirs des deux camps et rayon de Glissement s'arrêtent sans code propre (testés).
- **Outils** : `tools/build_room.sh` (ASCII -> `.tscn`, scène `rooms/validator/room_builder.tscn`), `tools/validate_rooms.sh`. Les trois salles du pool sont dans `art_source/rooms/` et `rooms/pool/onset/`. Le tileset `onset.tres` est produit par `rooms/tilesets/make_onset_tileset.gd` (à relancer si les tuiles changent).
- **Vérifications** : `tools/run_tests.sh` : 62 tests verts (dont 15 nouveaux d'intégration et validateur) ; `validate_rooms.sh` renvoie 0 sur le pool et 1 sur les fixtures fautives ; `run_all.sh` du `.scratch` en mode normal : tout passe sauf `t_glide` (11 contrôles de visée à la souris), qui échoue de même sur le commit d'avant la 4.2 dès que `XDG_DATA_HOME` est isolé (ajout de `run_all.sh` par la revue de la 4.1) et passe seul ; `--quit-after 120` propre. Rien n'est NON ÉVALUÉ de plus que la lisibilité des trois salles (humain) : le contenu est vérifié par validateur et tests, pas jugé à l'œil.
- **Historique** : le commit `feat(rooms): add onset tileset, door and room marker classes` précède le commit du `RoomTuning` dont `Door` dépend (erreur d'ordre : le dépôt ne s'importe pas à ce seul commit, tout est bon dès le suivant).

### File List

- `game/rooms/room.gd`, `game/rooms/arena/arena.gd`, `game/rooms/room_base.tscn`, `game/rooms/door.gd/.tscn`, `game/rooms/furniture.gd`, `game/rooms/markers/{enemy_spawn,reinforcement_spawn,trigger}.gd`, `game/rooms/tilesets/{onset.tres,make_onset_tileset.gd}`
- `game/rooms/waves/{wave_list,wave_runner}.gd`, `game/rooms/validator/{room_validator,validate_rooms,room_builder}.gd` (+ `.tscn` des deux outils), `game/rooms/pool/onset/onset_combat_00{1,2,3}.tscn`, `art_source/rooms/*.txt`
- `game/generation/room_info.gd`, `game/run/{run,run_options}.gd`, `game/main/main.gd`, `game/autoloads/events.gd`, `game/core/{room_tuning,tuning}.gd`, `game/data/tuning/room_tuning.tres`, `game/debug/{debug_panel,perf_overlay}.gd`
- `tools/{validate_rooms,build_room}.sh`, `tools/run_tests.sh` (`--fixed-fps 60`)
- `game/tests/support/room_harness.gd`, `game/tests/integration/rooms/test_room_{waves,doors,obstacles}.gd`, `game/tests/integration/run/test_run_requested.gd`, `game/tests/unit/rooms/test_room_validator.gd`, `game/tests/fixtures/rooms/*` (+ `.uid`)

### Change Log

- 2026-11-24 : revue de code : 8 correctifs à faire, 11 reports, 3 décisions ; story repassée `in-progress`.
- 2026-11-24 : `Room` extraite d'`Arena`, salles prédessinées (marqueurs, portes, vagues, validateur, outil ASCII, trois salles), `RunOptions` et F1 `R`.
