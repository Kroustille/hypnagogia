---
baseline_commit: e0cacf27a7865d67ae953a2b128b54ecc03e2d78
---

# Story 1.4 : Dasher

Status: review

## Story

En tant que joueur,
je veux un dash court et invulnérable, avec un tampon d'entrée,
afin d'esquiver au dernier moment.

**Exigences couvertes :** FR3, FR4 (murs), AR9, AR12, AR13, AR24 (F4).

## Critères d'acceptation

1. **Étant donné** le joueur, en mouvement ou à l'arrêt, **quand** il appuie sur Espace ou sur RB, **alors** il parcourt 3 tuiles en 0,18 s dans sa direction de déplacement. À l'arrêt, il part dans sa dernière direction de déplacement.
2. Il est invulnérable pendant les 0,15 premières secondes. `is_dash_invulnerable()` et `is_invulnerable()` exposent cet état.
3. Un signal `dash_ended` est émis à la fin du dash.
4. **Étant donné** un dash qui vient de finir, **quand** le joueur appuie de nouveau sur dash pendant la recharge de 0,6 s, **alors** l'appui n'est retenu que s'il tombe dans les 0,1 s qui précèdent la fin de la recharge : le dash part alors dès qu'elle est terminée. Plus tôt, il est ignoré.
5. Le tampon est compté en ticks de physique.
6. **Étant donné** un mur sur la trajectoire, **quand** le joueur dashe vers lui, **alors** le dash s'arrête contre le mur, sans le traverser.
7. **Étant donné** les valeurs du dash, **quand** on les modifie dans `DashTuning.tres`, **alors** le dash change sans toucher au code.
8. **Étant donné** un build de debug, **quand** on appuie sur F4, **alors** tout le jeu passe au ralenti ×0,25 par `GameClock`, sans toucher à `Engine.time_scale`.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture ou par l'état du dépôt) :

