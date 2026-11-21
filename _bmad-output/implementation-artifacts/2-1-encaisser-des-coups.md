---
baseline_commit: 677739a03b12fc90b3efe98c41fd1f53b9827d5f
---

# Story 2.1 : Encaisser des coups

Status: ready-for-dev

## Story

En tant que joueur,
je veux des cœurs, une armure et une invulnérabilité après chaque coup,
afin de savoir exactement ce que me coûte une erreur.

**Exigences couvertes :** FR11, FR12 (coup de base), FR13, FR14 (hors ramassage), AR7, AR8, AR24 (F1), ainsi que AR9, AR13, AR27, AR28, AR32.

**Prérequis : la story 1.6 est `done`** (vérifié à la création de ce fichier : `Events.enemy_damaged`, pause par `Main`, `Hurtbox`, `BulletManager` par camp, `Audio`, `Tuning` existent dans le dépôt). Les stories 1.7 et 1.8 sont reportées par Kroustille (avant le playtest du jalon A) : elles ne sont **pas** des prérequis.

**Première story de l'epic 2.** Elle pose la santé du joueur et le chemin des dégâts ennemis ; les ennemis eux-mêmes arrivent avec les stories 2.3 à 2.5, la mort et la relance avec la 2.2, le HUD avec la 2.7.

## Critères d'acceptation

1. **Étant donné** le début d'une partie, **quand** le joueur apparaît, **alors** il a 3 cœurs, soit 6 demi-cœurs, gérés par un composant `Health` qui compte en demi-cœurs entiers.
2. **Étant donné** le joueur vulnérable, **quand** un projectile ennemi touche sa hurtbox, **alors** le coup passe par `DamageInfo`, `Hurtbox.receive()` puis `Health.apply_damage()`, et retire ½ cœur, la valeur de `CombatTuning`, **et** le projectile est détruit, **et** `Events.player_hit` est émis.
3. **Étant donné** le joueur qui vient d'être touché, **quand** d'autres coups arrivent dans la seconde qui suit, **alors** ils ne comptent pas, et les projectiles qui le touchent continuent leur course, **et** le sprite clignote pendant toute l'invulnérabilité, et un son de coup se joue.
4. **Étant donné** le joueur en dash, pendant ses 0,15 s d'invulnérabilité, **quand** un projectile ennemi le traverse, **alors** aucun coup n'est compté, et le projectile continue sa course.
5. **Étant donné** le joueur avec de l'armure, **quand** il prend un coup, **alors** l'armure, en demi-cœurs bleus, est retirée avant les cœurs, **et** l'ajout d'armure ou de cœurs est refusé au-delà du plafond de 12 cœurs, armure comprise, et l'appel renvoie `false`.
6. **Étant donné** un build de debug, **quand** on ouvre le panneau F1, **alors** il permet de basculer l'invulnérabilité, d'ajouter de l'armure, de se retirer ½ cœur et de faire tirer un émetteur de projectiles ennemis de test, **et** le panneau est une scène séparée, instanciée seulement en debug (par `Main`, voir les décisions), qui appelle les méthodes publiques du jeu.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture, par les reports des stories précédentes ou par l'état du dépôt) :

7. **Une hurtbox qui ne peut pas être touchée n'arrête pas les projectiles** (report de la revue de 1.5) : le test de touche du `BulletManager` tient compte de l'état de la `Hurtbox` (`monitorable`, forme `disabled`, et un filtre fourni par son propriétaire : invulnérabilité, mort). Un projectile qui chevauche une hurtbox non touchable continue sa course, sans coup ni destruction.
8. **Un seul coup par tick sur le joueur** : quand plusieurs projectiles ennemis chevauchent la hurtbox du joueur au même tick, un seul compte et un seul est détruit ; les autres continuent leur course (le premier coup ouvre l'invulnérabilité).
9. **`Events.enemy_damaged` n'est émis que pour un coup accepté** (report de la revue de 1.6) : `Hurtbox.receive()` sort sans rien émettre (ni `damage_received`, ni `enemy_damaged`) quand la hurtbox n'est pas touchable, et renvoie `false`. Les chiffres de dégâts ne comptent donc plus de dégâts fictifs.
10. **Ordre de traitement fixé** (reports de 1.4 et de 1.5) : tous les `BulletManager` traitent leur tick **après** les entités (`process_physics_priority`), quel que soit leur rang dans l'arbre. L'invulnérabilité du dash et celle d'après un coup sont donc lues dans l'état du tick courant : plus de trou d'un tick au départ du dash.
11. **La source du coup suit le camp** (report de la revue de 1.5) : les projectiles du camp ennemi livrent `DamageInfo.Source.ENEMY_BULLET`, ceux du joueur `PLAYER_SHOT`.
12. **Mort minimale** : à 0 demi-cœur, `Health` émet `died` une seule fois, le joueur journalise sa mort et ne peut plus être touché ; rien d'autre (l'écran de réveil et la relance sont la story 2.2). Un aller-retour F5 recrée l'arène et redonne 3 cœurs.
13. **Pause et ralenti** : l'invulnérabilité, le clignotement et le tir automatique de l'émetteur de test se figent pendant la pause et sont quatre fois plus lents sous F4 (ticks pondérés par `GameClock`).
14. Marche, dash, tir sur les cibles, chiffres de dégâts, pause, réglages, F2, F3, F4, F5 et le test de charge (`Bullets 400 | refused 0`) de 1.1 à 1.6 sont inchangés.

## Tâches / sous-tâches

- [ ] **T1. Lexique** (AR32 : un terme entre dans le lexique **avant** le code)
  - [ ] `game-architecture.md`, section « Lexique » : ajouter `Santé ; cœur ; demi-cœur ; armure ; plafond de cœurs ; coup reçu ; invulnérabilité après un coup ; clignotement ; panneau de debug ; émetteur de test | health ; heart ; half_heart ; armor ; heart_cap ; hit ; hit_invulnerability ; blink ; debug_panel ; test_emitter`.
  - [ ] `game-architecture.md`, section « Temps (D7) » ou « Projectiles (D1) » : consigner en une ligne la règle d'ordre (CA 10 : `BulletManager` en `process_physics_priority` = `Const.PHYSICS_PRIORITY_BULLETS`, après les entités).
- [ ] **T2. `CombatTuning`** (CA 1, 2, 3, 5 ; AR9)
  - [ ] `core/combat_tuning.gd`, `data/tuning/combat_tuning.tres`, `Tuning.COMBAT` (voir « `CombatTuning` »).
- [ ] **T3. `Health`** (CA 1, 3, 5, 12, 13)
  - [ ] `combat/health.gd` : demi-cœurs, armure, plafond, invulnérabilité après un coup en ticks, invulnérabilité forcée (F1), mort (voir « `Health` »).
- [ ] **T4. `Hurtbox` touchable ou non** (CA 7, 8, 9)
  - [ ] `combat/hurtbox.gd` : `set_hit_filter()`, `is_hittable()`, `one_hit_per_tick`, `receive()` qui renvoie `bool` et ne fait rien pour un coup refusé (voir « `Hurtbox` »).
  - [ ] `combat/damage_info.gd` : sources `ENEMY_BULLET` et `DEBUG`.
- [ ] **T5. `BulletManager`** (CA 2, 3, 4, 7, 8, 10, 11)
  - [ ] Priorité de tick, état « touchable » des cibles lu une fois par tick, un coup par tick pour les cibles `one_hit_per_tick`, source selon le camp (voir « `BulletManager` »).
  - [ ] `debug/bullet_load_test.gd` : garder son ordre relatif (priorité au-dessus de celle des managers).
- [ ] **T6. Joueur** (CA 1 à 5, 12, 13)
  - [ ] `player/player.gd` : `Health` et `Hurtbox` créés en code, filtre de touche, `Events.player_hit`, son de coup, clignotement, mort journalisée, groupe `player` (voir « Joueur »).
  - [ ] `autoloads/events.gd` : signal `player_hit`.
  - [ ] `audio/sfx/sfx_player_hit.wav` : son provisoire généré par script (voir « Son de coup »).
