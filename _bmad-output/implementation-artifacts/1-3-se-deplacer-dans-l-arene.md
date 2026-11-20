---
baseline_commit: 35880ff
---

# Story 1.3 : Se déplacer dans l'arène

Status: review

## Story

En tant que joueur,
je veux déplacer mon personnage dans une arène, au clavier ou au stick, avec une réponse immédiate,
afin de sentir un contrôle nerveux.

**Exigences couvertes :** FR1, FR2, FR9 (caméra fixe), AR9, AR12, AR24 (F2), AR29 (caméra et bande de HUD).

## Critères d'acceptation

1. **Étant donné** la scène d'arène : une salle d'un écran, 36×19 tuiles jouables entourées de murs, sous une bande de HUD de 24 px, **quand** le jeu démarre, **alors** le joueur apparaît dans l'arène, et la caméra est fixe et centrée sur la salle.
2. **Étant donné** le joueur dans l'arène, **quand** il se déplace avec ZQSD ou le stick gauche, **alors** il atteint 6 tuiles/s en 0,06 s et s'arrête en 0,04 s, dans les 8 directions.
3. Il ne va pas plus vite en diagonale.
4. Les touches par défaut sont des **touches physiques** : ZQSD sur un clavier AZERTY, WASD sur un clavier QWERTY.
5. Les entrées sont lues dans `_physics_process` par les actions `InputMap` `move_*`.
6. Les murs l'arrêtent.
7. **Étant donné** le joueur, avec un sprite provisoire de 16×24, **quand** on inspecte sa hitbox, **alors** elle mesure 6×6 px, centrée sur le torse.
8. La vitesse, l'accélération, la décélération et la taille de la hitbox viennent de `PlayerTuning.tres` et se règlent sans toucher au code.
9. **Étant donné** un build de debug, **quand** on appuie sur F2, **alors** les hitbox et hurtbox s'affichent.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture ou par l'état du dépôt) :

10. L'arène est la scène de démarrage de **tous** les builds (la mire de netteté de la story 1.1 ne l'est plus). En debug, F5 bascule toujours entre l'arène et le test de charge, dans les deux sens, sans erreur.
11. Le déplacement obéit à `GameClock` : avec `GameClock.paused = true` (échelle 0), le joueur est figé.
12. L'interpolation physique 2D est activée (AR12, D6) et le joueur ne « glisse » pas à son apparition.

## Tâches / sous-tâches

- [x] **T1. Socle partagé** (CA 1, 8, 9)
  - [x] `Const` : `HUD_BAND_HEIGHT: int = 24`, `ROOM_TILES: Vector2i = Vector2i(36, 19)` (tuiles jouables, murs exclus), `GROUP_DEBUG_SHAPES: StringName`.
  - [x] `core/player_tuning.gd` : `class_name PlayerTuning extends Resource` (voir « `PlayerTuning` »).
  - [x] `data/tuning/player_tuning.tres` (valeurs du GDD) et `Tuning.PLAYER` (`preload`, voir « `PlayerTuning` »).
- [x] **T2. Actions d'entrée et réglages du projet** (CA 2, 4, 5, 12)
  - [x] `project.godot` : actions `move_up`, `move_down`, `move_left`, `move_right` (touches physiques W/A/S/D + stick gauche, voir « Entrées »).
  - [x] `project.godot` : action `debug_toggle_collisions` sur F2 (touche physique, `physical_keycode` 4194333), même forme que `debug_toggle_perf`.
  - [x] `project.godot` : `physics/common/physics_interpolation=true`. Ne pas toucher à la VSync (déjà activée par défaut).
- [x] **T3. `PlayerMotor`** (CA 2, 3, 8)
  - [x] `player/player_motor.gd` : `class_name PlayerMotor extends RefCounted`, logique pure de vitesse (voir « `PlayerMotor` »).
- [x] **T4. `Player`** (CA 2, 5, 6, 7, 11, 12)
  - [x] `player/player.tscn` + `player/player.gd` : `CharacterBody2D`, sprite provisoire 16×24, forme de collision 6×6 (voir « `Player` »).
- [x] **T5. Arène et caméra** (CA 1, 6)
  - [x] `rooms/arena/arena.tscn` + `rooms/arena/arena.gd` : couches `Floor` et `Walls` construites en code, joueur, caméra fixe (voir « Arène » et « Caméra »).
- [x] **T6. `Main`** (CA 1, 10)
  - [x] Démarrer sur l'arène dans tous les builds ; F5 bascule arène ↔ test de charge ; instancier le `CollisionDrawer` en debug (voir « `Main` »).
- [x] **T7. F2 : affichage des formes de collision** (CA 9)
  - [x] `debug/collision_drawer.gd` : `class_name CollisionDrawer` (voir « F2 »).
- [x] **T8. Lexique** : ajouter à `game-architecture.md` (section « Lexique ») la ligne `Arène ; bande de HUD | arena ; hud_band` (AR32 : un terme entre dans le lexique avant le code).
- [x] **T9. Vérifications headless** (CA 2 à 8, 11)
  - [x] Scripts jetables dans le scratchpad (pas dans le dépôt) : voir « Stratégie de test ».
- [x] **T10. Vérifications fenêtrées sous WSLg** (CA 1, 9, 10, 12)
  - [x] Arène à l'écran, bandes noires, netteté du sprite en mouvement, F2, F5 dans les deux sens, capture d'écran.
- [x] **T11. Régression** : import et lancement headless sans erreur, recherche des interdits, F3 et F5 de 1.1 et 1.2 toujours conformes.
- [x] **T12. Reports** : consigner dans `deferred-work.md` ce qui n'a pas pu être vérifié (manette physique, ressenti au stick, voir « Stratégie de test »).

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

