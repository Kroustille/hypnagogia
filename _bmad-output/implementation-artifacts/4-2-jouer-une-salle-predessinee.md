# Story 4.2 : Jouer une salle prédessinée

Status: ready-for-dev

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

- [ ] Extraire `Room` d'`Arena` (git mv logique, `Arena extends Room`). Remplacer les types `Arena` par `Room` dans `WaveRunner`, `DebugPanel`, `Run`, `Main`. `Const.ROOM_TILES` reste la taille d'un écran ; `Room.playable_tiles()` la dérive de `size_kind` (SCREEN seul pour l'instant) et remplace les usages de `Const.ROOM_TILES` dans `_spawn_bounds`, `player_spawn_position`, `_check_screen_layout`, `_setup_lucidity_fx`.
- [ ] `WaveList.loop`, `WaveRunner` : une seule `room_cleared` à la fin d'une liste sans boucle, `begin_room` à la première vague puis `begin_wave`, état terminé (plus aucune apparition). `Room.begin_wave()`.
- [ ] `rooms/room_base.tscn`, `rooms/tilesets/onset.tres` (images générées par script comme `_solid_image`), `rooms/door.gd/.tscn`, `rooms/markers/{enemy_spawn,reinforcement_spawn,trigger}.gd`, `rooms/furniture.gd`, `data/tuning/room_tuning.tres` + `RoomTuning` (`Tuning.ROOM` : largeur de porte en tuiles, distance d'entrée du joueur) .
- [ ] `RoomInfo` (RefCounted, `generation/room_info.gd` : `id`, `path`, `room_type`, `size_kind`, `doors: Array[int]`) avec `static from_scene(PackedScene)` : instancie, lit, libère (sert au validateur ici, au générateur en 4.7).
- [ ] `RunOptions`, `Events.run_requested`, `Main._start_run(options)`, `Run.setup(options)` avant `add_child`. `Run` en ROOM : `setup` de la salle comme pour l'arène (joueur, `rng`).
- [ ] `RoomValidator` (pur), `validate_rooms.gd/.tscn`, `tools/validate_rooms.sh`, `tools/build_room.sh`, builder, les trois salles.
- [ ] `tests/support/room_harness.gd` : instancie une `Run` en mode ROOM, `await ticks(n)` (priorité physique 200, comme `th.gd`), accès à la salle, au joueur, aux ennemis. `tests/integration/rooms/test_room_waves.gd`, `test_room_doors.gd`, `test_room_obstacles.gd`, `tests/unit/rooms/test_room_validator.gd`.
- [ ] `run_all.sh` du `.scratch` une fois à la fin ; `--quit-after 120` propre.

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

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List
