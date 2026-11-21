---
baseline_commit: 816127d83f82b0b0a7a2c5eae6428368f349e668
---

# Story 2.2 : Mourir et relancer en moins de 3 secondes

Status: in-progress

## Story

En tant que joueur,
je veux qu'une mort me renvoie aussitôt à une nouvelle partie,
afin de relancer sans attendre.

**Exigences couvertes :** FR15, NFR3 (relance), AR20, ainsi que AR8 (état de run dans `Run`), AR13, AR22, AR24, AR27, AR28, AR32.

**Prérequis : la story 2.1 est `done`** (vérifié à la création de ce fichier : `Health`, `Hurtbox.is_hittable()`, `Events.player_hit`, `EnemyBullets` dans l'arène, panneau F1 instancié par `Main`, groupe `player` existent dans le dépôt). Les stories 1.7 et 1.8 sont reportées par Kroustille (avant le playtest du jalon A) : elles ne sont **pas** des prérequis.

**Deuxième story de l'epic 2.** Elle pose la boucle de run minimale : `Main` → `Run` → joueur + salle, la mort, l'écran de réveil et la relance. Les ennemis arrivent avec les stories 2.3 à 2.5, le HUD avec la 2.7, la question « mort juste ? » et la télémétrie avec la 2.8.

## Critères d'acceptation

1. **Étant donné** la scène `Main` persistante, **quand** une partie démarre, **alors** `Main` instancie un nœud `Run` sous `ActiveScene`, avec le joueur et l'arène dans `RoomSlot` (le joueur est un enfant de `Run`, l'arène l'unique enfant de `RoomSlot` : voir les décisions), **et** `UI` et `Transition` sont des `CanvasLayer` de `Main`.
2. **Étant donné** le joueur à ½ cœur, sans armure, **quand** il prend un coup, **alors** il meurt, `Events.run_ended` est émis, et un écran de réveil s'affiche.
3. **Étant donné** l'écran de réveil, **quand** le joueur appuie sur la touche de relance, ou passe l'écran, **alors** le nœud `Run` est détruit, un nouveau est instancié, et la nouvelle partie démarre en moins de 3 s après la mort, **et** les ressources de l'arène restent en cache, **et** `Log.info("run", ...)` journalise la mort et le lancement de la nouvelle partie.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture, par les reports de la story 2.1 ou par l'état du dépôt) :

4. **Ordre du coup mortel fixé** (report de la revue de 2.1) : `Health` émet `changed` **avant** `died` ; le joueur émet `Events.player_hit` du coup mortel **avant** de signaler sa mort ; puis `Run` émet `Events.run_ended`. Ordre observable sur un coup mortel : `Health.changed` → `Events.player_hit` → `Player.died` → `Events.run_ended`, tous au même tick, une seule fois chacun.
5. **Un mort ne joue plus** : à sa mort, le joueur cesse de bouger et de tirer (même sans `Main`, dans un `Run` isolé), son sprite disparaît, et il reste intouchable. `Events.run_ended` n'est émis qu'une fois par `Run`, même si plusieurs coups arrivent au même tick.
6. **Le clignotement ne force plus la visibilité** (report de la revue de 2.1) : `Player._update_blink()` n'écrit `Sprite2D.visible` qu'aux changements d'état du clignotement ; un sprite masqué ailleurs (mort) reste masqué.
7. **Partie figée derrière l'écran de réveil** : pendant l'écran de réveil, le jeu est figé comme en pause (`GameClock.paused` et `ActiveScene` désactivé, écrits par `Main` seul) ; la touche pause et la perte du focus n'ouvrent pas le menu de pause ; F4, F5 et les commandes 1 à 5 de F1 sont ignorées ; le curseur système est visible. Après la relance, tout reprend (pause, F4, F5, F1 comprises).
8. **Pas de relance par accident** : pendant les 0,3 premières secondes de l'écran de réveil, ni la touche de relance ni le bouton ne relancent (appui encore tenu ou martelé au moment de la mort).
9. **Le panneau F1 suit la nouvelle structure** (report de la revue de 2.1) : il trouve le `BulletManager` ennemi qui vise la hurtbox du joueur, et non plus par parent partagé ; ses commandes marchent sur le joueur de chaque nouvelle partie.
10. **Ordre de dessin conservé** : le joueur, sorti de l'arène, reste dessiné au-dessus du sol et des murs, et sous les projectiles et les chiffres de dégâts.
11. **Rien ne fuit d'une partie à l'autre** : après cinq relances, nombre de nœuds stable, aucun nœud orphelin, connexions au bus stables (`Events.enemy_damaged`, `Events.run_ended`).
12. Marche, dash, tir sur les cibles, chiffres de dégâts, coups et invulnérabilité de 2.1, clignotement, panneau F1, pause, réglages, F2, F3, F4, F5 (test de charge ↔ partie) et le test de charge (`Bullets 400 | refused 0`) de 1.1 à 2.1 sont inchangés.

## Tâches / sous-tâches

- [x] **T1. Lexique** (AR32 : un terme entre dans le lexique **avant** le code)
  - [x] `game-architecture.md`, section « Lexique » : ajouter `Run, nuit, partie ; mort ; issue de la run ; écran de réveil ; se rendormir, relancer ; emplacement de salle ; transition ; couche de décor | run ; death ; outcome ; wake_screen ; restart ; room_slot ; transition ; decor`.
  - [x] `game-architecture.md`, section « Temps (D7) » : une ligne « pendant l'écran de réveil, `Main` fige aussi `ActiveScene` et `GameClock.paused`, sans menu de pause (story 2.2) ». Section « Rendu (D13) » : une ligne « couches de décor en `z_index` = `Const.Z_INDEX_DECOR` : le joueur vit dans `Run`, hors de la salle (story 2.2) ».
- [x] **T2. Ordre du coup mortel et mort du joueur** (CA 2, 4, 5, 6)
  - [x] `combat/health.gd` : `changed` avant `died` (voir « `Health` »).
  - [x] `player/player.gd` : signal local `died`, `_die()`, mort traitée après `Events.player_hit`, `_update_blink()` aux transitions seulement (voir « Joueur »).
- [x] **T3. `Run`** (CA 1, 2, 3, 5)
  - [x] `run/run.tscn` + `run/run.gd` : `Player` et `RoomSlot`, arène instanciée en code, joueur placé, `Events.run_ended`, logs `run` (voir « `Run` »).
  - [x] `autoloads/events.gd` : signal `run_ended(outcome: int)`.
  - [x] `core/constants.gd` : `Z_INDEX_DECOR`.
- [x] **T4. Arène sans joueur propre** (CA 1, 10)
  - [x] `rooms/arena/arena.tscn` : retirer le nœud `Player`. `rooms/arena/arena.gd` : `setup(player)`, `player_spawn_position()`, décor en `Const.Z_INDEX_DECOR` (voir « Arène »).
- [x] **T5. Écran de réveil** (CA 2, 3, 7, 8)
  - [x] Action `restart` (R) dans `project.godot`.
  - [x] `ui/menus/wake_screen.tscn/.gd` : titre, bouton « Se rendormir (R) », garde de 0,3 s, signal `restart_requested` (voir « Écran de réveil »).
  - [x] `localization/strings.csv` : `UI_WAKE_TITLE`, `UI_WAKE_RESTART` ; réimporter.
- [x] **T6. `Main`** (CA 1, 3, 7)
  - [x] `main/main.tscn` : `Transition` (`CanvasLayer`, `layer = 2`).
  - [x] `main/main.gd` : `_start_run()`, `_freeze()`, `_run_over`, écran de réveil, relance, F5 entre test de charge et partie (voir « `Main` »).
- [x] **T7. Panneau F1** (CA 9)
  - [x] `combat/bullets/bullet_manager.gd` : `has_hurtbox(hurtbox) -> bool` (lecture seule).
  - [x] `debug/debug_panel.gd` : `_find_enemy_manager()` par `has_hurtbox(player.hurtbox)`.
- [x] **T8. Vérifications headless** (CA 1 à 12) : scripts jetables du scratchpad (voir « Stratégie de test »).
- [x] **T9. Vérifications fenêtrées sous WSLg** (CA 2, 7, 10) : écran de réveil lisible, ordre de dessin, curseur, captures.
- [x] **T10. Régression** : import et lancement sans erreur, recherche des interdits, marche, dash, tir, coups, pause, F1 à F5, test de charge.
- [x] **T11. Reports** : mettre à jour `deferred-work.md` (entrées résolues, voir « Reports traités par cette story » ; nouvelles entrées NON ÉVALUÉ / NON VÉRIFIÉ, voir « Stratégie de test » point 10).

### Review Findings

Revue de code du 2026-11-21 (`gds-code-review`, mode complet : Blind Hunter, Edge Case Hunter, Acceptance Auditor ; diff `005623e..1ae804d`). 0 `decision_needed` (4 tranchés sans Kroustille, voir les décisions 20 à 23), 7 `patch`, 3 `defer`, 17 rejetés. Aucune violation fonctionnelle des CA 1 à 12 ; les correctifs portent sur deux chemins d'erreur, l'ordre du dégel, la doc de l'ordre du coup mortel et des contrôles de la « Stratégie de test » absents ou vides. Les vérifications du scratchpad sont dans `game/.scratch/` (lien vers le scratchpad du pipeline, non versionné) ; `run_all.sh` passe aujourd'hui (7 scènes `PASS`).

