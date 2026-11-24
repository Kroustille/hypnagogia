# Story 4.8 : Passer d'une salle à l'autre

Status: review

## Story

En tant que joueur,
je veux parcourir l'étage en choisissant l'ordre des salles,
afin d'explorer à ma façon.

Exigences : FR24 (portes fermées), FR36, FR39 (ordre libre), FR42, AR17 (préchargement), AR20 (epics.md, Story 4.8). Architecture : D14 (`Main` / `ActiveScene` / `Run` / `RoomSlot` / `Transition`), D11 (préchargement en tâche de fond).

**Dépend de : 4.7** (`FloorLayout`, `RunState`, `RoomCatalog`, salles provisoires, pool ≥ 12 combats), **4.2** (portes, `room_cleared`), **4.3** (`Player.enter_room/leave_room`), **4.6** (grandes salles, caméra). Prépare 4.9 (`FloorMap`) et 4.11 (relance avec seed).

Hors périmètre : sauvegarde de reprise (`RunSnapshot`, epic 8), carte affichée (4.9), contenu de la salle trésor et de la boutique, porte de sortie de l'étage vers le suivant (epic 6).

## Critères d'acceptation

1. **Nouvelle partie** : `Run` en mode `FLOOR` (nouveau défaut de `Main`) génère l'étage (`FloorGenerator`, `RoomCatalog`), lance le chargement des 16 salles en tâche de fond (`ResourceLoader.load_threaded_request`), charge la salle de départ **tout de suite** et y place le joueur. L'arène du jalon A reste accessible depuis le panneau F1 (commande « arène » : `Events.run_requested(ARENA, ...)`).
2. **Franchir une porte ouverte** : le joueur entre dans la zone de sortie d'une porte `OPEN` → transition courte (fondu au noir, 2 × 0,12 s, compteurs de ticks), la salle quittée est **libérée** (retirée de l'arbre d'abord, puis `queue_free()`), la salle voisine (de `FloorLayout`) est instanciée dans `RoomSlot`, le joueur apparaît à l'intérieur de la porte opposée (`Tuning.ROOM.entry_offset_tiles` ≈ 2,5 tuiles de la porte), face à l'intérieur. **Une seule salle est active** (`RoomSlot` a un seul enfant, groupe `room` à un seul membre) à chaque instant, transition comprise après le noir.
3. **Salle déjà vidée** : ses portes sont ouvertes dès l'entrée, aucun ennemi ne réapparaît, pas de `begin_room()`, pas de nouvel `Events.room_cleared` (`Room.setup(..., already_cleared)`).
4. **Salle de combat ou cauchemar non vidée** : à l'entrée, `begin_room()`, les portes se ferment (fermées = tuiles de mur, Glissement ne les franchit pas), les vagues démarrent ; à la dernière vague vidée, `room_cleared` et les portes s'ouvrent. Départ, trésor, boutique : ouvertes en permanence. Un joueur qui ressort d'une salle non vidée est impossible (portes closes), même par dash.
5. **Joueur qui survit aux salles** (deferred-work 1.4 et 3.1) : `Player.leave_room()` rend le joueur propre : plus de `PlayerBullets` (`_bullets = null`), plus de source de trous, plus d'abonnement vers la salle ; `enter_room(room)` équipe les nouveaux `BulletManager` et enregistre la hurtbox du joueur chez les tirs ennemis de la nouvelle salle. `equip_bullets()` devient **répétable sans effet de bord** (même manager : rien ; manager libéré : refusé avec `Log.error`). Après 10 changements de salle : le nombre de connexions des signaux du joueur ne grandit pas.
6. **État de l'étage** : `FloorMap` (`run/floor_map.gd`, `RefCounted`) : `current`, `visited` (cellules), `cleared` (cellules), `mark_entered(cell)`, `mark_cleared(cell)`, `is_cleared(cell)`. Mis à jour par `Run`, lu par la 4.9. Signaux de bus `Events.room_entered(room_id, cell_x, cell_y)` (télémétrie, journal `Log.info("run", "room entered ...")`).
7. **Salle de départ du premier étage** : calme, sans ennemi, avec un **tutoriel visuel des contrôles** (déplacement, tir, dash, pouvoirs Éveil et Glissement), libellés localisés (`strings.csv`, clés `UI_TUTORIAL_*`) et touches du **périphérique actif** (clavier-souris ou manette) lues dans `InputMap`, mises à jour quand le joueur change de périphérique.
8. **Mort pendant ou après** : `run_ended` fonctionne dans n'importe quelle salle ; la relance (`_start_run`) détruit le `Run` et ses salles sans fuite ; le tutoriel ne réapparaît que dans la salle de départ.
9. **Robustesse** : si la génération échoue (`FloorLayout.valid` faux) ou si une salle ne se charge pas, `Log.error` et repli sur l'arène du jalon A (jamais de jeu bloqué, AR28).