Le joueur se déplace dans une arène vide, rien d'autre. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Dash, invulnérabilité, tampon d'entrée, API d'écriture de `GameClock`, ralenti F4 | 1.4 |
| Visée, tir, réticule, `ShotTuning`, `BulletManager` du joueur dans l'arène, cible d'entraînement, `Hurtbox`/`Hitbox` (scripts), `Audio` | 1.5 |
| Pause effective et menu, réglages, `tr()` et localisation | 1.6 |
| Autres actions `InputMap` (`aim_*`, `shoot`, `dash`, `pause`…), bascule clavier-souris ↔ manette, réassignation | 1.7 |
| Export, latence mesurée | 1.8 |
| Santé, coups, `Hurtbox` du joueur | 2.1 |
| HUD (la bande de 24 px reste **vide** ici) | 2.7 |
| Obstacles, trous, meubles, portes, salles peintes, `Room`, `Run` | Epic 4 |
| Sprites définitifs | 7.x |

Aucun texte affiché au joueur dans cette story : pas de `tr()` à écrire.

### État actuel du dépôt (stories 1.1 et 1.2, `done`)

- `Main` (`game/main/main.gd`, classe `Main`, racine `Node`) : enfants `ActiveScene` (`%ActiveScene`) et `UI` (`CanvasLayer`, contient `PerfOverlay`). Aujourd'hui, **en debug seulement**, il charge la mire `res://debug/scale_test_pattern.tscn` par `_show_debug_scene(path) -> bool` (qui retire de l'arbre puis `queue_free()` tous les enfants d'`ActiveScene`, puis instancie). `_unhandled_input` : F5 (`debug_load_test`) bascule mire ↔ `res://debug/bullet_load_test.tscn` ; le drapeau `_load_test_active` n'est inversé qu'après un chargement réussi (correctif de revue de 1.2 : à conserver). Il vérifie aussi `Const.VIEWPORT` et les noms de couches de collision en debug, et fixe `Window.min_size`.
- `Const` : `TILE_SIZE = 16`, `VIEWPORT = 640×360`, `GROUP_BULLET_MANAGERS`, `integer_scale()`, masques `LAYER_*` (`LAYER_WALLS = 1 << 0`, `LAYER_PLAYER = 1 << 4`, …, alignés sur `[layer_names]` de `project.godot`), `LAYER_NAMES`.
- `Tuning` : `@abstract class_name Tuning`, **vide** (« chaque story y ajoutera sa Resource »). Il n'existe ni dossier `data/`, ni `player/`, ni `rooms/`.
- `GameClock` : `scale(group) -> float`, `paused`. **Pas d'API d'écriture** : ne pas en ajouter (1.4).
- `Log` : catégories valides `run`, `room`, `combat`, `lucidity`, `items`, `gen`, `save`, `input`, `audio`, `ui`. Ici : `room` (arène) et `input` si besoin. **Aucun log par frame.**
- `BulletManager` (1.2) : attend `setup(solid_layers)` avant `add_child()`, des couches à la **même origine** que lui (position nulle) et dont le `TileSet.tile_size` vaut `Const.TILE_SIZE`. **Cette story n'ajoute aucun `BulletManager` à l'arène** (1.5 et epic 2). Mais l'arène doit être compatible : couches `Walls` à l'origine de l'arène, tuiles de 16 px.
- `debug/bullet_load_test.gd` construit déjà un `TileMapLayer` « Walls » en code (une `TileSetAtlasSource` à image générée, une tuile en `(0, 0)`). **C'est le modèle de la construction de l'arène**, avec en plus la couche de physique (voir « Arène »). Ne pas modifier cette scène de test.
- `debug/scale_test_pattern.*` : n'est plus instanciée par `Main` après cette story. **La laisser en place, intacte et non référencée** (1.8 peut la réutiliser) ; ne pas la supprimer.
- `project.godot` : aucune action de déplacement ; `[physics] common/physics_ticks_per_second=60` ; pas d'interpolation physique. Rendu `gl_compatibility`, filtre `Nearest`, stretch `viewport` + `keep` + `integer`.
- Environnement : Godot 4.7.2 via WSLg, `godot` dans le `PATH`. **Pas de manette sous WSL** (sans `usbipd`) : le stick réel ne se teste pas ici. Les FPS WSLg (Mesa llvmpipe) ne sont pas représentatifs.

### Leçons des stories 1.1 et 1.2 à appliquer

- **Typage strict, avertissements en erreur** (`untyped_declaration`, `unsafe_*` à 2). Un `Variant` ne se convertit pas avec `int(...)` : passer par une variable typée. Les divisions entières voulues demandent `@warning_ignore("integer_division")`.
- **Aucune valeur de gameplay en dur** (NFR9, AR9) : vitesse, accélération, décélération, taille de hitbox viennent de la Resource. Les dimensions de salle (36×19), la bande de HUD (24) et la taille du sprite (16×24) sont des constantes **structurelles** (architecture, NFR11), pas du gameplay : elles vivent dans `Const` ou en constante locale.
- **Couches de collision** : toujours par `Const.LAYER_*`, jamais par un nombre.
- **Injection** : `setup()` avant `add_child()` ; dépendances internes d'une scène par `%NomUnique` ou `@export`. Pas de `/root/...`, pas de `get_parent().get_parent()`.
- **Fichiers `*.uid` générés par Godot : à versionner.**
- **Vérifications** : `godot --headless --path game --import`, puis `godot --headless --path game --quit-after <n>`. Zéro `SCRIPT ERROR`, zéro `Parse Error`. `--script` ne résout pas les autoloads : les vérifications tournent comme une **scène** du scratchpad (`godot --headless --path game --scene <scène>`), avec `call_deferred` pour attendre que la racine soit prête.
- **Reports de la revue de 1.2 qui touchent cette story :**
  - « F5 vide tous les enfants d'`ActiveScene` » : résolu par construction, l'arène est recréée à chaque retour de F5 (le joueur repart de zéro, c'est voulu). Ne rien ajouter.
  - « Projectile qui sort de la zone tuilée » : impossible ici, le cadre de murs est fermé. Ne pas créer d'ouverture.
  - « Couches solides remplacées pendant la vie du manager » : sans objet tant que l'arène ne porte pas de manager.

### `PlayerTuning` (AR9, D4)

`class_name PlayerTuning extends Resource`, dans **`game/core/player_tuning.gd`** : `core/` ne peut dépendre d'aucun dossier de fonctionnalité, et `Tuning` (dans `core/`) type ses constantes avec cette classe. (Variance assumée par rapport à l'arborescence, qui ne cite pas ces classes : un `PlayerTuning` dans `player/` ferait dépendre `core/` de `player/`.) `data/` ne contient que des `.tres`.