- [ ] **T7. Projectiles ennemis dans l'arène** (CA 2)
  - [ ] `rooms/arena/arena.gd` : `EnemyBullets` (`BulletManager`, camp `ENEMY`) qui enregistre la hurtbox du joueur (voir « Arène »).
- [ ] **T8. Panneau F1** (CA 6, 13)
  - [ ] Action `debug_toggle_panel` (F1) dans `project.godot`.
  - [ ] `debug/debug_panel.tscn/.gd` : invulnérabilité, armure, −½ cœur, émetteur de test (salve et tir automatique), état affiché ; instancié par `Main` en debug seulement (voir « Panneau F1 »).
- [ ] **T9. Vérifications headless** (CA 1 à 14) : scripts jetables du scratchpad (voir « Stratégie de test »).
- [ ] **T10. Vérifications fenêtrées sous WSLg** (CA 3, 6) : clignotement, panneau lisible, captures.
- [ ] **T11. Régression** : import et lancement sans erreur, recherche des interdits, marche, dash, tir, pause, F2 à F5, test de charge.
- [ ] **T12. Reports** : mettre à jour `deferred-work.md` (entrées résolues, voir « Reports traités par cette story » ; ce qui n'a pas pu être vérifié : ressenti du clignotement et du son, son à l'oreille).

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