- [ ] [Review][Patch] `Run` sans arène valide (chemin d'erreur, `assert` retiré en release) : le `return` de la ligne 24 saute `_player.died.connect(_on_player_died)`, donc une mort n'émet jamais `run_ended` et la partie reste ouverte avec un joueur mort et invisible (blocage, contre AR28). Connecter `_player.died` en tout début de `_ready()`, avant l'instanciation de l'arène ; le reste inchangé [game/run/run.gd:19-29]
- [ ] [Review][Patch] Arène ajoutée sans `setup()` (chemin d'erreur) : le `if _player == null: return` saute aussi l'inscription des cibles dans `PlayerBullets`, qui ne déréférence pas le joueur ; en release les cibles deviennent intouchables. Déplacer la boucle `for child in _targets.get_children(): … bullets.register_hurtbox(target.hurtbox)` avant le test du joueur, et ne garder sous la garde que `_player.equip_bullets(bullets)` (AR28 : « le reste continue ») [game/rooms/arena/arena.gd:69-75]
- [ ] [Review][Patch] Relance : `_start_run()` dégèle (`_freeze(false)`) pendant que l'ancien `Run` mort est encore sous `ActiveScene` : tous ses nœuds reçoivent `NOTIFICATION_ENABLED` (le réticule mort recache la souris) juste avant d'être retirés ; sans effet aujourd'hui, mais tout futur nœud qui réagit au dégel (son, effets) se déclencherait sur la partie morte. Scinder `_show_scene()` en `_clear_active_scene()` (boucle `remove_child` + `queue_free`) puis ajout ; dans `_start_run()` : `_wake_screen.hide()`, `_run_over = false`, `_clear_active_scene()`, `_freeze(false)`, ajout de `RUN_SCENE.instantiate()` ; la branche F5 du test de charge appelle les deux mêmes étapes ; réécrire le commentaire de la ligne 140 (« remove the old run while still frozen, unfreeze, then add the new one: it must enter an enabled tree »). Rejouer `t_death`, `t_misc`, `t_arena` (curseur, nœuds, F5) [game/main/main.gd:137-153]
- [ ] [Review][Patch] Ordre réel du coup mortel à documenter dans le code (décision 20) : la doc du signal `died` doit dire « The Run is its only listener: it emits Events.run_ended inside this emission, so any other listener of died runs after run_ended and after Main froze the game; cross-system listeners use Events.run_ended » ; la doc de `Events.run_ended` doit dire « emitted from the Run's handler of Player.died, in the tick of the lethal hit » [game/player/player.gd:9-10] [game/autoloads/events.gd:15-18]
- [ ] [Review][Patch] NFR3 non affirmé et mesure mal nommée : `t_end_ticks` est calculé mais jamais lu, et la fenêtre `usec0`..`usec1` englobe deux ticks de latence d'entrée simulée (≈ 33 ms), pas `_start_run()`. Affirmer `ticks(run_ended → _ready() du nouveau Run) <= 180` (relever le tick de `run_ended` dans l'enregistreur et celui du nouveau `Run`, par exemple via `Log` « run started » ou `child_entered_tree` d'`ActiveScene`), et mesurer `_start_run()` seul (`Time.get_ticks_usec()` autour d'un appel direct `main._on_wake_screen_restart_requested()` dans un cycle dédié, ou d'un `restart_requested.emit()`). Puis corriger « `_start_run()` ≈ 30 à 70 ms » dans les Completion Notes de cette story et dans `deferred-work.md` (« Ressenti de la relance ») avec la valeur réellement mesurée [game/.scratch/t_death.gd:281-304]
- [ ] [Review][Patch] Contrôles du gel et des gardes (CA 5, 7) qui ne prouvent pas leur mécanisme : (a) la garde `_run_over` de `_set_paused()` n'est jamais exercée, car l'action `pause` et `FOCUS_OUT` appellent `_set_paused(true)` qui sort déjà sur `value == GameClock.paused` : ajouter, pendant l'écran de réveil, `main._pause_menu.resume_requested.emit()` → partie toujours figée (`GameClock.paused`, `ActiveScene` désactivé), `_run_over` vrai, écran visible (contrôle par mutation : sans `_run_over or`, le test doit échouer) ; (b) le paramètre `flash` de la cible est lu (`flash_before`, ligne 191) mais jamais affirmé, et le scénario ne peut pas le prouver (`kill()` attend ≥ 60 ticks, le flash est éteint) : toucher la cible dans les ticks qui précèdent le coup mortel (balle lente déjà en vol vers la cible, ou tir posé juste avant la balle mortelle), puis affirmer `flash` identique pendant les 60 ticks d'écran ; (c) F3 pendant l'écran (doit basculer) absent ; F4 n'est montré ni ignoré par la vraie touche ni actif après une relance : ajouter `key(KEY_F4)` pendant l'écran → `global_multiplier` inchangé, et après la relance → bascule ; (d) `t_isolated` : les gardes `Run._ended` et `Player._death_handled` ne sont jamais atteintes (le second coup est refusé par la hurtbox) : appeler `player._die(DamageInfo.Source.DEBUG)` une seconde fois → un seul `died`, un seul `run_ended` [game/.scratch/t_death.gd:170-230] [game/.scratch/t_isolated.gd]
- [ ] [Review][Patch] Stratégie de test incomplète ou vide (points 2, 4, 8, 9, 12) : (a) fuites : comparer `node_counts[0]` (1er cycle) et `node_counts[4]` (5e) comme le demande la spec, ou expliquer dans le test pourquoi le 1er cycle diffère (ligne 370-371) ; (b) contrôles vides à remplacer : `DisplayServer.mouse_get_mode() == DisplayServer.mouse_get_mode()` (ligne 170, tautologie : retirer du compte), `check(true, "F1 key 4 after returning to a run")` (ligne 361 : affirmer `eb.active_count == a0 + 3` sur le manager de la nouvelle partie), impression `arm_ticks + 7` sans sens (ligne 282 : imprimer le nombre de ticks réel entre la mort et l'armement) ; (c) logs `run` non affirmés : dans `run_all.sh` ou par un `Log` capturé, « run started » une fois au départ et après chaque relance, « run ended outcome=death » une fois par mort, « restart requested … ms » avant « run started » ; (d) point 9 absent : `TranslationServer.set_locale("en")` puis `"fr"`, `tr(&"UI_WAKE_TITLE") == "Tu te réveilles."`, texte du bouton `"Se rendormir (R)"` ; (e) point 12 : ajouter la recherche des interdits et « `GameClock.paused` écrit seulement dans `main.gd` » à `run_all.sh`. Puis relancer `run_all.sh` et mettre à jour les comptes du Debug Log [game/.scratch/t_death.gd:282] [game/.scratch/t_death.gd:361] [game/.scratch/t_death.gd:370] [game/.scratch/run_all.sh]
- [x] [Review][Defer] `Main` ignore l'issue de la run : toute issue ouvre l'écran de réveil de la mort ; la victoire (6.4) devra brancher sur `outcome` [game/main/main.gd:157] — deferred, story 6.4
- [x] [Review][Defer] Le joueur survit à la salle : au changement de salle, l'arène emporte `PlayerBullets` (équipé sur le joueur) et `EnemyBullets` (hurtbox du joueur inscrite) ; désinscrire et déséquiper à la sortie de salle [game/rooms/arena/arena.gd:71] [game/rooms/arena/arena.gd:88] — deferred, story 4.8
- [x] [Review][Defer] Garde de 0,3 s en ticks bruts : après un à-coup d'image, le rattrapage de physique (plusieurs ticks par image) peut l'écouler en une ou deux images affichées ; à juger sur la machine de référence [game/ui/menus/wake_screen.gd:36-42] — deferred, story 1.8

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

La boucle de run minimale (`Main` → `Run` → `Player` + `RoomSlot` → arène), la mort du joueur, l'écran de réveil et la relance, le gel de la partie derrière l'écran. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Ennemis, `room.spawn_enemy()`, PV des ennemis, retour du propriétaire dans `Hurtbox.receive()` | 2.3 à 2.5 |
| Vagues, `Events.room_cleared`, « tuer tout » dans F1 | 2.6 |
| HUD (cœurs, armure) | 2.7 |
| Question « cette mort était-elle juste ? », télémétrie, cause de la mort enregistrée | 2.8 |
| Seed, `RunRng`, seed journalisée et affichée à la mort, « relance avec une seed » dans F1 | Epic 4 (4.7, 4.11) |
| Changement de salle, transition courte, préchargement en tâche de fond, contenu de `Transition` | 4.8 |
| Chambre (`Bedroom`), retour à la chambre après l'écran, victoire (`Outcome.VICTORY`), heure du réveil | 6.4 à 6.6 |
| `run.json`, reprise de partie | 6.8 |
| Invites de touches selon le périphérique, réassignation de `restart` | 1.7 |
| Mesure de la relance sur la machine de référence et en export | 1.8 |

### État actuel du dépôt (stories 1.1 à 2.1 `done`)

- **Autoloads** (ordre dans `project.godot`) : `Log`, `Events`, `GameClock`, `Settings`, `SaveService`, `Audio`.
  - `Events` : `player_hit(damage: int, source: int)` et `enemy_damaged(world_position: Vector2, amount: float)`, chacun avec `@warning_ignore("unused_signal")`. Types primitifs seulement (`autoloads/` ne dépend d'aucun dossier de fonctionnalité).
  - `GameClock` : `paused` (écrit par `Main` seul), `global_multiplier` borné à [0, 1] (F4), `scale(group)` renvoie 0 en pause.
  - `Log` : catégories `run`, `room`, `combat`, `lucidity`, `items`, `gen`, `save`, `input`, `audio`, `ui`. Cette story utilise **`run`** (jamais utilisée jusqu'ici).
- **`main/main.tscn`** : `Main` (`Node`, `main.gd`) > `ActiveScene` (`Node`, `%ActiveScene`), `UI` (`CanvasLayer`, `%UI`, couche par défaut 1) > `PerfOverlay`. **Pas de `Transition`.**
- **`main/main.gd`** : `ARENA_PATH`, `BULLET_LOAD_TEST_PATH`, `DEBUG_PANEL_PATH`, menus préchargés. `_ready()` : en debug, vérifications, `CollisionDrawer`, panneau F1 chargé par `load()` dans la branche debug (aucune référence en release) ; `_setup_menus()` ; `_show_scene(ARENA_PATH)`. `_set_paused(value, reason)` est **le seul** endroit qui écrit `GameClock.paused` et `ActiveScene.process_mode` (garde `if value == GameClock.paused: return`, ouvre/cache les menus, log `ui`). `_notification()` : pause automatique sur `NOTIFICATION_APPLICATION_FOCUS_OUT`. `_unhandled_input()` : `pause` dans tous les builds ; F5 et F4 en debug **et hors pause** seulement (`if not OS.is_debug_build() or GameClock.paused: return`). `_show_scene(path) -> bool` : `load()`, retire **tout de suite** les enfants d'`ActiveScene` (`remove_child` puis `queue_free` : leurs groupes cessent de compter dans la même image), ajoute l'instance. F5 bascule `_load_test_active` entre le test de charge et l'arène.
- **`rooms/arena/arena.tscn`** : `Arena` (`Node2D`) > `Floor`, `Walls` (`TileMapLayer`, `%`), `Targets` (3 `TrainingTarget`), **`Player` (instance de `player.tscn`, `%Player`)**, `Camera` (`Camera2D`, `%Camera`).
- **`rooms/arena/arena.gd`** (`class_name Arena`) : `@onready var _player: Player = %Player`. `_ready()` : `_build_tiles()`, `_setup_player_bullets()` (`PlayerBullets`, `_player.equip_bullets(bullets)`, hurtbox des cibles), `_setup_enemy_bullets()` (`EnemyBullets`, `register_hurtbox(_player.hurtbox)`), `_setup_damage_numbers()` ; caméra centrée ; **place le joueur** au centre de la zone jouable (`frame_px / 2` = (304, 168)) puis `reset_physics_interpolation()` ; `Log.info("room", "arena ready ...")`. Les enfants de la scène ont fait leur `_ready()` avant `Arena._ready()`.
- **`player/player.gd`** (`class_name Player`, `CharacterBody2D`) : signal `dash_ended` ; `var health: Health`, `var hurtbox: Hurtbox` créés en code dans `_setup_health()` (avec `add_to_group(Const.GROUP_PLAYER)`) ; `health.died.connect(_on_health_died)` ; `_on_health_died()` ne fait que `Log.info("combat", "player died")` (commentaire « wake-up screen and restart: story 2.2 »). `_on_hurtbox_damage_received(info)` : `lost = health.apply_damage(info)` ; si `lost > 0` : `Events.player_hit.emit(lost, info.source)`, son, `Log.debug`. `_physics_process` : moteur, dash, tir, `move_and_slide()`, `_update_dash_tint()` (**`modulate`**), `_update_blink()`. `_update_blink()` : hors invulnérabilité après un coup, **`_sprite.visible = true` à chaque tick** (report de la revue de 2.1) ; sinon alternance dérivée de `health.hit_ticks_total() - health.hit_ticks_left()` toutes les `BLINK_HALF_PERIOD_TICKS` (6). `_can_be_hit()` : `not is_invulnerable() and not health.is_dead()`. Le `Reticle` est un enfant du joueur (`top_level`, curseur caché dans le jeu, visible sur `NOTIFICATION_DISABLED` et en quittant l'arbre).
- **`combat/health.gd`** : `apply_damage()` : sur le coup mortel, `_dead = true`, `_hit_ticks_left = 0`, **`died.emit()` puis `changed.emit()`** (report de la revue de 2.1) ; sinon invulnérabilité puis `changed`. Accesseurs `hit_ticks_total()`, `hit_ticks_left()`, `is_dead()`, `is_forced_invulnerable()`, `cap_half_hearts()`.
- **`combat/hurtbox.gd`** : `set_hit_filter()`, `is_hittable()`, `one_hit_per_tick`, `receive() -> bool`. Pas touché.
- **`combat/bullets/bullet_manager.gd`** : `_targets: Array[Hurtbox]` (privé), `register_hurtbox()` / `unregister_hurtbox()` (désinscription sur `tree_exiting` en `CONNECT_ONE_SHOT`), priorité `Const.PHYSICS_PRIORITY_BULLETS` (100). Aucun accesseur public sur les cibles.
- **`debug/debug_panel.gd`** : touches 1 à 5 ignorées si `GameClock.paused` ; joueur trouvé par le groupe `player` ; **`_find_enemy_manager()` exige `manager.get_parent() == player.get_parent()`** (report de la revue de 2.1 : cassera quand le joueur sera dans `Run` et le manager dans l'arène) ; tir automatique pondéré par `GameClock.scale(ENEMIES)`.
- **`debug/bullet_load_test.gd`** (F5) : son propre manager ennemi, pas de joueur. Pas touché.
- **`ui/menus/pause_menu.tscn/.gd`** : modèle de l'écran de réveil (`Dim` `ColorRect` noir α 0,6, `CenterContainer` > `PanelContainer` > `VBoxContainer`, `Label` titre, `Button`s ; textes posés par `tr()` dans `_ready()` ; `open()` avec `grab_focus()` ; signaux locaux vers `Main`).
- **`localization/strings.csv`** : 14 clés `UI_*`, première ligne `keys,fr` ; `strings.fr.translation` régénéré à l'import et versionné ; `locale/fallback="fr"`.
- **`project.godot`** : actions `debug_*` (F1 à F5), `move_*`, `dash`, `aim_*`, `shoot`, `pause` (Échap 4194305, Start). **Pas d'action `restart`.** R (`physical_keycode` 82) n'est utilisée nulle part. Avertissements de typage en erreur.
- **Il n'existe ni `run/`, ni `Run`, ni `Events.run_ended`, ni écran de réveil.**
- Environnement : Godot 4.7.2, `godot` dans le `PATH`, WSLg, pas de manette, pas de `python3` (`uv run python …`). `game/.scratch` : lien symbolique vers le scratchpad, exclu de git.

### Reports traités par cette story (`deferred-work.md`)

| Report | Origine | Réponse de cette story |
|---|---|---|
| Coup mortel : `Health` émet `died` avant `changed`, et `Player` émet `Events.player_hit` après la mort ; ordre à fixer avec `run_ended` | revue 2.1 | CA 4 : `changed` → `died` dans `Health` ; `player_hit` → `Player.died` → `run_ended` |
| `_update_blink()` force `_sprite.visible = true` à chaque tick : écrasera tout autre masquage (mort, écran de réveil) | revue 2.1 | CA 6 : `visible` écrit aux transitions seulement |
| Le panneau F1 trouve le manager ennemi par parent partagé avec le joueur : cassera si `Run`/`RoomSlot` séparent le joueur de la salle | revue 2.1 | CA 9 : `BulletManager.has_hurtbox(player.hurtbox)` |

**Restent ouverts** (ne pas traiter ici) : retour du propriétaire dans `Hurtbox.receive()` (2.3), dégâts ennemis < 0,5 (2.4), désinscription `CONNECT_ONE_SHOT` et pool d'ennemis (2.3+), `TICK_EPSILON` dans `Dash`, `equip_bullets()` répétable (sans objet ici : un joueur neuf par partie), mesure de 10 minutes à 400 projectiles sur la machine de référence (**étape humaine, NON FAITE**, à rappeler à Kroustille en fin d'epic).

### Leçons des stories 1.1 à 2.1 à appliquer

- **Un test doit prouver le mécanisme qu'il prétend vérifier** (revue de 2.1, correction 8 : le dash « évitait » les coups parce qu'il sortait le joueur de la trajectoire, pas grâce à l'invulnérabilité). Ici, plusieurs mécanismes se recouvrent (le joueur mort s'arrête **et** `Main` fige la partie ; le clignotement ne touche plus `visible` **et** le joueur mort ne tourne plus) : chaque contrôle de la « Stratégie de test » isole le sien. Le dire dans les notes de complétion.
- **Typage strict, avertissements en erreur.** Le résultat d'un `Callable.call()` ou d'un `get()` est un `Variant` : `is` avant usage ; `as` sur un `Variant` → `UNSAFE_CAST` (erreur). Une variable `@onready` jamais lue déclenche un avertissement : ne pas déclarer de `@onready` pour `Transition` si `main.gd` ne s'en sert pas.
- **Injection** : `setup()` avant `add_child()` ; signaux locaux vers le parent ; pas de `/root/...` ni `get_parent().get_parent()`. Composants créés en code avec un `name` explicite.
- **Calculer la valeur sûre avant de journaliser**, ne jamais planter (AR28) : `setup()` oublié → `Log.error` + `assert`, le reste continue.
- **Ticks** : compteurs en ticks de physique, pas de `Timer`, `create_timer`, `Tween` en temps réel. **Attention** : derrière l'écran de réveil `GameClock.paused` est vrai, donc `GameClock.scale()` vaut 0 : la garde de l'écran de réveil compte des ticks **bruts** (c'est de l'interface, pas du gameplay).
- **Vérifications** : `godot --headless --path game --import`, puis `godot --headless --path game --quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau. Scènes du scratchpad (`--scene res://.scratch/<scène>.tscn`, car `--script` ne résout pas les autoloads). `Input.parse_input_event()` s'applique **au tick suivant**. Scripts de test : `preload()` (pas de `class_name` vu depuis un dossier caché), `@warning_ignore_start(...)` pour les `unsafe_*` des scripts jetables seulement.
- **En headless** : `Input.mouse_mode`, mode de fenêtre et VSync sans effet, audio factice ; **`DisplayServer.keyboard_get_label_from_physical()` et `keyboard_get_keycode_from_physical()` impriment `ERROR: Not supported by this display server.`** (sonde à la création) : ne pas les utiliser pour le libellé de la touche (voir « Écran de réveil »).
- **Fichiers générés par Godot** : versionner les `.uid` des nouveaux scripts, le `.csv.import` inchangé, le `strings.fr.translation` régénéré.

### `Health` (CA 4)

`combat/health.gd`, dans `apply_damage()`, branche du coup mortel : émettre `changed` **puis** `died`, pour que tout auditeur de `died` lise un état complet et déjà notifié :

```gdscript
	if half_hearts <= 0:
		_dead = true
		_hit_ticks_left = 0.0
		changed.emit()
		died.emit()
	else:
		_hit_ticks_left = _hit_ticks
		changed.emit()
	return taken_armor + taken_hearts
```

Mettre à jour la doc du signal `died` (« Emitted once, after changed, when half-hearts reach 0 »). Rien d'autre ne change dans `Health`.

### Joueur (CA 2, 4, 5, 6)

`player/player.gd` :

- **Signal local** :

```gdscript
## Emitted once, when the player dies: after the Events.player_hit of the lethal hit. The Run listens.
signal died
```

- **Ne plus écouter `health.died`** : retirer `health.died.connect(_on_health_died)` et `_on_health_died()`. `Health.died` part *pendant* `apply_damage()`, donc avant que le joueur ait émis `Events.player_hit` ; c'est le gestionnaire de coup qui traite la mort, après le `player_hit` :

```gdscript
func _on_hurtbox_damage_received(info: DamageInfo) -> void:
	var lost: int = health.apply_damage(info)
	if lost <= 0:
		return
	Events.player_hit.emit(lost, info.source)
	Audio.play_sfx(HIT_SOUND)
	Log.debug("combat", "player hit lost=%d hearts=%d armor=%d source=%d" % [...])
	if health.is_dead():
		_die(info.source)
```

  Tout dégât passe par `Hurtbox.receive()` → ce gestionnaire (architecture, « Dégâts et unités » ; la commande −½ cœur de F1 aussi) : il n'existe pas d'autre chemin de mort. Commentaire en tête de `_on_hurtbox_damage_received` : « death is handled here, after player_hit, not on Health.died (emitted inside apply_damage()) ».
- **`_die(source)`** (une seule fois : `health.is_dead()` ne redevient jamais faux, et `apply_damage()` renvoie 0 sur un mort, donc on n'y repasse pas ; garder malgré tout un drapeau `_death_handled` contre un double appel) :
  1. `set_physics_process(false)` et `velocity = Vector2.ZERO` : plus de marche, de dash ni de tir, même si personne ne fige la partie (CA 5, `Run` isolé) ;
  2. `_sprite.visible = false` : le dormeur disparaît en se réveillant (repère visuel provisoire, voir les décisions) ;
  3. `Log.debug("combat", "player died source=%d" % source)` (le `Log.info` de la mort est celui de `Run`, catégorie `run`, CA 3 : pas de double `INFO`) ;
  4. `died.emit()`.
- **`_update_blink()`** (CA 6) : n'écrire `visible` qu'aux transitions. Un booléen `_blinking` :

```gdscript
func _update_blink() -> void:
	var blinking: bool = health.is_hit_invulnerable()
	if not blinking:
		if _blinking:
			_blinking = false
			_sprite.visible = true # the blink just ended: show the sprite once, never every tick
		return
	_blinking = true
	var elapsed: float = health.hit_ticks_total() - health.hit_ticks_left()
	_sprite.visible = int(elapsed / BLINK_HALF_PERIOD_TICKS) % 2 == 1
```

  Mettre à jour le commentaire de la fonction. Le comportement 2.1 (demi-période de 6 ticks, sprite caché les 6 premiers ticks, visible à la fin, figé en pause, ralenti sous F4) est inchangé.
- Rien d'autre ne change (`health`, `hurtbox`, `equip_bullets()`, réticule, son, teinte du dash). `Player` reste instancié depuis `player.tscn`, désormais par `run.tscn`.

### `Run` (AR8, AR20, D3, D14, CA 1 à 5)

`run/run.gd`, `class_name Run extends Node`, et `run/run.tscn` (nœud racine `Run`, `Node`) :

```
Run (Node, run.gd)
├── Player   (instance de res://player/player.tscn, unique_name_in_owner)
└── RoomSlot (Node, unique_name_in_owner)   — la salle active ; vide dans le .tscn
```

- **`Player` avant `RoomSlot`** dans l'arbre (architecture D14) : il fait son `_ready()` (santé, hurtbox) avant que l'arène ne s'en serve. L'ordre de dessin est rétabli par le décor en `z_index` négatif (voir « Arène »).
- `RoomSlot` est un `Node` simple (pas de transformation : l'arène reste à l'origine du monde, ce que le `BulletManager` exige).
- **État de run** (D3 : « l'état de la run vit dans un nœud `Run` ») : rien d'autre qu'un drapeau `_ended` dans cette story (pas de seed, d'Éclats ni d'étage avant les epics 4 et 5).
- **API** :

```gdscript
class_name Run
extends Node
## One night: the player and the active room (RoomSlot). Destroyed and recreated by Main on restart (AR20).
## Holds the run state (only "has it ended" for now). Notifies the end of the run on Events.run_ended.

## How a run ended. Values are explicit because they travel as ints on Events.run_ended:
## new outcomes are appended at the end (VICTORY: story 6.4).
enum Outcome { DEATH = 0 }

## Kept in the resource cache for the whole session: Main preloads run.tscn, which preloads this (AC 3).
const ARENA_SCENE: PackedScene = preload("res://rooms/arena/arena.tscn")

var _ended: bool = false

@onready var _player: Player = %Player
@onready var _room_slot: Node = %RoomSlot
```

- **`_ready()`** :
  1. `var arena: Arena = ARENA_SCENE.instantiate() as Arena` (`PackedScene.instantiate()` renvoie un `Node` : `as` sur un `Node` n'est pas un `UNSAFE_CAST`) ; nul → `Log.error("run", ...)` + `assert`, `return` ;
  2. `arena.setup(_player)` **avant** `_room_slot.add_child(arena)` (injection) ;
  3. `_player.global_position = arena.player_spawn_position()` puis `_player.reset_physics_interpolation()` (le joueur ne traîne pas depuis (0, 0)) ;
  4. `_player.died.connect(_on_player_died)` ;
  5. `Log.info("run", "run started")` (pas de seed : `RunRng` arrive avec l'epic 4 ; AR27 « seed journalisée » est reporté, voir les décisions).
- **`_on_player_died()`** : `if _ended: return` ; `_ended = true` ; `Log.info("run", "run ended outcome=death")` ; `Events.run_ended.emit(Outcome.DEATH)`.
- `autoloads/events.gd` :

```gdscript
## A run ended. outcome: Run.Outcome as an int (autoloads/ depends on no feature folder).
## Emitted once per run, after the Events.player_hit of the lethal hit. Listeners: Main (wake screen),
## telemetry (story 2.8).
@warning_ignore("unused_signal")
signal run_ended(outcome: int)
```

### Arène (CA 1, 10)

`rooms/arena/arena.tscn` : **retirer le nœud `Player`** (et l'`ext_resource` de `player.tscn`, `load_steps` ajusté ; ou laisser Godot réécrire la scène). Le reste de la scène est inchangé.

`rooms/arena/arena.gd` :

- `var _player: Player` remplace `@onready var _player: Player = %Player`.
- **`setup(player: Player) -> void`** (« Dependency injection: call before add_child() »). `_ready()` sans joueur : `Log.error("room", "arena added without setup()")` + `assert`, construire quand même les tuiles et la caméra, mais ni `equip_bullets()` ni `register_hurtbox()` (rien qui déréférence `null`).
- **Ne plus placer le joueur** dans `_ready()` (le joueur n'est pas un enfant de la salle) : exposer

```gdscript
## Where the player enters the arena (center of the playable area), in global coordinates.
func player_spawn_position() -> Vector2:
	var frame_px: Vector2 = Vector2((Const.ROOM_TILES + Vector2i(2, 2)) * Const.TILE_SIZE)
	return to_global(frame_px / 2.0)
```

  (même point qu'aujourd'hui, (304, 168)) ; `Run` place le joueur.
- **Décor sous les entités** (CA 10, AR19) : dans `_ready()`, `_floor.z_index = Const.Z_INDEX_DECOR` et `_walls.z_index = Const.Z_INDEX_DECOR`. Nouvelle constante dans `core/constants.gd` :

```gdscript
## z_index of the decor layers (floor, walls): drawn below the entities whatever their place in the tree.
## The player lives in Run, outside the room (story 2.2); entities, bullets and the HUD stay at 0 or above (AR19).
const Z_INDEX_DECOR: int = -1
```

  Ordre obtenu (tri par `z_index`, puis ordre de l'arbre, sur le même canevas puisque `Run` et `RoomSlot` sont des `Node` simples ; documentation `CanvasItem` 4.7 vérifiée à la création) : `Floor`, `Walls` (−1), puis à 0 `Player`, `Targets`, `PlayerBullets`, `EnemyBullets`, `DamageNumbers` ; le réticule (`top_level`, `z_index` 100) au-dessus. Seul changement visible : une cible est désormais dessinée par-dessus le joueur quand ils se chevauchent (même couche Entités, sans conséquence).
- Mettre à jour le commentaire d'en-tête de la classe (« the player » n'est plus un enfant : « the player is given by the Run through setup() »). Le reste (`_setup_player_bullets()`, `_setup_enemy_bullets()`, caméra, tuiles, `Log.info("room", ...)`) est inchangé.

### Écran de réveil (FR15, AR22, CA 2, 3, 7, 8)

**Entrée** : action `restart` dans `project.godot`, touche R (`InputEventKey`, `physical_keycode` 82), même forme sérialisée que `pause`. Pas d'événement de manette : à la manette, le bouton A (`ui_accept` par défaut) presse le bouton focalisé (voir les décisions). Puis `--import` et vérifier qu'aucun bruit parasite n'apparaît dans `project.godot`.

**Scène** : `ui/menus/wake_screen.tscn` + `ui/menus/wake_screen.gd` (`class_name WakeScreen extends Control`), **même structure que `pause_menu.tscn`** : racine plein écran, `Dim` (`ColorRect` noir, α 0,6, `mouse_filter` par défaut : il bloque les clics vers le jeu), `CenterContainer` > `PanelContainer` > `VBoxContainer` > `%Title` (`Label`, centré) et `%RestartButton` (`Button`). Caché au départ. Pas de `process_mode` particulier : sous `UI`, il n'est pas touché par le gel d'`ActiveScene`.

```gdscript
class_name WakeScreen
extends Control
## Wake-up screen shown by Main when a run ends (death). The restart key or the button asks Main for a new run.
## Inputs are ignored for a short guard so a held or mashed key at the moment of death cannot skip it.
## The game behind is frozen by Main (GameClock.paused): the guard counts raw physics ticks, not GameClock time.
## Texts come from tr() (localization/strings.csv), never from the scene.

signal restart_requested

## Input guard after the screen opens, in seconds (UI placeholder, not a gameplay value).
const INPUT_GUARD_SECONDS: float = 0.3
```

- **`_ready()`** : `_title.text = tr(&"UI_WAKE_TITLE")` ; `_restart_button.text = tr(&"UI_WAKE_RESTART") % _restart_key_label()` ; `pressed` → `_request_restart()` ; `hide()`.
- **`_restart_key_label() -> String`** : premier `InputEventKey` de `InputMap.action_get_events(&"restart")` → `as_text_physical_keycode()` (« R » ; fonctionne en headless, contrairement à `DisplayServer.keyboard_get_label_from_physical()`, sonde à la création) ; aucune touche → `Log.error("ui", ...)` + `assert`, renvoyer `"?"`. Libellé de la disposition QWERTY : identique pour R en AZERTY ; l'invite selon le périphérique et la disposition est la story 1.7 (report).
- **`open()`** : `show()` ; `_guard_ticks_left = INPUT_GUARD_SECONDS * Engine.physics_ticks_per_second` ; `_armed = false` ; `_restart_button.disabled = true` ; `_restart_button.grab_focus()`.
- **`_physics_process(_delta)`** : si visible et pas armé : décrémenter `_guard_ticks_left` de **1** par tick (ticks bruts : `GameClock` est en pause derrière l'écran) ; à ≤ `1e-6` : `_armed = true`, `_restart_button.disabled = false`. Aucun log par tick.
- **`_unhandled_input(event)`** : si visible, armé, et `event.is_action_pressed(&"restart")` (sans répétition) → `get_viewport().set_input_as_handled()` puis `_request_restart()`. Ne consommer ni `pause` ni `ui_cancel` (`Main` les ignore pendant l'écran, voir « `Main` »).
- **`_request_restart()`** : `if not visible or not _armed: return` ; `_armed = false` (pas de double demande) ; `restart_requested.emit()`. `Main` cache l'écran.
- Pendant la garde, le bouton désactivé garde le focus mais ne réagit ni à `ui_accept` ni au clic (doc `BaseButton.disabled` 4.7) ; après la garde, Entrée, Espace, A ou un clic le pressent.
- **Textes** (`localization/strings.csv`, puis `--import` qui régénère `strings.fr.translation`) :

```csv
UI_WAKE_TITLE,Tu te réveilles.
UI_WAKE_RESTART,Se rendormir (%s)
```

  Aucun texte en dur dans la scène ni le script. Vérifier les accents à l'écran (police Pixel Operator, déjà validée pour « Réglages »).

### `Main` (AR20, D7, D14, CA 1, 3, 7)

`main/main.tscn` : ajouter `Transition` (`CanvasLayer`, `unique_name_in_owner = true`, `layer = 2`, au-dessus d'`UI`), **vide** dans cette story (fondus : 4.8). Ne pas le référencer depuis `main.gd` (variable inutilisée = avertissement).

`main/main.gd` :

- `const RUN_SCENE: PackedScene = preload("res://run/run.tscn")` (remplace `ARENA_PATH`). Ce `preload` garde `run.tscn`, donc `run.gd` et sa constante `ARENA_SCENE`, donc `arena.tscn`, dans le cache des ressources toute la session (doc `Resource` 4.7 : une ressource reste en cache tant qu'une référence existe) : c'est le « les ressources de l'arène restent en cache » du CA 3, sans chargement en tâche de fond (4.8). Le test de charge reste chargé par `load()` dans la branche debug.
- `const WAKE_SCREEN_SCENE: PackedScene = preload("res://ui/menus/wake_screen.tscn")` ; `_setup_menus()` l'instancie et l'ajoute à `UI` **avant** le menu de pause et les réglages (les menus restent dessinés au-dessus) ; `restart_requested` → `_on_wake_screen_restart_requested`.
- `_ready()` : `Events.run_ended.connect(_on_events_run_ended)` ; `_start_run()` remplace `_show_scene(ARENA_PATH)`.
- **État** : `var _run_over: bool = false` (vrai pendant l'écran de réveil) ; `var _run_ended_msec: int = 0`.
- **`_freeze(frozen: bool)`** : le seul code qui écrit `GameClock.paused` et `ActiveScene.process_mode` (ensemble, comme aujourd'hui). `_set_paused()` l'appelle au lieu d'écrire lui-même ; mettre à jour le commentaire « The only place that pauses… » en conséquence (« only Main freezes the game: pause and wake screen »).
- **`_set_paused(value, reason)`** : nouvelle première ligne `if _run_over: return` (la pause et la perte du focus n'ouvrent pas le menu par-dessus l'écran de réveil, CA 7) ; le reste est inchangé.
- **`_on_events_run_ended(outcome: int)`** : `if _run_over: return` ; `_run_over = true` ; `_run_ended_msec = Time.get_ticks_msec()` ; `_freeze(true)` ; `_wake_screen.open()`. `outcome` n'est pas lu (une seule issue ; préfixer `_outcome` pour éviter l'avertissement de paramètre inutilisé). **Synchrone** : le gel arrive pendant le tick du `BulletManager` qui a livré le coup mortel ; sonde à la création (4.7.2) : aucune erreur moteur en désactivant un ancêtre de `CharacterBody2D` et d'`Area2D` depuis un `_physics_process` de priorité 100, et les nœuds suivants de ce tick (priorité 101) ne tournent pas. Le gel par la touche 3 de F1 (pendant l'entrée) marche de la même façon.
- **`_on_wake_screen_restart_requested()`** : `Log.info("run", "restart requested %d ms after the end of the run" % (Time.get_ticks_msec() - _run_ended_msec))` ; `_start_run()`.
- **`_start_run()`** : `_wake_screen.hide()` ; `_run_over = false` ; `_freeze(false)` **avant** d'ajouter la nouvelle partie (sonde : un nœud ajouté sous un parent désactivé ne reçoit pas `NOTIFICATION_DISABLED`, il ne recevrait qu'un `ENABLED` plus tard ; le réticule du nouveau joueur doit entrer dans un arbre actif) ; `_show_scene(RUN_SCENE)` ; `_load_test_active = false`. `_show_scene()` prend désormais une `PackedScene` (retrait immédiat de l'ancien enfant, puis `queue_free`, puis ajout : comportement inchangé). `_freeze(false)` alors que l'ancien `Run` est encore là le réactive un instant sans tick (tout est synchrone) : sans effet, il est retiré juste après.
- **F5** : `wants_load_test` → `load(BULLET_LOAD_TEST_PATH) as PackedScene` puis `_show_scene()` ; retour → `_start_run()`. Le basculement reste ignoré en pause **et donc pendant l'écran de réveil** (`GameClock.paused` vrai : garde existante, CA 7). Abandonner une partie par F5 n'émet pas `run_ended` (ce n'est pas une fin de partie).
- `_unhandled_input()` : `pause` appelle `_set_paused(true)`, qui ne fait rien pendant l'écran (garde `_run_over`) ; garder `set_input_as_handled()`.

### Panneau F1 (CA 9)

- `combat/bullets/bullet_manager.gd` : accesseur en lecture seule

```gdscript
## True when this hurtbox is registered (register_hurtbox()) and still in the hit tests.
func has_hurtbox(hurtbox: Hurtbox) -> bool:
	return _targets.has(hurtbox)
```

- `debug/debug_panel.gd`, `_find_enemy_manager(player)` : premier `BulletManager` du groupe, de camp `ENEMY`, tel que `manager.has_hurtbox(player.hurtbox)` (« the enemy manager that can hit this player ») ; mettre à jour le commentaire. Indépendant de l'arbre (`Run`, `RoomSlot`, et les salles de l'epic 4). Le test de charge (manager ennemi sans joueur) reste exclu : il n'y a pas de joueur.
- Rien d'autre ne change. Comportement attendu (à consigner, pas à corriger) : le tir automatique (touche 5) **continue** sur la nouvelle partie après une relance ; derrière l'écran de réveil il n'accumule rien (`GameClock.scale()` nul) et les touches 1 à 5 sont ignorées (`GameClock.paused`).

### Règles d'architecture qui s'appliquent

- GDScript typé partout (AR2) ; fichiers et dossiers en `snake_case`, un script par classe, nœud racine d'une scène en `PascalCase` (`run.tscn` → `Run`, `wake_screen.tscn` → `WakeScreen`), constantes `UPPER_SNAKE_CASE`, membres privés `_`, signaux au passé (`died`, `run_ended`, `restart_requested`), gestionnaires `_on_<émetteur>_<signal>` (`_on_player_died`, `_on_events_run_ended`, `_on_wake_screen_restart_requested`). Code, commentaires, logs et noms de fichiers **en anglais**.
- **Communication** (D3) : `Player` → `Run` par signal local (`died`) ; `Run` → transverse par `Events.run_ended` (notification, pas un ordre : `Main` décide d'afficher l'écran) ; `WakeScreen` → `Main` par signal local ; `Main` → `Run` : remplacement par `_show_scene()`. Pas de `/root/`, pas de `get_parent().get_parent()`.
- **Scènes** (D14, AR20) : `Main` persiste ; `ActiveScene` contient un seul `Run` ; la relance détruit le `Run` et en crée un neuf ; une seule salle active (`RoomSlot`).
- **Temps** (AR13, D7) : seul `Main` écrit `GameClock.paused` et `ActiveScene.process_mode` (`_freeze()`), jamais `SceneTree.paused`, jamais `Engine.time_scale` ; pas de `Timer` ni de `create_timer` (la garde de l'écran compte des ticks).
- **Frontières** : `autoloads/` et `core/` ne dépendent d'aucun dossier de fonctionnalité (`run_ended` porte un `int`) ; `ui/` ne modifie pas l'état de gameplay (l'écran de réveil émet une demande, `Main` agit) ; rien ne dépend de `debug/`.
- **Textes** (AR22, NFR10) : `tr()` pour tout texte de l'écran de réveil, clés dans `strings.csv`.
- **Logs** (AR27) : `Log.info("run", "run started")`, `Log.info("run", "run ended outcome=death")`, `Log.info("run", "restart requested ...")` ; `Log.debug` pour la mort côté joueur ; rien par tick.
- **Erreurs** (AR28) : `setup()` oublié, scène introuvable, action sans touche → `Log.error` + `assert`, valeur sûre, jamais de plantage en release.
- **Données** (AR9) : aucune nouvelle valeur du GDD (« moins de 3 s » est une exigence mesurée, pas un réglage). La garde de 0,3 s et l'opacité du fond sont des valeurs d'interface, constantes locales commentées.

### Arborescence attendue à la fin de la story

```
game/
├── project.godot                         (UPDATE : action restart, R)
├── autoloads/events.gd                   (UPDATE : run_ended)
├── core/constants.gd                     (UPDATE : Z_INDEX_DECOR)
├── combat/
│   ├── health.gd                         (UPDATE : changed avant died)
│   └── bullets/bullet_manager.gd         (UPDATE : has_hurtbox())
├── player/player.gd                      (UPDATE : died, _die(), ordre, clignotement aux transitions)
├── run/
│   ├── run.tscn                          (NEW : Run > Player, RoomSlot)
│   └── run.gd                            (NEW, + .uid)
├── rooms/arena/
│   ├── arena.tscn                        (UPDATE : sans Player)
│   └── arena.gd                          (UPDATE : setup(), player_spawn_position(), décor en z négatif)
├── ui/menus/
│   ├── wake_screen.tscn                  (NEW)
│   └── wake_screen.gd                    (NEW, + .uid)
├── localization/
│   ├── strings.csv                       (UPDATE : UI_WAKE_TITLE, UI_WAKE_RESTART)
│   └── strings.fr.translation            (régénéré)
├── main/
│   ├── main.tscn                         (UPDATE : Transition)
│   └── main.gd                           (UPDATE : Run, gel, écran de réveil, relance)
└── debug/debug_panel.gd                  (UPDATE : manager trouvé par has_hurtbox())
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (T1) et `deferred-work.md` (T11). Ne pas toucher à `hurtbox.gd`, `damage_info.gd`, `dash.gd`, `reticle.gd`, `training_target.gd`, `hit_feedback.gd`, `damage_numbers.gd`, `bullet_load_test.gd`, aux autoloads autres qu'`events.gd`, au menu de pause ni aux réglages.

### Stratégie de test

Aucun framework de test (AR26 : avant le jalon B). Scripts jetables du scratchpad, lancés comme scène (`godot --headless --path game --scene res://.scratch/<scène>.tscn`), avec `await get_tree().physics_frame` pour avancer au tick. Pour la partie complète, instancier `main.tscn` sous la scène de test ; joueur par le groupe `player`, `Run` par `ActiveScene.get_child(0)`. **Chaque contrôle dit quel mécanisme il isole** (leçon de 2.1).

1. **Import et lancement** : `--import` puis `--quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau (seul `settings.cfg missing` est déjà connu) ; `project.godot` sans bruit parasite ; `strings.fr.translation` régénéré.
2. **Structure** (CA 1) : `Main` > `ActiveScene` a un seul enfant, de classe `Run` ; `Run` a `Player` (premier) et `RoomSlot` ; `RoomSlot` a un seul enfant, de classe `Arena` ; l'arène n'a **aucun** `Player` parmi ses descendants ; `UI` et `Transition` sont des `CanvasLayer` enfants de `Main`, `Transition.layer > UI.layer` ; le joueur est à (304, 168) ; `Floor.z_index == Walls.z_index == Const.Z_INDEX_DECOR` ; `Log` « run started » une fois.
3. **`Health` seule** (CA 4) : coup mortel → ordre enregistré `[changed, died]`, une fois chacun ; coup non mortel → `[changed]` seulement.
4. **Mort dans la partie** (CA 2, 4, 5), dans `main.tscn` :
   - amener le joueur à ½ cœur (coup de 5 par `hurtbox.receive()`, source `DEBUG`), attendre la fin de l'invulnérabilité (≥ 60 ticks), puis **un vrai projectile ennemi** (`EnemyBullets.fire()`, apparence ajoutée par le test, `damage = Tuning.COMBAT.hit_damage_half_hearts`) → au tick du contact : mort ;
   - **ordre** : connecter `player.health.changed`, `Events.player_hit`, `player.died`, `Events.run_ended` à un enregistreur → `[changed, player_hit, died, run_ended]`, une fois chacun, au même tick (`Engine.get_physics_frames()` identique) ; `run_ended` reçu avec `Run.Outcome.DEATH` ;
   - **un seul `run_ended`** : refaire avec deux projectiles mortels au même tick (même origine, même direction, joueur à ½ cœur) → un seul `run_ended`, un seul `died` ;
   - logs : « run ended outcome=death » une fois (catégorie `run`), aucun `INFO` « player died » en `combat` ;
   - écran de réveil visible, bouton désactivé, `GameClock.paused == true`, `ActiveScene.process_mode == PROCESS_MODE_DISABLED`, `get_tree().paused == false`, `Engine.time_scale == 1.0` ;
   - sprite du joueur masqué.
5. **Gel par `Main`** (CA 7) — isole le gel, pas l'arrêt du joueur : un projectile ennemi **déjà en vol** au moment de la mort (tiré vers un mur, loin du joueur) garde exactement sa position pendant 60 ticks d'écran de réveil (`EnemyBullets` figé) ; une cible flashée juste avant garde son paramètre `flash`. Puis, pendant l'écran : action `pause` → menu de pause **caché**, `_run_over` inchangé ; `NOTIFICATION_APPLICATION_FOCUS_OUT` → menu caché ; F5 → l'`ActiveScene` contient toujours le même `Run` ; F4 → `global_multiplier` inchangé ; F1 visible + touche 4 → `EnemyBullets.active_count` inchangé ; F1 et F3 eux-mêmes basculent.
6. **Arrêt du joueur mort** (CA 5) — isole `_die()`, pas le gel : instancier `run.tscn` **seul** sous la scène de test (sans `Main` : rien ne fige), tuer le joueur, puis tenir `move_right` et `shoot` 30 ticks → position inchangée, `PlayerBullets.active_count` inchangé, `is_physics_processing() == false`, sprite masqué tout du long ; `Events.run_ended` reçu une fois.
7. **Clignotement aux transitions** (CA 6) — isole `_update_blink()`, pas la mort : joueur vivant, hors invulnérabilité, masquer le sprite depuis le test (`player.get_node("Sprite")`), avancer 10 ticks avec le joueur actif → **toujours masqué** (l'ancien code le rendait visible au tick suivant) ; puis un coup → alternance de 6 ticks comme en 2.1 ; à la fin de l'invulnérabilité → `visible == true` une fois, et un masquage posé ensuite tient de nouveau 10 ticks.
8. **Relance** (CA 3, 8, 9, 11) :
   - **garde** : 5 ticks après l'ouverture, action `restart` puis `ui_accept` → rien (même `Run`, écran visible) ; une fois la garde écoulée (0,3 s = 18 ticks comptés à partir du tick qui suit la mort, plus le tick d'application de l'entrée ; relever le nombre exact) action `restart` → relance ;
   - **relance par le bouton** : refaire une mort, après la garde, `ui_accept` (bouton focalisé) → relance ; puis une troisième mort, clic simulé (`pressed` émis par `InputEventMouseButton` sur le bouton, ou `_restart_button.pressed.emit()` en dernier recours, à consigner) → relance ;
   - après la relance : l'ancien `Run` n'est plus dans l'arbre et est libéré à l'image suivante (`is_instance_valid()` faux) ; un **nouveau** `Run` (autre `instance_id`) ; nouveau joueur à 6/6, armure 0, à (304, 168), sprite visible, `is_physics_processing()` ; écran caché ; `GameClock.paused == false`, `ActiveScene` en `PROCESS_MODE_INHERIT` ; logs `run` : « restart requested … ms … » puis « run started » ;
   - **le jeu repart** — isole le dégel : `move_right` tenu 10 ticks → le nouveau joueur avance ; un tir touche une cible (`Events.enemy_damaged` une fois) ; action `pause` → menu de pause ouvert (la garde `_run_over` est levée), reprise ; F4 et F5 marchent de nouveau ;
   - **moins de 3 s** (NFR3) : ticks entre `Events.run_ended` et le `_ready()` du nouveau `Run` quand `restart` est pressé dès la fin de la garde → ≤ 180 (attendu : ≈ 19 à 20) ; temps réel de `_start_run()` mesuré par `Time.get_ticks_usec()` autour de l'appel (attendu : quelques ms en headless ; consigner la valeur) ;
   - **cache** (CA 3) — prouve l'absence de rechargement, pas seulement la présence : `load("res://rooms/arena/arena.tscn").get_instance_id()` et `load("res://run/run.tscn").get_instance_id()` identiques avant la première mort et après la troisième relance, et `ResourceLoader.has_cached()` vrai pour les deux à tout moment ;
   - **F1 sur la nouvelle partie** (CA 9) — prouve le nouveau mécanisme (joueur dans `Run`, manager dans l'arène : l'ancienne règle du parent partagé échouerait) : touche 4 → `EnemyBullets.active_count` +3 du **nouveau** manager ; touche 3 → `Events.player_hit` source `DEBUG` ; F5 (test de charge) puis touche 4 → « no player » ; F5 retour → nouvelle partie, touche 4 marche ;
   - **pas de fuite** (CA 11) : cinq cycles mort → relance ; `Performance.get_monitor(Performance.OBJECT_NODE_COUNT)` identique après le 1er et le 5e cycle (mesuré une image après la relance, `queue_free` traité), `OBJECT_ORPHAN_NODE_COUNT` à 0, `Events.enemy_damaged.get_connections().size()` stable, `Events.run_ended.get_connections().size() == 1`.
9. **Localisation** : avec `TranslationServer.set_locale("en")` puis `"fr"`, `tr(&"UI_WAKE_TITLE") == "Tu te réveilles."` ; texte du bouton `"Se rendormir (R)"` ; recherche de chaînes littérales françaises dans `game/ui/` et `game/run/` : aucune.
10. **Fenêtré sous WSLg** (indicatif, captures `get_viewport().get_texture().get_image().save_png()`) : écran de réveil lisible et centré à ×2, accents corrects, focus visible sur le bouton, bouton grisé pendant la garde puis actif ; curseur système visible sur l'écran, caché de nouveau dans la nouvelle partie (réticule visible) ; **ordre de dessin** : joueur au-dessus du sol (pas caché par `Floor`), projectiles de test (F1, touche 4) dessinés au-dessus du joueur, chiffres de dégâts au-dessus des tirs ; F1 et F3 toujours lisibles au-dessus de l'écran de réveil ou non (consigner).
11. **Régression** : marche (96 px/s), dash (48 px), tir (4 tirs/s, 224 px/s), coups et invulnérabilité de 2.1 (un coup → 5/6, second projectile qui traverse, clignotement 6 ticks), chiffres de dégâts, pause et réglages, F2 (hurtbox et hitbox du joueur affichées dans le `Run`), F3, F4, F5 aller-retour et `Bullets 400 | refused 0`.
12. **Recherche des interdits** : `grep -rnE 'print\(|Timer|create_timer|time_scale|tree\(\)\.paused|randf|randi|randomize|shuffle|pick_random|/root/|get_parent\(\)\.get_parent' game --include=*.gd` : seules les occurrences attendues (`log.gd`, commentaires). Aucun `Log.` dans `_process` ni `_physics_process` ; `GameClock.paused` écrit seulement dans `main.gd` (`_freeze()`).
13. **Étapes humaines** (à consigner `NON ÉVALUÉ` / `NON VÉRIFIÉ` dans la story et `deferred-work.md`, ne pas déclarer vérifiées) : ressenti de la relance (rythme mort → écran → nouvelle partie, garde de 0,3 s, disparition du sprite) ; texte et lisibilité de l'écran de réveil ; relance en moins de 3 s sur la machine de référence et en export (story 1.8) ; bouton A sur une vraie manette (story 1.7) ; invite « (R) » affichée aussi aux joueurs à la manette (story 1.7).

### Commit

Directement sur `main`, Conventional Commits en anglais, `git push` après chaque commit (consigne du projet). Commiter par tâche cohérente, chaque commit laissant le jeu lançable. Exemples : `docs(architecture): add run and wake screen terms to the lexicon` ; `fix(combat): emit the lethal hit before the death` ; `feat(run): host the player and the arena in a run node` ; `feat(ui): add the wake screen and restart a new run` ; `fix(debug): find the enemy bullet manager by the player's hurtbox` ; `docs(story): record story 2.2 implementation progress`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `run/run.tscn/.gd`, `ui/menus/` pour l'écran de réveil (« menus/ — pause, death… »), `Transition` sous `Main`.
- **Écarts assumés** :
  - `main/transition.tscn/.gd` n'est pas créé : `Transition` est un `CanvasLayer` vide dans `main.tscn` (aucune transition avant la 4.8).
  - L'écran de réveil s'appelle `wake_screen` (et non `death`) : il servira aussi à la victoire (6.4) ; terme ajouté au lexique.
  - Le joueur est un enfant de `Run`, à côté de `RoomSlot` (D14), et non dans `RoomSlot` comme une lecture littérale du CA 1 pourrait le laisser croire (voir les décisions).
  - Couches de décor en `z_index` négatif plutôt que des `CanvasLayer` par couche : les couches de rendu complètes (distorsion, D13) viennent avec l'epic 3 et la 7.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md`, de la mémoire du projet et du brief du pipeline :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit, et la ligne `Co-Authored-By` (modèle réellement utilisé) en fin de message.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (`UI_WAKE_*` dans `strings.csv`).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.
- Pipeline automatisé de l'epic 2 : Kroustille n'est pas disponible avant la fin de l'epic ; toute question se tranche et se consigne ci-dessous.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Où vit le joueur** — Question : le CA 1 dit « avec le joueur et l'arène dans `RoomSlot` ». Choix : `Run` > `Player`, `RoomSlot` > arène. Raison : l'architecture (D14, « Gestion de l'état ») place le joueur sous `Run`, « conservé d'une salle à l'autre » ; le mettre dans `RoomSlot` serait à défaire au changement de salle (4.8).
2. **Arène sans joueur propre** — Choix : `Arena.setup(player)` avant `add_child`, `player_spawn_position()` lu par `Run`, qui place le joueur. Raison : injection (architecture, « Création d'entités ») ; le joueur n'est pas un enfant de la salle, c'est son parent (`Run`) qui le déplace.
3. **Ordre de dessin** — Choix : `Floor` et `Walls` en `z_index` = `Const.Z_INDEX_DECOR` (−1). Raison : avec le joueur hors de la salle, l'ordre de l'arbre seul mettrait soit le sol sur le joueur, soit le joueur sur les projectiles ; AR19 met le décor tout en bas.
4. **`Events.run_ended(outcome: int)`** et `Run.Outcome { DEATH = 0 }` aux valeurs explicites — Raison : types primitifs sur le bus (comme `player_hit`) ; la victoire (6.4) s'ajoutera en fin d'enum sans renuméroter (leçon de la revue de 2.1).
5. **`Main` écoute `Events.run_ended`** (pas de signal local `Run` → `Main`) — Raison : la fin de run est une notification transverse (télémétrie 2.8, progression plus tard) ; `Main` y réagit comme les autres, sans second chemin.
6. **Ordre du coup mortel** — Choix : `Health.changed` → `Health.died` (dans `apply_damage()`), puis côté jeu `Events.player_hit` → `Player.died` → `Events.run_ended`. Le joueur traite sa mort à la fin de son gestionnaire de coup et n'écoute plus `Health.died`. Raison : report de 2.1 ; la télémétrie (2.8) lira la source du dernier `player_hit` avant `run_ended` ; `Health` reste générique pour les ennemis.
7. **L'écran de réveil attend le joueur** (pas de relance automatique) ; « moins de 3 s après la mort » = garde de 0,3 s + chargement d'une image, si le joueur relance aussitôt. Raison : FR15 « l'écran du réveil peut se passer » ; la 2.8 y pose une question et la 6.5 y rattache le retour à la chambre, ce qu'une relance automatique empêcherait.
8. **Partie figée derrière l'écran** (`GameClock.paused` + `ActiveScene` désactivé, par `Main`), pause, perte du focus, F4, F5 et commandes de F1 ignorées — Raison : un mort ne doit plus rien subir ni faire, et le menu de pause par-dessus l'écran rouvrirait la partie à la reprise ; la garde existante « debug ignoré en pause » couvre F4, F5 et F1 sans code de plus.
9. **Garde de 0,3 s** avant d'accepter une relance (ticks bruts, constante d'interface) — Raison : Espace (dash) est aussi `ui_accept`, et un clic tenu au moment de la mort ne doit pas passer l'écran ; la 2.8 ajoutera une question à ne pas sauter par erreur.
10. **Deux façons de relancer, même effet** : action `restart` (R, sans événement de manette) et bouton focalisé « Se rendormir (R) » (Entrée, Espace, clic, A à la manette) — Raison : le CA 3 demande « la touche de relance, ou passer l'écran » ; dans cette story il n'existe que la relance (la chambre est la 6.5) ; R est libre dans le GDD ; l'invite selon le périphérique et la réassignation sont la 1.7.
11. **Le sprite du joueur disparaît à sa mort, et le joueur s'arrête** (`set_physics_process(false)`) — Raison : repère visuel provisoire de la mort derrière un fond semi-transparent (« la mort réveille ») ; l'arrêt rend le joueur inerte même sans gel (`Run` isolé, futurs écrans) ; règle aussi le report de 2.1 sur `_update_blink()`. Animation de mort : epic 7.
12. **`Transition` vide** (`CanvasLayer`, couche 2) — Raison : le CA 1 n'exige que sa présence ; la transition courte arrive avec la 4.8.
13. **Panneau F1 : manager trouvé par `BulletManager.has_hurtbox(player.hurtbox)`** — Raison : indépendant de l'arbre (`Run`, `RoomSlot`, salles de l'epic 4), et c'est exactement « le manager qui peut toucher ce joueur » ; un accesseur en lecture seule plutôt qu'un champ privé lu par le debug.
14. **Cache des ressources** par `preload` en chaîne (`Main` → `run.tscn` → `run.gd` → `arena.tscn`), sans chargement en tâche de fond — Raison : suffit pour une arène ; le préchargement d'étage est la 4.8 (AR17).
15. **Pas de seed dans « run started »** — Raison : `RunRng` n'existe pas avant l'epic 4 ; AR27 (« la seed est journalisée au lancement ») sera tenu par la 4.7 ou la 4.11. Consigné dans `deferred-work.md`.
16. **Libellé de touche par `InputEventKey.as_text_physical_keycode()`** — Raison : `DisplayServer.keyboard_get_label_from_physical()` imprime une erreur en headless (sonde) ; pour R, le libellé QWERTY et AZERTY est le même ; la 1.7 refera les invites.
17. **Un seul `INFO` par mort**, en catégorie `run` (`Run`) ; le joueur passe sa trace de mort en `Log.debug("combat", ...)`. `Main` journalise en `run` le délai entre la fin de partie et la demande de relance. Raison : CA 3 et AR27 (jalons en `INFO`, sans doublon).
18. **La décision 11 de la story 2.1** (« mort minimale ») est remplacée par cette story ; ses autres décisions restent valables (filtre de hurtbox, ordre des managers, panneau F1 instancié par `Main`, etc.).
19. **Tir automatique de F1 conservé d'une partie à l'autre** — Raison : outil de debug ; il retrouve le nouveau joueur et le nouveau manager à chaque tir, et n'accumule rien derrière l'écran. Consigné, pas corrigé.
20. **Ordre du coup mortel observé `[changed, player_hit, run_ended, died]`** (revue) — Question : accepter l'écart avec la lettre du CA 4 ou corriger ? Choix : accepter ; documenter dans le code (correctif de revue) et lire le CA 4 comme l'ordre des *débuts d'émission* (`died` part avant `run_ended`, qui est émis par le gestionnaire de `Run` *pendant* `died`). Raison : ce dont dépendent les consommateurs est tenu (`player_hit` mortel avant `run_ended` pour la 2.8, `changed` avant `died`, état du joueur complet, même tick, une fois chacun) ; `Player.died` est un signal local vers le parent (D3), `Run` est son seul auditeur ; différer `run_ended` casserait le gel synchrone dans le tick du `BulletManager`, émettre `died` avant `player_hit` rouvrirait le report de 2.1.
21. **Dégel après le retrait de l'ancien `Run`** (revue) — Choix : retirer l'ancien `Run` encore figé, puis dégeler, puis ajouter le nouveau (remplace l'ordre « dégel puis `_show_scene()` » des Dev Notes). Raison : garde la contrainte de la story (le nouveau `Run` entre dans un arbre actif) sans réactiver la partie morte.
22. **Arène sans `setup()` : les cibles restent inscrites** (revue) — Choix : seul `equip_bullets()` et l'inscription de la hurtbox du joueur sont sautés. Raison : la spec visait « rien qui déréférence `null` » ; les cibles ne dépendent pas du joueur (AR28, « le reste continue »).
23. **Garde de l'écran de réveil gardée en ticks bruts** (revue) — Choix : pas de mesure en temps réel ; le risque d'écoulement en une ou deux images après un à-coup est reporté à la mesure sur la machine de référence (1.8). Raison : AR13 (pas de minuterie en temps réel), et l'à-coup ne se juge pas en headless.

### Questions ouvertes

Aucune bloquante. Points à faire valider par Kroustille en fin d'epic : les décisions ci-dessus, en priorité 1 (où vit le joueur), 7 (l'écran attend le joueur), 10 (touches de relance) et 11 (le sprite disparaît à la mort), à juger au jeu.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2 : Mourir et relancer en moins de 3 secondes]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR15) et [#Exigences non fonctionnelles] (NFR3)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR8, AR13, AR19, AR20, AR22, AR24, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.8], [#Story 6.4], [#Story 6.5] (écran de réveil qui attend le joueur, question non bloquante, victoire, retour à la chambre : contexte, non implémenté ici)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Mort et progression] (« depuis la mort, une nouvelle run démarre en moins de 3 s. L'écran du réveil peut se passer »)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Conditions de victoire et de défaite] et [#Spécifications techniques] (chargement < 3 s entre la mort et une nouvelle run)
- [Source: _bmad-output/game-architecture.md#Scènes (D14)] (`Main` > `ActiveScene` > `Run` > `Player`, `RoomSlot` ; `UI`, `Transition`)
- [Source: _bmad-output/game-architecture.md#Gestion de l'état] (joueur enfant de `Run`, conservé d'une salle à l'autre) et [#Gestion des assets] (relance : `Run` détruit puis recréé, ressources en cache)
- [Source: _bmad-output/game-architecture.md#Communication entre systèmes (D3)] (`Events.run_ended`, signaux locaux) et [#Événements]
- [Source: _bmad-output/game-architecture.md#Temps (D7)] (seul `Main` met en pause) et [#Rendu (D13)] (décor sous les entités)
- [Source: _bmad-output/game-architecture.md#Logs] (`run`, jalons en `INFO`) et [#Gestion des erreurs]
- [Source: _bmad-output/game-architecture.md#Création d'entités] (`setup()` avant `add_child()`) et [#Frontières architecturales]
- [Source: _bmad-output/implementation-artifacts/2-1-encaisser-des-coups.md] (santé, hurtbox, panneau F1, revue : tests qui prouvent le mécanisme, reports vers 2.2)
- [Source: _bmad-output/implementation-artifacts/1-6-mettre-en-pause-et-regler-le-jeu.md] (pause par `Main`, menus, localisation, tests headless)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (reports listés dans « Reports traités par cette story »)
- Documentation Godot 4.7 consultée par Context7 à la création : `ResourceLoader.has_cached()` et cache des ressources tant qu'une référence existe (`Resource`, `@GDScript.load`) ; `Node.process_mode`, `NOTIFICATION_ENABLED/DISABLED`, `can_process()` ; `CanvasItem.z_index`, `z_as_relative`, `top_level`, ordre de dessin à travers un `Node` simple ; `BaseButton.disabled`, `action_mode`, `Control.grab_focus()` ; `InputEventKey.as_text_physical_keycode()`, `DisplayServer.keyboard_get_label_from_physical()`. Sonde headless en 4.7.2 (scratchpad, supprimée) : désactiver un ancêtre depuis un `_physics_process` de priorité 100 → aucune erreur moteur, le nœud de priorité 101 ne tourne plus dans ce tick ; nœud ajouté sous un parent désactivé → `can_process()` faux, pas de `NOTIFICATION_DISABLED`, puis `ENABLED` au dégel ; `keyboard_get_label_from_physical()` → `ERROR: Not supported by this display server.` en headless ; `as_text_physical_keycode()` → « R » sans erreur ; `preload()` → `has_cached()` vrai.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5 (`claude-sonnet-5-5`), workflow `gds-dev-story` en mode pipeline non interactif.

### Debug Log References

- Vérifications du scratchpad (`game/.scratch`, exclu de git) : `run_all.sh` lance `t_health`, `t_arena`, `t_misc`, `t_death`, `t_isolated`, `t_load`, `t_invalid` ; `t_shots22` (captures fenêtrées, `SHOT_DIR=...`) et `probe_focus` (sonde Entrée) à part. Dernier passage : 7 scènes `PASS` (t_health 16, t_arena 23, t_misc 30, t_death 86, t_isolated 6, t_load 3, t_invalid 1 contrôles `ok`), zéro `SCRIPT ERROR`, zéro `Parse Error` ; `--import` puis `--quit-after 120` : seul `settings.cfg missing` (connu).
- Contrôles par mutation (le mécanisme est absent, le contrôle doit échouer), faits à la main puis annulés : sans `set_physics_process(false)` dans `_die()` → 2 échecs de `t_isolated` ; sans `_freeze(true)` dans `Main` → 4 échecs de `t_death` (gel, bullet en vol, F5) ; avec le `visible = true` forcé dans `_update_blink()` → 2 échecs de `t_death` (clignotement).
- Recherche des interdits : seules des occurrences en commentaires (`main.gd`, `perf_overlay.gd`, `dash.gd`, `game_clock.gd`) ; `GameClock.paused` n'est écrit que dans `main.gd` (`_freeze()`) ; aucune chaîne française dans `game/ui/` ni `game/run/`.

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-21).
- **Implémenté** (T1 à T7, T10, T11) : lexique et lignes D7/D13 ; `Health` émet `changed` avant `died` ; `Player.died`, `_die()`, mort traitée après `Events.player_hit`, `_update_blink()` aux transitions ; `Run` (`Player` puis `RoomSlot`, arène instanciée en code, `Outcome.DEATH = 0`, `Events.run_ended`) ; arène sans joueur (`setup()`, `player_spawn_position()`, décor en `Z_INDEX_DECOR`) ; action `restart` (R), `WakeScreen` (garde de 0,3 s en ticks bruts) ; `Main` (`_start_run()`, `_freeze()`, `_run_over`, `Transition` vide, F5 entre test de charge et partie) ; `BulletManager.has_hurtbox()` et panneau F1.
- **Ordre du coup mortel** : `Run` est le premier auditeur de `Player.died` ; son `run_ended` part donc *pendant* l'émission de `died`, avant qu'un auditeur ajouté plus tard ne la reçoive. Le contrôle enregistre `[changed, player_hit, run_ended, died]` et prouve par la pile d'appels que `run_ended` sort du gestionnaire `_on_player_died` (même image physique pour les quatre). C'est l'ordre voulu (`player_hit` → mort du joueur → `run_ended`) ; le tableau de la story le lisait comme l'ordre d'*émission* de `died` et de *déclenchement* de `run_ended`.
- **Chaque contrôle isole son mécanisme** : le gel (`Main`) est isolé par un projectile déjà en vol (position exacte gardée 60 ticks ; contrôle : il avance quand la partie tourne) ; l'arrêt du joueur mort (`_die()`) par `t_isolated` sans `Main` (contrôle : le joueur vivant avance et tire sous les mêmes entrées) ; le clignotement par un sprite masqué hors invulnérabilité (l'ancien code le montrait au tick suivant) ; la garde de 0,3 s par une relance ignorée à 5 ticks (touche, Entrée, clic) puis acceptée une fois armée (trois chemins : R, Entrée sur le bouton focalisé, clic de souris simulé) ; le cache par l'`instance_id` des `PackedScene` arène et `run` identique avant et après cinq relances ; F1 par `player.get_parent() != eb.get_parent()` (l'ancienne règle du parent partagé aurait échoué).
- **Un seul `run_ended` par mort** : deux balles mortelles au même tick (cycle 1 de `t_death`) → un seul ; deux `receive()` mortels au même tick sur un `Run` isolé → le second est refusé.
- **Relance** : arbre stable à 106 nœuds après chaque relance (cycles 1 à 5, mesure une image après), 0 orphelin, `enemy_damaged` sans connexion en plus. NFR3 : garde armée 18 ticks après l'ouverture ; relance demandée à ≈ 340 à 370 ms de la mort, `_start_run()` ≈ 30 à 70 ms en headless (inclut 2 ticks de latence d'entrée simulée).
- **Découvertes d'environnement** : (1) un `Button` ne se presse qu'au *relâchement* (`action_mode` par défaut) : pour `ui_accept` il faut un `InputEventKey` Entrée pressé puis relâché, et une action `ui_accept` simulée (`InputEventAction`) n'atteint pas le bouton ; (2) un clic simulé doit être exprimé en pixels de fenêtre (coordonnées du viewport × échelle de fenêtre) ; (3) les `Callable` d'un test connectés à `Player.died` passent après `Run` (voir ci-dessus).
- **Vérifications de 2.1 relancées**, adaptées là où 2.2 change le comportement : `t_arena`, `t_misc`, `t_shot`, `p_dash` trouvent l'arène par `Run/RoomSlot` (le joueur n'est plus son frère) ; `t_arena` : le joueur mort a le sprite **masqué** (était visible), l'aller-retour F5 commence par une relance (F5 est ignoré derrière l'écran de réveil), « joueur mort intouchable » est désormais aussi couvert par le gel (le mécanisme propre est prouvé par `t_isolated`), et le contrôle dash K=1, qui échouait déjà au commit de base `816127d` (le coup arrive un tick avant que l'entrée n'atteigne le joueur), est affirmé comme un coup. `t_health` et `t_invalid` inchangés (`t_invalid` affirme maintenant son résultat attendu : deux refus et deux assertions).
- **Écarts** : `strings.fr.translation` n'est pas versionné (`*.translation` est dans `.gitignore`), la story annonçait le contraire : rien à commiter. `_show_scene()` prend une `PackedScene` et renvoie toujours `true` (la signature `bool` est conservée) ; le chargement du test de charge reste par `load()` dans la branche F5, avec `Log.warn` si introuvable.
- **NON ÉVALUÉ / NON VÉRIFIÉ** (étapes humaines, consignées dans `deferred-work.md`) : ressenti de la relance et de la garde de 0,3 s ; lisibilité de l'écran de réveil à l'œil ; relance en moins de 3 s sur la machine de référence et en export (story 1.8) ; bouton A à la manette et invite « (R) » (story 1.7) ; tirs au-dessus du joueur non photographiés. Captures WSLg faites : écran de réveil pendant et après la garde, partie, nouvelle partie ; curseur visible sur l'écran, caché en jeu (`Input.mouse_mode` 0 puis 1), F1 lisible au-dessus de l'écran.

### File List

- `game/combat/health.gd` (modifié)
- `game/combat/bullets/bullet_manager.gd` (modifié : `has_hurtbox()`)
- `game/player/player.gd` (modifié)
- `game/autoloads/events.gd`, `game/core/constants.gd` (modifiés)
- `game/run/run.tscn`, `game/run/run.gd`, `game/run/run.gd.uid` (nouveaux)
- `game/rooms/arena/arena.tscn`, `game/rooms/arena/arena.gd` (modifiés)
- `game/ui/menus/wake_screen.tscn`, `game/ui/menus/wake_screen.gd`, `game/ui/menus/wake_screen.gd.uid` (nouveaux)
- `game/main/main.tscn`, `game/main/main.gd` (modifiés)
- `game/project.godot` (action `restart`), `game/localization/strings.csv` (`UI_WAKE_*`)
- `game/debug/debug_panel.gd` (modifié)
- `_bmad-output/game-architecture.md` (lexique, D7, D13), `_bmad-output/implementation-artifacts/deferred-work.md`, `sprint-status.yaml`, cette story

### Change Log

- 2026-11-21 : story 2.2 créée (`ready-for-dev`).
- 2026-11-21 : story 2.2 implémentée, vérifiée en headless et sous WSLg, passée en `review`.
- 2026-11-21 : revue de code (3 couches) : 7 correctifs laissés en actions, 3 reports, 17 rejets ; story repassée en `in-progress`.
