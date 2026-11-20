# Story 1.5 : Viser et tirer

Status: ready-for-dev

## Story

En tant que joueur,
je veux tirer librement à la souris ou au stick, avec des retours nets à chaque tir et à chaque impact,
afin que chaque tir se sente.

**Exigences couvertes :** FR5, FR6 (hors chiffres de dégâts, voir 1.6), AR6 (camp joueur), AR21 (bus et pool), NFR8 (tirs du joueur discrets), AR9, AR12, AR13, AR32.

**Prérequis : la story 1.4 doit être `done`.** Cette story s'appuie sur `Player.is_dashing()`, sur `GameClock.global_multiplier` (F4), sur l'action `dash` et sur la boucle `_physics_process` de 1.4. Au moment où ce fichier a été écrit, 1.4 était `ready-for-dev` : **vérifier avant de commencer** que `Dash`, `Player.is_dashing()` et `GameClock.global_multiplier` existent dans le dépôt. S'ils n'existent pas, **s'arrêter** et le dire à Kroustille (ne pas réimplémenter 1.4 ici). Les extraits de `Player` plus bas décrivent l'état **après 1.4**, tel que la story 1.4 le spécifie : relire `player/player.gd` tel qu'il est réellement avant d'y toucher.

## Critères d'acceptation

1. **Étant donné** le joueur au clavier-souris, **quand** il bouge la souris, **alors** la visée suit la direction du joueur vers le curseur, convertie dans les coordonnées du monde (viewport 640×360), et un réticule s'affiche.
2. **Étant donné** le joueur à la manette, **quand** il incline le stick droit au-delà de la zone morte, **alors** la visée suit le stick, et le tir part tout seul. RT tire dans la dernière direction visée.
3. **Étant donné** le clic gauche maintenu, **quand** le joueur tire, **alors** le tir part à 4 tirs/s, va à 14 tuiles/s, inflige 10 dégâts et a une hitbox de 4×4, **exactement** dans la direction visée, par le `BulletManager` du joueur. Il file jusqu'à un mur, sans portée maximale. Les tirs du joueur sont plus petits et plus transparents que des projectiles ennemis, dans une couleur qui leur est réservée. Les valeurs viennent de `ShotTuning.tres`.
4. **Étant donné** un dash en cours, **quand** le joueur maintient le tir, **alors** aucun tir ne part pendant le dash, et le tir reprend dès sa fin.
5. **Étant donné** un tir qui part, **quand** il est émis, **alors** le sprite du joueur recule de 1 px pendant 0,05 s, et un son court provisoire se joue par l'autoload `Audio` sur le bus `SFX`. Les bus `Master`, `Music`, `SFX` et `UI` existent, et `Audio` gère un pool de lecteurs avec une limite de voix par son.
6. **Étant donné** une cible d'entraînement dans l'arène, qui porte une `Hurtbox`, **quand** un tir la touche, **alors** le tir est détruit, et les dégâts passent par `DamageInfo` puis `Hurtbox.receive()`. La cible flashe en blanc pendant 0,05 s et recule de 2 px.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture ou par l'état du dépôt) :