| Champ | Type | Sens | Valeur (GDD) |
|---|---|---|---|
| `move_speed` | `float` | tuiles par seconde | 6,0 |
| `acceleration_time` | `float` | secondes pour passer de l'arrêt à la vitesse max | 0,06 |
| `deceleration_time` | `float` | secondes pour passer de la vitesse max à l'arrêt | 0,04 |
| `hitbox_size` | `float` | côté du carré, en **tuiles** | 0,375 (= 6 px) |

- Distances en tuiles, durées en secondes ; **la conversion en pixels se fait à un seul endroit** (`PlayerMotor` pour les vitesses, `Player` pour la hitbox, via `Const.TILE_SIZE`).
- 0,375 × 16 = 6 exactement en virgule flottante : pas d'arrondi à craindre. Le palier Lucide (4×4, epic 3) ajoutera son champ plus tard : ne pas le prévoir.
- `@export` typés ; `@export_range` bienvenu pour borner les saisies dans l'éditeur.
- `data/tuning/player_tuning.tres`, en texte :

```
[gd_resource type="Resource" script_class="PlayerTuning" load_steps=2 format=3]

[ext_resource type="Script" path="res://core/player_tuning.gd" id="1_tuning"]

[resource]
script = ExtResource("1_tuning")
move_speed = 6.0
acceleration_time = 0.06
deceleration_time = 0.04
hitbox_size = 0.375
```

- `Tuning` : `const PLAYER: PlayerTuning = preload("res://data/tuning/player_tuning.tres")`. Les Resources sont **en lecture seule à l'exécution** : aucune affectation sur `Tuning.PLAYER`.
- Après création des fichiers, lancer `godot --headless --path game --import` : Godot peut ajouter un `uid=` aux fichiers ; le versionner.

### `PlayerMotor` : la logique de vitesse, sans scène

`class_name PlayerMotor extends RefCounted`, `game/player/player_motor.gd`. Pur : aucune dépendance à un nœud, donc vérifiable sans lancer le jeu (AR26, esprit).

```gdscript
func _init(tuning: PlayerTuning) -> void   # précalcule max_speed_px, accel_px, decel_px (px/s, px/s²)
func step(wish: Vector2, dt: float) -> Vector2   # avance la vitesse de dt secondes et la renvoie (px/s)
var velocity: Vector2   # lecture seule pour l'extérieur
```

- `wish` : sortie de `Input.get_vector` (longueur ≤ 1).
- Cible : `wish * max_speed_px`. Taux : `accel_px` si `wish != Vector2.ZERO`, sinon `decel_px`. `velocity = velocity.move_toward(target, rate * dt)`.
- `max_speed_px = move_speed * Const.TILE_SIZE` ; `accel_px = max_speed_px / acceleration_time` ; `decel_px = max_speed_px / deceleration_time`. Borner les durées par un minimum technique (par exemple 0,001 s, constante du script) pour ne jamais diviser par zéro ; une durée négative ou nulle dans la Resource est une donnée invalide : `Log.error("input", ...)` une fois, valeur sûre. Pas d'`assert` seul (AR28).
- **Pas de lecture de `GameClock` ici** : `dt` arrive déjà mis à l'échelle.
- Conséquences chiffrées à 60 Hz (`Engine.physics_ticks_per_second`, ne pas coder 60) : 96 px/s au maximum ; le pas de 1/60 s atteint la vitesse max en **4 ticks** (3,6 arrondi au tick supérieur) et l'arrêt en **3 ticks** (2,4 arrondi). C'est conforme à 0,06 s et 0,04 s à un tick près ; les vérifications le tolèrent.
- Un demi-tour passe par `accel_px` (cible opposée) : il dure donc deux fois le temps d'accélération. Valeur de départ, à juger au ressenti.

### `Player` (FR1, FR2, D2)

`game/player/player.tscn`, racine **`Player`** (`CharacterBody2D`), script `game/player/player.gd` (`class_name Player`).

Nœuds : `Player` → `Sprite` (`Sprite2D`, `%Sprite`) et `Hitbox` (`CollisionShape2D`, `%Hitbox`, `RectangleShape2D`).

- **Origine du nœud = centre du torse.** Le sprite 16×24 est centré sur l'origine (`centered = true`, décalage nul) ; la forme de collision l'est aussi. Les stories de tir (1.5) émettent depuis cette origine. Quand les vrais sprites arriveront (epic 7), c'est le décalage du `Sprite` qui s'ajustera, pas la hitbox.
- **Sprite provisoire** : texture 16×24 générée en code (comme `BulletLoadTest._make_bullet_texture`), couleur unie avec un liseré d'un pixel plus clair. Les couleurs en dur sont tolérées ici, avec un commentaire « placeholder until epic 7 » ; la taille 16×24 est une constante locale (`SPRITE_SIZE`).
- **`CharacterBody2D` : `motion_mode = CharacterBody2D.MOTION_MODE_FLOATING`.** Le défaut (`GROUNDED`) est celui d'un platformer : il fausse tout en vue de dessus. `up_direction` ne sert alors à rien.
- **Couches** (en code dans `_ready()`, par `Const`) : `collision_layer = Const.LAYER_PLAYER`, `collision_mask = Const.LAYER_WALLS`. Les obstacles bas et hauts et les meubles rejoindront le masque avec l'epic 4 : ne pas les ajouter maintenant.
- **Forme** : `RectangleShape2D` dont `size = Vector2.ONE * Tuning.PLAYER.hitbox_size * Const.TILE_SIZE`, posée en `_ready()` sur une **instance neuve** (`RectangleShape2D.new()`), jamais une sous-ressource de la scène partagée modifiée. Le `Hitbox` rejoint le groupe `Const.GROUP_DEBUG_SHAPES` en code (`add_to_group`) : une seule source de vérité pour le nom du groupe.
- **Simplification assumée (à connaître)** : la forme 6×6 sert à la fois de collision contre les murs et de « hitbox » du GDD (la zone où les tirs ennemis blessent). L'architecture prévoit à terme deux choses distinctes : le corps (`layer player`) et la `Hurtbox` (`Area2D`, couche `player_hurtbox`, scripts en 1.5 et 2.1). Dès qu'elles existent, ou au palier Lucide (4×4), la hurtbox deviendra un nœud séparé et le corps gardera sa taille. Ne pas créer d'`Area2D` ni de `Hurtbox` ici.
- **Boucle** :