## Tâches

- [x] `Main.default_mode` (statique, `Run.Mode.FLOOR`), `RunOptions`/`Run.setup` : modes ARENA, ROOM, FLOOR. **Les scènes `.scratch` qui lancent `main.tscn` (9 : `t_enemy_main`, `t_regress`, `t_sheep_main`, `t_shooters_main`, `t_waves_main`, `t_hud`, `t_telemetry`, `t_lucidity`, `t_lucidity_fx`) et `th.gd` supposent l'arène : leur ajouter une seule ligne `Main.default_mode = Run.Mode.ARENA`** (seule modification de `.scratch` permise).
- [x] `run/room_loader.gd` (`RoomLoader`) : `request_all(paths)`, `scene_for(path) -> PackedScene` (bloque via `load_threaded_get` si pas prête), `is_ready(path)`. Le départ est chargé en synchrone.
- [x] `Room.setup(player, rng, floor_index, options)` : cellule, côtés de portes ouverts par la disposition (`Door.State` : `CLOSED/OPEN` selon l'état, `SEALED` sans voisin), `already_cleared`, signal `door_taken(side)` émis quand le joueur est dans la zone de sortie d'une porte `OPEN`.
- [x] `Run.travel(side)` (différé hors de la physique) : fondu, `leave_room`, retrait + libération de l'ancienne salle, instanciation, `enter_room`, positionnement (`Room.entry_position(side)`), `reset_physics_interpolation()` joueur et caméra, fondu retour, `FloorMap` et `Events.room_entered`.
- [x] `main/transition.gd` sur le nœud `Transition` existant de `main.tscn` (un `ColorRect` noir, fondus par compteurs de ticks, groupe `transition`), jamais de `Timer`.
- [x] `Player.enter_room/leave_room` complets, `equip_bullets` répétable, `Room._exit_tree` appelle `leave_room` ; `Sheep`/ennemis : rien (les salles libérées emportent leurs ennemis).
- [x] Tutoriel : `ui/tutorial/controls_tutorial.tscn/.gd` (`Control` dans un `CanvasLayer` de la salle de départ, ou ajouté par `Run` quand `floor_index == 0` et type START), libellés d'actions depuis `InputMap` (clavier : `as_text_physical_keycode()`, manette : `Input.get_joy_button_string` ou nom d'axe : vérifier l'API avec Context7), `strings.csv`.
- [x] F1 : « arène (jalon A) » et « étage » ; tests GUT : `tests/integration/run/test_room_travel.gd` (franchir une porte, libération, une seule salle, entrée par la bonne porte, vidée = ouverte et sans ennemis, non vidée = fermée, 10 allers-retours sans fuite de nœuds ni de connexions de signaux), `test_floor_start.gd` (génération, départ calme, tutoriel présent), `tests/unit/run/test_floor_map.gd`, `tests/unit/run/test_room_loader.gd` (état prêt).
- [x] `run_all.sh` du `.scratch` ; `--quit-after 120` propre.

## État du code concerné

- `Run` : `ARENA_SCENE` en `preload`, `rng` créé dans `_ready`, `arena.setup(_player, rng)` avant `add_child`, joueur placé à `arena.player_spawn_position()`, journal `run started`, `Events.run_started`. `RoomSlot` est un `Node`. `Run._on_player_died` émet `run_ended`.
- `Main._start_run()` : retire les enfants d'`ActiveScene` avant de les libérer (groupes comptés tout de suite), ajoute `RUN_SCENE.instantiate()`. Le nœud `Transition` (CanvasLayer, couche 2) existe, vide.
- `Player.equip_bullets()` : crée `_shot_params` et une apparence à chaque appel ; `_bullets` jamais remis à nul. La hurtbox du joueur est enregistrée par `Room._setup_enemy_bullets` ; le graze et l'esquive y sont branchés (`grazed`, `dodged`).
- Les `Door` (4.2) manipulent `Walls` ; leur zone de sortie est un `Area2D` sur `LAYER_PLAYER`, active seulement ouverte.
- `Events.room_cleared(room, tier)` : le joueur l'écoute (`+5` de lucidité) ; `Room` ouvre ses portes à la réception pour sa propre instance.
- Deferred-work à clore ici : « le joueur survit aux salles » (équipement, hurtbox), « `equip_bullets()` répétable », « une charge qui ne touche rien ne finit jamais » (les portes sont fermées en combat ; la 4.3 a ajouté la distance maximale).

## Pièges

- Libérer une salle depuis un callback d'`Area2D` (`body_entered`) : « can't change state while flushing queries ». Le signal ne fait que mémoriser le côté ; `Run` agit au tick suivant (`call_deferred`), jamais de `queue_free` d'une salle depuis son propre signal de physique.
- `remove_child` avant `queue_free` (comme `Main._clear_active_scene`) : sinon la salle libérée reste dans le groupe `room` jusqu'à la fin de la frame et les outils de debug la trouvent.
- `ResourceLoader.load_threaded_get()` doit être appelé pour chaque requête, sinon la ressource reste en mémoire et `load_threaded_get_status` reste `IN_PROGRESS` ; en headless le chargement threadé marche mais est plus lent à démarrer : les tests attendent par `is_ready()` avec un plafond de ticks.
- Fermer les portes **après** avoir placé le joueur, en vérifiant que `entry_position` n'est pas dans une cellule de mur (portes à 2,5 tuiles du joueur) ; les ennemis apparaissent à ≥ 3 tuiles du joueur et des portes (validateur 4.2).
- Le joueur est un enfant de `Run`, **hors** de la salle : une salle libérée ne le libère pas ; mais ses `BulletManager` (priorité de physique 100) disparaissent avec elle : ne garder aucune référence.
- `Player.process_mode = DISABLED` pendant le noir : `_arrival_ticks_left`, cooldowns (comptés en ticks) sont gelés avec lui, c'est voulu.
- Aucune dépendance de `ui/` vers `rooms/` : le tutoriel lit `Player.aim_source()` et `InputMap`, pas la salle.
- Telemetry : `run_started` n'est émis qu'une fois par `Run`, pas à chaque salle (`Events.room_entered` pour ça).

## Fichiers prévus

`run/run.gd`, `run/run_options.gd`, `run/floor_map.gd`, `run/room_loader.gd`, `main/main.gd`, `main/transition.gd` (+ `main.tscn`), `rooms/room.gd`, `rooms/door.gd`, `player/player.gd`, `autoloads/events.gd`, `ui/tutorial/controls_tutorial.tscn/.gd`, `localization/strings.csv`, `debug/debug_panel.gd`, `.scratch/*` (une ligne dans 9 scènes), `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Défaut de `Main` = étage** dès cette story ; l'arène par F1, et les scènes `.scratch` qui s'appuient sur l'arène la demandent par une ligne.
2. **Fondu au noir de 2 × 0,12 s**, entrée à 2,5 tuiles de la porte ; durées dans `Tuning.ROOM`, pas de glissement de caméra.
3. **Les tirs en vol disparaissent avec la salle quittée** ; le joueur est désactivé pendant la transition (pas de coup possible).
4. **Salle vidée = définitive** pour la run (pas de réapparition) ; l'état vit dans `FloorMap`, pas dans la salle.
5. **Repli sur l'arène** si l'étage ne se génère pas ou si une salle manque (AR28).
6. **Tutoriel affiché dans la salle de départ** (tant que le joueur y est) plutôt que seulement au début de la run ; une aide par action, texte court, périphérique selon la dernière source d'entrée.
7. **`Events.room_entered`** ajouté (le texte de l'epic ne le cite pas) pour la télémétrie et la carte.
8. **Aucune sauvegarde d'entrée de salle** (`RunSnapshot`, AR18) : à l'epic 8.

9. **Nouvelles décisions du développement** : (a) `RoomOptions` (`rooms/room_options.gd`, `RefCounted`) porte la cellule, les côtés reliés, `already_cleared` et le côté d'entrée plutôt que quatre paramètres de `Room.setup()` ; une salle sans options reste autonome (arène, mode ROOM, tests de la 4.2). (b) `Tuning.ROOM.player_entry_distance` (3 tuiles du centre de la porte, soit 2,5 tuiles de la case de jeu) sert de distance d'entrée : pas de second champ `entry_offset_tiles`. (c) `Tuning.ROOM.transition_duration` = 0,12 s (chaque moitié du fondu). (d) `Main.default_mode` est de type `RunOptions.Mode` (l'énumération vit dans `RunOptions`, pas dans `Run`) ; la ligne de repli sur l'arène est posée une seule fois dans `th.gd` (base de toutes les scènes qui lancent `main.tscn`), pas dans chacune des 9 scènes. (e) Le validateur vérifie désormais les points d'entrée (deux cases de part et d'autre du point, contre mur, obstacle, trou, meuble) : `onset_combat_001` a vu un bloc d'obstacles bas déplacé (source ASCII et scène reconstruite). (f) Une salle dont aucun marqueur n'a d'ennemi ni de scène n'arme pas de vagues (portes jamais fermées : clôt le deferred « salle bloquée »). (g) Un joueur dans l'embrasure quand les portes se ferment est replacé au point d'entrée de cette porte (`Room._close_doors`). (h) Mode ROOM (F1 R) et arène : les portes restent telles que peintes (ouvertes sur le vide une fois la salle vidée) : outils de debug, pas de voisin à rejoindre. (i) Le départ est chargé en synchrone *avant* les requêtes d'arrière-plan : un `load()` lancé pendant que des chargements threadés tournent a bloqué les tests (interblocage reproduit). (j) F1 : touche A (arène du jalon A) et F (étage). (k) Mi-run, une salle qui ne se charge pas : `Log.error` et repli sur l'arène, la run continue (AR28).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- Tous les critères sont couverts. `Run` en mode FLOOR joue l'étage : `RoomLoader` demande les 15 autres salles en arrière-plan, la salle de départ se charge d'abord ; `Run.travel(side)` (différé hors de la physique) passe par `Transition` (fondu 2 × 0,12 s en ticks), libère l'ancienne salle (retirée de l'arbre puis `queue_free()`), installe la voisine et place le joueur à l'entrée de la porte opposée, tourné vers l'intérieur, avant l'entrée de la salle dans l'arbre (les portes se ferment autour d'un joueur déjà placé, `snap_camera()` suit).
- Joueur qui survit aux salles : `equip_bullets()` répétable (même gestionnaire : rien ; gestionnaire détruit ou nul : `Log.error`), `leave_room()` rend les tirs et la source de trous, la salle se désabonne du joueur dans `_exit_tree`, `Player.stop_motion()` annule un dash en vol, `Player.face()`. Dix allers-retours : nombre de nœuds et de connexions de signaux inchangés, deux `BulletManager` dans le groupe, hurtbox inscrite une fois.
- Deferred 4.8 traités : porte ouverte vers le vide (portes sans voisin scellées par `RoomOptions`), porte qui se ferme sur un corps (joueur replacé ; ennemis et renforts jamais si près : validateur 4.2), salle sans vague valide (plus de portes fermées pour toujours), `RoomNav.origin` (suivi par `NOTIFICATION_TRANSFORM_CHANGED`), point d'entrée contre les bloqueurs (validateur), `snap_camera()` après placement, `equip_bullets()` répétable, joueur qui survit aux salles, charge sans fin (portes fermées en combat, distance maximale de la 4.3). Cohérence par salle : `begin_room()` de la jauge à chaque entrée (le palier de salle repart du palier vivant), `danger` propre à chaque salle, pas de `room_cleared` pour une salle déjà vidée.
- Tutoriel des contrôles dans la salle de départ du premier étage (touches de l'`InputMap`, clavier-souris ou manette selon le dernier périphérique). `FloorMap`, `Events.room_entered` (après `run_started` pour la première salle), journal `room entered`.
- Vérifications : `tools/run_tests.sh` vert (GUT, 263 tests), `run_all.sh` en mode normal ALL PASS avec la nouvelle scène `t_floor_main` (jeu complet : fondu réel, 16 allers-retours sans fuite de nœud, mort puis relance, arène par requête), `--quit-after 120` propre. NON ÉVALUÉ (humain) : sensation du fondu et de l'arrivée, lisibilité du tutoriel, libellés de manette (RB/LB/RT/LT), sur une vraie manette.

### Change Log

- 2026-11-24 : implémentation de la story 4.8.

### File List

`game/run/{run,run_options,floor_map,room_loader}.gd`, `game/main/{main.gd,main.tscn,transition.gd}`, `game/rooms/{room,door,room_options}.gd`, `game/rooms/validator/room_validator.gd`, `game/rooms/pool/onset/onset_combat_001.tscn`, `art_source/rooms/onset_combat_001.txt`, `game/player/{player,dash}.gd`, `game/autoloads/events.gd`, `game/core/{constants,room_tuning}.gd`, `game/data/tuning/room_tuning.tres`, `game/ui/tutorial/controls_tutorial.{gd,tscn}`, `game/localization/strings.csv`, `game/debug/debug_panel.gd`, `game/tests/**` (`test_room_travel`, `test_floor_start`, `test_player_rooms`, `test_floor_map`, `test_room_loader`, `test_controls_tutorial`, `room_harness`, `test_run_requested`), `game/.scratch/{th.gd,t_floor_main.*,run_all.sh}` (hors dépôt).