7. Tout obéit à `GameClock` : avec `GameClock.paused = true`, aucun tir ne part, les tirs en vol se figent, la cadence, le recul et le flash se figent ; sous F4 (×0,25), ils ralentissent en conséquence. Aucun `Timer`, aucun `Engine.time_scale`.
8. La cadence tient même si le joueur clique plus vite que 4 fois par seconde : jamais plus de 4 tirs/s, quelle que soit la façon d'appuyer.
9. Le retour d'impact (flash + recul) est un **composant réutilisable** : la story 2.3 l'exige pour Le Somnambule (« avec les retours d'impact de la Story 1.5 »). Il ne doit rien savoir de la cible d'entraînement.
10. F2 affiche aussi la `Hurtbox` des cibles ; F3 compte les tirs du joueur dans `Bullets` ; F5 (arène ↔ test de charge) et F4 continuent de fonctionner. Le test de charge à 400 projectiles ennemis ne régresse pas (le coût ajouté à la boucle de `BulletManager` est nul quand aucune cible n'est enregistrée).
11. Le curseur système est caché tant que l'arène est active et **redevient visible** quand l'arène quitte l'arbre (F5).
12. La marche et le dash de 1.3 et 1.4 sont inchangés.

## Tâches / sous-tâches

- [ ] **T1. Lexique** (AR32 : un terme entre dans le lexique **avant** le code)
  - [ ] `game-architecture.md`, section « Lexique » : ajouter `Tir ; cadence ; recul du tir ; visée ; réticule ; cible d'entraînement | shot ; fire_rate ; recoil ; aim ; reticle ; training_target`.
- [ ] **T2. Réglages du tir** (CA 3, 5, 6)
  - [ ] `core/shot_tuning.gd` : `class_name ShotTuning extends Resource` (voir « `ShotTuning` »).
  - [ ] `data/tuning/shot_tuning.tres` (valeurs du GDD) et `Tuning.SHOT` (`preload`).
- [ ] **T3. Entrées** (CA 1 à 3)
  - [ ] `project.godot` : actions `aim_left`, `aim_right`, `aim_up`, `aim_down` (stick droit) et `shoot` (clic gauche, RT) (voir « Entrées »).
- [ ] **T4. Bus audio et `Audio`** (CA 5)
  - [ ] `default_bus_layout.tres` : `Master`, `Music`, `SFX`, `UI`.
  - [ ] `autoloads/audio.gd` : pool de lecteurs, limite de voix par son, `play_sfx()` (voir « `Audio` »).
  - [ ] `audio/sfx/sfx_player_shot.wav` : son provisoire généré par script (voir « Son provisoire »).
- [ ] **T5. Dégâts et `Hurtbox`** (CA 6)
  - [ ] `combat/damage_info.gd`, `combat/hurtbox.gd` (voir « `DamageInfo` et `Hurtbox` »).
- [ ] **T6. `BulletManager` : dégâts et cibles** (CA 3, 6, 10)
  - [ ] `BulletParams.damage`, tableau `_damages`, `register_hurtbox()`, test cercle contre rectangle (voir « `BulletManager` »).
- [ ] **T7. Retour d'impact réutilisable** (CA 5, 6, 9)
  - [ ] `vfx/sprite_kick.gd`, `vfx/shaders/hit_flash.gdshader`, `combat/hit_feedback.gd` (voir « Retours »).
- [ ] **T8. Visée, cadence, réticule** (CA 1 à 4, 7, 8)
  - [ ] `player/aim.gd`, `player/shooter.gd`, `player/reticle.gd` (voir « `Aim` », « `Shooter` », « `Reticle` »).
- [ ] **T9. `Player`** (CA 1 à 5, 7, 11)
  - [ ] Brancher visée, cadence, tir, recul, réticule ; `equip_bullets()` (voir « `Player` »).
- [ ] **T10. Arène et cible d'entraînement** (CA 3, 6, 10)
  - [ ] `rooms/arena/training_target.gd` + `.tscn`, `arena.tscn` (conteneur `Targets`), `arena.gd` (`BulletManager` du joueur, enregistrement des cibles) (voir « Arène »).
- [ ] **T11. Vérifications headless** (CA 1 à 10)
  - [ ] Scripts jetables dans le scratchpad (pas dans le dépôt) : voir « Stratégie de test ».
- [ ] **T12. Vérifications fenêtrées sous WSLg** (CA 1, 3, 5, 6, 11)
  - [ ] Tir visible, réticule, conversion souris→monde, flash et recul de la cible, capture d'écran.
- [ ] **T13. Régression** : import et lancement headless sans erreur, recherche des interdits, marche, dash, F2, F3, F4 et F5 de 1.1 à 1.4 toujours conformes, test de charge sans régression de coût.
- [ ] **T14. Reports** : consigner dans `deferred-work.md` ce qui n'a pas pu être vérifié (manette réelle : stick droit et RT ; ressenti ; son provisoire ; curseur et pause pour 1.6).

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

Le joueur tire dans l'arène sur des cibles qui ne font que réagir. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Menu de pause, réglages (volumes sur les bus créés ici), chiffres de dégâts | 1.6 |
| Bascule automatique clavier-souris ↔ manette, réassignation, touches de `shoot` et `aim_*` configurables, gestion fine du curseur | 1.7 |
| Export, latence mesurée | 1.8 |
| `Health`, mort d'une cible, `Hurtbox` du joueur, coups reçus | 2.1 |
| `Telegraph`, ennemis réels, projectiles ennemis (couleur, contour), graze, dash parfait (`FLAG_COUNTED`) | Epic 2, 3 |
| `Lucidity` : cadence +30 % au palier Lucide, bonus de dégâts | Epic 3 |
| `StatBlock`, objets : traversée, tir arrière, taille, traînée | Epic 5 |
| Obstacles hauts et bas, meubles, trous | Epic 4 |
| Musique, filtre passe-bas sur `Music`, sons définitifs, sprites et effets définitifs | 3.x, 7.x |
| `Hitbox` (émetteur de contact) | Epic 2 |

Aucun texte affiché au joueur : pas de `tr()` à écrire.

### État actuel du dépôt (stories 1.1 à 1.3 `done`, 1.4 supposée `done`)

- `BulletManager` (`combat/bullets/bullet_manager.gd`, `class_name BulletManager extends Node2D`) : `enum Camp { ENEMY, PLAYER }` ; tableaux parallèles `_positions`, `_velocities` (px/s), `_radii` (px), `_lifetimes`, `_flags`, `_appearances`, pile d'emplacements libres, `_high_water` ; `setup(solid_layers)` **avant** `add_child()` ; `add_appearance(texture) -> int` ; `fire(params, origin, direction) -> bool` (valide les paramètres même en release : vitesse dans `(0, une tuile par tick)`, durée finie > 0, rayon ≥ 0, direction normalisée ; `Log.error` + refus sinon) ; `_physics_process` (une lecture de `GameClock.scale(groupe)` par tick, test de mur par **un échantillon de cellule par tick**) ; `_process` (rendu `MultiMesh`) ; compteurs `active_count` et `refused_count`. `FLAG_COUNTED` est réservé au graze (epic 2) : **ne pas y toucher**. Le groupe d'horloge est `PLAYER_BULLETS` pour `Camp.PLAYER`. Sa position doit être nulle et ses couches solides à la même origine.
- `BulletParams` (`class_name BulletParams extends Resource`) : `speed` (tuiles/s), `radius` (tuiles), `lifetime` (s), `appearance`. Aucun champ de dégâts.
- `Audio` (`autoloads/audio.gd`) : **coquille vide** (`extends Node`, deux lignes de commentaire). `Events`, `Settings`, `SaveService` : coquilles vides, ne pas y toucher. **Aucun `default_bus_layout.tres`** : seul le bus `Master` existe.
- `Const` : `TILE_SIZE`, `LAYER_*` (dont `LAYER_ENEMY_HURTBOX` = `1 << 7` et `LAYER_PLAYER_HURTBOX` = `1 << 6`, déjà nommées dans `project.godot`), `GROUP_BULLET_MANAGERS`, `GROUP_DEBUG_SHAPES`. `Tuning` : `PLAYER` (et `DASH` après 1.4). Les Resources sont en lecture seule à l'exécution.
- `Player` (`player/player.gd`, `CharacterBody2D`, après 1.4) : nœuds `Sprite` (`%Sprite`, `Sprite2D` 16×24 centré, texture générée en code) et `Hitbox` (`%Hitbox`, `CollisionShape2D` 6×6, groupe `GROUP_DEBUG_SHAPES`). **L'origine du nœud est le centre du torse : les tirs en partent** (commentaire de 1.3). Boucle `_physics_process` : `clock_scale` lu une fois, `wish` par `Input.get_vector`, moteur, `_dash.tick(...)`, vitesse, `move_and_slide()`, `_dash.finish_tick()`, teinte du dash (`_sprite.modulate`). Méthodes publiques : `is_dashing()`, `is_dash_invulnerable()`, `is_invulnerable()`. **Le sprite est déjà piloté par `modulate` (dash) : le recul du tir passe par `position`, pas par `modulate`.**
- `Arena` (`rooms/arena/arena.gd` + `.tscn`) : nœuds `Floor`, `Walls` (`TileMapLayer`, construits **en code** dans `_ready()` par `_build_tiles()`), `Player` (instance de `player.tscn`), `Camera` (fixe, `process_callback = 0`). `_ready()` : `_check_screen_layout()`, `_build_tiles()`, caméra, joueur au centre `(304, 168)`. **Les enfants (dont `Player`) ont déjà exécuté leur `_ready()` quand `Arena._ready()` démarre** : le joueur ne peut donc pas recevoir son `BulletManager` par un `setup()` avant `add_child()` ; voir `Player.equip_bullets()`.
- Arène : cadre de murs fermé de 38×21 tuiles, zone jouable `x ∈ [16, 592]`, `y ∈ [16, 320]`. Aucune ouverture : tout tir finit contre un mur.
- `Main` : `_show_scene()` recrée l'arène à chaque retour de F5 (`ActiveScene` garde un seul enfant). `CollisionDrawer` (F2) dessine tout `CollisionShape2D` du groupe `GROUP_DEBUG_SHAPES`, **rectangles et cercles** seulement, par position physique.
- `debug/bullet_load_test.gd` : `BulletManager` ennemi, 400 projectiles, `BulletParams` à `damage` implicite 0 ; ne pas le modifier (il doit seulement continuer à fonctionner). Le rose `Color(1.0, 0.35, 0.6)`, 8×8, y tient lieu de projectile ennemi provisoire.
- Interpolation physique 2D **activée** (`physics/common/physics_interpolation=true`) ; `physics_ticks_per_second=60`. Rendu Compatibility, filtre `Nearest`.
- Environnement : Godot 4.7.2 via WSLg, `godot` dans le `PATH`. **Pas de manette sous WSL** (stick droit et RT réels non testables). **Pas de `python3`** : `uv` est disponible (`uv run python …`). Les fichiers `*.import` sont versionnés (`game/.godot/` ne l'est pas).

### Leçons des stories 1.1 à 1.4 à appliquer

- **Typage strict, avertissements en erreur** (`untyped_declaration`, `unsafe_*` à 2). Un `Variant` ne se convertit pas avec `int(...)` : passer par une variable typée. Un nœud récupéré par groupe se caste (`as`) et un `null` est ignoré.
- **Aucune valeur de gameplay en dur** (NFR9, AR9) : cadence, vitesse, dégâts, hitbox, recul, flash viennent de `ShotTuning`. Sont des constantes **locales** autorisées, car structurelles ou visuelles provisoires : capacité du pool de tirs, taille et couleur du réticule, textures provisoires, distance du réticule au stick (voir plus bas).
- **Calculer la valeur sûre avant de journaliser et d'`assert`** (revue de 1.3) pour toute valeur de réglage qui peut faire diviser par zéro (`fire_rate`, durées). Le repli doit valoir aussi en debug sans débogueur.
- **L'échelle de temps ne s'applique qu'une fois** (décision de revue de 1.3). Les compteurs de la story sont des **ticks de jeu** : `clock_scale` par tick (1,0 normal, 0,25 sous F4, 0 en pause), durées converties **une fois** par `secondes * Engine.physics_ticks_per_second` (ne pas coder 60).
- **Couches de collision** par `Const.LAYER_*`. **Injection** : `setup()` avant `add_child()` quand c'est possible. Pas de `/root/...`, pas de `get_parent().get_parent()`.
- **Fichiers `*.uid` générés par Godot : à versionner**, comme les `.import` du `.wav`.
- **Vérifications** : `godot --headless --path game --import`, puis `godot --headless --path game --quit-after <n>`. Zéro `SCRIPT ERROR`, zéro `Parse Error`. `--script` ne résout pas les autoloads : les vérifications tournent comme une **scène** du scratchpad (`godot --headless --path game --scene <scène>`), avec `call_deferred`, puis `await get_tree().physics_frame` en boucle pour avancer au tick.
- `TileMapLayer` crée ses corps physiques avec un léger différé : attendre au moins un `physics_frame` avant de tester.
- **Un nœud déplacé dans `_process` doit désactiver l'interpolation physique** (`physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF`), sinon il traîne : c'est le cas du réticule.
- Le contour F2 suit la position physique (≈ 1,6 px d'écart à pleine vitesse) : attendu pour le joueur ; pour une cible immobile, il coïncide.

### `ShotTuning` (AR9, D4)

`class_name ShotTuning extends Resource`, dans **`game/core/shot_tuning.gd`** (même raison que `PlayerTuning` : `Tuning`, dans `core/`, type ses constantes avec cette classe). Distances en tuiles, durées en secondes ; la conversion en pixels se fait à un seul endroit (`BulletManager.fire` pour le tir, `SpriteKick` pour les décalages).

| Champ | Type | Sens | Valeur (GDD) |
|---|---|---|---|
| `damage` | `float` | dégâts par tir (PV ennemis) | 10,0 |
| `fire_rate` | `float` | tirs par seconde | 4,0 |
| `bullet_speed` | `float` | tuiles par seconde | 14,0 |
| `hitbox_size` | `float` | côté de la hitbox du tir, en tuiles (4×4 px) | 0,25 |
| `lifetime` | `float` | secondes avant disparition : **filet de sécurité, pas une portée** (`BulletManager` refuse une durée infinie) | 10,0 |
| `recoil_distance` | `float` | recul du sprite du joueur au tir, en tuiles (1 px) | 0,0625 |
| `recoil_duration` | `float` | durée du recul, en secondes | 0,05 |
| `impact_flash_duration` | `float` | durée du flash blanc de la cible, en secondes | 0,05 |
| `impact_knockback_distance` | `float` | recul visuel de la cible touchée, en tuiles (2 px) | 0,125 |
| `impact_knockback_duration` | `float` | durée de ce recul, en secondes (le GDD ne la donne pas : même valeur que le flash) | 0,05 |

- `@export` typés ; `@export_range` pour borner les saisies (`fire_rate` ≥ 0,1, `bullet_speed` > 0, `hitbox_size` ≥ 0, durées ≥ 0).
- Un seul `.tres` pour le tir **et** son retour d'impact (le GDD les regroupe dans « Sensations ») ; la story 2.3 lira les champs `impact_*` pour Le Somnambule.
- `data/tuning/shot_tuning.tres`, en texte, sur le modèle de `player_tuning.tres` :

```
[gd_resource type="Resource" script_class="ShotTuning" load_steps=2 format=3]

[ext_resource type="Script" path="res://core/shot_tuning.gd" id="1_tuning"]

[resource]
script = ExtResource("1_tuning")
damage = 10.0
fire_rate = 4.0
bullet_speed = 14.0
hitbox_size = 0.25
lifetime = 10.0
recoil_distance = 0.0625
recoil_duration = 0.05
impact_flash_duration = 0.05
impact_knockback_distance = 0.125
impact_knockback_duration = 0.05
```

- `Tuning` : `const SHOT: ShotTuning = preload("res://data/tuning/shot_tuning.tres")`. Aucune affectation sur `Tuning.SHOT`. Après création, `godot --headless --path game --import` et versionner l'éventuel `uid=`.
- Valeurs invalides : `fire_rate < 0,01` fait diviser par zéro la période. Calculer la valeur sûre (`maxf(fire_rate, MIN_FIRE_RATE)`) **avant** `Log.error("combat", ...)` et `assert(false, ...)`. Une vitesse qui dépasse une tuile par tick est déjà refusée par `BulletManager.fire()` (journalisée, pas de tir) : ne pas la dupliquer. Les autres champs négatifs sont ramenés à 0 par `maxf(..., 0.0)` sans log.
- Vérifier le passage tuiles → pixels : 14 tuiles/s = 224 px/s = **3,73 px par tick** (sous la limite d'une tuile par tick) ; 0,25 tuile = 4 px (rayon 2 px).

### Entrées (D6, AR12)

Dans `project.godot`, section `[input]`, même forme que les actions existantes. Lues dans `_physics_process`.

| Action | Clavier et souris | Manette | Zone morte |
|---|---|---|---|
| `aim_left` | (aucune) | stick droit, axe 2, valeur −1,0 (`JOY_AXIS_RIGHT_X`) | 0,2 |
| `aim_right` | (aucune) | stick droit, axe 2, valeur +1,0 | 0,2 |
| `aim_up` | (aucune) | stick droit, axe 3, valeur −1,0 (`JOY_AXIS_RIGHT_Y`) | 0,2 |
| `aim_down` | (aucune) | stick droit, axe 3, valeur +1,0 | 0,2 |
| `shoot` | clic gauche (`MOUSE_BUTTON_LEFT`, indice 1) | RT : axe 5, valeur +1,0 (`JOY_AXIS_TRIGGER_RIGHT`) | 0,5 |

- La visée souris **n'est pas une action** : c'est la position du curseur (architecture D6 : « visée souris convertie dans les coordonnées du monde »). `aim_*` ne porte que le stick droit.
- `Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")` applique la zone morte (moyenne des zones mortes des quatre actions : 0,2, comme pour `move_*`). Le stick incliné au-delà donne un vecteur non nul : pas de recalcul de zone morte.
- Zone morte de `shoot` à 0,5 : une gâchette est un axe qui repose à 0 ; 0,5 évite les tirs parasites. Valeur de départ, à juger sur une vraie manette (report).
- Formes sérialisées (à écrire à la main, puis `godot --headless --path game --import` pour vérifier la ré-sérialisation, sans bruit parasite dans `project.godot`, comme en 1.3 et 1.4) :
  - clic gauche : `Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":1,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":true,"double_click":false,"script":null)` ;
  - stick et RT : `Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":<n>,"axis_value":<±1.0>,"script":null)`.
- Les noms `aim_*` et `shoot` sont ceux de l'architecture : ne pas en inventer d'autres. La réassignation et la bascule de périphérique sont la story 1.7.

### `Audio` et les bus (D15, AR21)

**Bus** : créer `game/default_bus_layout.tres` (chemin de l'architecture ; Godot le charge par défaut, aucun réglage de `project.godot` à ajouter). `Master` existe toujours ; ajouter `Music`, `SFX`, `UI`, tous **envoyés vers `Master`**, volume 0 dB. Écrire le `.tres` à la main (type `AudioBusLayout`, propriétés `bus/1/name`, `bus/1/send`, etc.), puis vérifier au lancement : `AudioServer.get_bus_index(&"SFX") != -1` pour les quatre noms, et `AudioServer.get_bus_send(index)` vaut `Master` pour les trois autres. Pas de filtre passe-bas sur `Music` ici (Epic 3).

**`autoloads/audio.gd`** : remplace la coquille. Pas d'état de run (règle des autoloads).

```gdscript
const SFX_BUS: StringName = &"SFX"
const POOL_SIZE: int = 16                 # technical, not gameplay
const DEFAULT_MAX_VOICES: int = 3         # per sound

var dropped_count: int = 0                # plays refused (pool full or voice limit), for debugging

func play_sfx(stream: AudioStream, max_voices: int = DEFAULT_MAX_VOICES) -> bool
```

- Le pool : `POOL_SIZE` `AudioStreamPlayer`, créés dans `_ready()`, `bus = SFX_BUS`, enfants de l'autoload.
- **Limite de voix par son** : un compteur par `AudioStream` (clé : la Resource elle-même) du nombre de lecteurs qui le jouent. `play_sfx` refuse (renvoie `false`, incrémente `dropped_count`, **aucun log**) si ce compteur a atteint `max_voices`, ou si aucun lecteur n'est libre. Chaque lecteur décrémente le compteur de son flux à `finished`. Un flux `null` : `Log.error("audio", ...)`, `assert(false, ...)`, renvoie `false` (erreur de programmation, AR28).
- Pas de `Timer`, pas de RNG (pas de variation de hauteur au hasard : un tir répété doit sonner identique ; les variations viendront avec le flux `cosmetic`).
- L'audio ne suit pas `GameClock` (hauteur et vitesse de lecture inchangées sous F4) ; en pause, aucun tir ne part donc aucun son. Rien à brancher.
- **Sous `--headless`, le pilote audio est factice** : `play_sfx` doit réussir sans erreur et le compteur de voix doit se vider quand le son se termine (le pilote factice consomme les flux). Si `finished` n'arrive jamais en headless, ne pas bricoler le code : le noter et vérifier le décrément en fenêtré.
- Aucun `Log.` par son joué.

### Son provisoire

Pas d'asset audio dans le dépôt. Générer `game/audio/sfx/sfx_player_shot.wav` (nommage de l'architecture : `sfx_<domaine>_<nom>.wav`) par un script jetable du scratchpad, avec le module standard `wave` : `uv run python <script>`. Mono, 16 bits, 22 050 Hz, **≈ 0,06 s** (un « pew » très court : sinusoïde de 900 Hz descendant vers 400 Hz, enveloppe en décroissance linéaire, amplitude ≈ 0,4 pour ne pas saturer). Aucun hasard (déterminisme du script). Après création : `godot --headless --path game --import`, puis **versionner le `.wav` et son `.wav.import`** (les `.import` sont versionnés dans ce dépôt). Le son est provisoire (« remplacé par la story 7.7 »), à signaler dans un commentaire du chargement. Chargement : `const SHOT_SOUND: AudioStream = preload("res://audio/sfx/sfx_player_shot.wav")` dans `Player`.

### `DamageInfo` et `Hurtbox` (D2, « Dégâts et unités »)

`combat/damage_info.gd` :

```gdscript
class_name DamageInfo
extends RefCounted
## One hit, from a source to a Hurtbox. Joueur : half-hearts (integers). Enemies: HP (floats).

enum Source { PLAYER_SHOT }          # extended by later stories (enemy bullet, contact, pit...)

var amount: float = 0.0
var source: Source = Source.PLAYER_SHOT
var is_heavy: bool = false
var direction: Vector2 = Vector2.ZERO # unit vector of the hit (bullet heading), 0 if none: drives the knockback

static func from_bullet(amount: float, direction: Vector2, source: Source) -> DamageInfo
```

`direction` est un ajout à la liste de l'architecture (`amount`, `source`, `is_heavy`) : le recul de 2 px (FR6) en a besoin. À consigner dans les décisions.

`combat/hurtbox.gd` :

```gdscript
class_name Hurtbox
extends Area2D
signal damage_received(info: DamageInfo)   # local signal: the owner (parent) listens

@export var camp: BulletManager.Camp = BulletManager.Camp.ENEMY   # whose hurtbox this is

func receive(info: DamageInfo) -> void     # emits damage_received; no HP here (Health: story 2.1)
func world_rect() -> Rect2                 # axis-aligned rect of its RectangleShape2D, global coordinates
```

- Une `Hurtbox` **appartient à un camp** : `Camp.ENEMY` pour une cible touchée par les tirs du joueur. Son `collision_layer` est `Const.LAYER_ENEMY_HURTBOX` (camp ennemi) ou `Const.LAYER_PLAYER_HURTBOX` (camp joueur), `collision_mask = 0`, `monitoring = false`, `monitorable = true`, posés dans `_ready()`. Les `BulletManager` ne passent pas par la physique (D1) : ces couches servent aux consommateurs `Area2D` futurs (contact, Epic 2).
- Son `CollisionShape2D` enfant porte un `RectangleShape2D` (frais par instance, comme pour le joueur) et rejoint `GROUP_DEBUG_SHAPES` : F2 l'affiche sans toucher à `CollisionDrawer` (qui gère déjà les rectangles ; ce report de 1.3 est donc réglé pour les rectangles).
- `world_rect()` : centre = `global_position` du `CollisionShape2D` ; ignore rotation et échelle (documenter).
- Pas de `Health` : `receive()` émet seulement le signal. **Pas de classe `Hitbox`** ici.

### `BulletManager` : dégâts et cibles (D1, AR6, P2 en retrait)

Modifications de `combat/bullets/bullet_manager.gd` et `bullet_params.gd`, **sans changer l'interface existante** (`fire`, `setup`, `add_appearance`) ni le comportement des managers ennemis sans cibles :

1. **`BulletParams.damage: float`** (`@export`, défaut 0,0). Pour le camp joueur : PV ennemis. `_is_shot_valid()` refuse un dégât non fini ou négatif (même schéma : `Log.error`, `assert`, refus).
2. **`_damages: PackedFloat32Array`** (redimensionné dans `_ready()` comme les autres), écrit par `fire()`.
3. **Cibles** : `register_hurtbox(hurtbox: Hurtbox) -> void` et `unregister_hurtbox(hurtbox: Hurtbox) -> void`.
   - `register_hurtbox` refuse (`Log.error("combat", ...)`, `assert`) une hurtbox de **même camp** que le manager (un manager `PLAYER` ne touche que des hurtbox `ENEMY`, et inversement), ou un doublon.
   - Se désenregistre tout seul à `tree_exiting` de la hurtbox (connexion faite à l'enregistrement).
   - **Pourquoi un enregistrement et pas un parcours de groupe à chaque tick** : un `get_nodes_in_group()` alloue un tableau par tick. Les cibles sont peu nombreuses et connues de la salle qui les crée (`room.spawn_enemy`, epic 2) : c'est elle qui enregistre.
4. **Test de collision dans `_physics_process`**, **après** le déplacement du projectile et **avant** le test de mur (un tir qui touche une cible collée à un mur doit compter) :
   - une fois par tick, si au moins une cible est enregistrée, calculer le `Rect2` de chaque cible dans l'espace local du manager (`to_local`), dans un tableau réutilisé ; **si aucune cible n'est enregistrée, ne rien calculer** (coût nul pour le test de charge) ;
   - par projectile actif : test **cercle contre rectangle** (rayon = `_radii[i]`, point le plus proche du rectangle par `clampf`, distance² ≤ rayon²) contre chaque cible dans l'ordre d'enregistrement ; **un tir touche au plus une cible** (pas de traversée avant l'epic 5) ;
   - un tir qui touche est libéré (`_free(i)`) ; les dégâts sont **livrés après la boucle** (liste de touches réutilisée : cible, montant, direction), jamais pendant : un `receive()` qui libère sa cible ne doit pas modifier les tableaux en cours d'itération ;
   - la livraison : `hurtbox.receive(DamageInfo.from_bullet(amount, direction, DamageInfo.Source.PLAYER_SHOT))`, `direction` = `_velocities[i].normalized()` pris avant la libération.
5. **Aucune allocation par projectile et par tick** dans la boucle (les `DamageInfo` ne sont créés qu'aux touches). Aucun `Log.` dans la boucle.
6. Le graze et le dash parfait (P2) ne sont **pas** implémentés : un manager ennemi n'a pas de cible tant que la `Hurtbox` du joueur n'existe pas (2.1). Mais l'API est faite pour ce cas (le manager ennemi enregistrera la hurtbox du joueur).

### Retours d'impact et de tir (FR6, CA 5, 6, 9)

Trois pièces, petites, réutilisables :

- **`vfx/sprite_kick.gd`** : `class_name SpriteKick extends RefCounted`. Décale un `Node2D` (le sprite) de `direction * distance_px` pendant une durée, puis le remet à `Vector2.ZERO`. Compté en **ticks de jeu**.
  - `func _init(sprite: Node2D)` ; `func kick(direction: Vector2, distance_px: float, duration: float) -> void` (convertit la durée en ticks une fois ; rejoue = redémarre, sans cumuler les décalages) ; `func tick(clock_scale: float) -> void` (appelé par le propriétaire dans son `_physics_process`).
  - Le décalage s'écrit sur `sprite.position` (le joueur garde `_sprite.offset = Vector2.ZERO` et `modulate` libres pour le dash). Pas d'arrondi au pixel (le sprite se déplace déjà à des positions fractionnaires ; à juger à l'écran).
  - Une `direction` nulle ne décale pas.
- **`vfx/shaders/hit_flash.gdshader`** (chemin de l'architecture) : `shader_type canvas_item;` avec `uniform float flash : hint_range(0.0, 1.0) = 0.0;` ; blanc pur à `flash = 1` **en conservant l'alpha** de la texture, inchangé à `flash = 0`. `modulate` ne peut pas éclaircir au-delà du blanc : c'est la raison du shader. Attention à la sémantique de `COLOR` dans `fragment()` : vérifier **à l'écran** (capture) que `flash = 0` rend la texture à l'identique et `flash = 1` une silhouette blanche, avant de conclure.
- **`combat/hit_feedback.gd`** : `class_name HitFeedback extends Node`. Composant à poser sur toute entité qui encaisse un tir.
  - `func setup(sprite: Sprite2D, clock_group: GameClock.Group) -> void`, appelée **avant** `add_child()` : crée un `ShaderMaterial` **par instance** (jamais partagé) et l'affecte au sprite.
  - `func play(direction: Vector2) -> void` : flash blanc pendant `Tuning.SHOT.impact_flash_duration`, et `SpriteKick.kick(direction, impact_knockback_distance * TILE_SIZE, impact_knockback_duration)`. Rejouer pendant un retour en cours redémarre les deux.
  - `_physics_process` : lit `GameClock.scale(_clock_group)` **une fois** par tick, avance le flash et le `SpriteKick`.
  - Ne connaît **pas** `TrainingTarget` : c'est le propriétaire qui relie `hurtbox.damage_received` à `play(info.direction)`. La story 2.3 y branchera Le Somnambule (`GameClock.Group.ENEMIES`).
  - Pas de `Timer`. Aucun `Log.` par frame.

### `Aim` : la visée, sans scène (D6)

`class_name Aim extends RefCounted`, `game/player/aim.gd`. Logique pure : testable sans lancer le jeu, comme `PlayerMotor` et `Dash`.

```gdscript
enum Source { MOUSE, STICK }

var direction: Vector2 = Vector2.RIGHT   # unit, never zero: the last valid aim
var source: Source = Source.MOUSE

func update(origin: Vector2, mouse_world: Vector2, mouse_moved: bool, stick: Vector2) -> void
func is_stick_active() -> bool           # the stick was beyond the dead zone on the last update()
```

Règles de `update()` (un appel par tick physique) :

1. `stick != Vector2.ZERO` → `source = STICK`, `direction = stick.normalized()`, `is_stick_active() = true`.
2. Sinon, `is_stick_active() = false`, et si `mouse_moved` → `source = MOUSE`.
3. Si `source == MOUSE` : `to_cursor = mouse_world - origin` ; si `to_cursor.length_squared()` est supérieur à un epsilon (le curseur n'est pas sur le joueur), `direction = to_cursor.normalized()` ; sinon `direction` est **conservée**.
4. Si `source == STICK` et le stick est relâché : `direction` est conservée (RT tire dans la dernière direction visée : CA 2).
- `direction` n'est jamais nulle et toujours normalisée (`BulletManager.fire()` refuse une direction non normalisée).
- **Règle de bascule provisoire** (la vraie bascule de périphérique est la story 1.7, qui remplacera `source` par l'état du dernier périphérique) : le stick prend la main dès qu'il dépasse la zone morte ; la souris la reprend dès qu'elle **bouge** (position de viewport différente de celle du tick précédent). Une souris immobile après usage du stick n'écrase pas la visée au stick. À consigner.
- La visée souris suit le curseur **même si la souris ne bouge pas** mais que le joueur bouge (le curseur est fixe dans le monde, la direction change).

### `Shooter` : la cadence, sans scène (AR12, AR13)

`class_name Shooter extends RefCounted`, `game/player/shooter.gd`. Compté en ticks de jeu, comme `Dash`.

```gdscript
func _init(tuning: ShotTuning) -> void                                   # period_ticks = Engine.physics_ticks_per_second / fire_rate
func tick(clock_scale: float, wants_fire: bool, blocked: bool) -> bool   # true: emit one shot on this tick
```

- Période à 60 Hz : 60 / 4 = **15 ticks**. Ne pas coder 60.
- **Ordre dans `tick()`** : (1) `_cooldown_left = maxf(_cooldown_left - clock_scale, 0.0)` ; (2) si `clock_scale <= 0.0` (pause) → `false` ; (3) si `wants_fire and not blocked and _cooldown_left <= 0.0` → `_cooldown_left = _period_ticks`, renvoie `true` ; (4) sinon `false`.
- La recharge **continue pendant le dash** (`blocked`) : un joueur qui tient le tir pendant un dash tire dès le premier tick après la fin du dash si la recharge est écoulée (CA 4).
- La recharge court même sans tir demandé : cliquer plus vite que 4 fois par seconde ne dépasse jamais la cadence (CA 8). Un appui bref pendant la recharge est **perdu** (pas de tampon de tir : le tir est un état maintenu).
- Premier tir : au tick de l'appui (recharge initiale à 0).
- Pas de `Timer`, pas de RNG, aucun `Log.` par tick (hors le `Log.error` de réglage invalide, une fois, à la construction).
- `Lucidity` rendra la cadence dynamique (+30 % au palier Lucide) : hors périmètre ; ne pas préparer de modificateur.

### `Reticle` (CA 1)

`class_name Reticle extends Node2D`, `game/player/reticle.gd`. Dessin par `_draw()` : un petit **plus** de 4 branches de 3 px avec un trou central de 2 px, blanc à ≈ 0,85 d'opacité (constantes locales, visuel provisoire jusqu'à l'epic 7), `z_index` élevé (constante locale ; il passera dans la couche HUD avec la story 2.7).

- **Position** : `_process` (présentation, pas de gameplay) : en source `MOUSE`, `global_position = get_global_mouse_position()` ; en source `STICK`, `player.global_position + direction * STICK_RETICLE_DISTANCE` (constante locale, 4 tuiles, **visuel**, pas une portée de tir).
- **`physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF`** : il est déplacé dans `_process`, sans quoi il traîne derrière la souris. C'est le seul `_process` de la story qui lit une position d'entrée : exception tolérée, ajoutée à celle de `Main` pour F4/F5 (toute décision de gameplay reste dans `_physics_process`).
- Curseur système : `Input.mouse_mode = Input.MOUSE_MODE_HIDDEN` dans `_ready()` ; `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE` dans `_exit_tree()` (CA 11). Pas de `MOUSE_MODE_CONFINED` (ne pas enfermer le curseur). La pause (1.6) devra rendre le curseur visible : consigner dans `deferred-work.md`.
- `top_level = true` pour que sa position ne dépende pas de celle du joueur. Créé par `Player` dans `_ready()` (enfant du joueur) : `Reticle.setup(player)` **avant** `add_child()`.

### `Player` : brancher visée, tir et recul (FR5, FR6)

Dans `player/player.gd` (état après 1.4) :

- Champs : `_aim: Aim`, `_shooter: Shooter`, `_recoil: SpriteKick`, `_bullets: BulletManager`, `_shot_params: BulletParams`, `_last_mouse_pos: Vector2`. Dans `_ready()` : `_aim = Aim.new()`, `_shooter = Shooter.new(Tuning.SHOT)`, `_recoil = SpriteKick.new(_sprite)`, réticule.
- **`func equip_bullets(manager: BulletManager) -> void`** : appelée par `Arena._ready()` (le joueur est déjà prêt, voir « État actuel »). Garde `manager`, enregistre l'apparence **du tir du joueur** (`manager.add_appearance(_make_shot_texture())`) et construit **une fois** `_shot_params` depuis `Tuning.SHOT` : `speed = bullet_speed`, `radius = hitbox_size / 2.0`, `lifetime`, `damage`, `appearance`. `_shot_params` est un `BulletParams` à soi, jamais une Resource partagée. Avant l'équipement, **aucun tir ne part** : un seul `Log.error("combat", ...)` à la première tentative, puis silence (erreur de programmation, pas de spam par tick).
- Méthode publique : `aim_direction() -> Vector2` (la direction de visée courante : le réticule et les tests la lisent).
- **Un nouvel appel dans la boucle de 1.4**, juste après `_dash.tick(...)` et **avant** `velocity`/`move_and_slide()` :

```gdscript
	_dash.tick(clock_scale, Input.is_action_just_pressed(&"dash"), _facing)
	_update_shooting(clock_scale)         # new (story 1.5): sees "is the dash active this tick"
	if _dash.is_active():
		...
```

```gdscript
func _update_shooting(clock_scale: float) -> void:
	var stick: Vector2 = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var mouse_moved: bool = mouse_pos != _last_mouse_pos
	_last_mouse_pos = mouse_pos
	_aim.update(global_position, get_global_mouse_position(), mouse_moved, stick)
	var wants_fire: bool = Input.is_action_pressed(&"shoot") or _aim.is_stick_active()
	if _shooter.tick(clock_scale, wants_fire, _dash.is_active()):
		_fire()
	_recoil.tick(clock_scale)
```

  - Pourquoi **avant** le mouvement : `_dash.is_active()` y vaut « le dash est actif **ce tick** » ; après `finish_tick()` il serait déjà faux sur le dernier tick du dash et laisserait partir un tir pendant le dash (CA 4). Le tir part donc de la position du début de tick (≤ 1,6 px d'écart avec la position de fin de tick, imperceptible).
  - `wants_fire` : clic ou RT (`shoot`) **ou** stick incliné (tir automatique, CA 2). RT sans stick tire dans la dernière direction (`_aim.direction` conservée).
  - `get_global_mouse_position()` convertit la position de viewport (déjà en 640×360 avec le stretch `viewport`) en coordonnées du monde en tenant compte de la caméra : **ne pas recalculer l'échelle entière à la main**. Dans les barres noires (fenêtre non 16:9), la position sort de [0,640)×[0,360) : la visée reste valide, pas de repli à écrire.
- **`_fire()`** : `_bullets.fire(_shot_params, global_position, _aim.direction)` (l'origine est le **centre du torse**, la direction est exactement la visée) ; si `fire()` renvoie `true` : `_recoil.kick(-_aim.direction, Tuning.SHOT.recoil_distance * Const.TILE_SIZE, Tuning.SHOT.recoil_duration)` puis `Audio.play_sfx(SHOT_SOUND)`. Si `fire()` renvoie `false` (pool plein : compté dans `refused_count`), pas de recul ni de son.
  - Les tirs ne se **traversent pas le joueur** (aucune hurtbox joueur avant 2.1) : pas d'auto-touche à gérer.
  - Pas de `Log.` par tir.
- **Texture du tir** (`_make_shot_texture()`, provisoire) : image **4×4** (même taille que la hitbox : plus petite que les 8×8 des projectiles ennemis provisoires), disque plein, couleur `Const.COLOR_PLAYER_SHOT` à **alpha ≈ 0,7** (plus transparent que les projectiles ennemis, opaques). Ajouter à `Const` : `COLOR_PLAYER_SHOT` (un cyan clair, p. ex. `Color(0.55, 0.95, 1.0)`), avec le commentaire « couleur réservée aux tirs du joueur (NFR8) ; aucune autre entité ne l'utilise ; arrêtée définitivement par la story 7.2 ». Le rose du test de charge (`1.0, 0.35, 0.6`) reste la couleur ennemie provisoire.
- **Ordre de dessin** : le `BulletManager` du joueur est ajouté **après** le joueur dans l'arène : il est dessiné au-dessus de lui (couche « Combat », D13). Les projectiles ennemis passeront au-dessus de tout (epic 2).
- Ne pas toucher à `_update_dash_tint()` ni à `modulate` : le recul n'utilise que `position`.
- Aucune lecture d'entrée hors `_physics_process`, sauf `Reticle._process` (voir ci-dessus).

### Arène : le `BulletManager` du joueur et la cible d'entraînement

- **`arena.gd`** : après `_build_tiles()` (le `BulletManager` exige que `Walls` ait un `TileSet`), créer le manager **en code**, comme l'arène construit déjà ses tuiles :

```gdscript
const PLAYER_BULLET_CAPACITY: int = 128   # technical pool size (~11 shots in flight at 4/s over 36 tiles at 14 tiles/s)

var bullets: BulletManager = BulletManager.new()
bullets.camp = BulletManager.Camp.PLAYER
bullets.capacity = PLAYER_BULLET_CAPACITY
var solid_layers: Array[TileMapLayer] = [_walls]
bullets.setup(solid_layers)               # before add_child()
add_child(bullets)                        # last child: drawn above the player
_player.equip_bullets(bullets)
for target: TrainingTarget in _targets.get_children():   # typed loop; skip anything else
	bullets.register_hurtbox(target.hurtbox)
```

  Le manager est à l'origine de l'arène (position nulle), comme `Walls`. La capacité de 128 est **technique** (pas du gameplay).
- **`rooms/arena/arena.tscn`** : ajouter un `Node2D` `Targets` (`unique_name_in_owner`) **avant** `Player` dans l'ordre des enfants (les cibles sont dessinées sous le joueur), avec **3 instances** de `training_target.tscn` placées à des positions fixes : à droite `(464, 168)`, en haut à gauche `(144, 104)`, en bas à gauche `(144, 232)` (dans la zone jouable `[16, 592] × [16, 320]`, loin du joueur en `(304, 168)`). Ces positions servent aux tests ; les modifier n'a aucune conséquence.
- **`rooms/arena/training_target.gd` + `.tscn`** : `class_name TrainingTarget extends Node2D`. Un `Sprite2D` (`%Sprite`, texture générée en code, **16×24** comme le joueur, couleur orangée distincte du joueur et du tir, avec un liseré), une `Hurtbox` (`%Hurtbox`, `camp = ENEMY`, rectangle ≈ 12×20 px, un peu plus petit que le sprite, centré) et un `HitFeedback` créé dans `_ready()` (`setup(_sprite, GameClock.Group.ENEMIES)` puis `add_child()`). `hurtbox` est exposée (`@onready var hurtbox: Hurtbox = %Hurtbox`). `_ready()` relie `hurtbox.damage_received` à `_on_hurtbox_damage_received(info)` qui appelle `_feedback.play(info.direction)` et un `Log.debug("combat", "training target hit amount=%s")` (debug seulement ; un événement, pas une boucle par frame).
- La cible est **indestructible** et sans PV (`Health` : 2.1). Elle n'a **pas de corps physique** : le joueur et son dash la traversent (le dash « ne traverse pas les ennemis » : Epic 2). Documenter.
- Nommer les nœuds en `PascalCase`, fichiers en `snake_case` anglais.
- `Main` n'est pas modifié (l'arène est déjà chargée par `_show_scene`). F5 recrée l'arène : manager, cibles et réticule sont recréés ; le curseur est restauré par `Reticle._exit_tree()` (CA 11).

### Règles d'architecture qui s'appliquent

- GDScript typé partout (AR2) ; `snake_case` fichiers et dossiers, un script par classe, constantes `UPPER_SNAKE_CASE`, membres privés `_`, signaux au passé (`damage_received`), gestionnaires `_on_<émetteur>_<signal>`. Code, commentaires, logs et noms de fichiers **en anglais**.
- **Temps** (AR13) : compteurs manuels pilotés par `GameClock.scale(groupe)`. Pas de `Timer`, `create_timer`, `Engine.time_scale`. Joueur : `PLAYER` ; cibles : `ENEMIES` ; tirs du joueur : `PLAYER_BULLETS` (déjà dans `BulletManager`).
- **Entrées** (AR12) : actions `InputMap`, lues dans `_physics_process` (exception du réticule, voir plus haut).
- **Création** : tout tir passe par `BulletManager.fire()`. Jamais d'instanciation de scène par tir.
- **Données** (AR9) : aucune valeur de gameplay en dur ; `Tuning.SHOT` en lecture seule.
- **Dégâts** : toujours `DamageInfo` → `Hurtbox.receive()` (→ `Health.apply_damage()` en 2.1). Jamais d'appel direct à une méthode de la cible.
- **Aléatoire** : aucun (pas de dispersion, pas de critique : FR5).
- **Logs** (AR27) : `Log.<niveau>(catégorie, message)`, pas de `print()`, rien par frame ni par tir ni par son.
- **Erreurs** (AR28) : valeur sûre calculée avant `Log.error` et `assert` ; un tir refusé ne plante jamais.
- **Frontières** : `core/` ne dépend d'aucun dossier de fonctionnalité ; `player/` ne dépend que de `core/`, des autoloads, de `combat/` et de `vfx/` par leur API publique ; `combat/` ne dépend pas de `player/` ; rien ne dépend de `debug/` sauf `Main`.
- **Pas de signal sur `Events`** dans cette story (aucun consommateur transverse avant l'epic 2 et 3).

### Arborescence attendue à la fin de la story

```
game/
├── project.godot                           (UPDATE : aim_*, shoot)
├── default_bus_layout.tres                 (NEW)
├── autoloads/audio.gd                      (UPDATE : pool, play_sfx)
├── core/
│   ├── constants.gd                        (UPDATE : COLOR_PLAYER_SHOT)
│   ├── tuning.gd                           (UPDATE : SHOT)
│   └── shot_tuning.gd                      (NEW)
├── data/tuning/shot_tuning.tres            (NEW)
├── audio/sfx/sfx_player_shot.wav           (NEW, + .import)
├── combat/
│   ├── damage_info.gd                      (NEW)
│   ├── hurtbox.gd                          (NEW)
│   ├── hit_feedback.gd                     (NEW)
│   └── bullets/
│       ├── bullet_manager.gd               (UPDATE : dégâts, cibles)
│       └── bullet_params.gd                (UPDATE : damage)
├── vfx/
│   ├── sprite_kick.gd                      (NEW)
│   └── shaders/hit_flash.gdshader          (NEW)
├── player/
│   ├── player.gd                           (UPDATE : visée, tir, recul, equip_bullets)
│   ├── aim.gd                              (NEW)
│   ├── shooter.gd                          (NEW)
│   └── reticle.gd                          (NEW)
└── rooms/arena/
    ├── arena.gd / arena.tscn               (UPDATE : BulletManager joueur, Targets)
    └── training_target.gd / .tscn          (NEW)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (lexique, T1) et `deferred-work.md` (T14). Les `*.uid` et `*.import` se versionnent. Ne pas toucher à `main.gd`, `player_motor.gd`, `dash.gd`, `collision_drawer.gd`, ni aux scènes de `debug/`.

### Stratégie de test

Aucun framework de test (AR26 : avant le jalon B). Contrôles par scripts jetables du scratchpad (hors dépôt) lancés comme scène : `godot --headless --path game --scene <scène>`. Entrées simulées par `Input.action_press(&"shoot")` / `action_release`, et pour le stick `Input.parse_input_event(InputEventJoypadMotion)` (axes 2 et 3, comme 1.3).

1. **Import et lancement** : `godot --headless --path game --import`, puis `--quit-after 120`. Zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement. Le `.wav` est importé ; `project.godot` ne contient pas de bruit parasite.
2. **`Aim` seul** (sans scène) : souris à droite du joueur → `(1, 0)` ; au-dessus → `(0, -1)` ; en diagonale → normalisé ; curseur **sur** le joueur → direction **conservée** ; stick `(0, 0.5)` → `source = STICK`, `(0, 1)`, `is_stick_active()` ; stick relâché → direction conservée, `is_stick_active()` faux ; souris qui bouge après le stick → `source = MOUSE` ; souris immobile après le stick → reste `STICK` ; `direction` jamais nulle, longueur 1 ± 1e-6.
3. **`Shooter` seul** : tenu **60 ticks** à `clock_scale = 1` → **4 tirs** (aux ticks 0, 15, 30, 45) ; `blocked` pendant 30 ticks puis relâché → le tir part au premier tick non bloqué (recharge écoulée) ; `blocked` ne gèle pas la recharge ; clic tous les 5 ticks → **jamais plus de 4 tirs en 60 ticks** (CA 8) ; `clock_scale = 0` → aucun tir et la recharge ne bouge pas ; `0,25` → un tir toutes les 60 ticks réels ; `fire_rate = 0` dans une `ShotTuning` neuve → valeur sûre, pas de division par zéro, `Log.error` une fois ; `fire_rate = 8` → un tir tous les 7,5 ticks.
4. **Joueur et tir dans l'arène** (attendre un `physics_frame` après l'entrée de l'arène) :
   - **CA 3** : `shoot` tenu 60 ticks → 4 tirs, `bullets.active_count` correct ; un tir fait `224 px/s` (±1 %) ; à 8 directions de visée et à 2 angles quelconques (p. ex. 17° et 203°), l'écart angulaire entre la visée et la trajectoire mesurée est < 0,1° (tir **exact**, sans dispersion) ; il part de `player.global_position` ; il disparaît contre un mur sans portée maximale (le suivre jusqu'à `active_count == 0` : ~2 s pour 576 px à 224 px/s) ; son rayon vaut 2 px ; `damage = 10`.
   - **CA 3, réglage** : modifier temporairement `damage`, `fire_rate`, `bullet_speed` puis `hitbox_size` dans `shot_tuning.tres`, relancer, constater le changement ; **remettre les valeurs d'origine**.
   - **CA 4** : `shoot` tenu, puis dash : aucun tir pendant les ~11 ticks du dash (y compris le tick de départ et le dernier), tir dès le tick suivant la fin du dash si la recharge est écoulée.
   - **CA 2** : stick droit incliné à 0,5 vers le haut → `aim_direction()` `(0, -1)` et tir **sans** appui sur `shoot` ; stick incliné à 0,1 (sous la zone morte) → aucun tir ; stick relâché puis `shoot` seul (RT simulé) → tir dans la dernière direction.
   - **CA 7** : `GameClock.paused = true` → aucun tir, les tirs en vol se figent (position identique d'un tick à l'autre), reprise à `false` ; `global_multiplier = 0.25` → un tir toutes les 60 ticks, vitesse ÷ 4.
   - **CA 5** : après un tir, `_sprite.position` vaut ≈ `-direction * 1 px` pendant ~3 ticks (0,05 s à 60 Hz = 3 ticks) puis `Vector2.ZERO` ; **pas d'accumulation** après 20 tirs ; `Audio.play_sfx` appelé une fois par tir ; sans `equip_bullets`, aucun tir et **un seul** `Log.error`.
   - **Marche et dash non régressés** : sans `shoot`, comportement de 1.3 et 1.4 inchangé (96 px/s, dash de 48 px, murs à 19/589/19/317).
   - **Entrées** : `InputMap.action_get_events(&"shoot")` contient un `InputEventMouseButton` d'indice 1 et un `InputEventJoypadMotion` d'axe 5 ; `aim_*` contiennent chacune un `InputEventJoypadMotion` d'axe 2 ou 3 de la bonne valeur ; zones mortes 0,2 et 0,5.
5. **`Audio` et bus** : `AudioServer.get_bus_index` pour `Master`, `Music`, `SFX`, `UI` ≠ −1 ; `get_bus_send` des trois derniers = `Master` ; `play_sfx(stream, 2)` trois fois de suite sans attente → 2 jouées, 1 refusée, `dropped_count` = 1 ; un 4ᵉ son **différent** passe (limite par son, pas globale) ; 17 sons différents d'affilée → le 17ᵉ est refusé (pool de 16) ; flux `null` → `false` + `Log.error` ; sous headless, vérifier que le compteur de voix se vide quand les sons sont finis (sinon : le noter, vérifier en fenêtré).
6. **Cibles et dégâts** (CA 6) :
   - tir droit vers une cible : le tir est détruit au contact (`active_count` diminue), `damage_received` émis **une fois** avec `amount = 10`, `source = PLAYER_SHOT`, `direction` ≈ direction du tir ; la cible flashe (paramètre `flash = 1` pendant ~3 ticks puis 0) et son sprite recule de 2 px dans la direction du tir puis revient à zéro ;
   - un tir qui frôle le bord (cercle de 2 px à 1 px du bord) touche ; un tir à 3 px du bord passe ; **pas de traversée** : une cible de 12×20 et un tir à 3,73 px/tick ne sont jamais sautés (tester 200 tirs sur des décalages verticaux variés) ;
   - un tir ne touche qu'**une** cible quand deux sont alignées (la plus proche, dans l'ordre de l'enregistrement : documenter) ;
   - `register_hurtbox` d'une hurtbox de **même camp** → refus + `Log.error` ; doublon refusé ; une cible libérée (`queue_free`) se désenregistre toute seule, sans erreur au tir suivant ;
   - un manager **ennemi** sans cible : le test de charge F5 (400 projectiles) donne `Bullets 400 | refused 0` et un coût par tick comparable à 1.2 (≈ 67 µs, comparaison indicative, pas une régression visible).
7. **F2 / F3 / F4 / F5 (debug)** : F2 affiche le rectangle de la `Hurtbox` des cibles et le carré 6×6 du joueur ; F3 compte les tirs du joueur dans `Bullets` ; F4 ralentit les tirs et les retours ; F5 charge le test de charge puis revient à l'arène sans erreur, **et le curseur système est redevenu visible** pendant le test de charge (`Input.mouse_mode == MOUSE_MODE_VISIBLE`), puis caché au retour dans l'arène.
8. **Fenêtré sous WSLg** (indicatif) :
   - **Conversion souris → monde** : `get_viewport().warp_mouse(Vector2(...))` vers un point de viewport choisi pour tomber sur la cible de droite (monde `(464, 168)`) : **calculer sa position de viewport avec `get_canvas_transform() * Vector2(464, 168)`**, sans chiffre en dur ; `aim_direction()` pointe bien vers ce point ; le tir touche la cible visée ; refaire à ×2 (1280×720) et, si possible, à ×3 (redimensionner la fenêtre). En headless, tenter `Input.parse_input_event(InputEventMouseMotion)` : si la position de viewport n'est pas mise à jour, ne pas insister (tester cette partie en fenêtré seulement).
   - Le réticule suit le curseur sans traîner ; le tir est petit, clair et translucide à côté d'un projectile rose du test de charge (F5) ; le recul du joueur et le flash/recul de la cible se voient ; capture d'écran par `get_viewport().get_texture().get_image().save_png()` depuis un script du scratchpad (flash : la cible est blanche sur la capture prise au bon tick).
   - Netteté : si le sprite ou le tir vacillent, le consigner (ne pas activer `snap_2d_transforms_to_pixel` sans nécessité).
9. **Ressenti, étapes humaines** (à consigner, ne pas déclarer vérifié) : stick droit et RT sur une vraie manette ; cadence, recul de 1 px, flash et recul de 2 px à l'œil ; son provisoire ; réticule au stick ; zone morte de la gâchette. Reportés à 1.7 et 1.8 ; les consigner dans `deferred-work.md`.
10. **Recherche des interdits** : `grep -rnE 'print\(|Timer|create_timer|time_scale|randf|randi|randomize|shuffle|pick_random|/root/' game --include=*.gd` : seules les occurrences attendues (`log.gd`, commentaires). Aucun `Log.` dans `_physics_process`, `_process`, `tick()` ni dans les boucles de `bullet_manager.gd`.

### Commit

Directement sur `main`, Conventional Commits en anglais, un `git push` après chaque commit (consigne du projet). Exemples : `docs(architecture): add shot terms to the lexicon` ; `feat(audio): add sfx buses and voice-limited player pool` ; `feat(combat): add damage info, hurtbox and player bullet hits` ; `feat(player): add aim, fire rate, reticle and shot recoil` ; `docs(story): record story 1.5 implementation progress`. La story est grosse : **commiter par tâche cohérente**, chaque commit laissant le jeu lançable.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `combat/hurtbox.gd`, `combat/damage_info.gd`, `data/tuning/shot_tuning.tres`, `vfx/shaders/hit_flash.gdshader`, `audio/sfx/sfx_player_shot.wav`, `default_bus_layout.tres`, `player/` (`aim.gd`, `shooter.gd`, `reticle.gd`).
- **Écarts assumés** :
  - `ShotTuning` dans `core/` et non dans `player/` (même raison que `PlayerTuning` et `DashTuning`).
  - `Aim` et `Shooter` sont des `RefCounted` possédés par `Player` (testables sans scène, comme `PlayerMotor` et `Dash`), et non des nœuds composants.
  - `ShotTuning` porte aussi les valeurs du retour d'impact (`impact_*`) : le GDD les regroupe sous « Sensations ».
  - `DamageInfo` gagne un champ `direction` (le recul d'impact en a besoin).
  - `HitFeedback` et `SpriteKick` sont ajoutés (non listés dans l'architecture) pour que 1.5 et 2.3 partagent un seul retour d'impact.
  - `TrainingTarget` vit dans `rooms/arena/` (l'arène existe dans tous les builds, `debug/` ne peut pas être référencé par elle).
  - `Reticle` lit la position de la souris dans `_process` (présentation) : seule exception à « entrées dans `_physics_process` », avec F4/F5 de `Main`.
  - Le joueur reçoit son `BulletManager` par `equip_bullets()` après coup, et non par `setup()` avant `add_child()` (il est déjà prêt quand l'arène l'équipe).

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md` et de la mémoire du projet :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (aucun dans cette story).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.

### Décisions prises à la création de la story (modifiables)

1. **Bascule souris ↔ stick provisoire** : le stick prend la main au-delà de la zone morte, la souris la reprend quand elle bouge ; la vraie bascule est la story 1.7.
2. **Tir maintenu, pas de tampon** : la cadence court en continu ; un appui bref pendant la recharge est perdu. La recharge continue pendant le dash (le tir reprend au premier tick libre).
3. **Tir bloqué pendant le dash, évalué avant le mouvement** (`is_active()` vaut « actif ce tick »).
4. **Hitbox du tir : cercle de rayon 2 px** (4×4 → disque inscrit), test cercle contre rectangle comme l'architecture.
5. **Un tir touche au plus une cible** ; livraison des dégâts après la boucle.
6. **Cibles enregistrées par la salle**, pas découvertes par groupe à chaque tick.
7. **Retour d'impact** : flash par shader (blanc pur, alpha conservé) et recul **visuel** du sprite de 2 px sur 0,05 s (le GDD ne donne pas la durée du recul : même valeur que le flash).
8. **Cible d'entraînement** : 3 cibles indestructibles, sans corps physique, sous le joueur.
9. **Son provisoire généré par script** (`wav`, 0,06 s), remplacé par la story 7.7. Pas de variation de hauteur au hasard.
10. **Curseur système caché** par le réticule, rendu à la sortie de l'arène ; la pause (1.6) devra le rendre.
11. **Réticule au stick** à 4 tuiles du joueur dans la direction visée (visuel, pas une portée).
12. **Zone morte de `shoot` à 0,5** pour la gâchette (0,2 pour les sticks).

### Questions ouvertes (sans effet bloquant sur le code)

1. **Le recul de 2 px de la cible est-il visuel ou physique ?** Choix actuel : visuel (sprite seul). La story 2.3 pourra décider d'un vrai recul de l'ennemi.
2. **Tir à travers soi-même et à bout portant** : un tir émis dans une cible collée au joueur la touche au tick suivant, sans « zone morte » de départ. À juger au jeu.
3. **Réticule au stick** : utile ou parasite avec le tir automatique ? À juger sur une vraie manette.
4. **Sonorité du tir** : un son qui se répète 4 fois par seconde peut lasser ; la limite de voix par son est de 3, à ajuster à l'oreille.
5. **Docs Godot non consultées à la création de cette story** (pas de requête Context7 à ce stade) : à confirmer par le dev, avec `Context7` ou des essais, la sémantique de `COLOR` dans `fragment()` d'un shader `canvas_item`, le comportement de `Input.get_vector` avec la moyenne des zones mortes, et `Viewport.warp_mouse` sous `--headless`.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.5]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR5, FR6)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences non fonctionnelles] (NFR8, NFR9)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR6, AR9, AR12, AR13, AR21, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3] (« avec les retours d'impact de la Story 1.5 »)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Tir] (10 dégâts, 4 tirs/s, 14 tuiles/s, 4×4, portée illimitée, aucune dispersion)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Contrôles] (clic gauche, stick droit, RT)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Armes et tir] (sensations : recul 1 px 0,05 s, flash 0,05 s, recul 2 px)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Style visuel] (lisibilité : tirs du joueur plus petits, plus transparents, couleur réservée)
- [Source: _bmad-output/game-architecture.md#Projectiles (D1)] et [#Création d'entités]
- [Source: _bmad-output/game-architecture.md#Entrées et latence (D6)] (visée souris en coordonnées du monde, `aim_*`, `shoot`)
- [Source: _bmad-output/game-architecture.md#Audio (D15)] (bus, pool, limite de voix)
- [Source: _bmad-output/game-architecture.md#Dégâts et unités] (`DamageInfo` → `Hurtbox.receive()` → `Health.apply_damage()`)
- [Source: _bmad-output/game-architecture.md#Rendu (D13)] (couche Combat) et [#Temps (D7)]
- [Source: _bmad-output/game-architecture.md#Structure du projet] (arborescence, frontières, lexique)
- [Source: _bmad-output/implementation-artifacts/1-4-dasher.md] (`is_dashing()`, boucle de `Player`, `GameClock.global_multiplier`)
- [Source: _bmad-output/implementation-artifacts/1-3-se-deplacer-dans-l-arene.md] (Review Findings : échelle de temps appliquée une fois, valeur sûre avant `assert`)
- [Source: _bmad-output/implementation-artifacts/1-2-valider-400-projectiles-a-60-fps.md] (interface de `BulletManager`, limites de `fire()`)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (`CollisionDrawer` et hurtbox, manette réelle, F2 non interpolé)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-20).

### File List