```gdscript
func _physics_process(delta: float) -> void:
	var dt: float = delta * GameClock.scale(GameClock.Group.PLAYER)   # une lecture par tick
	var wish: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var motor_velocity: Vector2 = _motor.step(wish, dt)
	# move_and_slide() integrates with the unscaled physics delta: scaling the velocity is the same as scaling delta.
	velocity = motor_velocity * GameClock.scale(GameClock.Group.PLAYER)
	move_and_slide()
```

  - `velocity` est réécrit à chaque tick à partir du moteur : `move_and_slide()` le modifie en glissant, ne **jamais** le relire comme état du moteur.
  - Échelle 0 (pause) : `dt = 0`, `velocity = 0`, le joueur ne bouge pas et garde sa vitesse intérieure.
  - Pas de `Timer`, pas de `Engine.time_scale`, pas de RNG.
  - Aucune lecture d'entrée dans `_process` ni `_input` (CA 5).
- **Apparition** : le joueur est placé dans la scène de l'arène (voir plus bas). L'interpolation physique est active : après tout placement par code, appeler `reset_physics_interpolation()` **après** avoir fixé `position` (sinon une traînée d'une frame). Placé dans le `.tscn`, il n'y a rien à faire.
- **Ressenti à surveiller, sans le régler d'avance** : en `MOTION_MODE_FLOATING`, `wall_min_slide_angle` (15° par défaut) arrête le corps au lieu de le laisser glisser quand il heurte un mur presque de face. Au clavier (angles de 0°, 45°, 90°) rien à signaler ; au stick, on peut « accrocher » en longeant un mur. Laisser le défaut, tester un stick simulé incliné de ~10° contre un mur, et ne mettre `wall_min_slide_angle = 0.0` que si le glissement est collant. Consigner le choix.

### Entrées (D6, AR12)

Actions déclarées dans `project.godot`, section `[input]`, en copiant la forme des actions `debug_*` existantes (`InputEventKey` avec `keycode` 0 et `physical_keycode`) :

| Action | Clavier (touche **physique**) | `physical_keycode` | Stick gauche |
|---|---|---|---|
| `move_up` | W (Z en AZERTY) | 87 | axe 1, valeur −1,0 |
| `move_down` | S | 83 | axe 1, valeur +1,0 |
| `move_left` | A (Q en AZERTY) | 65 | axe 0, valeur −1,0 |
| `move_right` | D | 68 | axe 0, valeur +1,0 |

- Pour le stick : `Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":0,"axis_value":-1.0,"script":null)` (axe 0 = X gauche, axe 1 = Y gauche, `device` −1 = toutes les manettes). Le plus sûr : écrire une action à la main, ouvrir le projet dans l'éditeur (ou relancer `--import`) et vérifier la ré-sérialisation.
- Zone morte de chaque action : `0.2` (comme les actions de debug). `Input.get_vector()` normalise la diagonale clavier (longueur 1 : **pas plus vite en diagonale**, CA 3) et applique la zone morte circulaire du stick. Ne pas recalculer la normalisation à la main.
- Les noms `move_up/down/left/right` sont ceux du motif `move_*` de l'architecture et de 1.7 : ne pas en inventer d'autres. La bascule clavier-souris ↔ manette est la story 1.7.

### Arène (FR9 `[A]`, AR16, AR29)

`game/rooms/arena/arena.tscn`, racine **`Arena`** (`Node2D`), script `arena.gd` (`class_name Arena`).

Nœuds : `Arena` → `Floor` (`TileMapLayer`), `Walls` (`TileMapLayer`), `Player` (instance de `player.tscn`), `Camera` (`Camera2D`). Les noms `Floor` et `Walls` sont ceux du format de salle de l'architecture (D10) : l'epic 4 les conservera en y peignant les vraies salles.

**Géométrie** (origine monde = coin haut-gauche du cadre de murs, en pixels) :

- Zone jouable : 36×19 tuiles = cellules `x` de 1 à 36, `y` de 1 à 19. Cadre de murs : cellules `x` ∈ {0, 37}, `y` ∈ {0, 20}. Cadre total : 38×21 tuiles = **608×336 px**.
- Bords intérieurs : `x` de 16 à 592, `y` de 16 à 320. Centre jouable (apparition du joueur) : **(304, 168)**.
- Cohérence avec l'écran : 360 − 24 (bande de HUD) = 336 = 21 × 16 ✓ ; 640 − 608 = 32, soit 16 px de marge de chaque côté ✓. Vérifier au démarrage, en debug : `assert(Const.VIEWPORT.y - Const.HUD_BAND_HEIGHT == (Const.ROOM_TILES.y + 2) * Const.TILE_SIZE)` et la même chose pour la largeur (marge ≥ 0). Les cellules de murs se calculent depuis `Const.ROOM_TILES`, pas depuis des nombres.

**Construction (provisoire : l'epic 4 la remplace par des salles peintes)** : dans `_ready()`, un `TileSet` partagé par les deux couches, construit en code sur le modèle de `BulletLoadTest._build_walls()` :

- `TileSet.tile_size = Vector2i(Const.TILE_SIZE, Const.TILE_SIZE)` (le `BulletManager` l'exigera).
- Deux `TileSetAtlasSource`, une par image générée (mur, sol). **Ordre qui compte** : `texture`, puis `texture_region_size`, puis `create_tile(Vector2i.ZERO)`. Le sol doit se distinguer des murs ; un damier léger à peine visible aide à juger le mouvement.
- **Couche de physique pour les murs (nouveau par rapport à 1.2)** : `tile_set.add_physics_layer()` (indice 0), `tile_set.set_physics_layer_collision_layer(0, Const.LAYER_WALLS)`, `set_physics_layer_collision_mask(0, 0)`. Sur la tuile de mur : `var data: TileData = source.get_tile_data(Vector2i.ZERO, 0)`, `data.add_collision_polygon(0)`, `data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))` (le polygone est relatif au centre de la tuile ; dériver le 8 de `Const.TILE_SIZE / 2`). La tuile de sol n'a **pas** de collision. **Ajouter la couche de physique avant de créer les tuiles et d'ajouter les sources au `TileSet`** : un `TileData` créé avant ne la connaît pas.
- Murs : `Walls.set_cell()` sur le cadre ; sol : `Floor` sur toute la zone jouable (le cadre peut aussi avoir du sol dessous, sans importance).
- `TileMapLayer` crée ses corps physiques à son entrée dans l'arbre, avec un léger différé : en test headless, attendre au moins un `await get_tree().physics_frame` avant de déplacer le joueur.
- **Vérifier d'abord** que les noms d'API ci-dessus existent tels quels en Godot 4.7.2 (déjà confirmé dans la documentation : `TileSet.add_physics_layer`, `set_physics_layer_collision_layer`, `TileData.add_collision_polygon`, `set_collision_polygon_points`). Si un détail diffère, trancher avec la doc (Context7) et consigner.

**Risque connu : accrochage sur les jointures de tuiles.** Un corps rectangulaire qui longe un mur fait de plusieurs tuiles carrées peut parfois s'accrocher aux arêtes internes (« collisions fantômes » des moteurs physiques 2D). Un test headless le détecte (voir plus bas). Si ça accroche : d'abord vérifier la `safe_margin` et le `wall_min_slide_angle` ; en dernier recours, fusionner les polygones d'une rangée de mur ou passer le corps en forme arrondie (en le consignant ici). Ne pas y répondre d'avance.

### Caméra (FR9, AR29)

- `Camera2D` nommée `Camera`, **fixe** : pas de suivi, pas de `position_smoothing`, pas de limites. Placée en code dans `Arena._ready()` à partir des constantes : centre de la salle moins la demi-bande de HUD, soit pour 608×336 : `(304, 168 − 24 / 2) = (304, 156)`. `anchor_mode` par défaut (`DRAG_CENTER`) : la position est le centre de l'écran.
- Conséquence vérifiable : le monde `(0, 0)` s'affiche à l'écran en `(16, 24)`, donc `get_viewport().get_canvas_transform().origin == Vector2(16, 24)`, et la bande de 24 px du haut est vide (fond noir, `default_clear_color` déjà noir). Elle reste vide jusqu'au HUD (2.7).
- Une seule caméra courante : si l'arène est recréée (F5), la nouvelle `Camera2D` prend le relais.
- Le suivi dans les grandes salles est l'epic 4 (FR9 `[B]`).

### `Main` (D14)

- `_ready()` : dans **tous** les builds, `_show_scene(ARENA_PATH)` avec `ARENA_PATH = "res://rooms/arena/arena.tscn"`. Remplacer `_show_debug_scene` par un `_show_scene(path) -> bool` qui sert aux deux (même corps : retirer de l'arbre puis `queue_free()` les enfants d'`ActiveScene`, instancier). Les contrôles de cohérence de `Const` restent en debug seulement.
- `_unhandled_input` : F5 (debug seulement) bascule **arène ↔ test de charge** (`SCALE_TEST_PATTERN_PATH` disparaît de `Main`). Conserver la règle de 1.2 : le drapeau `_load_test_active` n'est inversé qu'après un chargement réussi.
- Debug seulement : `Main` ajoute un `CollisionDrawer` (`CollisionDrawer.new()`) au `CanvasLayer` `UI`. Pour le retrouver, donner à `UI` `unique_name_in_owner = true` dans `main.tscn` (`%UI`). Rien d'autre ne dépend de `debug/`.
- Une arène en release charge sans aucun outil de debug : vérifier que le chemin de démarrage ne touche à aucune scène de `debug/` hors `PerfOverlay` (déjà dans `main.tscn`).
- `Log.info("room", ...)` une fois à l'entrée de l'arène (par exemple dimensions de la zone jouable) ; rien par frame.

### F2 : affichage des formes de collision (AR24)

`game/debug/collision_drawer.gd`, `class_name CollisionDrawer extends Node2D`, enfant du `CanvasLayer` `UI` (donc en coordonnées d'écran du viewport 640×360, au-dessus du monde).

- Invisible au départ ; `_unhandled_input` bascule `visible` sur l'action `debug_toggle_collisions` (F2), puis `set_input_as_handled()` ; `process_mode = PROCESS_MODE_ALWAYS` comme la surcouche F3 ; le script porte le commentaire d'exemption de `debug/`.
- Découplage : le dessinateur ne connaît aucune classe de jeu. Il parcourt `get_tree().get_nodes_in_group(Const.GROUP_DEBUG_SHAPES)` (des `CollisionShape2D`), et dessine le contour de chaque `RectangleShape2D` (et `CircleShape2D` si présent), 1 px, couleur unie en dur (debug).
- Conversion monde → écran : `get_viewport().get_canvas_transform() * shape_node.get_global_transform_interpolated()` appliquée aux coins. L'interpolée évite que le cadre traîne d'un tick derrière le sprite (interpolation physique active). Vérifier que `Node2D.get_global_transform_interpolated()` existe en 4.7 ; sinon `global_transform` et le consigner.
- `queue_redraw()` dans `_process` **uniquement quand visible**. Le parcours du groupe en debug est acceptable (quelques nœuds).
- Les `Hurtbox` et `Hitbox` des stories 1.5, 2.x et 5.x rejoindront le même groupe : le CA 9 dit « hitbox et hurtbox » mais seule la forme du joueur existe à ce stade. Les murs ne sont pas dessinés.
- `CollisionDrawer` n'est instancié que par `Main` en debug : en release, le groupe existe mais personne ne le lit, et les nœuds qui le rejoignent n'ont aucun coût.

### Règles d'architecture qui s'appliquent

- GDScript typé partout (AR2) ; `snake_case` fichiers et dossiers, un script par classe, constantes `UPPER_SNAKE_CASE`, membres privés `_`, gestionnaires `_on_<émetteur>_<signal>`. Code, commentaires, logs et noms de fichiers **en anglais**.
- **Temps** (AR13) : `delta * GameClock.scale(GameClock.Group.PLAYER)`. Pas de `Timer`, `create_timer`, `Engine.time_scale`.
- **Entrées** (AR12) : actions `InputMap`, lues dans `_physics_process`.
- **Aléatoire** : aucun (pas de `randf` & co).
- **Données** (AR9) : aucune valeur de gameplay en dur ; `Tuning.PLAYER` en lecture seule.
- **Logs** (AR27) : `Log.<niveau>(catégorie, message)`, pas de `print()`, rien dans les boucles par frame.
- **Erreurs** (AR28) : `assert` + `Log.error` pour un invariant violé, valeur sûre en release.
- **Frontières** : `core/` ne dépend d'aucun dossier de fonctionnalité ; `player/` ne dépend que de `core/` et des autoloads ; `rooms/` peut instancier `player/` (provisoire, avant `Run`) ; rien ne dépend de `debug/` sauf `Main`.
- **Pas de nouveau signal sur `Events`**, pas d'autoload : rien dans cette story n'en a besoin.

### Arborescence attendue à la fin de la story

```
game/
├── project.godot                       (UPDATE : move_*, debug_toggle_collisions, physics_interpolation)
├── core/
│   ├── constants.gd                    (UPDATE : HUD_BAND_HEIGHT, ROOM_TILES, GROUP_DEBUG_SHAPES)
│   ├── tuning.gd                       (UPDATE : PLAYER)
│   └── player_tuning.gd                (NEW)
├── data/tuning/player_tuning.tres      (NEW)
├── player/                             (NEW)
│   ├── player.tscn / player.gd
│   └── player_motor.gd
├── rooms/arena/                        (NEW)
│   └── arena.tscn / arena.gd
├── main/
│   ├── main.gd                         (UPDATE : arène au démarrage, _show_scene, CollisionDrawer)
│   └── main.tscn                       (UPDATE : %UI)
└── debug/
    ├── collision_drawer.gd             (NEW)
    └── scale_test_pattern.*, bullet_load_test.*, perf_overlay.*   (inchangés)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (lexique, T8). Les `*.uid` se versionnent. Pas d'autre dossier (`player_input.gd`, `dash.gd`, `hud/`… viendront avec leurs stories).

### Stratégie de test

Aucun framework de test (AR26 : avant le jalon B). Contrôles par scripts jetables du scratchpad (hors dépôt) lancés comme scène : `godot --headless --path game --scene <scène>`. Pour un temps déterministe, essayer `--fixed-fps 60` ; sinon `await get_tree().physics_frame` en boucle. Entrées simulées par `Input.action_press(&"move_right")` / `Input.action_release`, ou `Input.parse_input_event()` avec un `InputEventJoypadMotion` pour le stick.

1. **Import et lancement** : `godot --headless --path game --import`, puis `--quit-after 120`. Zéro `SCRIPT ERROR`, zéro `Parse Error`.
2. **`PlayerMotor` seul** (sans scène, `dt = 1 / Engine.physics_ticks_per_second`) :
   - de l'arrêt avec `wish = (1, 0)` : vitesse = 96 px/s après `ceili(acceleration_time * ticks)` ticks, et jamais au-dessus ;
   - à vitesse max, `wish = ZERO` : vitesse 0 après `ceili(deceleration_time * ticks)` ticks ;
   - diagonale `wish = (1, 1).normalized()` : norme de la vitesse = 96 px/s (pas de gain en diagonale) ;
   - `dt = 0` : la vitesse ne change pas ;
   - une `PlayerTuning` neuve avec `move_speed = 3.0` donne 48 px/s (réglable sans toucher au code).
3. **Joueur dans l'arène** :
   - **CA 1** : l'arène démarre, `Player.position == (304, 168)`, `Camera.get_screen_center_position() == (304, 156)`, `get_viewport().get_canvas_transform().origin == (16, 24)`.
   - **CA 6** : tenir `move_right` 3 s : `position.x` se stabilise à `592 − 3` (à ~0,5 px, `safe_margin` comprise) ; idem pour les trois autres murs (bornes `19`, `589`, `19`, `317`). Tenir une diagonale contre un coin : le joueur reste dans le rectangle `[19, 589] × [19, 317]` pendant 10 s.
   - **Glissement** : longer chaque mur sur toute sa longueur (par exemple `move_up` + `move_right` collé au mur du haut) et vérifier que la progression ne s'interrompt pas sur les jointures des tuiles (voir « Risque connu »).
   - **CA 7** : la forme `Hitbox` est un `RectangleShape2D` de `Vector2(6, 6)`, centrée à `Vector2.ZERO` ; le sprite fait 16×24 et est centré.
   - **CA 8** : modifier temporairement `move_speed` dans `player_tuning.tres`, relancer, constater le changement de vitesse ; **remettre la valeur d'origine**. Idem pour `hitbox_size`.
   - **CA 11** : `GameClock.paused = true`, tenir une direction 1 s : la position ne change pas ; `paused = false` : le joueur repart.
   - **Stick** : `InputEventJoypadMotion` (axe 0, valeur 1,0) pendant 10 ticks : le joueur se déplace à droite ; valeur 0,1 (sous la zone morte) : il ne bouge pas.
   - **Clavier physique** : `InputMap.action_get_events(&"move_up")` contient un `InputEventKey` de `physical_keycode` 87 (KEY_W), etc.
4. **F2 / F5 (debug)** : `InputEventAction` `debug_toggle_collisions` : `CollisionDrawer.visible` bascule et le cadre est à la position écran attendue (centre du joueur + (16, 24)) ; `debug_load_test` : arène → test de charge (`Bullets 400 | refused 0` dans F3) → arène, deux fois de suite, sans erreur ; le nombre d'enfants d'`ActiveScene` reste 1.
5. **Fenêtré sous WSLg** (indicatif, pas la machine de référence) : arène nette en ×2 (1280×720), bande vide en haut, marges de 16 px, sprite net en mouvement (`get_viewport().get_texture().get_image().save_png()` depuis un script du scratchpad pour une capture) ; F2 affiche le carré 6×6 ; F3 toujours fonctionnel. **Netteté en mouvement** : à 96 px/s et 60 Hz, un sprite à position fractionnaire peut faire vaciller ses colonnes de pixels (filtre `Nearest`). Si c'est visible, activer `rendering/2d/snap/snap_2d_transforms_to_pixel` (et `snap_2d_vertices_to_pixel`) dans `project.godot`, revérifier la mire d'échelle et le consigner. Sinon, ne rien changer.
6. **Ressenti, étapes humaines** (à consigner, ne pas déclarer vérifié sans manette réelle) : stick réel sous Windows, absence d'accrochage au stick, latence : reportés à 1.7 et 1.8. Les consigner dans `deferred-work.md`.
7. **Recherche des interdits** : `grep -rnE 'print\(|Timer|create_timer|time_scale|randf|randi|randomize|shuffle|pick_random|/root/' game --include=*.gd` : seules les occurrences attendues de `log.gd` et des commentaires. Aucun `Log.` dans `_physics_process` ni `_process`.

### Commit

Directement sur `main`, Conventional Commits en anglais, un `git push` après chaque commit (consigne du projet). Exemples : `feat(player): add arena with 8-direction player movement` pour le code ; `docs(architecture): add arena and hud_band to the lexicon` ; `docs(story): record story 1.3 implementation progress`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `player/player.tscn/.gd`, `player/player_motor.gd`, `rooms/arena/arena.tscn`, `debug/collision_drawer.gd`, `data/tuning/player_tuning.tres`.
- **Écarts assumés** :
  - `PlayerTuning` dans `core/` et non dans `player/` (frontière `core/` → fonctionnalités, voir plus haut).
  - Le joueur est instancié par l'arène : l'architecture le place sous `Run` (D14). `Run` n'existe qu'à l'epic 6 ; à ce moment le joueur remontera d'un niveau.
  - `Floor` et `Walls` sont construits en code (le test de charge de 1.2 faisait de même) ; l'epic 4 les remplace par des salles peintes (`rooms/pool/`).
  - La forme de collision du joueur sert aussi de hitbox du GDD (voir « Simplification assumée »).
  - `scale_test_pattern.*` n'est plus instancié, mais conservé.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md` et de la mémoire du projet :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (aucun dans cette story).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.

### Questions ouvertes (sans effet bloquant sur le code)

1. **Corps et hitbox confondus** : la forme 6×6 sert de collision contre les murs. Si, au ressenti, le sprite (16×24) mord trop dans les murs, la séparation corps / hurtbox pourra être faite plus tôt que prévu.
2. **Mire de netteté** conservée mais non affichée : à supprimer ou à rebrancher (par exemple sur une touche de debug) selon le besoin de 1.8.
3. **Manette réelle** : non testable sous WSL ; à valider sous Windows avec 1.7.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR1, FR2, FR9)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR9, AR12, AR13, AR24, AR27, AR28, AR29, AR32)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Déplacement et dash] (6 tuiles/s, 0,06 s, 0,04 s, hitbox 6×6)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Arènes et salles] (36×19, bande de HUD)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Contrôles]
- [Source: _bmad-output/game-architecture.md#Entrées et latence (D6)]
- [Source: _bmad-output/game-architecture.md#Données de réglage (D4)]
- [Source: _bmad-output/game-architecture.md#Salles et génération (D10, D11)] (`Floor`, `Walls`)
- [Source: _bmad-output/game-architecture.md#Compléments (ajoutés à la validation)] (caméra, bande de HUD 24 px)
- [Source: _bmad-output/game-architecture.md#Scènes (D14)]
- [Source: _bmad-output/game-architecture.md#Outils de debug] (F2)
- [Source: _bmad-output/game-architecture.md#Structure du projet] (arborescence, frontières, lexique)
- [Source: _bmad-output/implementation-artifacts/1-2-valider-400-projectiles-a-60-fps.md] (Review Findings, Dev Notes)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md]
- [Externe : docs Godot 4.7 via Context7 : `CharacterBody2D` (`motion_mode`, `wall_min_slide_angle`, `move_and_slide`), `TileSet.add_physics_layer` / `set_physics_layer_collision_layer`, `TileData.add_collision_polygon` / `set_collision_polygon_points`, réglage `physics/common/physics_interpolation` et `Node.reset_physics_interpolation()`]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5 (claude-sonnet-5-5)

### Implementation Plan

- `PlayerMotor` (`RefCounted`) porte toute la logique de vitesse (`move_toward` vers `wish * max_speed_px`, taux d'accélération ou de décélération). Aucune dépendance à un nœud : vérifiable sans scène.
- `Player` (`CharacterBody2D`, `MOTION_MODE_FLOATING`) lit `Input.get_vector` dans `_physics_process`, applique `GameClock.scale(PLAYER)` une seule fois par tick, puis `move_and_slide()`.
- `Arena` construit `Floor` et `Walls` en code (un `TileSet` partagé, couche de physique ajoutée **avant** les sources), place le joueur au centre et la caméra fixe à `(304, 156)`.
- `Main` démarre sur l'arène dans tous les builds ; `_show_debug_scene` devient `_show_scene` ; F5 bascule arène ↔ test de charge (drapeau inversé après chargement réussi, règle de 1.2 conservée) ; `CollisionDrawer` instancié en debug.

### Debug Log References

- `get_global_transform_interpolated()` n'existe pas en Godot 4.7.2 (sondage de `ClassDB` : aucune méthode `*interpol*` sur `Node2D` ni `CanvasItem`, seulement `Node.is_physics_interpolated*`, `reset_physics_interpolation`). Repli prévu par la story : `global_transform`. Consigné dans `deferred-work.md`.
- Avertissement du moteur « Camera2D overridden to physics process mode » : supprimé en fixant `process_callback = 0` (physique) dans `arena.tscn`. Le régler dans `_ready()` ne suffit pas, le moteur l'émet avant.
- En `MOTION_MODE_FLOATING`, `move_and_slide()` conserve la vitesse en glissant : le long d'un mur à 45° le joueur avance à ~94 px/s (pas à la composante de 68 px/s). Il ne dépasse jamais 96 px/s, donc CA 3 est respecté ; aucun ralentissement au mur.
- Tracé tick par tick d'un glissement le long du mur du haut : pas de pas bloqué sur les jointures de tuiles (« Risque connu » de la story non rencontré).
- Premier test de glissement invalide (45° ne touchait jamais le mur) puis corrigé ; les « blocages » comptés dans le coin d'arrivée ont été exclus. Test de timing du test de charge corrigé (50 ticks nécessaires pour 400 projectiles).

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-20).
- ✅ T1 : `Const.HUD_BAND_HEIGHT`, `ROOM_TILES`, `GROUP_DEBUG_SHAPES` ; `PlayerTuning` dans `core/` ; `player_tuning.tres` (valeurs du GDD) ; `Tuning.PLAYER`.
- ✅ T2 : actions `move_up/down/left/right` (touches physiques W/A/S/D + stick gauche, zone morte 0,2), `debug_toggle_collisions` (F2), `physics/common/physics_interpolation=true`. `project.godot` : +30 lignes, aucune re-sérialisation parasite.
- ✅ T3 à T7 : `PlayerMotor`, `Player`, `Arena`, `Main`, `CollisionDrawer` comme spécifiés. Une durée de rampe invalide (< 0,001 s) est consignée par `Log.error` et ramenée à la valeur sûre.
- ✅ T8 : ligne `Arène ; bande de HUD | arena ; hud_band` ajoutée au lexique de `game-architecture.md`.
- ✅ T9, vérifications headless (scripts jetables du scratchpad, hors dépôt), toutes réussies :
  - `PlayerMotor` : 96 px/s atteints en 4 ticks, arrêt en 3 ticks, jamais au-dessus de 96, diagonale à 96 (95,99999), `dt = 0` sans effet, `move_speed = 3` donne 48.
  - Arène : joueur en `(304, 168)`, caméra en `(304, 156)`, origine du canvas `(16, 24)`, hitbox `6×6` centrée, sprite `16×24` centré, couches `player`/`walls`.
  - Murs : arrêt à 589 / 19 / 317 / 19 (à 0,01 px près) ; diagonale contre le coin pendant 10 s reste dans `[19, 589] × [19, 317]`.
  - Glissement sur les quatre murs (clavier 45° et stick incliné de 10°) : zéro pas bloqué. `wall_min_slide_angle` laissé au défaut (15°).
  - CA 8 : `move_speed = 3.0` et `hitbox_size = 0.5` dans le `.tres` donnent 48 px/s et 8×8 ; valeurs d'origine remises.
  - CA 11 : `GameClock.paused = true` fige le joueur, il repart au `false`.
  - Stick simulé : 0,1 (sous la zone morte) ne bouge pas, 1,0 déplace à droite. Touches physiques 87/83/65/68 avec `keycode` 0.
  - F2 bascule le `CollisionDrawer` ; F5 arène → test de charge (400 projectiles) → arène, deux fois de suite, `ActiveScene` toujours à un enfant, joueur de retour en `(304, 168)`.
- ✅ T10, fenêtré sous WSLg (indicatif) : arène en ×2 (1280×720), bande noire de 24 px en haut, marges de 16 px, F2 affiche le carré 6×6 centré sur le torse, F3 et F5 fonctionnels. Netteté en mouvement : le sprite mesure 16×24 pixels à l'écran sur 90 frames consécutives, donc **pas de `snap_2d_transforms_to_pixel`** (réglage non modifié).
- ✅ T11 : import et lancement headless sans `SCRIPT ERROR`, `Parse Error` ni avertissement. Recherche des interdits propre (seules occurrences : `log.gd`, commentaires, et la variable locale renommée en `clock_scale`). Aucun `Log.` dans `_physics_process` ni `_process`.
- ✅ T12 : reports consignés dans `deferred-work.md` (manette réelle, ressenti et latence, contour F2 non interpolé, mire de netteté).
- Écart de méthode : les tests ont été écrits **après** le code (scripts jetables, pas de framework avant le jalon B, AR26), pas en rouge-vert-refactor strict.
- Aucun test automatisé ajouté au dépôt (AR26). Les vérifications fonctionnelles de la manette physique et du ressenti restent des étapes humaines.

### File List

- `game/core/constants.gd` (modifié)
- `game/core/tuning.gd` (modifié)
- `game/core/player_tuning.gd` (nouveau) + `.uid`
- `game/data/tuning/player_tuning.tres` (nouveau)
- `game/player/player.gd`, `game/player/player.tscn` (nouveaux) + `.uid`
- `game/player/player_motor.gd` (nouveau) + `.uid`
- `game/rooms/arena/arena.gd`, `game/rooms/arena/arena.tscn` (nouveaux) + `.uid`
- `game/debug/collision_drawer.gd` (nouveau) + `.uid`
- `game/main/main.gd`, `game/main/main.tscn` (modifiés)
- `game/project.godot` (modifié)
- `_bmad-output/game-architecture.md` (modifié : lexique)
- `_bmad-output/implementation-artifacts/deferred-work.md` (modifié)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modifié)
- `_bmad-output/implementation-artifacts/1-3-se-deplacer-dans-l-arene.md` (cette story)

### Change Log

- 2026-11-20 : implémentation de la story 1.3 (arène, joueur, déplacement 8 directions, caméra fixe, F2, F5 arène ↔ test de charge). Statut : `review`.