La santé du joueur (cœurs, armure, invulnérabilité après un coup), le chemin complet d'un projectile ennemi jusqu'à `Health`, la convention d'ordre de traitement, et le panneau F1. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Écran de réveil, `Events.run_ended`, nœud `Run`, `RoomSlot`, relance en moins de 3 s | 2.2 |
| Ennemis, `EnemyDef`, `room.spawn_enemy()`, `Telegraph`, `min_telegraph`, dégâts au contact, `Hitbox`, PV des ennemis (et donc la `Health` des ennemis) | 2.3 à 2.5 |
| Couleur et contour réservés des projectiles ennemis, dessin au-dessus de tout le monde | 2.4 |
| Vagues, apparition d'un ennemi choisi, « tuer tout », « vague suivante » dans F1 | 2.6 |
| HUD (cœurs, armure en demi-cœurs bleus à l'écran) | 2.7 |
| Télémétrie, cause de la mort | 2.8 |
| Graze, dash parfait, drapeau `counted`, lucidité fixée dans F1 | Epic 3 |
| Coup à 1 cœur (étage 3, attaques lourdes), trous | Epic 4, 6 |
| Ramassage d'armure et de cœurs, boutique, `hit_taken` des objets, cœurs max modifiés (Dent qui tombe) | Epic 5 |

### État actuel du dépôt (stories 1.1 à 1.6 `done`)

- **Autoloads** (ordre dans `project.godot`) : `Log`, `Events`, `GameClock`, `Settings`, `SaveService`, `Audio`.
  - `Events` : un seul signal, `enemy_damaged(world_position: Vector2, amount: float)`, avec `@warning_ignore("unused_signal")`. Types primitifs seulement dans les signatures (`autoloads/` ne dépend d'aucun dossier de fonctionnalité).
  - `GameClock` : `enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }`, `paused` (écrit par `Main` seul), `global_multiplier` borné à [0, 1] (F4), `scale(group)` renvoie 0 en pause.
  - `Audio` : pool de 16 lecteurs sur `SFX`, `play_sfx(stream, max_voices = 3) -> bool`, `voices_of(stream)`. Ne pas modifier.
  - `Log` : catégories `run`, `room`, `combat`, `lucidity`, `items`, `gen`, `save`, `input`, `audio`, `ui`. Utiliser `combat`.
- **`core/`** : `Const` (tuile 16 px, `HUD_BAND_HEIGHT` 24, `ROOM_TILES` 36×19, groupes `GROUP_BULLET_MANAGERS` et `GROUP_DEBUG_SHAPES`, couches de collision dont `LAYER_PLAYER_HURTBOX` et `LAYER_ENEMY_HURTBOX`, `COLOR_PLAYER_SHOT`) ; `Tuning` (classe `@abstract`, `const PLAYER`, `DASH`, `SHOT` préchargés) ; les **scripts** des Resources de réglage vivent dans `core/` (`player_tuning.gd`, `dash_tuning.gd`, `shot_tuning.gd`), les `.tres` dans `data/tuning/` (`data/` ne contient que des `.tres`). Il n'existe **pas** de `CombatTuning`.
- **`combat/damage_info.gd`** (`RefCounted`) : `amount: float`, `source: Source` (`enum Source { PLAYER_SHOT }`), `is_heavy`, `direction` ; `static from_bullet(amount, direction, source)`.
- **`combat/hurtbox.gd`** (`Area2D`, `class_name Hurtbox`) : `@export var camp`, signal local `damage_received(info)`. `_ready()` fixe la couche selon le camp, cherche un `CollisionShape2D` enfant à `RectangleShape2D` (sinon `Log.error` + `assert`), l'ajoute au groupe F2. `receive(info)` émet `damage_received` **puis**, pour le camp ennemi, `Events.enemy_damaged` (haut centre du rectangle) — **sans aucun test d'état** : c'est le report de 1.6 à régler. `world_rect()` en coordonnées globales. **Aucune `Health` n'existe.**
- **`combat/bullets/bullet_manager.gd`** : un manager par camp, tableaux compacts, `FLAG_ACTIVE`, `FLAG_COUNTED` (réservé à l'epic 3). `register_hurtbox()` (camp opposé obligatoire, désinscription sur `tree_exiting` en `CONNECT_ONE_SHOT`). Dans `_physics_process` : `_refresh_target_rects()` une fois par tick, puis pour chaque projectile : déplacement, `_test_targets(i)` **avant** les murs (le projectile est libéré dès qu'il chevauche une cible), et après la boucle `_deliver_hits()` qui appelle `target.receive(DamageInfo.from_bullet(..., DamageInfo.Source.PLAYER_SHOT))` — **source fixe, quel que soit le camp** (report de 1.5). Aucune priorité de tick : l'ordre dépend du rang dans l'arbre (report de 1.5). `fire(params, origin, direction) -> bool` refuse et journalise un tir invalide (vitesse ≥ 1 tuile par tick, direction non normée…).
- **`combat/bullets/bullet_params.gd`** : `speed` (tuiles/s), `radius` (tuiles), `lifetime` (s), `appearance`, `damage`.
- **`combat/hit_feedback.gd`**, **`vfx/sprite_kick.gd`** : retours d'impact des cibles et recul du tir du joueur. Pas touchés.
- **`player/player.gd`** (`CharacterBody2D`, `class_name Player`) : nœuds de scène `%Sprite` (`Sprite2D` 16×24, texture générée en code) et `%Hitbox` (`CollisionShape2D` du corps contre les murs, `RectangleShape2D` neuf de `Tuning.PLAYER.hitbox_size` × 16 = 6×6 px, créé dans `_ready()`). **Pas de hurtbox.** Composants en code : `PlayerMotor`, `Dash` (`RefCounted`), `Aim`, `Shooter`, `SpriteKick`, `Reticle` (`setup(self)` avant `add_child`). `_physics_process` : `clock_scale` lu une fois, moteur, `_dash.tick(...)`, tir, `move_and_slide()`, `_dash.finish_tick()`, `_update_dash_tint()` (**`_sprite.modulate`** = `DASH_TINT` pendant l'invulnérabilité du dash). Méthodes publiques : `equip_bullets(manager)`, `is_dash_invulnerable()`, `is_invulnerable()` (commentaire : « Story 2.1 will add the invulnerability granted after a hit »), `is_dashing()`, `aim_direction()`, `aim_source()`. Son de tir : `SHOT_SOUND` préchargé (`audio/sfx/sfx_player_shot.wav`).
- **`player/dash.gd`** : `_invulnerable` calculé dans `tick()` **avant** le mouvement (`_elapsed < _invulnerability_ticks`) : le premier tick du dash est couvert. Ne pas modifier (le report « pas de `TICK_EPSILON` » reste ouvert).
- **`player/reticle.gd`** : enfant du joueur, `top_level`, propriétaire du curseur (le cache dans l'arène, le montre en pause). **Ne pas masquer le nœud `Player` pour le clignotement** : le réticule disparaîtrait aussi. Clignoter le `Sprite2D` seul.
- **`rooms/arena/arena.gd`** (`class_name Arena`) : construit `Floor` et `Walls` en code ; `_setup_player_bullets()` crée `PlayerBullets` (camp `PLAYER`, capacité 128), appelle `_player.equip_bullets()`, enregistre la hurtbox des 3 `TrainingTarget` ; `_setup_damage_numbers()` ajoute `DamageNumbers` après. Place le joueur au centre de la zone jouable (`frame_px / 2` = (304, 168)). Les enfants (`Player`, cibles) ont fait leur `_ready()` avant `Arena._ready()`.
- **`rooms/arena/training_target.gd`** : `hurtbox` exposée, `HitFeedback`, indestructible, aucune `Health`. Pas touché.
- **`vfx/damage_numbers.gd`** : écoute `Events.enemy_damaged` (connexion dans `_enter_tree`, déconnexion dans `_exit_tree`), lit `Settings.damage_numbers` à chaque coup. Pas touché.
- **`main/main.gd`** : `_ready()` → en debug, vérifications puis `_ui.add_child(CollisionDrawer.new())` ; `_setup_menus()` ; `_show_scene(ARENA_PATH)`. Seul `_set_paused()` écrit `GameClock.paused` et `ActiveScene.process_mode`. `_unhandled_input()` : `pause` dans tous les builds ; F5 et F4 en debug **et hors pause** seulement. `_show_scene()` retire tout de suite l'ancien enfant d'`ActiveScene` (ses groupes cessent de compter dans la même image) puis le libère.
- **`debug/`** : `perf_overlay.tscn/.gd` (F3, `Control` plein écran, `Label` en haut à gauche 300×40 px, `process_mode = ALWAYS`, gère sa touche dans `_unhandled_input`), `collision_drawer.gd` (F2, même modèle, dessine le groupe `GROUP_DEBUG_SHAPES`), `bullet_load_test.tscn/.gd` (F5 : son propre manager camp `ENEMY`, 512 places, **`process_physics_priority = 1` pour passer après le manager**, apparence 8×8 rose `BULLET_COLOR`). Les textes de `debug/` sont exemptés de `tr()` (documenté dans `perf_overlay.gd`).
- **`project.godot`** : actions `debug_toggle_perf` (F3, `physical_keycode` 4194334), `debug_load_test` (F5, 4194336), `debug_toggle_collisions` (F2, 4194333), `debug_slow_motion` (F4, 4194335), `move_*`, `dash`, `aim_*`, `shoot`, `pause`. **F1 (4194332) n'est pas encore une action.** Avertissements de typage en erreur (`untyped_declaration`, `unsafe_*` à 2).
- **`audio/sfx/`** : seulement `sfx_player_shot.wav` (+ `.import`), généré par script (module `wave`, story 1.5).
- `localization/strings.csv` : 14 clés `UI_*`. **Cette story n'ajoute aucun texte joueur** (le panneau F1 est du debug, exempté).
- Environnement : Godot 4.7.2, `godot` dans le `PATH`, WSLg, pas de manette, pas de `python3` (`uv run python …`). `game/.scratch` : lien symbolique vers le scratchpad, exclu de git.

### Reports traités par cette story (`deferred-work.md`)

| Report | Origine | Réponse de cette story |
|---|---|---|
| Le test de touche ignore l'état de la `Hurtbox` (`monitorable`, forme `disabled`) ; à trancher avec `Health`, la mort et l'invulnérabilité | revue 1.5 | `Hurtbox.is_hittable()` (CA 7), lu par le `BulletManager` une fois par tick |
| `Events.enemy_damaged` émis pour tout coup, même ignoré (invulnérable, mort) | revue 1.6 | `receive()` ne fait rien pour une hurtbox non touchable (CA 9) |
| `_deliver_hits()` livre toujours `PLAYER_SHOT` ; à étendre quand les projectiles ennemis toucheront la `Hurtbox` du joueur | revue 1.5 | source selon le camp (CA 11) |
| Lecture de l'invulnérabilité dépendante de l'ordre dans l'arbre (trou d'un tick au départ du dash) ; convention à fixer en 2.1 | revue 1.4 | priorité de tick des managers (CA 10) |
| Ordre de traitement : cibles lues dans le tick du manager, `HitFeedback` à 3 ticks grâce à l'ordre, ennemi ajouté après le manager testé avec un tick de retard ; convention à fixer en 2.1 (`process_physics_priority`) | revue 1.5 | même règle (CA 10) |

**Restent ouverts** (ne pas traiter ici) : désinscription `CONNECT_ONE_SHOT` et pool d'ennemis (2.3+), projectile apparu dans une cellule solide (motifs ennemis, 2.4), `CollisionDrawer` et formes désactivées / `Hitbox` (2.3), `TICK_EPSILON` dans `Dash`, montant des chiffres de dégâts non validé, mesure de 10 minutes à 400 projectiles sur la machine de référence (**étape humaine, NON FAITE** : `deferred-work.md` la demandait « avant de bâtir le combat ennemi » ; elle n'est pas bloquante pour cette story, qui n'ajoute aucun motif ennemi, mais à rappeler à Kroustille en fin d'epic).

### Leçons des stories 1.1 à 1.6 à appliquer

- **Typage strict, avertissements en erreur.** Le résultat d'un `Callable.call()` est un `Variant` : le tester par `is bool` avant de s'en servir (l'affectation directe à un `bool` compile, vérifié à la création, mais un filtre qui renverrait autre chose casserait en silence). `as` sur un `Variant` déclenche `UNSAFE_CAST` (erreur ici).
- **Calculer la valeur sûre avant de journaliser**, ne jamais planter sur une donnée invalide (AR28) : un `CombatTuning` incohérent retombe sur des bornes sûres avec **un** `Log.error` + `assert`.
- **Injection** : `setup()` avant `add_child()` ; signaux locaux vers le parent ; pas de `/root/...` ni `get_parent().get_parent()`. Les composants créés en code reçoivent un `name` explicite (chemins lisibles dans les logs).
- **Ne jamais modifier une sous-ressource partagée** : formes neuves par instance (comme `%Hitbox` du joueur).
- **Ticks pondérés** : un compteur en ticks décrémenté de `GameClock.scale(groupe)` à chaque `_physics_process`, avec `TICK_EPSILON = 1e-6` dans les comparaisons (modèle : `HitFeedback`). Pas de `Timer`, de `create_timer`, de `Tween` en temps réel.
- **Vérifications** : `godot --headless --path game --import`, puis `godot --headless --path game --quit-after 120`. Zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau. Les vérifications tournent comme **scène** du scratchpad (`godot --headless --path game --scene res://.scratch/<scène>.tscn`), car `--script` ne résout pas les autoloads. `Input.parse_input_event()` est appliqué **au tick suivant**. Les scripts de vérification avec `class_name` ne sont pas vus depuis un dossier caché : `preload()` à la place ; `@warning_ignore_start` pour les `unsafe_*` des scripts jetables seulement.
- **En headless** : `Input.mouse_mode`, mode de fenêtre et VSync sans effet, audio factice (le compteur de voix d'`Audio` fonctionne quand même).
- **Fichiers générés par Godot** : versionner les `.uid` et les `.import` (dont celui du `.wav`).

### `CombatTuning` (AR9, D4)

`core/combat_tuning.gd` (`class_name CombatTuning extends Resource`), `data/tuning/combat_tuning.tres`, et `const COMBAT: CombatTuning = preload("res://data/tuning/combat_tuning.tres")` dans `core/tuning.gd`. Même forme que `ShotTuning` (commentaire d'en-tête, `@export_range`, une ligne de doc par champ). Seulement les valeurs dont cette story a besoin :

| Champ | Type | Valeur | Source |
|---|---|---|---|
| `starting_half_hearts` | `int` | 6 | GDD « Santé et armure » : 3 cœurs |
| `heart_cap_half_hearts` | `int` | 24 | 12 cœurs, armure comprise |
| `hit_damage_half_hearts` | `int` | 1 | ½ cœur aux étages 1 et 2 (coup de base) |
| `hit_invulnerability_duration` | `float` (s) | 1.0 | invulnérabilité après un coup |

- Les cœurs sont stockés **en demi-cœurs** dans la Resource (le suffixe `_half_hearts` le dit) : `Health` compte en demi-cœurs entiers, aucune conversion n'est nécessaire (les distances restent en tuiles et les durées en secondes, comme le veut AR9).
- Pas de champ pour le coup lourd (1 cœur), `min_telegraph`, les PV des ennemis ou le clignotement : ce sont d'autres stories ou des valeurs visuelles.

### `Health` (AR7, D2, « Dégâts et unités »)

`combat/health.gd`, `class_name Health extends Node`. **Composant d'état d'exécution** (les Resources restent en lecture seule). Conçu pour le joueur : demi-cœurs entiers, armure, invulnérabilité après un coup. Les ennemis (PV flottants, story 2.3) décideront s'ils le réutilisent ou non ; ne rien généraliser ici.

**API publique** (proposition, à garder petite) :

```gdscript
## Local signals: the owner (parent) listens.
signal changed  # half_hearts, max_half_hearts or armor changed
signal died     # emitted once, when half_hearts reaches 0

var half_hearts: int        # read-only from outside
var max_half_hearts: int    # heart containers; fixed in this story (no item changes them yet)
var armor: int              # blue half-hearts, lost first

## Dependency injection: call before add_child().
func setup(starting_half_hearts: int, cap_half_hearts: int, hit_invulnerability_seconds: float,
		clock_group: GameClock.Group) -> void

## Returns the half-hearts removed (armor + hearts), 0 when the hit is ignored (invulnerable, dead, invalid).
func apply_damage(info: DamageInfo) -> int
func add_armor(amount: int) -> bool   # false when nothing fits under the cap
func heal(amount: int) -> bool        # false when nothing fits (already at max_half_hearts) or dead
func is_invulnerable() -> bool        # any reason: after a hit, or forced (F1)
func is_hit_invulnerable() -> bool    # only the post-hit window (drives the blink)
func set_forced_invulnerability(enabled: bool) -> void  # debug F1 and future scripted moments
func is_dead() -> bool
```

- **`setup()`** : borne les valeurs avant de les garder (`starting ≥ 1`, `cap ≥ starting`, durée finie ≥ 0 ; sinon `Log.error("combat", ...)` + `assert` et valeur bornée). `half_hearts = max_half_hearts = starting`, `armor = 0`. `_ready()` sans `setup()` : `Log.error` + `assert` + `set_physics_process(false)` (modèle : `HitFeedback`).
- **`apply_damage(info)`** :
  1. ignoré (renvoie 0) si mort ou `is_invulnerable()` ;
  2. montant : `roundi(info.amount)` demi-cœurs ; un montant non fini ou `< 1` après arrondi est refusé (`Log.error` + `assert`, renvoie 0) ;
  3. l'armure absorbe d'abord (`taken_armor = mini(amount, armor)`), le reste sur les cœurs, sans descendre sous 0 ;
  4. si `half_hearts` atteint 0 : `died.emit()` (une seule fois), **pas** d'invulnérabilité ; sinon, ouvrir l'invulnérabilité après un coup (`_hit_ticks_left = durée × Engine.physics_ticks_per_second`) ;
  5. `changed.emit()` ; renvoie le total retiré.
  - `info.is_heavy` et `info.source` ne sont pas lus (le montant porte déjà le coup lourd, FR12 plus tard).
- **Plafond** (CA 5) : `max_half_hearts + armor ≤ cap`. `add_armor(n)` : place = `cap − max_half_hearts − armor` ; place ≤ 0 → `false` ; sinon ajoute `mini(n, place)`, `changed`, `true`. `heal(n)` : place = `max_half_hearts − half_hearts` ; place ≤ 0 ou mort → `false` ; sinon ajoute `mini(n, place)`, `true`. `n ≤ 0` → `Log.error` + `assert`, `false`. (« Au plafond, l'armure reste au sol » : le ramassage, epic 5, lira ce `false`.)
- **Invulnérabilité après un coup** : compteur en ticks décrémenté dans `_physics_process` de `GameClock.scale(_clock_group)` (le joueur passe `GameClock.Group.PLAYER`), avec `TICK_EPSILON`. Coup au tick N du manager → nouveau coup accepté au tick N + 60 (exactement 1,0 s). Figée en pause (nœud sous `ActiveScene`, échelle 0), ×4 plus longue sous F4.
- **Invulnérabilité forcée** : un booléen, sans compteur ; ne fait pas clignoter.
- Aucun log par tick ; `Log.debug("combat", ...)` au plus par coup.

### `Hurtbox` (CA 7, 8, 9)

`combat/hurtbox.gd`, en gardant tout le comportement actuel :

```gdscript
## When true, once one bullet hits this hurtbox in a tick, the other bullets of that tick pass through.
## Set on the player's hurtbox: its first hit opens the invulnerability (story 2.1).
@export var one_hit_per_tick: bool = false

var _hit_filter: Callable  # set by the owner; returns bool: "can this hurtbox be hit now?"

func set_hit_filter(filter: Callable) -> void

## monitorable, shape enabled, in the tree, and the owner's filter (if any) says yes.
func is_hittable() -> bool

## Returns false and emits nothing when the hurtbox cannot be hit.
func receive(info: DamageInfo) -> bool
```

- `is_hittable()` : `false` si la forme manque, si `not monitorable`, si `_shape_node.disabled`, si hors de l'arbre ; si `_hit_filter.is_valid()`, renvoie son résultat (testé `is bool` ; un résultat qui n'est pas un `bool` → `Log.error` + `assert`, traité comme touchable pour ne pas rendre une entité immortelle en release) ; sinon `true`.
- `receive(info)` : `if not is_hittable(): return false` ; puis `damage_received.emit(info)` ; puis `Events.enemy_damaged` comme aujourd'hui pour le camp ennemi ; `return true`. Le propriétaire applique les dégâts dans son gestionnaire de `damage_received` (synchrone) : `enemy_damaged` part donc **après** l'application.
- Mettre à jour le commentaire d'en-tête (« Holds no HP (Health: story 2.1) » n'est plus vrai : la hurtbox ne détient toujours pas de PV, son propriétaire les confie à `Health`).
- `combat/damage_info.gd` : `enum Source { PLAYER_SHOT, ENEMY_BULLET, DEBUG }` (garder `PLAYER_SHOT` en premier : sa valeur entière ne change pas). Commentaire : contact et trou viendront avec 2.3 et 4.3.

### `BulletManager` (CA 2, 3, 4, 7, 8, 10, 11)

1. **Priorité** : `Const.PHYSICS_PRIORITY_BULLETS: int = 100` (nouvelle constante technique, commentée : « every BulletManager ticks after the entities (priority 0), whatever its place in the tree: hit tests read this tick's state of the hurtboxes (story 2.1) »). Dans `_ready()` : `process_physics_priority = Const.PHYSICS_PRIORITY_BULLETS`.
   - **Vérifié à la création** (Context7, doc `Node` 4.7, et sonde headless en 4.7.2) : « lower priority values are called first ; nodes with the same priority are processed in tree order ». La priorité est **globale** : un nœud profond à 100 passe après un nœud à 0 placé plus bas dans l'arbre.
   - `debug/bullet_load_test.gd` règle aujourd'hui `process_physics_priority = 1` pour passer **après** son manager : le passer à `Const.PHYSICS_PRIORITY_BULLETS + 1`, sinon il passerait avant et le test de charge changerait d'ordre.
   - Le joueur (0) tire dans `PlayerBullets` avant le tick du manager, comme aujourd'hui ; `HitFeedback` (0) passe avant les managers dans tous les cas.
2. **État touchable des cibles** : dans `_refresh_target_rects()`, remplir aussi un tableau parallèle réutilisé (`_target_hittable`, `PackedByteArray` ou `Array[bool]`, redimensionné, jamais réalloué par tick) avec `target.is_hittable()` — **une lecture par cible et par tick**, pas par projectile.
3. **`_test_targets(i)`** : ignorer une cible non touchable (le projectile n'est ni libéré ni compté : il continue, puis teste les murs comme d'habitude). Après avoir enregistré un coup sur une cible `one_hit_per_tick`, la marquer non touchable pour le reste du tick.
4. **`_deliver_hits()`** : source = `PLAYER_SHOT` si `camp == Camp.PLAYER`, `ENEMY_BULLET` sinon (retirer le commentaire « the enemy camp adds its own with epic 2 »). La valeur de retour de `receive()` n'est pas utilisée (le projectile est déjà libéré : cas rare d'une cible devenue intouchable entre le test et la livraison, voir les décisions).
5. Ne rien changer d'autre (graze, `FLAG_COUNTED`, rendu, validation des tirs). Mettre à jour le commentaire d'en-tête (« a bullet that overlaps one is freed » → « one that can be hit »).

### Joueur (CA 1 à 5, 12, 13)

`player/player.gd` :

- **Composants créés en code dans `_ready()`** (après la forme de `%Hitbox`) :
  - `health` : `Health.new()`, `name = "Health"`, `setup(Tuning.COMBAT.starting_half_hearts, Tuning.COMBAT.heart_cap_half_hearts, Tuning.COMBAT.hit_invulnerability_duration, GameClock.Group.PLAYER)`, puis `add_child()` ; relier `died` à `_on_health_died`.
  - `hurtbox` : `Hurtbox.new()`, `name = "Hurtbox"`, `camp = BulletManager.Camp.PLAYER`, `one_hit_per_tick = true` ; un `CollisionShape2D` enfant avec un `RectangleShape2D` **neuf** de `Tuning.PLAYER.hitbox_size × Const.TILE_SIZE` (6×6 px, la même zone que la hitbox du GDD), ajouté **avant** `add_child(hurtbox)` (le `_ready()` de la hurtbox cherche sa forme à ce moment-là) ; puis `hurtbox.set_hit_filter(_can_be_hit)` et `hurtbox.damage_received.connect(_on_hurtbox_damage_received)`.
  - Exposés en lecture : `var health: Health` et `var hurtbox: Hurtbox` (l'arène enregistre la hurtbox, F1 et le HUD de 2.7 lisent la santé). Ne pas les mettre dans `player.tscn` : `setup()` doit précéder `add_child()`, et la taille vient de `Tuning`.
- `add_to_group(Const.GROUP_PLAYER)` (nouvelle constante `&"player"` dans `Const`) : le panneau F1 trouve le joueur sans chemin absolu, y compris après F5 (et après la relance de 2.2).
- **`is_invulnerable()`** : `is_dash_invulnerable() or health.is_invulnerable()` (mettre à jour le commentaire). `_can_be_hit() -> bool` : `not is_invulnerable() and not health.is_dead()`.
- **`_on_hurtbox_damage_received(info)`** : `var lost: int = health.apply_damage(info)` ; si `lost > 0` : `Events.player_hit.emit(lost, info.source)`, `Audio.play_sfx(HIT_SOUND)`, `Log.debug("combat", "player hit lost=%d hearts=%d armor=%d source=%d" % [...])`.
- **Clignotement** (CA 3) : dans `_physics_process`, après `_update_dash_tint()`, `_update_blink()` : si `health.is_hit_invulnerable()`, `_sprite.visible` alterne toutes les `BLINK_HALF_PERIOD_TICKS` ticks de jeu (compteur pondéré par `clock_scale`, ou dérivé du temps d'invulnérabilité restant exposé par `Health`) ; sinon `_sprite.visible = true`. Constante visuelle locale « placeholder until epic 7 » : demi-période de **0,1 s** (6 ticks, 5 clignotements par seconde ; petite surface, pas un flash plein écran — les réglages de photosensibilité sont FR67, epic 3). Le clignotement touche **`visible` du `Sprite2D`**, jamais `modulate` (teinte du dash) ni le nœud `Player` (réticule). Figé en pause (le joueur est désactivé) ; à la fin de l'invulnérabilité, le sprite est **visible**.
- **`_on_health_died()`** : `Log.info("combat", "player died")`. Rien d'autre (2.2) : le joueur peut encore bouger et tirer, il n'est plus touchable (`_can_be_hit()`), le sprite reste visible.
- **Son de coup** : `const HIT_SOUND: AudioStream = preload("res://audio/sfx/sfx_player_hit.wav")`, commenté « placeholder, replaced by story 7.7 ».
- `autoloads/events.gd` :

```gdscript
## The player took a hit. damage: half-hearts removed (armor included). source: DamageInfo.Source as an int
## (autoloads/ depends on no feature folder). Listeners: lucidity rules, HUD, telemetry (later stories).
@warning_ignore("unused_signal")
signal player_hit(damage: int, source: int)
```

  Émis par `Player` (pas par `Health`, qui reste générique), une fois par coup accepté. Pas de signal de mort sur le bus dans cette story (`run_ended` : 2.2).

### Son de coup (FR13)

Générer `game/audio/sfx/sfx_player_hit.wav` par un script jetable du scratchpad, module standard `wave`, `uv run python <script>` (même méthode que `sfx_player_shot.wav`, story 1.5) : mono, 16 bits, 22 050 Hz, **≈ 0,15 s**, un « choc » **grave** et distinct du tir (Kroustille a trouvé le tir trop aigu) : par exemple une sinusoïde de 220 Hz descendant vers 90 Hz, enveloppe en décroissance, amplitude ≈ 0,5. **Aucun hasard** (pas de bruit pseudo-aléatoire non semé ; un bruit déterministe est permis). Puis `godot --headless --path game --import` et versionner le `.wav` et son `.wav.import`. Son provisoire, remplacé par la story 7.7.

### Arène (CA 2)

`rooms/arena/arena.gd` : `_setup_enemy_bullets()` appelé après `_setup_player_bullets()` et avant `_setup_damage_numbers()` (ordre de dessin : tirs du joueur, projectiles ennemis au-dessus, chiffres de dégâts au-dessus de tout ; le dessin réservé « au-dessus de tout le monde » est la 2.4).

- `BulletManager.new()`, `name = "EnemyBullets"`, `camp = Camp.ENEMY`, `capacity = ENEMY_BULLET_CAPACITY` (constante technique, **512** comme le test de charge, commentée), `setup([_walls])` avant `add_child()`, puis `register_hurtbox(_player.hurtbox)`.
- **Aucune apparence** n'est ajoutée par l'arène : les tireurs l'ajoutent (l'émetteur de test aujourd'hui, les ennemis de 2.4 avec la couleur réservée). L'arène ne dépend pas de `debug/`.
- Mettre à jour le commentaire d'en-tête de la classe.

### Panneau F1 (AR24, D18, CA 6, 13)

**Entrée** : action `debug_toggle_panel` dans `project.godot`, F1 (`InputEventKey`, `physical_keycode` 4194332), même forme sérialisée que `debug_toggle_perf`. Puis `--import` et vérifier qu'aucun bruit parasite n'apparaît dans `project.godot`.

**Scène** : `debug/debug_panel.tscn` + `debug/debug_panel.gd` (`class_name DebugPanel extends Control`), sur le modèle de `perf_overlay.tscn` : racine plein écran `mouse_filter = IGNORE`, un `Label` (`%Label`) ancré **en haut à droite** (ne pas recouvrir F3 en haut à gauche), contour sombre comme F3, police du thème. `process_mode = PROCESS_MODE_ALWAYS`, caché au départ. Textes techniques en anglais, exemptés de `tr()` (exemption de `debug/`, à rappeler en commentaire d'en-tête).

**Instanciation** : par **`Main`, en debug seulement**, dans `_ready()`, dans la branche `if OS.is_debug_build()` à côté de `CollisionDrawer`, **avant** `_setup_menus()` (les menus restent dessinés au-dessus). Charger la scène par `load("res://debug/debug_panel.tscn")` **dans** cette branche (pas de `preload` ni de `class_name DebugPanel` référencé dans `main.gd`) : aucune référence à la compilation depuis le code de release (le report de 1.3 sur `CollisionDrawer` montre le problème).

**Commandes** — pourquoi des touches et pas des boutons : en jeu, le réticule cache le curseur système et le panneau ne doit pas mettre le jeu en pause (on teste en direct). Quand le panneau est visible et que le jeu **n'est pas** en pause (`GameClock.paused`), les touches **1 à 5** (lues sur `InputEventKey.physical_keycode`, `KEY_1`…`KEY_5`, appui sans répétition ; touches libres dans le GDD) déclenchent, puis `set_input_as_handled()` :

| Touche | Action | Méthode publique appelée |
|---|---|---|
| 1 | Bascule l'invulnérabilité | `player.health.set_forced_invulnerability(not …)` |
| 2 | +½ armure (refus affiché si le plafond est atteint) | `player.health.add_armor(1)` |
| 3 | −½ cœur, comme un vrai coup (armure d'abord, invulnérabilité respectée, clignotement, son, `Events.player_hit`) | `player.hurtbox.receive(DamageInfo)` de source `DEBUG`, montant `Tuning.COMBAT.hit_damage_half_hearts` |
| 4 | Salve de l'émetteur de test : 3 projectiles en éventail (15°) visés sur le joueur | `BulletManager.fire()` |
| 5 | Bascule le tir automatique de l'émetteur : 1 projectile visé toutes les 0,25 s | `BulletManager.fire()` |

- F1 elle-même marche aussi pendant la pause (comme F2 et F3) ; seules les commandes 1 à 5 sont ignorées en pause. Touches lues avec `pressed and not echo`.
- **Trouver les cibles** à chaque commande (jamais en cache, l'arène est recréée par F5) : le joueur par `get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player` ; le manager ennemi par `Const.GROUP_BULLET_MANAGERS`, premier `BulletManager` de camp `ENEMY` **dont le joueur partage la scène** (le test de charge F5 a un manager ennemi mais pas de joueur : si aucun joueur, la commande ne fait rien et le panneau l'affiche).
- **Émetteur de test** : position fixe en haut au centre de la zone jouable de l'arène, dans l'espace du manager (par exemple `Vector2((Const.ROOM_TILES.x + 2) * Const.TILE_SIZE / 2.0, 2.5 * Const.TILE_SIZE)`, soit (304, 40)) ; vise le joueur (`(cible − origine).normalized()`, rien si la distance est nulle). Il ajoute **sa propre apparence** au manager (texture 8×8 générée en code, couleur du projectile de test de charge, placeholder jusqu'à la 2.4), une fois par manager (retenir l'`instance_id` du manager : une nouvelle arène → nouvelle apparence). `BulletParams` : `damage = Tuning.COMBAT.hit_damage_half_hearts` (**la valeur de `CombatTuning`**, CA 2), vitesse 5 tuiles/s, rayon 0,25 tuile, durée de vie 10 s — ces trois dernières sont des valeurs de **debug** (constantes locales commentées), pas des valeurs du GDD.
- **Tir automatique** : compteur en ticks dans le `_physics_process` du panneau, pondéré par `GameClock.scale(GameClock.Group.ENEMIES)` : nul en pause (le panneau tourne toujours, mais rien ne s'accumule), ×4 plus lent sous F4. Coupé quand le joueur ou le manager disparaît (F5) ; le panneau garde l'état affiché « off ».
- **Affichage** (rafraîchi à chaque commande et quelques fois par seconde, jamais de log par frame) : lignes des commandes avec leur état (`invulnerable: on/off`, `auto fire: on/off`), `hearts 5/6  armor 1  cap 24`, et le dernier refus éventuel (`armor refused: cap reached`, `no player`).
- `Log.debug("combat", ...)` à chaque commande au plus. Les commandes appellent les **mêmes méthodes publiques** que le jeu (architecture, « Outils de debug »), jamais un champ privé.

### Règles d'architecture qui s'appliquent

- GDScript typé partout (AR2) ; fichiers et dossiers en `snake_case`, un script par classe, nœud racine d'une scène en `PascalCase` (`debug_panel.tscn` → `DebugPanel`), constantes `UPPER_SNAKE_CASE`, membres privés `_`, signaux au passé (`player_hit`, `died`, `changed`), gestionnaires `_on_<émetteur>_<signal>` (`_on_hurtbox_damage_received`, `_on_health_died`). Code, commentaires, logs et noms de fichiers **en anglais**.
- **Temps** (AR13) : pas de `Timer`, `create_timer`, `Engine.time_scale`, ni `SceneTree.paused`. Invulnérabilité, clignotement et tir automatique en ticks × `GameClock.scale(groupe)`.
- **Communication** (D3) : `Hurtbox` → `Player` par signal local ; `Player` → `Health` par appel direct ; transverse par `Events.player_hit`. Le bus ne porte que des notifications.
- **Dégâts** : toujours `DamageInfo` → `Hurtbox.receive()` → `Health.apply_damage()`, y compris pour la commande « −½ cœur » de F1.
- **Frontières** : `combat/` ne dépend pas de `player/` (le filtre de touche est un `Callable`, pas une référence au joueur) ; `autoloads/` et `core/` ne dépendent d'aucun dossier de fonctionnalité ; rien ne dépend de `debug/`.
- **Données** (AR9) : les valeurs du GDD de cette story vivent dans `CombatTuning` ; aucune en dur. Valeurs visuelles (clignotement) et de debug (émetteur) : constantes locales commentées.
- **Logs** (AR27) : `Log.info("combat", "player died")` ; `Log.debug` par coup au plus ; rien par tick.
- **Erreurs** (AR28) : valeurs de réglage incohérentes bornées, montant de coup invalide refusé, jamais de plantage.

### Arborescence attendue à la fin de la story

```
game/
├── project.godot                         (UPDATE : action debug_toggle_panel, F1)
├── autoloads/events.gd                   (UPDATE : player_hit)
├── core/
│   ├── constants.gd                      (UPDATE : PHYSICS_PRIORITY_BULLETS, GROUP_PLAYER)
│   ├── tuning.gd                         (UPDATE : COMBAT)
│   └── combat_tuning.gd                  (NEW)
├── data/tuning/combat_tuning.tres        (NEW)
├── combat/
│   ├── health.gd                         (NEW)
│   ├── hurtbox.gd                        (UPDATE : touchable ou non, receive() -> bool)
│   ├── damage_info.gd                    (UPDATE : ENEMY_BULLET, DEBUG)
│   └── bullets/bullet_manager.gd         (UPDATE : priorité, cibles touchables, source)
├── player/player.gd                      (UPDATE : Health, Hurtbox, clignotement, son)
├── audio/sfx/sfx_player_hit.wav          (NEW, + .import)
├── rooms/arena/arena.gd                  (UPDATE : EnemyBullets)
├── main/main.gd                          (UPDATE : panneau F1 en debug)
└── debug/
    ├── debug_panel.tscn / .gd            (NEW)
    └── bullet_load_test.gd               (UPDATE : priorité relative)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (T1) et `deferred-work.md` (T12). Ne pas toucher à `dash.gd`, `training_target.gd`, `hit_feedback.gd`, `damage_numbers.gd`, `audio.gd`, `game_clock.gd`, `settings.gd`, aux menus ni à `strings.csv`.

### Stratégie de test

Aucun framework de test (AR26 : avant le jalon B). Scripts jetables du scratchpad, lancés comme scène (`godot --headless --path game --scene res://.scratch/<scène>.tscn`), avec `await get_tree().physics_frame` pour avancer au tick. Pour l'arène, instancier `main.tscn` (ou `arena.tscn` sous un nœud de test) et récupérer le joueur par le groupe `player`.

1. **Import et lancement** : `--import` puis `--quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau ; `project.godot` sans bruit parasite ; le `.wav` et le `.tres` sont importés.
2. **`Health` seule** (nœud créé dans la scène de test) :
   - après `setup(6, 24, 1.0, PLAYER)` : 6/6, armure 0, ni invulnérable ni mort ;
   - `apply_damage(1)` → renvoie 1, 5/6, `changed` une fois, invulnérable ; nouveau coup pendant 59 ticks → 0 ; au 60e tick → accepté (1,0 s exactement) ;
   - `add_armor(2)` → `true`, armure 2 ; coup → armure 1, cœurs inchangés ; coup de 2 avec armure 1 → armure 0 et −1 cœur ;
   - plafond : `add_armor()` jusqu'à `max + armor = 24` → le suivant renvoie `false`, rien ne change ; ajout partiel (place de 1, demande de 2) → `true`, plafond atteint ; `heal()` à 6/6 → `false` ; `heal(1)` à 4/6 → `true`, 5/6 ;
   - mort : coups jusqu'à 0 → `died` **une fois**, `is_dead()`, coups suivants → 0, `heal` et `add_armor` → `false` ;
   - montant invalide (`NAN`, 0,2) → 0 et une erreur journalisée (lancer ce cas dans un processus séparé ou en release, l'`assert` interrompt en debug) ;
   - `set_forced_invulnerability(true)` → coups refusés, `is_hit_invulnerable()` faux ;
   - `GameClock.global_multiplier = 0.25` → invulnérabilité de 240 ticks ; `GameClock.paused = true` (test isolé, hors `Main`) → le compteur ne bouge pas.
3. **Coups de projectiles ennemis dans l'arène** (tirs posés directement par `EnemyBullets.fire()` avec une apparence ajoutée par le test, `damage = Tuning.COMBAT.hit_damage_half_hearts`) :
   - un projectile visé sur le joueur immobile → au tick du contact : 5/6, `Events.player_hit` reçu une fois avec `(1, DamageInfo.Source.ENEMY_BULLET)`, `EnemyBullets.active_count` diminue de 1, `Audio.voices_of(Player.HIT_SOUND) == 1` ;
   - un second projectile qui arrive 0,5 s plus tard → aucun coup, `active_count` inchangé au passage, il ressort de l'autre côté du joueur et finit dans le mur ;
   - un troisième qui arrive après 1,0 s → coup accepté ;
   - **deux projectiles au même tick** (même origine, même direction) → un seul coup, un seul projectile libéré, l'autre continue (CA 8) ;
   - **dash** : un projectile placé pour toucher le joueur au **premier tick** du dash (dash simulé par l'action, attendre le tick d'application) → aucun coup, le projectile continue (CA 4, CA 10) ; vérifier `process_physics_priority` des deux managers = `Const.PHYSICS_PRIORITY_BULLETS` ;
   - **clignotement** : pendant l'invulnérabilité, `Sprite.visible` alterne avec une demi-période de 6 ticks ; à la fin, `visible == true` ; la teinte du dash (`modulate`) n'est pas modifiée ;
   - **pause** (action `pause`) pendant l'invulnérabilité : compteur et `visible` figés pendant 60 ticks, reprise où ils en étaient ;
   - **mort** : coups jusqu'à 0 → `Log.info` « player died » une fois, projectiles suivants qui traversent le joueur, sprite visible ; aller-retour F5 → nouveau joueur à 6/6.
4. **Hurtbox et cibles** :
   - les tirs du joueur touchent toujours les cibles : flash, `Events.enemy_damaged` une fois par tir, `DamageInfo.Source.PLAYER_SHOT` ;
   - cible avec un filtre qui renvoie `false`, puis avec `monitorable = false`, puis avec sa forme `disabled` → le tir la traverse, aucun `damage_received`, **aucun** `enemy_damaged`, `receive()` renvoie `false` (CA 7, 9).
5. **Panneau F1** (dans `main.tscn`, debug) : F1 simulé → visible ; touche 1 → projectiles sans effet, pas de clignotement ; touche 1 à nouveau → coups de nouveau comptés ; touche 2 → armure 1 ; touche 3 → armure 0 (armure d'abord), `Events.player_hit` source `DEBUG`, puis touche 3 pendant l'invulnérabilité → rien ; touche 4 → `active_count` +3 ; touche 5 → un tir toutes les 15 ticks, aucun pendant une pause de 60 ticks, un toutes les 60 ticks sous F4 ; touches 1 à 5 pendant la pause → ignorées ; F1 de nouveau → caché, touches 1 à 5 sans effet ; F5 (test de charge) puis touche 4 → rien, « no player » affiché ; F5 retour → les commandes marchent sur le nouveau joueur (nouvelle apparence ajoutée une fois) ; recherche dans `main.gd` : aucune référence à `DebugPanel` hors de la branche debug.
6. **Fenêtré sous WSLg** (indicatif, captures `get_viewport().get_texture().get_image().save_png()`) : clignotement visible sur deux captures décalées ; panneau F1 lisible en haut à droite, sans recouvrir F3 ; projectiles de test visibles au-dessus des tirs du joueur ; réticule toujours visible pendant le clignotement.
7. **Régression** : marche (96 px/s), dash (48 px), tir (4 tirs/s, 224 px/s) et chiffres de dégâts inchangés ; pause et réglages inchangés ; F2 affiche aussi la hurtbox du joueur (6×6, confondue avec la hitbox) ; F3, F4 ; F5 et test de charge `Bullets 400 | refused 0` avec la nouvelle priorité (le test de charge passe toujours après son manager).
8. **Recherche des interdits** : `grep -rnE 'print\(|Timer|create_timer|time_scale|tree\(\)\.paused|randf|randi|randomize|shuffle|pick_random|/root/' game --include=*.gd` : seules les occurrences attendues (`log.gd`, commentaires). Aucun `Log.` dans `_process` ni `_physics_process` ; aucun nombre du GDD en dur (`6`, `24`, `1.0` de santé) hors de `combat_tuning.tres` et `combat_tuning.gd`.
9. **Étapes humaines** (à consigner `NON ÉVALUÉ`, ne pas déclarer vérifiées) : ressenti du clignotement (cadence, lisibilité), son de coup à l'oreille, lisibilité d'un coup reçu en plein combat.

### Commit

Directement sur `main`, Conventional Commits en anglais, `git push` après chaque commit (consigne du projet). Commiter par tâche cohérente, chaque commit laissant le jeu lançable. Exemples : `docs(architecture): add health terms and bullet tick order to the lexicon` ; `feat(combat): add combat tuning and player health with armor and hit invulnerability` ; `feat(combat): let hurtboxes refuse hits and tick bullet managers after entities` ; `feat(player): take enemy bullet hits with blink and hit sound` ; `feat(debug): add f1 debug panel with test bullet emitter` ; `docs(story): record story 2.1 implementation progress`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `combat/health.gd`, `debug/debug_panel.tscn/.gd`, `data/tuning/combat_tuning.tres`, `audio/sfx/sfx_player_hit.wav`.
- **Écarts assumés** :
  - L'armure vit dans `Health` (pas de `combat/armor.gd`, prévu par l'arborescence) : elle se consomme dans le même calcul que les cœurs et partage le plafond ; un second composant obligerait à les coordonner.
  - Le script de `CombatTuning` est dans `core/`, comme les autres Resources de réglage du dépôt (`data/` ne contient que des `.tres`).
  - `Health` et `Hurtbox` du joueur sont créés en code et non dans `player.tscn` (injection avant `add_child`, taille venue de `Tuning`).
  - La hurtbox accepte ou refuse un coup par un filtre (`Callable`) fourni par son propriétaire, au lieu du `player.is_invulnerable()` lu directement par le `BulletManager` dans l'exemple du pattern P2 : `combat/` ne dépend pas de `player/`, et le même mécanisme servira aux ennemis (mort, invulnérabilité). L'epic 3 (graze, dash parfait) étendra la lecture si elle doit distinguer le dash.
  - `Events.player_hit` porte `(damage: int, source: int)` : signal nouveau, déjà cité par l'architecture sans signature.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md`, de la mémoire du projet et du brief du pipeline :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit, et la ligne `Co-Authored-By` en fin de message.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (aucun dans cette story ; le panneau F1 est du debug, exempté).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.
- Pipeline automatisé de l'epic 2 : Kroustille n'est pas disponible avant la fin de l'epic ; toute question se tranche et se consigne ci-dessous.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Cœurs max et soin** — Question : « l'ajout de cœurs » du CA 5 parle-t-il de soin ou de cœurs max ? Choix : `Health` a des cœurs max (`max_half_hearts`, 6, fixes dans cette story) ; `heal()` soigne jusqu'aux cœurs max ; le plafond de 12 cœurs porte sur `cœurs max + armure` (modèle d'Isaac). Raison : le GDD parle de « −1 cœur max » (Dent qui tombe) et d'un cœur de boutique qui « soigne », ce qui suppose des cœurs max ; aucun objet du MVP n'en ajoute.
2. **Ajout partiel sous le plafond** — Choix : on ajoute ce qui tient et l'appel renvoie `true` ; `false` seulement si rien ne tient. Raison : « au plafond, l'armure reste au sol » ne vise que le plafond atteint ; le cas partiel (armure de boutique +1 cœur avec ½ place) est rare.
3. **Unités de `CombatTuning`** — Choix : cœurs stockés en demi-cœurs (`starting_half_hearts = 6`, `heart_cap_half_hearts = 24`, `hit_damage_half_hearts = 1`). Raison : `Health` compte en demi-cœurs entiers ; pas de conversion ni de fraction dans un `int`.
4. **Départ, plafond et coup dans `CombatTuning`** (pas dans `PlayerTuning`) — Raison : le CA 2 nomme `CombatTuning` ; la santé est un sujet de combat.
5. **Armure dans `Health`**, pas de `combat/armor.gd` — Raison : même calcul, même plafond (voir « Écarts assumés »).
6. **`Health` pensée pour le joueur** (demi-cœurs entiers) — Raison : les PV flottants des ennemis arrivent avec la 2.3, qui décidera de réutiliser ou non le composant ; ne rien concevoir d'avance.
7. **Touche par filtre de la hurtbox** — Choix : `Hurtbox.set_hit_filter(Callable)` + `is_hittable()` lu par le `BulletManager` une fois par tick, et `receive()` qui ne fait rien pour un coup refusé. Raison : règle d'un coup les reports de 1.5 (état de la hurtbox) et 1.6 (`enemy_damaged` fictif), sans faire dépendre `combat/` de `player/`.
8. **Un coup par tick sur le joueur** (`one_hit_per_tick`) — Raison : sans cela, deux projectiles arrivés au même tick seraient détruits alors que le second ne compte pas, contre le CA 3. Les ennemis ne l'activent pas (un tir du joueur qui traverserait un ennemi serait faux).
9. **Ordre de traitement** — Choix : `process_physics_priority = 100` pour tous les `BulletManager` (`Const.PHYSICS_PRIORITY_BULLETS`), entités à 0. Raison : règle les reports de 1.4 et 1.5 en une ligne, indépendamment de l'ordre de l'arbre ; vérifié en 4.7.2 par une sonde.
10. **Cas résiduel** : une cible devenue intouchable entre le test et la livraison du même tick (deux ennemis tués au même tick, par exemple) a déjà fait détruire le projectile. Accepté : un tick de décalage, sans effet visible ; le joueur est protégé par le point 8.
11. **Mort dans cette story** — Choix : `died` émis une fois, `Log.info`, joueur intouchable, rien d'autre ; F5 aller-retour pour repartir. Raison : l'écran de réveil, `run_ended` et la relance sont la 2.2.
12. **Panneau F1 instancié par `Main` dès cette story** (l'epic écrit « puis par `Main` dès la Story 2.2 ») — Raison : l'architecture dit « instanciée par `Main` seulement en debug », `Main` existe déjà et instancie `CollisionDrawer` de la même façon ; l'arène ne doit pas dépendre de `debug/`. Chargé par `load()` dans la branche debug pour ne laisser aucune référence en release.
13. **Commandes du panneau aux touches 1 à 5**, pas de boutons — Raison : le curseur est caché par le réticule en jeu et le panneau ne met pas le jeu en pause ; touches libres dans le GDD ; lues en `physical_keycode` (outil de debug, hors des actions joueur que la 1.7 rendra réassignables).
14. **« −½ cœur » de F1 = un vrai coup** (`Hurtbox.receive()`, source `DEBUG`) : armure d'abord, invulnérabilité respectée. Raison : l'architecture impose que tout dégât passe par `DamageInfo` → `Hurtbox.receive()`, et que le debug appelle les méthodes publiques du jeu.
15. **Émetteur de test** : position fixe en haut au centre de l'arène, salve de 3 en éventail et tir automatique à 4/s, visés sur le joueur ; vitesse 5 tuiles/s (celle de La Veilleuse), constantes de debug ; apparence provisoire (couleur du test de charge) ajoutée par l'émetteur. Raison : de quoi vérifier à l'œil l'invulnérabilité (les projectiles suivants traversent) et le dash, sans concevoir les ennemis de la 2.4.
16. **Clignotement** : `Sprite2D.visible`, demi-période de 0,1 s, constante visuelle provisoire. Raison : le GDD ne donne pas de cadence ; `modulate` sert déjà au dash et masquer `Player` cacherait le réticule.
17. **Son de coup** : `sfx_player_hit.wav` provisoire généré par script, grave (220 → 90 Hz, 0,15 s). Raison : FR13 demande un son ; Kroustille a trouvé le son de tir trop aigu.
18. **`Events.player_hit(damage: int, source: int)`**, émis par `Player` — Raison : types primitifs sur le bus ; la cause servira à la télémétrie (2.8), le montant au HUD et aux règles de lucidité.
19. **Mesure de 10 minutes à 400 projectiles non faite** (report de 1.2 « avant le combat ennemi ») : pas bloquante pour cette story (aucun motif ennemi ajouté) ; à rappeler en fin d'epic.

### Questions ouvertes

Aucune bloquante. Points à faire valider par Kroustille en fin d'epic : les décisions ci-dessus, en priorité 1 (cœurs max), 12 (instanciation de F1) et 16 (cadence du clignotement, à juger au jeu).

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1 : Encaisser des coups]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR11 à FR14)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR7, AR8, AR9, AR13, AR24, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Santé et armure] (3 cœurs, plafond de 12 armure comprise, ½ cœur, 1,0 s, clignotement et son, armure perdue en premier)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Déplacement et dash] (hitbox 6×6, invulnérabilité du dash 0,15 s, le dash traverse les projectiles)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Contrôles] (touches 1 à 5 libres)
- [Source: _bmad-output/game-architecture.md#Communication entre systèmes (D3)] (`Events.player_hit`)
- [Source: _bmad-output/game-architecture.md#Dégâts et unités] (`DamageInfo` → `Hurtbox.receive()` → `Health.apply_damage()`, demi-cœurs entiers, armure d'abord)
- [Source: _bmad-output/game-architecture.md#P2. Graze et dash parfait] (projectile qui continue pendant l'invulnérabilité, détruit sur un coup)
- [Source: _bmad-output/game-architecture.md#Outils de debug] (F1, scène séparée instanciée par `Main` en debug, méthodes publiques)
- [Source: _bmad-output/game-architecture.md#Création d'entités] (`setup()` avant `add_child()`) et [#Accès aux données] (`Tuning.COMBAT`)
- [Source: _bmad-output/game-architecture.md#Temps (D7)] et [#Frontières architecturales]
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (reports de 1.4, 1.5 et 1.6 listés dans « Reports traités par cette story »)
- [Source: _bmad-output/implementation-artifacts/1-6-mettre-en-pause-et-regler-le-jeu.md] (pause, `enemy_damaged`, leçons de test headless)
- [Source: _bmad-output/implementation-artifacts/1-5-viser-et-tirer.md] (`Hurtbox`, `BulletManager`, son généré par script)
- Documentation Godot 4.7 consultée par Context7 à la création : `Node.process_physics_priority` (« lower priority values are called first ; same priority → tree order »), avertissement `UNSAFE_CAST` et motif `is` avant affectation typée (`static_typing.rst`). Sonde headless en 4.7.2 : priorité globale à travers l'arbre, affectation de `Callable.call()` à un `bool` typé acceptée sous les avertissements du projet.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-21).

### File List