9. Le dash obéit à `GameClock` : avec `GameClock.paused = true`, ou sous F4, sa durée, son invulnérabilité, sa recharge et son tampon s'étirent en conséquence ; en pause, rien n'avance.
10. Le dash ne peut pas être déclenché pendant un dash, et un appui pendant le dash lui-même est ignoré (la recharge ne commence qu'à la fin du dash).
11. `Player` expose `is_dashing()` : la story 1.5 en a besoin (« aucun tir pendant le dash », FR3).
12. F5 (arène ↔ test de charge) et F2 continuent de fonctionner, avec F4 actif ou non. Le ralenti F4 survit à un F5.

## Tâches / sous-tâches

- [x] **T1. Réglages du dash** (CA 7)
  - [x] `core/dash_tuning.gd` : `class_name DashTuning extends Resource` (voir « `DashTuning` »).
  - [x] `data/tuning/dash_tuning.tres` (valeurs du GDD) et `Tuning.DASH` (`preload`).
- [x] **T2. Actions d'entrée** (CA 1, 8)
  - [x] `project.godot` : action `dash` (Espace, touche physique 32, et bouton RB de manette, indice 10).
  - [x] `project.godot` : action `debug_slow_motion` sur F4 (touche physique, `physical_keycode` 4194335), même forme que `debug_toggle_collisions`.
- [x] **T3. `GameClock`** (CA 8, 9)
  - [x] Ajouter le multiplicateur global (voir « `GameClock` : multiplicateur global »).
- [x] **T4. `Dash`** (CA 1 à 6, 9, 10)
  - [x] `player/dash.gd` : `class_name Dash extends RefCounted`, logique pure, sans nœud (voir « `Dash` »).
- [x] **T5. `Player`** (CA 1 à 3, 6, 9, 11)
  - [x] Brancher `Dash` dans `player/player.gd` : direction, vitesse, signal `dash_ended`, `is_dash_invulnerable()`, `is_invulnerable()`, `is_dashing()`, repère visuel provisoire (voir « `Player` »).
- [x] **T6. `Main` : F4** (CA 8, 12)
  - [x] Bascule du ralenti en debug seulement (voir « F4 »).
- [x] **T7. Lexique** : ajouter à `game-architecture.md` (section « Lexique ») la ligne `Dash ; invulnérabilité du dash ; recharge ; tampon d'entrée | dash ; dash_invulnerability ; cooldown ; input_buffer` (AR32 : un terme entre dans le lexique avant le code).
- [x] **T8. Vérifications headless** (CA 1 à 10)
  - [x] Scripts jetables dans le scratchpad (pas dans le dépôt) : voir « Stratégie de test ».
- [x] **T9. Vérifications fenêtrées sous WSLg** (CA 1, 8, 12)
  - [x] Dash visible à l'écran, F4, F2, F5, capture d'écran.
- [x] **T10. Régression** : import et lancement headless sans erreur, recherche des interdits, déplacement, F2, F3 et F5 de 1.1 à 1.3 toujours conformes.
- [x] **T11. Reports** : consigner dans `deferred-work.md` ce qui n'a pas pu être vérifié (RB réel, ressenti du dash) et fermer le report de 1.2 sur la traversée de mur (voir « Report de 1.2 : échelle de temps > 1 »).

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

Le joueur dashe dans l'arène vide, rien d'autre. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Visée, tir, `ShotTuning`, blocage du tir pendant le dash (la story expose seulement `is_dashing()`), son du dash (`Audio`), `Hurtbox`/`Hitbox` | 1.5 |
| Pause effective et menu | 1.6 |
| Réassignation, autres actions `InputMap` (`aim_*`, `shoot`, `power_*`…), bascule clavier-souris ↔ manette | 1.7 |
| Export, latence mesurée | 1.8 |
| Santé, coups, invulnérabilité après un coup (`is_invulnerable()` ne couvre ici que le dash) | 2.1 |
| Dash parfait (`perfect_dash`), graze, lucidité | Epic 3 |
| Trous (le dash ne survole un trou que s'il le franchit), ennemis (le dash ne les traverse pas), obstacles | Epic 4 et 2 |
| Onde de choc « Piqué » (branchée sur `dash_ended`), `BuildCarrier` | 5.7 |
| `GameClock.set_scale_for(...)` par groupe et durée (Réveil cassé) | 5.8 |
| Sprites et effets visuels définitifs du dash | 7.x |

Aucun texte affiché au joueur : pas de `tr()` à écrire.

### État actuel du dépôt (stories 1.1 à 1.3, `done`)

- `Player` (`game/player/player.gd`, `class_name Player`, `CharacterBody2D`, `MOTION_MODE_FLOATING`) : lit `Input.get_vector(move_left, move_right, move_up, move_down)` dans `_physics_process`, appelle `_motor.step(wish, delta)` avec le `delta` **réel**, puis `velocity = motor_velocity * clock_scale` et `move_and_slide()`. `clock_scale = GameClock.scale(GameClock.Group.PLAYER)`, **une lecture par tick**. Nœuds : `Sprite` (`%Sprite`, 16×24 centré) et `Hitbox` (`%Hitbox`, carré de 6×6, groupe `Const.GROUP_DEBUG_SHAPES`). Couches : `collision_layer = LAYER_PLAYER`, `collision_mask = LAYER_WALLS`. Origine du nœud = centre du torse.
- `PlayerMotor` (`RefCounted`, `player/player_motor.gd`) : `step(wish, dt) -> Vector2` ; `velocity` ; `MIN_RAMP_TIME = 0.001` ; durée invalide → `Log.error("input", ...)` + valeur sûre calculée **avant** l'`assert` (correctif de revue de 1.3 : à reproduire pour tout nouveau garde-fou).
- `GameClock` (autoload) : `enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }`, `paused`, `scale(group) -> float` (`0.0` si pause, sinon `_scales[group]`, tous à 1,0). **Aucune API d'écriture.** Lu par `Player` et par `BulletManager` (`delta * GameClock.scale(_clock_group)`, une lecture par tick). `PerfOverlay` mesure le delta réel et ne lit pas `GameClock`.
- `Tuning` : `@abstract class_name Tuning`, constante `PLAYER` (`preload`). Les Resources sont **en lecture seule à l'exécution**.
- `Const` : `TILE_SIZE = 16`, `LAYER_*`, `GROUP_DEBUG_SHAPES`, `HUD_BAND_HEIGHT`, `ROOM_TILES`.
- `Main` (`game/main/main.gd`) : `_unhandled_input` ne fait quelque chose **qu'en debug** (`OS.is_debug_build()`) ; il gère F5 (`debug_load_test`, drapeau `_load_test_active` inversé seulement après un chargement réussi : **à conserver**). `CollisionDrawer` (F2) est instancié en debug.
- `project.godot` : actions `move_*`, `debug_toggle_perf` (F3), `debug_load_test` (F5), `debug_toggle_collisions` (F2). **Pas d'action `dash` ni `debug_slow_motion`.** `physics/common/physics_ticks_per_second=60`, interpolation physique activée.
- Arène : cadre de murs fermé de 38×21 tuiles (cellules de murs en `x ∈ {0, 37}`, `y ∈ {0, 20}`), zone jouable en pixels `x ∈ [16, 592]`, `y ∈ [16, 320]`, joueur au centre `(304, 168)`. Avec la hitbox de 6×6, le centre du joueur s'arrête à `x ∈ [19, 589]`, `y ∈ [19, 317]` (mesuré en 1.3).
- Environnement : Godot 4.7.2 via WSLg, `godot` dans le `PATH`. **Pas de manette sous WSL** : RB réel non testable ici. Les FPS WSLg ne sont pas représentatifs.

### Leçons des stories 1.1 à 1.3 à appliquer

- **Typage strict, avertissements en erreur** (`untyped_declaration`, `unsafe_*` à 2). Un `Variant` ne se convertit pas avec `int(...)` : passer par une variable typée.
- **Aucune valeur de gameplay en dur** (NFR9, AR9) : distance, durée, invulnérabilité, recharge, tampon viennent de `DashTuning`. Le multiplicateur 0,25 de F4 est un **outil de debug** (AR24), pas du gameplay : constante locale de `Main` autorisée (`SLOW_MOTION_SCALE`).
- **Le moteur reste cohérent avec l'entrée, l'échelle ne s'applique qu'une fois** (décision de revue de 1.3) : `PlayerMotor` avance au `delta` réel, l'échelle de `GameClock` multiplie la vitesse **finale** envoyée à `move_and_slide()` (qui intègre avec le `delta` non mis à l'échelle). Même principe pour le dash (voir plus bas).
- **Revue de 1.3 : calculer la valeur sûre avant de journaliser et d'`assert`**, pour que le repli vaille aussi en debug sans débogueur.
- **Couches de collision** par `Const.LAYER_*`. **Injection** : `setup()` avant `add_child()`. Pas de `/root/...`.
- **Fichiers `*.uid` générés par Godot : à versionner.**
- **Vérifications** : `godot --headless --path game --import`, puis `godot --headless --path game --quit-after <n>`. Zéro `SCRIPT ERROR`, zéro `Parse Error`. `--script` ne résout pas les autoloads : les vérifications tournent comme une **scène** du scratchpad (`godot --headless --path game --scene <scène>`), avec `call_deferred` pour attendre que la racine soit prête, puis `await get_tree().physics_frame` en boucle pour avancer au tick.
- `TileMapLayer` crée ses corps physiques avec un léger différé : attendre au moins un `physics_frame` avant de déplacer le joueur en test.
- **Le contour F2 suit la position physique, pas l'interpolée** (report de 1.3, ≈1,6 px à pleine vitesse). Au dash (≈4,4 px par tick), il devancera le sprite de **jusqu'à ~4,4 px** : attendu, ne pas « corriger » (`get_global_transform_interpolated()` n'existe pas en 4.7.2).

### `DashTuning` (AR9, D4)

`class_name DashTuning extends Resource`, dans **`game/core/dash_tuning.gd`** (même raison que `PlayerTuning` : `Tuning`, dans `core/`, type ses constantes avec cette classe). Distances en tuiles, durées en secondes ; la conversion se fait à un seul endroit (`Dash`).

| Champ | Type | Sens | Valeur (GDD) |
|---|---|---|---|
| `distance` | `float` | tuiles parcourues par un dash complet | 3,0 |
| `duration` | `float` | secondes de déplacement | 0,18 |
| `invulnerability_duration` | `float` | secondes d'invulnérabilité, depuis le début du dash | 0,15 |
| `cooldown` | `float` | secondes de recharge, **comptées depuis la fin du dash** | 0,6 |
| `input_buffer` | `float` | secondes avant la fin de la recharge pendant lesquelles un appui est retenu | 0,1 |

- `@export` typés ; `@export_range` pour borner les saisies dans l'éditeur (par exemple `duration` ≥ 0,001).
- `data/tuning/dash_tuning.tres`, en texte, sur le modèle de `player_tuning.tres` :

```
[gd_resource type="Resource" script_class="DashTuning" load_steps=2 format=3]

[ext_resource type="Script" path="res://core/dash_tuning.gd" id="1_tuning"]

[resource]
script = ExtResource("1_tuning")
distance = 3.0
duration = 0.18
invulnerability_duration = 0.15
cooldown = 0.6
input_buffer = 0.1
```

- `Tuning` : `const DASH: DashTuning = preload("res://data/tuning/dash_tuning.tres")`. Aucune affectation sur `Tuning.DASH`.
- Après création, `godot --headless --path game --import` : Godot peut ajouter un `uid=` ; le versionner.
- Valeurs invalides (la spec ne valide que ce qui casse le code, comme en 1.3) : `duration < 0,001` fait diviser par zéro la vitesse du dash. Calculer d'abord la valeur sûre (`maxf(duration, MIN_DURATION)`), puis `Log.error("input", ...)` une fois et `assert(false, ...)`. Les autres champs négatifs sont ramenés à 0 par `maxf(value, 0.0)`, sans log (aucun point de division). `invulnerability_duration` supérieure à `duration` est tolérée (l'invulnérabilité dure alors tout le dash).

### `GameClock` : multiplicateur global (CA 8)

F4 doit ralentir « tout le jeu » par `GameClock`. Ajouter un **multiplicateur global**, distinct des échelles par groupe, pour ne pas écraser plus tard celles de Réveil cassé (5.8), qui composera avec lui :

```gdscript
## Global time multiplier, composed with every group scale. Debug slow motion (F4) uses it.
## Clamped to [0, 1]: a scale above 1 is not a supported case (see deferred-work, story 1.2).
var global_multiplier: float = 1.0:
	set(value):
		global_multiplier = clampf(value, 0.0, 1.0)

func scale(group: Group) -> float:
	return 0.0 if paused else _scales[group] * global_multiplier
```

- Rien d'autre dans l'API : pas de `set_scale_for` (5.8). `paused` garde sa priorité absolue.
- `Engine.time_scale` reste à 1.
- Le plafond à 1 est volontaire : il referme le report de 1.2 sur la traversée de mur à échelle > 1 (voir « Report de 1.2 »).

### `Dash` : la logique, sans scène (D6, P2)

`class_name Dash extends RefCounted`, `game/player/dash.gd`. Pur : aucune dépendance à un nœud, vérifiable sans lancer le jeu. Architecture : `player/dash.gd`.

**Tout est compté en ticks de jeu**, pas en secondes ni en `Timer` (CA 5, AR12, AR13). Un **tick de jeu** vaut `clock_scale` à chaque tick de physique (1,0 à l'échelle normale, 0,25 sous F4, 0 en pause). Les durées de `DashTuning` (secondes) sont converties **une fois**, dans `_init`, par `ticks = seconds * Engine.physics_ticks_per_second` (ne pas coder 60). Pas de comparaison de temps réel, pas d'accumulation de `delta` : à échelle 1,0, 0,25 ou 0,5 les compteurs sont exacts en virgule flottante.

Valeurs converties à 60 Hz : durée **10,8** ticks ; invulnérabilité **9,0** ; recharge **36,0** ; tampon **6,0**. Vitesse du dash : `distance_px / duration_ticks` pixels par tick de jeu, soit 48 / 10,8 ≈ 4,444 px par tick (≈ 266,7 px/s).

```gdscript
signal ended                                  # émis par finish_tick(), après le déplacement du dash

func _init(tuning: DashTuning) -> void        # convertit les durées en ticks, calcule la vitesse
func tick(clock_scale: float, pressed: bool, facing: Vector2) -> void   # avant move_and_slide()
func velocity(physics_delta: float) -> Vector2                          # px/s à donner à move_and_slide() pour ce tick, ZERO si inactif
func finish_tick() -> void                    # après move_and_slide() : clôt le dash si sa durée est écoulée
func is_active() -> bool
func is_invulnerable() -> bool
```

- `facing` : vecteur **unitaire non nul** fourni par `Player` (voir « Direction »). `Dash` ne le recalcule pas et le fige au départ du dash.
- **Ordre dans `tick()`** (un seul passage par tick physique) :
  1. Si inactif et `_cooldown_left > 0` : `_cooldown_left = maxf(_cooldown_left - clock_scale, 0.0)`.
  2. Si `pressed` :
     - dash actif → ignoré (CA 10) ;
     - sinon recharge terminée (`_cooldown_left <= 0`) → départ immédiat, **le tick même de l'appui** ;
     - sinon, si `_cooldown_left <= _buffer_ticks` → l'appui est retenu (`_buffered = true`) ;
     - sinon (plus de 0,1 s avant la fin de la recharge) → ignoré.
  3. Si inactif, `_buffered` et `_cooldown_left <= 0` → départ, `_buffered = false`.
  4. Si actif : `_step = minf(clock_scale, _duration_ticks - _elapsed)` (le dernier pas est tronqué, pour que le dash parcoure **exactement** 3 tuiles), puis `_elapsed += _step`.
- `velocity(physics_delta)` : `facing * _speed_px_per_tick * _step / physics_delta`. Au pas normal (`_step = 1`, `physics_delta = 1/60`) cela donne 266,7 px/s ; au dernier pas, une fraction ; en pause (`_step = 0`), zéro. `move_and_slide()` intègre avec `physics_delta` non mis à l'échelle, donc le déplacement du tick vaut `facing * _speed_px_per_tick * _step` : **distance totale = 48 px à l'épsilon près, quelle que soit l'échelle**. Protéger `physics_delta <= 0` (renvoyer `Vector2.ZERO`).
- `finish_tick()` : si actif et `_elapsed >= _duration_ticks` (avec une marge d'un millionième de tick contre l'arrondi) → `_active = false`, `_cooldown_left = _cooldown_ticks`, `ended.emit()`. La recharge commence donc **à la fin du dash**, pas à l'appui (CA 4, 10) ; le tick suivant la décrémente en premier.
- `is_invulnerable()` : `_active and _elapsed < _invulnerability_ticks`. `_elapsed` est mis à jour dans `tick()` : l'invulnérabilité couvre donc les 9 premiers ticks de jeu du dash (la vérification tolère un tick, comme en 1.3).
- `_buffered` est remis à `false` au départ d'un dash. Une retenue ne peut pas expirer seule : elle part au plus tard à la fin de la recharge. (En pause, tout est figé, rien ne se perd.)
- Pas de `Timer`, pas de `create_timer`, pas de RNG, aucun `Log.` par tick. Un `Log.debug("combat", ...)` au **départ** d'un dash est toléré (pas par tick) ; sinon rien.
- Un appui n'est lu qu'une fois : `Player` passe `Input.is_action_just_pressed(&"dash")`. Maintenir la touche ne répète pas le dash.

### `Player` : brancher le dash (FR3, FR4)

Dans `player/player.gd` :

- `signal dash_ended` (au passé, signal **local** : `BuildCarrier` et les effets d'objets s'y brancheront, 5.7). Dans `_ready()`, `_dash = Dash.new(Tuning.DASH)` puis `_dash.ended.connect(_on_dash_ended)` ; le gestionnaire fait `dash_ended.emit()`. Pas de nouveau signal sur `Events` (aucun consommateur transverse avant l'epic 3).
- Méthodes publiques : `is_dash_invulnerable() -> bool` (renvoie `_dash.is_invulnerable()`), `is_invulnerable() -> bool` (renvoie, **pour l'instant**, `is_dash_invulnerable()` ; la story 2.1 y ajoutera l'invulnérabilité après un coup ; garder un commentaire qui le dit), `is_dashing() -> bool` (renvoie `_dash.is_active()`, pour la story 1.5).
- **Direction** : `_facing: Vector2 = Vector2.DOWN` (valeur de départ : le personnage regarde vers le joueur ; consigner le choix). À chaque tick, si `wish != Vector2.ZERO`, `_facing = wish.normalized()`. Le stick incliné de 0,3 donne donc un dash complet dans cette direction. `wish` est la sortie de `Input.get_vector` (zone morte déjà appliquée) : pas de recalcul de zone morte. À l'arrêt, `_facing` garde la **dernière** direction de déplacement (CA 1). La direction est celle de l'**entrée**, pas celle de la vitesse du moteur (au demi-tour, la vitesse peut encore pointer vers l'ancien côté).
- **Boucle** (remplace celle de 1.3, en gardant sa structure) :

```gdscript
func _physics_process(delta: float) -> void:
	var clock_scale: float = GameClock.scale(GameClock.Group.PLAYER)   # une lecture par tick
	var wish: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if wish != Vector2.ZERO:
		_facing = wish.normalized()
	# The motor keeps stepping during a dash (real delta, same rule as for pause): it stays consistent
	# with the held input, so walking resumes smoothly when the dash ends.
	var motor_velocity: Vector2 = _motor.step(wish, delta)
	_dash.tick(clock_scale, Input.is_action_just_pressed(&"dash"), _facing)
	if _dash.is_active():
		velocity = _dash.velocity(delta)   # already scaled by the clock (see Dash)
	else:
		velocity = motor_velocity * clock_scale
	move_and_slide()
	_dash.finish_tick()   # after the movement: listeners of dash_ended see the final position
	_update_dash_tint()
```

  - **Ne pas multiplier `_dash.velocity()` par `clock_scale`** : l'échelle est déjà dans `_step` (double application sinon).
  - `velocity` est réécrit à chaque tick : ne jamais le relire comme état (règle de 1.3).
  - Si le dash vient de finir dans ce tick (`finish_tick()`), le tick suivant reprend la marche normale avec la vitesse courante du moteur.
  - Aucune lecture d'entrée dans `_process` ni `_input` (CA 5 de 1.3, AR12). Seule exception tolérée : `Main` pour F4/F5 (debug).
- **Mur (CA 6)** : `move_and_slide()` en `MOTION_MODE_FLOATING` **arrête** le corps contre un mur de face (la composante dans le mur est annulée) et le **fait glisser** le long d'un mur oblique. Les deux respectent « s'arrête contre le mur, sans le traverser ». **Décision de cette story : garder `move_and_slide()`**, comme à la marche. Le dash garde sa propre durée : contre un mur, le joueur reste immobile jusqu'à la fin des 0,18 s, l'invulnérabilité et `dash_ended` arrivent à l'heure prévue (déterministe). Ne pas terminer le dash sur collision. À juger au ressenti ; si un dash oblique qui glisse choque, le consigner, ne pas anticiper.
- **Pas de traversée** : le pas maximal est de ≈ 4,4 px par tick (échelle ≤ 1 garantie par `GameClock.global_multiplier`), pour des murs de 16 px et une hitbox de 6 px. Vérifier quand même en test que 20 dashs de face contre chacun des quatre murs et dans les coins ne sortent jamais de `[19, 589] × [19, 317]`.
- **Repère visuel provisoire** (pour juger le dash et F4 à l'écran) : pendant `is_dash_invulnerable()`, `_sprite.modulate` prend une teinte claire et translucide (constante locale `DASH_TINT`, commentaire « placeholder until epic 7 ») ; sinon `Color.WHITE`. Rien d'autre (pas de traînée, pas d'animation, pas de son).
- **Point de départ du dash et interpolation** : aucun placement par code, donc pas de `reset_physics_interpolation()`.

### Entrées (D6, AR12)

Dans `project.godot`, section `[input]`, même forme que les actions existantes :

| Action | Clavier (touche **physique**) | `physical_keycode` | Manette |
|---|---|---|---|
| `dash` | Espace | 32 | bouton RB (`JOY_BUTTON_RIGHT_SHOULDER`, indice 10) |
| `debug_slow_motion` | F4 | 4194335 | (aucune) |

- Pour RB : `Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":10,"pressure":0.0,"pressed":true,"script":null)`. Le plus sûr : écrire l'action à la main puis relancer `godot --headless --path game --import` et vérifier la ré-sérialisation (pas de bruit parasite dans `project.godot`, comme en 1.3).
- Espace est une touche physique : identique en AZERTY et QWERTY. Zone morte de chaque action : `0.2` (comme les autres).
- `dash` est le nom de l'architecture : ne pas en inventer d'autre. La réassignation est la story 1.7.

### F4 : ralenti ×0,25 (AR24)

- Dans `Main._unhandled_input`, **dans le garde `OS.is_debug_build()` existant**, ajouter l'action `debug_slow_motion` : bascule `GameClock.global_multiplier` entre `1.0` et `SLOW_MOTION_SCALE` (`0.25`, constante locale de `Main`), puis `get_viewport().set_input_as_handled()`. Un `Log.info("input", ...)` par bascule (pas par frame).
- L'état se lit sur `GameClock.global_multiplier` (pas de drapeau doublon dans `Main`). Il **survit à F5** : l'autoload n'est pas recréé.
- `Engine.time_scale` reste à 1 : vérifier par une recherche de `time_scale` (hors commentaires).
- Ce qui ralentit : tout ce qui lit `GameClock.scale()` (joueur, projectiles du test de charge). La surcouche F3 mesure le moteur et ne ralentit pas (voulu).
- `Main` ne connaît ni `Player` ni `Dash` pour F4 : il ne touche que `GameClock`.

### Report de 1.2 : échelle de temps > 1

`deferred-work.md` (revue de 1.2) : « Traversée de mur si l'échelle de temps d'un groupe dépasse 1 : un seul échantillon de cellule par tick. À traiter (sous-pas ou plafond de pas) à la story 1.4, quand `GameClock` aura une API d'écriture. » Décision : **plafond** : `global_multiplier` est borné à [0, 1] et aucune échelle de groupe n'est modifiable ici, donc `scale() ≤ 1` reste un invariant. Marquer le report **résolu par la story 1.4** (plafond d'échelle). Si une story future veut une échelle > 1 (aucune dans le GDD), elle devra rouvrir le sujet.

### Règles d'architecture qui s'appliquent

- GDScript typé partout (AR2) ; `snake_case` fichiers et dossiers, un script par classe, constantes `UPPER_SNAKE_CASE`, membres privés `_`, signaux au passé (`dash_ended`, `ended`), gestionnaires `_on_<émetteur>_<signal>`. Code, commentaires, logs et noms de fichiers **en anglais**.
- **Temps** (AR13) : compteurs manuels pilotés par `GameClock.scale(PLAYER)`. Pas de `Timer`, `create_timer`, `Engine.time_scale`.
- **Entrées** (AR12) : actions `InputMap`, lues dans `_physics_process`, tampon compté en ticks.
- **Aléatoire** : aucun.
- **Données** (AR9) : aucune valeur de gameplay en dur ; `Tuning.DASH` en lecture seule.
- **Logs** (AR27) : `Log.<niveau>(catégorie, message)`, pas de `print()`, rien par frame.
- **Erreurs** (AR28) : valeur sûre calculée avant `Log.error` et `assert`.
- **Frontières** : `core/` ne dépend d'aucun dossier de fonctionnalité ; `player/` ne dépend que de `core/` et des autoloads ; rien ne dépend de `debug/` sauf `Main`.
- **Pas d'autoload**, pas de signal sur `Events` dans cette story.

### Arborescence attendue à la fin de la story

```
game/
├── project.godot                       (UPDATE : dash, debug_slow_motion)
├── autoloads/game_clock.gd             (UPDATE : global_multiplier)
├── core/
│   ├── tuning.gd                       (UPDATE : DASH)
│   └── dash_tuning.gd                  (NEW)
├── data/tuning/dash_tuning.tres        (NEW)
├── player/
│   ├── player.gd                       (UPDATE : dash, signal, méthodes publiques, repère visuel)
│   └── dash.gd                         (NEW)
└── main/main.gd                        (UPDATE : F4)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (lexique, T7) et `deferred-work.md` (T11). Les `*.uid` se versionnent. Ne pas toucher à `arena.*`, `player_motor.gd`, `collision_drawer.gd`, ni aux scènes de `debug/`.

### Stratégie de test

Aucun framework de test (AR26 : avant le jalon B). Contrôles par scripts jetables du scratchpad (hors dépôt) lancés comme scène : `godot --headless --path game --scene <scène>`. Entrées simulées par `Input.action_press(&"dash")` puis `Input.action_release(&"dash")` **sur un autre tick** (un appui = un `is_action_just_pressed` à un seul tick), `Input.action_press(&"move_right")`, etc.

1. **Import et lancement** : `godot --headless --path game --import`, puis `--quit-after 120`. Zéro `SCRIPT ERROR`, zéro `Parse Error`.
2. **`Dash` seul** (sans scène, un tick = `tick(1.0, pressed, facing)` puis `velocity(1.0 / 60.0)` puis `finish_tick()`) :
   - départ au tick de l'appui ; position cumulée après le dash = **48 px** (±0,01) ; dash fini après **11 ticks** (10,8 arrondi au tick supérieur) ; le dernier pas est fractionnaire (0,8) ;
   - invulnérable pendant les ~9 premiers ticks (±1), plus après ; `ended` émis une fois, au dernier tick ;
   - recharge de **36 ticks** à partir de la fin ; un appui à 7 ticks de la fin de la recharge est **ignoré**, un appui à 6 ticks ou moins est **retenu** et le dash part au tick où la recharge atteint 0 (±1) ; un appui pendant le dash est ignoré ;
   - un appui pendant la recharge, hors fenêtre, puis rien : pas de dash fantôme ;
   - `clock_scale = 0` : rien ne bouge, rien n'avance (ni dash, ni recharge) ; `0,25` : le dash dure ~43 ticks réels pour 48 px ; `0,5` : ~22 ticks ;
   - `physics_delta = 0` : `velocity()` renvoie `ZERO` sans erreur ;
   - une `DashTuning` neuve avec `distance = 5.0` donne 80 px (réglable sans toucher au code).
3. **Joueur dans l'arène** (attendre un `physics_frame` après l'entrée de l'arène) :
   - **CA 1** : joueur au centre, `move_right` tenu puis `dash` : déplacement de 48 px (±1 px, `safe_margin` comprise) vers la droite en ~11 ticks ; idem dans les 8 directions (diagonale : 48 px de longueur, pas plus) ; à l'arrêt après un déplacement vers la gauche : le dash part vers la gauche ; **tout premier dash sans avoir bougé** : vers le bas.
   - **CA 2** : `is_dash_invulnerable()` et `is_invulnerable()` vrais pendant les ~9 premiers ticks, faux avant et après ; `is_dashing()` vrai pendant les ~11 ticks.
   - **CA 3** : `dash_ended` émis une fois par dash, à la position finale du dash.
   - **CA 4 et 5** : séquences d'appuis (voir `Dash` seul) rejouées sur le joueur.
   - **CA 6** : 20 dashs de face contre chacun des quatre murs et dans les quatre coins : le joueur ne sort jamais de `[19, 589] × [19, 317]` ; il s'arrête à ±0,5 px de la borne ; `dash_ended` reste émis à l'heure (≈ 11 ticks après le départ).
   - **CA 7** : modifier temporairement `distance` (puis `duration`) dans `dash_tuning.tres`, relancer, constater le changement ; **remettre la valeur d'origine**.
   - **CA 9** : `GameClock.paused = true` en plein dash : le joueur se fige, le dash reprend à `paused = false` sans perdre de distance (total 48 px) ; `GameClock.global_multiplier = 0.25` : dash complet en ~43 ticks, 48 px ; une valeur 2.0 est ramenée à 1.0 et −1 à 0.
   - **Marche non régressée** : sans appui sur `dash`, le comportement de 1.3 est inchangé (96 px/s, arrêt en 3 ticks, murs à 19/589/19/317).
   - **Entrées** : `InputMap.action_get_events(&"dash")` contient un `InputEventKey` de `physical_keycode` 32 avec `keycode` 0, et un `InputEventJoypadButton` de `button_index` 10.
4. **F4 / F5 / F2 (debug)** : `InputEventAction` `debug_slow_motion` : `GameClock.global_multiplier` vaut 0,25, puis 1,0 ; `Engine.time_scale` reste 1,0 ; avec F4 actif, F5 charge le test de charge (`Bullets 400`) et revient à l'arène sans erreur, le multiplicateur reste à 0,25 ; F2 bascule toujours le `CollisionDrawer`.
5. **Fenêtré sous WSLg** (indicatif) : le dash se voit (déplacement net de 3 tuiles, teinte pendant l'invulnérabilité), F4 ralentit visiblement le joueur et les 400 projectiles du test de charge, F2 affiche le carré 6×6, F3 reste fluide et inchangé ; capture d'écran par `get_viewport().get_texture().get_image().save_png()` depuis un script du scratchpad. Netteté du sprite pendant le dash : si des colonnes de pixels vacillent à 266 px/s, le consigner (ne pas activer `snap_2d_transforms_to_pixel` sans nécessité).
6. **Ressenti, étapes humaines** (à consigner, ne pas déclarer vérifié) : RB sur une vraie manette, sensation de la distance, du tampon, du dash contre un mur oblique, du demi-tour juste après un dash. Reportés à 1.7 et 1.8 ; les consigner dans `deferred-work.md`.
7. **Recherche des interdits** : `grep -rnE 'print\(|Timer|create_timer|time_scale|randf|randi|randomize|shuffle|pick_random|/root/' game --include=*.gd` : seules les occurrences attendues (`log.gd`, commentaires). Aucun `Log.` dans `_physics_process`, `_process` ni `tick()`.

### Commit

Directement sur `main`, Conventional Commits en anglais, un `git push` après chaque commit (consigne du projet). Exemples : `feat(player): add dash with i-frames, input buffer and f4 slow motion` pour le code ; `docs(architecture): add dash terms to the lexicon` ; `docs(story): record story 1.4 implementation progress`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `player/dash.gd`, `data/tuning/dash_tuning.tres`.
- **Écarts assumés** :
  - `DashTuning` dans `core/` et non dans `player/` (même raison que `PlayerTuning`, voir 1.3).
  - `Dash` est une logique pure (`RefCounted`) possédée par `Player`, et non un nœud composant : testable sans scène, cohérent avec `PlayerMotor`. Si 5.x préfère un nœud, l'interface publique de `Player` ne change pas.
  - `GameClock.global_multiplier` est une addition minimale à un autoload « sans état de run » : c'est un réglage de debug, pas de l'état de run.
  - `is_invulnerable()` ne couvre que le dash tant que la story 2.1 n'existe pas.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md` et de la mémoire du projet :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (aucun dans cette story).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.

### Décisions prises à la création de la story (modifiables)

1. **Tampon** : fenêtre = les 0,1 s qui précèdent la **fin de la recharge** (lecture littérale de l'epic). Un appui pendant le dash lui-même est ignoré.
2. **Mur** : le dash garde sa durée et ne se termine pas sur collision ; `move_and_slide()` arrête de face et glisse en oblique.
3. **Direction initiale** : vers le bas (`Vector2.DOWN`) tant que le joueur n'a jamais bougé.
4. **Moteur pendant le dash** : continue d'avancer au `delta` réel vers l'entrée tenue ; la marche reprend à la vitesse courante.
5. **F4** : multiplicateur global dans `GameClock`, borné à [0, 1], composé avec les échelles de groupe.
6. **Report de 1.2 (échelle > 1)** : refermé par ce plafond.

### Questions ouvertes (sans effet bloquant sur le code)

1. **Dash dans un mur** : une invulnérabilité qui continue alors que le joueur est coincé est-elle juste ? À juger au jeu.
2. **Le dash interrompt-il la marche** (vitesse du moteur à zéro au départ) ? Choix actuel : non. À juger au ressenti.
3. **Manette réelle** (RB) : non testable sous WSL ; à valider sous Windows avec 1.7.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.4]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR3, FR4)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR9, AR12, AR13, AR24, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Déplacement et dash] (3 tuiles, 0,18 s, 0,15 s, 0,6 s, 0,1 s)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Contrôles] (Espace, RB)
- [Source: _bmad-output/game-architecture.md#Entrées et latence (D6)]
- [Source: _bmad-output/game-architecture.md#Temps (D7)] et [#P4. Temps par groupe]
- [Source: _bmad-output/game-architecture.md#P2. Graze et dash parfait] (`is_dash_invulnerable()`, `is_invulnerable()`)
- [Source: _bmad-output/game-architecture.md#Outils de debug] (F4)
- [Source: _bmad-output/game-architecture.md#Données de réglage (D4)] et [#Accès aux données]
- [Source: _bmad-output/game-architecture.md#Compléments (ajoutés à la validation)] (trous et dash : hors périmètre ici)
- [Source: _bmad-output/game-architecture.md#Structure du projet] (arborescence, frontières, lexique)
- [Source: _bmad-output/implementation-artifacts/1-3-se-deplacer-dans-l-arene.md] (Review Findings, Dev Notes)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (échelle > 1, F2 non interpolé)
- [Externe : docs Godot 4.7 via Context7 : `Input.is_action_just_pressed` (vrai sur le tick de physique de l'appui, même si l'action est relâchée aussitôt), `CharacterBody2D.move_and_slide` (intègre `velocity` avec le `delta` de physique ; `MOTION_MODE_FLOATING` : toute collision est un mur, `wall_min_slide_angle` 15°)]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5 (`claude-sonnet-5-5`)

### Debug Log References

- Les scripts de vérification jetables (scratchpad, hors dépôt) tournent comme des scènes ; les avertissements en erreur s'appliquent aussi à eux (types stricts, pas de `Variant`).
- Piège de test : après `await physics_frame`, le coroutine reprend **avant** le `_physics_process` du joueur du même tick ; un appui suivi d'une lecture de `is_dashing()` sans attendre un tick de plus lit l'état du tick précédent.
- Changer `distance`/`duration` dans `dash_tuning.tres` change bien le dash (74 px au lieu de 48 sur la fenêtre de test) ; valeurs d'origine remises.

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-20).
- **T1** `DashTuning` + `dash_tuning.tres` (valeurs du GDD) + `Tuning.DASH`. **T2** actions `dash` (Espace physique 32, RB indice 10) et `debug_slow_motion` (F4) ; `--import` ne ré-écrit pas `project.godot`. **T3** `GameClock.global_multiplier` (borné à [0, 1], composé avec les échelles de groupe, `paused` prioritaire).
- **T4** `Dash` (`RefCounted`, ticks de jeu, sans `Timer`) : départ au tick de l'appui, dernier pas tronqué (48 px exacts à toute échelle), recharge comptée depuis la fin du dash, tampon = 6 derniers ticks de la recharge, appui pendant le dash ignoré. Valeurs sûres calculées avant `Log.error` + `assert` (leçon de 1.3).
- **T5** `Player` : `_facing` (départ `Vector2.DOWN`, dernière direction d'**entrée**), signal `dash_ended`, `is_dash_invulnerable()`, `is_invulnerable()` (dash seul pour l'instant), `is_dashing()`, teinte provisoire `DASH_TINT` pendant l'invulnérabilité. `move_and_slide()` conservé : le dash garde sa durée contre un mur. **T6** F4 dans `Main` (garde debug), état lu sur `GameClock`, survit à F5, `Engine.time_scale` jamais touché.
- **T7** lexique de `game-architecture.md` complété.
- **Vérifications (T8, T10)** : `Dash` seul, 31 contrôles OK (48 px, 11 ticks, invulnérabilité 8 ticks vus après `tick()` soit 9 pour un tiers qui lit avant le joueur, recharge 36 ticks, tampon refusé à 7 ticks et retenu à 6 ou moins avec départ au tick 46, pause, échelles 0 / 0,25 / 0,5, `physics_delta = 0`, `distance = 5` → 80 px, bornes du multiplicateur, entrées `InputMap`). Joueur dans l'arène : premier dash vers le bas, 8 directions, arrêt dans la dernière direction (48 px, diagonale 48 px), 20 dashs contre chacun des 4 murs et 4 coins sans jamais sortir de `[19, 589] × [19, 317]`, arrêt à ±0,01 px de la borne, `dash_ended` à l'heure, pause en plein dash (total 48 px), F4 (48 px en 43 ticks), marche inchangée (96 px/s). `Main` : F4 → 0,25 puis 1,0, F5 aller-retour avec F4 actif, multiplicateur conservé. Import et lancement sans `SCRIPT ERROR` ; recherche des interdits : seules occurrences attendues, aucun `Log.` par tick.
- **Fenêtré sous WSLg (T9)** : sprite teinté et translucide pendant le dash (capture), F4 ralentit visiblement (dash de 745 ms réels pour ~720 attendues ; llvmpipe, non représentatif). F2 non revérifié à l'œil : seul le comportement de `Main` est testé (aucun changement dans `CollisionDrawer`).
- **T11** `deferred-work.md` : report de 1.2 (échelle > 1) refermé par le plafond ; nouveaux reports (RB réel, ressenti, netteté sous Windows, questions ouvertes). Pas de framework de test (AR26) : aucun fichier de test ajouté au dépôt, conformément à la story.
- Décision sans impact : la story demandait `Dash.tick()` avant `move_and_slide()`, `finish_tick()` après ; respecté tel quel.

### File List

- `game/core/dash_tuning.gd` (nouveau) + `game/core/dash_tuning.gd.uid`
- `game/data/tuning/dash_tuning.tres` (nouveau)
- `game/core/tuning.gd` (modifié : `DASH`)
- `game/player/dash.gd` (nouveau) + `game/player/dash.gd.uid`
- `game/player/player.gd` (modifié)
- `game/autoloads/game_clock.gd` (modifié : `global_multiplier`)
- `game/main/main.gd` (modifié : F4)
- `game/project.godot` (modifié : actions `dash`, `debug_slow_motion`)
- `_bmad-output/game-architecture.md` (modifié : lexique)
- `_bmad-output/implementation-artifacts/deferred-work.md` (modifié)
- `_bmad-output/implementation-artifacts/1-4-dasher.md` (cette story)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modifié)

### Change Log

- 2026-11-21 : implémentation de la story 1.4 (dash, tampon d'entrée, F4, `GameClock.global_multiplier`) ; statut `review`.
