---
baseline_commit: 9426ef4
---

# Story 1.2 : Valider 400 projectiles à 60 FPS

Status: review

## Story

En tant que développeur,
je veux un `BulletManager` orienté données et une scène de test de charge à 400 projectiles,
afin de lever le risque n°1 (les performances de Godot) avant de bâtir le combat dessus.

**Exigences couvertes :** AR5, AR6 (camps ennemi et joueur ; hurtbox, graze et meubles hors périmètre, voir ci-dessous), AR31 (points 1 et 3), NFR1

## Critères d'acceptation

1. **Étant donné** un `BulletManager` par camp, enfant de la scène active, **quand** on appelle `fire(params, origin, direction)`, **alors** le projectile est rangé dans des tableaux compacts de taille fixe, avec une liste d'emplacements libres, sans aucun nœud par projectile.
2. Il est dessiné par un `MultiMeshInstance2D` par camp et par apparence.
3. Il avance selon `delta * GameClock.scale()` du groupe de son camp (`ENEMY_BULLETS` pour le camp ennemi, `PLAYER_BULLETS` pour le camp joueur).
4. Il disparaît en touchant une cellule des couches `Walls` ou `HighObstacles`, détectée par lecture de cellule du `TileMapLayer`.
5. **Étant donné** un pool plein, **quand** un nouveau tir est demandé, **alors** le tir est refusé sans erreur, et le refus est compté dans la surcouche F3, sans log par frame.
6. **Étant donné** un build de debug, **quand** on appuie sur F5, **alors** une scène de test entretient 400 projectiles ennemis en mouvement, et F3 affiche leur nombre.
7. **Étant donné** la machine de référence (classe GTX 1060, CPU 4 cœurs, 8 Go), **quand** le test de charge tourne 10 minutes, **alors** le jeu tient 60 FPS soutenus, avec un 1 % low d'au moins 55 FPS.
8. Le résultat de ce test, avec le moteur de rendu utilisé, est consigné dans la story. En cas d'échec, le repli retenu (boucle en GDExtension ou rendu Forward+) est décidé et consigné **avant** la story suivante.
9. **Étant donné** un écran à 144 Hz, **quand** les projectiles se déplacent, **alors** ils ne saccadent pas. Si c'est le cas, le `BulletManager` interpole lui-même leurs positions de rendu entre deux ticks.

## Tâches / sous-tâches

- [x] **T1. Paramètres de tir et constantes partagées** (CA 1, 5, 6)
  - [x] `game/combat/bullets/bullet_params.gd` : `class_name BulletParams extends Resource` (voir « `BulletParams` »).
  - [x] `Const` : ajouter `GROUP_BULLET_MANAGERS: StringName` (nom du groupe de nœuds que la surcouche F3 interroge).
  - [x] `project.godot` : action `InputMap` `debug_load_test` sur F5 (touche physique, `physical_keycode` 4194336), même forme que `debug_toggle_perf`.
- [x] **T2. `BulletManager` : stockage, `fire`, libération, pool** (CA 1, 5)
  - [x] `game/combat/bullets/bullet_manager.gd` : `class_name BulletManager extends Node2D`, avec l'enum `Camp { ENEMY, PLAYER }`.
  - [x] Tableaux parallèles de taille fixe (capacité exportée, 512 par défaut) et pile d'emplacements libres (voir « Stockage »).
  - [x] `fire(params, origin, direction) -> bool` : renvoie `false` sans erreur, sans log, et incrémente `refused_count` quand le pool est plein.
  - [x] `active_count` et `refused_count` en lecture publique ; le manager s'ajoute au groupe `Const.GROUP_BULLET_MANAGERS` dans `_ready()`.
- [x] **T3. Simulation** (CA 3, 4)
  - [x] `_physics_process(delta)` : lire `GameClock.scale(group)` **une fois par tick**, avancer chaque projectile actif de `vitesse * delta * échelle`, décrémenter sa durée de vie du même pas.
  - [x] `setup(solid_layers: Array[TileMapLayer])`, appelée **avant** `add_child()` : les couches `Walls` et `HighObstacles` contre lesquelles les projectiles disparaissent.
  - [x] Test de mur : un projectile actif dont la cellule existe dans une des couches (`get_cell_source_id(cell) != -1`) est libéré.
- [x] **T4. Rendu par `MultiMeshInstance2D`** (CA 2)
  - [x] `add_appearance(texture: Texture2D) -> int` crée un `MultiMeshInstance2D` pour cette apparence (voir « Rendu »).
  - [x] `_process` : écrire les transformations des projectiles actifs, par apparence, et ajuster `visible_instance_count`.
  - [x] Texture provisoire générée en code (disque de 8×8 px) pour la scène de test ; pas de fichier image dans cette story.
- [x] **T5. Compteurs dans F3** (CA 5, 6)
  - [x] `PerfOverlay` : seconde ligne `Bullets <actifs> | refused <refus>`, calculée à chaque rafraîchissement (2 Hz) en sommant les nœuds du groupe `Const.GROUP_BULLET_MANAGERS`. Aucune dépendance de `debug/` vers `combat/`.
  - [x] Agrandir le `Label` (`offset_bottom`) pour deux lignes ; le contour de la story 1.1 reste.
- [x] **T6. Scène de test de charge et touche F5** (CA 6)
  - [x] `game/debug/bullet_load_test.tscn` + `bullet_load_test.gd` (voir « Scène de test »).
  - [x] `Main` (debug seulement) : F5 bascule entre la mire de netteté et la scène de test, dans `ActiveScene`.
- [x] **T7. Vérifications headless** (CA 1 à 5)
  - [x] Script jetable dans le scratchpad (pas dans le dépôt) : voir « Stratégie de test ».
- [x] **T8. Vérifications fenêtrées sous WSLg** (CA 2, 6)
  - [x] F5 affiche 400 projectiles qui bougent et se renouvellent ; F3 affiche `Bullets ~400`.
  - [x] Consigner le FPS et le coût CPU de la simulation (rendu logiciel Mesa llvmpipe : indicatif seulement, pas la machine de référence).
- [x] **T9. Mesure sur la machine de référence, 10 minutes** (CA 7, 8) — **REPORTÉE, NON MESURÉE** (décision de Kroustille, 2026-11-20) : voir `deferred-work.md`
  - [x] Voir « Mesure sur la machine de référence ». Consigner dans les Completion Notes : machine, moteur de rendu (Compatibility), FPS moyen, 1 % low, durée. *(reporté)*
  - [x] En cas d'échec : décider et consigner le repli (GDExtension ou Forward+) avant la story 1.3. *(reporté)*
- [x] **T10. Fluidité à 144 Hz** (CA 9) — **REPORTÉE, NON VÉRIFIÉE** (décision de Kroustille, 2026-11-20) : voir `deferred-work.md`
  - [x] Observer sur un écran 144 Hz. Si les projectiles saccadent, ajouter l'interpolation des positions de rendu entre deux ticks dans `BulletManager`. *(reporté)*
  - [x] Si aucun écran 144 Hz n'est disponible : consigner « non vérifié » et le reporter à la story 1.8 (`deferred-work.md`). *(reporté)*
- [x] **T11. Régression** : import et lancement headless sans erreur, recherche des interdits (voir « Stratégie de test »), mire de netteté et F3 de la story 1.1 toujours conformes.

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

C'est un **prototype de risque** : le but est un chiffre (FPS soutenus à 400 projectiles), pas le système de combat. Ne rien construire qui ne serve pas ce chiffre ou les neuf critères ci-dessus.

**Hors périmètre** (stories suivantes ; ne pas anticiper) :

| Élément | Story |
|---|---|
| Collision projectile ↔ hurtbox du joueur, graze, drapeau `counted` actif, `Events.player_grazed` | 2.1 et suivantes (le drapeau `counted` existe dans le stockage mais n'est pas utilisé ici) |
| Collision avec les meubles | 1.3 ou ultérieure (les meubles n'existent pas encore) |
| Collision projectile joueur ↔ hurtbox ennemies | 1.5 / 2.x |
| Arène réelle, `TileMapLayer` définitifs `Walls` et `HighObstacles`, joueur | 1.3 |
| Tir du joueur, `ShotTuning`, cadence | 1.5 |
| `BulletPattern`, motifs d'ennemis, `DangerProfile` | 2.x |
| Effets d'objets (traversée, tir arrière, taille) via `BulletParams` | 5.x : ne prévoir **aucun** champ spéculatif dans `BulletParams` |
| Couche de rendu isolée du shader de distorsion (D13) | Epic 3 ou 7 |
| Sprites définitifs des projectiles (`bullet_sprites/`) | 7.x |
| Ralenti F4, hitstop (API d'écriture de `GameClock`) | 1.4 |
| Pause effective, menu | 1.6 |
| Export Windows et macOS | 1.8 |

### Ce qu'il faut savoir de l'état actuel du dépôt (story 1.1, `done`)

- Existent : `game/autoloads/{log,events,game_clock,settings,save_service,audio}.gd`, `game/core/{constants,tuning}.gd`, `game/main/main.{gd,tscn}`, `game/debug/{perf_overlay,scale_test_pattern}.{gd,tscn}`. **Aucun** dossier `combat/` : il est créé ici.
- `Main` (`class_name Main`) : racine `Node`, enfants `ActiveScene` (`%ActiveScene`) et `UI` (`CanvasLayer`, contient `PerfOverlay`). En debug seulement, il instancie `res://debug/scale_test_pattern.tscn` sous `ActiveScene`, fixe `Window.min_size = Const.VIEWPORT` et vérifie la cohérence `Const` ↔ `project.godot`.
- `GameClock` (autoload) : `enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }`, `scale(group) -> float` (1,0 par défaut, 0,0 si `paused`), `paused`. **Aucune API pour modifier les échelles** : ne pas en ajouter ici (story 1.4).
- `Log` : `Log.info(category, message)` etc. Catégories valides (`assert` en debug) : `run`, `room`, `combat`, `lucidity`, `items`, `gen`, `save`, `input`, `audio`, `ui`. Pour cette story : `combat`.
- `PerfOverlay` : texte en un `Label` (`%Label`), rafraîchi à 2 Hz par `_refresh_text()` ; le delta est mesuré par `Time.get_ticks_usec()` ; le tampon est remis à zéro à l'affichage. Les textes sont des relevés techniques : exemption de `tr()` limitée à `debug/` (voir le commentaire de tête).
- Couches de collision 2D nommées (1 à 10) : `walls`, `high_obstacles`, … Les couches de **physique** ne servent pas ici : les projectiles ne passent pas par `PhysicsServer2D`. Ce qui compte, ce sont les **cellules** des `TileMapLayer`.
- Le rendu est **Compatibility** (`gl_compatibility`), filtre de texture `Nearest`, physique à **60 Hz**.
- Environnement : Godot 4.7.2 stable via WSLg, binaire `godot` dans le `PATH`. Le rendu WSLg passe par Mesa llvmpipe (rendu logiciel, VSync non supporté, ~270 FPS sur la mire) : **les FPS mesurés ici ne représentent pas la machine de référence**.

### Leçons de la story 1.1 à appliquer

- **Typage strict, avertissements en erreur** : `untyped_declaration`, `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast`, `unsafe_call_argument` sont à 2. Un `int(variant)` sur un `Variant` est refusé ; passer par une variable typée (`var x: int = dict.get("clé", 0)`). Les divisions entières appellent `@warning_ignore("integer_division")` quand elles sont voulues.
- **Aucun log dans une boucle par frame** : seuls les compteurs de la surcouche F3 portent les données de projectiles. Un seul `Log.info("combat", ...)` au lancement de la scène de test.
- Les fichiers `*.uid` générés par Godot se versionnent.
- Le calcul du facteur d'échelle est centralisé dans `Const.integer_scale()` : ne pas le recopier.
- **Vérifications** : `godot --headless --path game --import`, puis `godot --headless --path game --quit-after <n>`. Zéro `SCRIPT ERROR`, zéro `Parse Error`. Les scripts jetables vont dans le scratchpad, pas dans le dépôt.
- Reports de la revue de 1.1 qui touchent cette story : `GameClock.paused` est indépendant de `SceneTree.paused` (à trancher en 1.6) ; la couverture release de F3 est vérifiée en 1.8.

### `BulletParams`

`class_name BulletParams extends Resource`, dans `game/combat/bullets/bullet_params.gd`. Champs, avec distances en **tuiles** et durées en **secondes** (AR9), convertis en pixels **à un seul endroit** (`BulletManager.fire`, avec `Const.TILE_SIZE`) :

| Champ | Type | Sens | Valeur du test |
|---|---|---|---|
| `speed` | `float` | tuiles par seconde | ~5,5 (≈ 90 px/s) |
| `radius` | `float` | rayon en tuiles (réservé aux collisions des stories suivantes ; stocké dans `_radii`) | 0,25 |
| `lifetime` | `float` | secondes avant disparition | 8,0 |
| `appearance` | `int` | indice renvoyé par `add_appearance()` | 0 |

Pas d'autres champs : les effets d'objets viendront en 5.x, sans changer la boucle (D1).

### Stockage (AR6, ADR-001)

Tableaux parallèles, tous de la même taille fixe `capacity` (pré-alloués dans `_ready()` ou `setup`, jamais redimensionnés ensuite) :

```gdscript
var _positions: PackedVector2Array
var _velocities: PackedVector2Array      # px par seconde
var _radii: PackedFloat32Array           # px
var _lifetimes: PackedFloat32Array       # secondes restantes
var _flags: PackedByteArray              # bit 0 : actif ; bit 1 : counted (réservé)
var _appearances: PackedByteArray        # indice d'apparence
var _free_slots: PackedInt32Array        # pile d'emplacements libres
var _free_top: int                       # nombre d'emplacements libres
var _high_water: int                     # 1 + plus grand indice jamais utilisé : borne des boucles
```

- `fire` : si `_free_top == 0` → `refused_count += 1`, `return false`. Sinon dépiler un emplacement, écrire les neuf champs, marquer actif, `active_count += 1`, `return true`. `direction` est normalisée par l'appelant ; en debug, `assert` sur sa norme et sur `params != null` (AR28), jamais d'arrêt en release.
- Libération : effacer le bit actif, empiler l'emplacement, `active_count -= 1`.
- **Aucun nœud, aucun `Resource` ni `Dictionary` par projectile.** Aucune allocation dans la boucle de simulation.
- Une boucle sur `0.._high_water` qui saute les emplacements inactifs suffit à 512 emplacements ; ne pas ajouter de liste d'actifs.

### Simulation (CA 3, 4)

```gdscript
func _physics_process(delta: float) -> void:
	var step: float = delta * GameClock.scale(_clock_group)   # une seule lecture par tick
	if step <= 0.0:
		return
	for i: int in _high_water:
		if _flags[i] & FLAG_ACTIVE == 0:
			continue
		_positions[i] += _velocities[i] * step
		_lifetimes[i] -= step
		if _lifetimes[i] <= 0.0 or _hits_solid(_positions[i]):
			_free(i)
```

- `_clock_group` : `GameClock.Group.ENEMY_BULLETS` pour `Camp.ENEMY`, `PLAYER_BULLETS` pour `Camp.PLAYER`.
- `_hits_solid(pos)` : pour chaque couche de `_solid_layers`, `layer.get_cell_source_id(layer.local_to_map(pos)) != -1`. Les couches doivent avoir la **même origine** que le `BulletManager` (frères sous la même scène, position nulle) : `setup()` le vérifie par `assert`. Test du centre du projectile seulement (le rayon n'entre pas dans le test de mur).
- **Pas de traversée de mur** : à 5,5 tuiles/s et 60 Hz, un pas fait ~1,5 px pour des tuiles de 16 px. `assert` en debug que `speed * delta` reste inférieur à `Const.TILE_SIZE`.
- Pas de `Timer`, pas de `create_timer`, pas de `Engine.time_scale`, pas de RNG global (AR13, AR14).
- Si les tableaux sont lus en `Packed*Array` par indice, c'est déjà la forme la plus rapide en GDScript : n'optimiser (GDExtension) **que** si la mesure de T9 échoue.

### Rendu (CA 2)

- Un `MultiMeshInstance2D` par camp et par apparence, **enfant du `BulletManager`**. Un manager par camp donne donc « par camp » ; `add_appearance()` donne « par apparence ».
- Création d'un `MultiMesh` : **`transform_format = MultiMesh.TRANSFORM_2D` avant `instance_count`** (Godot refuse de changer le format quand le nombre d'instances n'est pas nul), `mesh = QuadMesh` de la taille de la texture, `instance_count = capacity`, `visible_instance_count = 0`. La texture se pose sur le `MultiMeshInstance2D` (`texture`).
- Mise à jour dans `_process` (une fois par image affichée) : parcourir les emplacements actifs, écrire `Transform2D(0.0, position)` pour l'apparence du projectile avec `multimesh.set_instance_transform_2d(index, transform)`, puis `visible_instance_count = n`. Commencer par cette API : 400 appels par image sont modestes. N'utiliser `MultiMesh.buffer` (écriture en bloc d'un `PackedFloat32Array`) **que** si le profilage montre que c'est le goulot ; sa disposition pour les transformations 2D est de 8 flottants par instance, à vérifier dans la doc 4.7 avant usage.
- Pas de couleur par instance, pas de données personnalisées : inutile ici.
- Positions de rendu : en coordonnées locales du manager (le manager est à l'origine de la scène). L'interpolation entre deux ticks (CA 9) n'est ajoutée qu'en T10, si nécessaire, avec `Engine.get_physics_interpolation_fraction()` et un tableau des positions du tick précédent.

### Compteurs et surcouche F3 (CA 5, 6)

- `BulletManager` : `var active_count: int` et `var refused_count: int`, lisibles de l'extérieur ; s'ajoute au groupe `Const.GROUP_BULLET_MANAGERS` dans `_ready()`.
- `PerfOverlay._refresh_text()` somme `active_count` et `refused_count` de `get_tree().get_nodes_in_group(Const.GROUP_BULLET_MANAGERS)`, une fois par rafraîchissement (2 Hz, jamais par frame). Typage : le groupe renvoie des `Node` ; caster chaque nœud avec `as BulletManager` et ignorer les `null`. Format de la seconde ligne : `Bullets %d | refused %d`.
- Le `Label` s'étend sur deux lignes : relever `offset_bottom` en conséquence (une ligne de 16 px ≈ 18 px de haut dans le viewport 640×360).

### Scène de test (CA 6)

`game/debug/bullet_load_test.tscn` (racine `BulletLoadTest`, `Node2D`) + `bullet_load_test.gd`, instanciée par `Main` sous `ActiveScene` en **debug seulement**.

- **Murs de test** : un `TileMapLayer` nommé `Walls` construit **en code** dans `_ready()` : `TileSet` (`tile_size = Vector2i(Const.TILE_SIZE, Const.TILE_SIZE)`) avec une seule `TileSetAtlasSource` dont la texture est une image générée, une tuile à `(0, 0)`, et un cadre de cellules autour du viewport 640×360 (40×22,5 tuiles : prendre 40×22 et laisser le reste libre). Il sert de modèle à l'arène de la story 1.3, qui le remplacera ; ne pas le généraliser.
- **Gestionnaire** : un `BulletManager` (camp `ENEMY`, capacité 512) ajouté **après** `setup([walls])`.
- **Émetteurs** : quelques points fixes (4 à 6), au centre et sur les côtés. À chaque tick de `_physics_process`, tant que `active_count < TARGET_COUNT` (400, constante locale), tirer depuis un émetteur dans une direction déterministe (angle = compteur × angle d'or, 2,39996 rad) : **pas de `randf`**. Les projectiles meurent aux murs ou par durée de vie ; le spawner maintient donc ~400 projectiles en permanence, ce qui exerce `fire`, la libération et le test de mur.
- Un `Log.info("combat", "bullet load test started target=400")` au démarrage ; rien d'autre.
- `Main` : action `debug_load_test` (F5), `OS.is_debug_build()` seulement. F5 vide `ActiveScene` de son contenu courant et y place la scène de test ; F5 à nouveau remet la mire de netteté. Ne pas dupliquer le code de `_spawn_scale_test_pattern` : en tirer une méthode commune qui prend le chemin de la scène.
- La scène de test et son script restent dans `debug/` : 1.8 les exclura de l'export (la surcouche F3, elle, reste).

### Mesure sur la machine de référence (CA 7, 8)

- **Machine de référence :** classe GTX 1060, CPU 4 cœurs, 8 Go. WSLg (rendu logiciel) **ne la représente pas**.
- **Protocole :** F5, F3 visible, 10 minutes, en fenêtre 1280×720 ou plein écran 1080p, VSync activée si disponible. Relever à la fin : FPS (affiché), 1 % low (affiché), `Bullets` (~400) et `refused` (doit rester 0). Une capture de la surcouche à la fin suffit comme preuve.
- **Comment la lancer :** soit un Godot 4.7.2 Windows (version standard) qui ouvre le dossier `game/` du dépôt (par exemple via `\\wsl$\...`), soit un export Windows. L'export officiel est la story 1.8 ; ne pas le construire ici. À défaut de machine de référence disponible, **ne pas déclarer le CA 7 vérifié** : le consigner « non mesuré » et laisser la story ouverte sur ce point (voir « Questions ouvertes »).
- **Seuils :** 60 FPS soutenus, 1 % low ≥ 55. Le 1 % low se lit après les premières secondes (le tampon de F3 est remis à zéro à chaque affichage).
- **Repli** (CA 8) si le seuil n'est pas tenu : (a) profiler d'abord (la simulation ? le rendu ? les deux ?), (b) porter la boucle de `_physics_process` en GDExtension sans changer l'interface (D1), ou (c) passer en Forward+. Choisir, consigner la décision et ses chiffres dans les Completion Notes **et** dans `game-architecture.md` (D1, Versions) avant de créer la story 1.3.

### Règles d'architecture qui s'appliquent

- **GDScript typé statiquement partout** (AR2). Nommage : `snake_case` pour fichiers et dossiers, un script par classe (`class_name BulletManager` → `bullet_manager.gd`), constantes en `UPPER_SNAKE_CASE`, membres privés préfixés `_`, gestionnaires `_on_<émetteur>_<signal>`.
- **Code, commentaires, logs et noms de fichiers en anglais.**
- **Création** : tout projectile passe par `BulletManager.fire(params, origin, direction)`, jamais d'instanciation de scène. Les pools ne concernent que les projectiles et les effets d'impact.
- **Injection** : `setup()` est appelée **avant** `add_child()` ; les dépendances internes à une scène passent par `@export` ou `%NomUnique`.
- **Frontières** : `combat/` ne dépend que de `core/` et des autoloads. Rien ne dépend de `debug/` sauf `Main`. La surcouche F3 (dans `debug/`) lit les managers par le **groupe de nœuds**, pas par un chemin ni par un import de `combat/`.
- **Erreurs** (AR28) : `assert` + `Log.error` pour un invariant violé (projectile sans paramètres, direction non normalisée) ; un pool plein n'est **pas** une erreur.
- **Temps** (AR13) : `delta * GameClock.scale(group)`. Pas de `Timer`.
- **Pas de chemins `/root/...`, pas de `get_parent().get_parent()`.**

### Arborescence attendue à la fin de la story

```
game/
├── project.godot                       (UPDATE : action debug_load_test sur F5)
├── core/constants.gd                   (UPDATE : GROUP_BULLET_MANAGERS)
├── combat/                             (NEW)
│   └── bullets/                        (NEW)
│       ├── bullet_manager.gd           (NEW)
│       └── bullet_params.gd            (NEW)
├── main/main.gd                        (UPDATE : F5, méthode commune de bascule de scène de debug)
└── debug/
    ├── perf_overlay.gd / .tscn         (UPDATE : seconde ligne, compteurs)
    ├── bullet_load_test.gd / .tscn     (NEW)
    └── scale_test_pattern.*            (inchangé)
```

Fichiers `*.uid` à versionner. Ne pas créer d'autres dossiers (`bullet_pattern.gd`, `bullet_sprites/`… viendront avec leurs stories).

### Stratégie de test

Aucun framework de test n'est choisi (AR26 : avant le jalon B). Les vérifications sont des commandes et des contrôles manuels, consignés dans les Completion Notes.

1. **Import et analyse headless :** `godot --headless --path game --import`, puis `godot --headless --path game --quit-after 60`. Zéro `SCRIPT ERROR`.
2. **Script jetable headless** (dans le scratchpad, lancé avec `godot --headless --path game --script <fichier>`), qui vérifie :
   - **CA 1** : après `fire` jusqu'à saturation, `active_count == capacity` ; aucun nœud enfant par projectile (`get_child_count()` constant).
   - **CA 5** : le tir suivant renvoie `false`, `refused_count` augmente, aucune sortie de log.
   - **CA 3** : après N ticks simulés, un projectile a avancé de `vitesse × N × delta` à `scale = 1`, et **n'a pas bougé** avec `GameClock.paused = true`.
   - **CA 4** : un projectile tiré vers un mur disparaît ; `active_count` diminue ; le pool est ré-utilisable (tirer à nouveau réussit).
   - **Durée de vie** : un projectile disparaît après `lifetime`.
   - **Fuite** : 100 000 tirs/libérations de suite, `active_count` revient à 0, `_free_top == capacity`.
   - **Coût CPU** : durée moyenne de `_physics_process` avec 400 projectiles actifs (`Time.get_ticks_usec()` autour de l'appel, 1 000 ticks). Consigner la valeur ; à 60 Hz le tick dispose de 16 667 µs, la simulation doit en prendre une petite fraction.
3. **Fenêtré (WSLg) :** F5 affiche la scène de test ; F3 montre `Bullets` autour de 400 et `refused 0` ; les projectiles disparaissent aux murs ; F5 à nouveau revient à la mire.
4. **Mesure de référence (T9) et 144 Hz (T10)** : étapes humaines, voir plus haut.
5. **Recherche des interdits :** `grep -rnE 'print\(|Timer|create_timer|time_scale|randf|randi|randomize|shuffle|pick_random' game --include=*.gd`. Seul le `print(` de `log.gd` est attendu (plus ses commentaires). Aucun `Log.` dans les boucles par frame de `bullet_manager.gd`.

### Commit

Commits directement sur `main`, Conventional Commits en anglais. Par exemple `feat(combat): add data-oriented bullet manager and load test` pour le code ; les mesures de T9 et le repli éventuel dans un commit `docs(story): record bullet load test results` (ou `docs(architecture): record bullet manager fallback decision`).

### Project Structure Notes

- Conforme à l'arborescence de l'architecture (`combat/bullets/` : `bullet_manager.gd`, `bullet_params.gd`).
- **Écarts assumés :**
  - `debug/bullet_load_test.*` n'est pas dans l'arborescence : outil de debug de l'architecture (touche F5), dans `debug/` comme la mire.
  - Le `TileMapLayer` de test est construit en code ; l'arène réelle de la story 1.3 le remplace.
  - Le groupe de nœuds `Const.GROUP_BULLET_MANAGERS` est une façon de découpler la surcouche F3 de `combat/` ; elle n'est pas dans la liste des patterns de l'architecture (elle n'invente pas de signal ni d'autoload).

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md` et de la mémoire du projet :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits, directement sur `main`, sans branche.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (exemption limitée à `debug/`).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.

### Questions ouvertes (sans effet bloquant sur le code)

1. **Machine de référence pour T9 :** disposez-vous d'une machine Windows de classe GTX 1060 (ou mieux, pour borner par le haut) et d'un Godot 4.7.2 Windows pour ouvrir `game/`, ou faut-il avancer l'export Windows de la story 1.8 ? Recommandation : un Godot Windows ouvert sur le dépôt, sans attendre 1.8.
2. **Écran 144 Hz pour T10 :** disponible ? Sinon, le CA 9 est reporté à 1.8.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.2]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR5, AR6, AR9, AR13, AR31)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences non fonctionnelles] (NFR1)
- [Source: _bmad-output/game-architecture.md#Projectiles (D1)]
- [Source: _bmad-output/game-architecture.md#ADR-001 : projectiles hors de l'arbre de scène]
- [Source: _bmad-output/game-architecture.md#Outils de debug] (F3, F5)
- [Source: _bmad-output/game-architecture.md#Logs] (aucun log par frame)
- [Source: _bmad-output/game-architecture.md#Création d'entités] (`fire`, injection par `setup()`)
- [Source: _bmad-output/game-architecture.md#Structure du projet] (`combat/bullets/`)
- [Source: _bmad-output/game-architecture.md#Points à vérifier] (interpolation à 144 Hz)
- [Source: _bmad-output/implementation-artifacts/1-1-lancer-le-jeu-dans-une-fenetre-nette-a-toutes-les-resolutions.md] (Review Findings, Completion Notes)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md]
- [Externe : docs Godot 4.7, `MultiMesh` (`transform_format`, `set_instance_transform_2d`, `visible_instance_count`, `buffer`) ; `TileMapLayer` (`local_to_map`, `get_cell_source_id`, renvoie -1 si la cellule n'existe pas), via Context7]

## Dev Agent Record

### Agent Model Used

claude-sonnet-5-5

### Debug Log References

- `godot --headless --path game --import`, puis `--quit-after`: aucune erreur de script.
- Les scripts jetables vivent dans le scratchpad (hors dépôt). `--script` ne résout pas les autoloads à la compilation (`Identifier not found: Log`) : les vérifications tournent donc comme une **scène** (`godot --headless --path game --scene <scène du scratchpad>`), avec `call_deferred` pour attendre que la racine soit prête.
- Vérification du pool, des murs, de la pause, de la durée de vie et des fuites : 12 contrôles PASS, 0 échec (CA 1, 3, 4, 5).
- F5 et F3 simulés par des `InputEventAction` en headless : `Bullets 400 | refused 0`, la scène de test remplace la mire, un second F5 la remet.
- Coût CPU mesuré en headless (rendu factice), 400 projectiles actifs et une couche de murs : **~68 µs par tick** de simulation et **~74 µs par image** de mise à jour du rendu, pour un budget de 16 667 µs par tick à 60 Hz.
- Fenêtré sous WSLg (Mesa llvmpipe, rendu logiciel, VSync non supporté), 1280×720 (×2), F5 actif pendant ~18 s : **~267 FPS**, 1 % low ~230, `Bullets` 394 à 399 avant le correctif d'ordre de tick, puis 400 exact, `refused 0`. **Indicatif seulement : ce n'est pas la machine de référence.**

### Implementation Plan

- `BulletManager` : tableaux parallèles `Packed*Array`, pile d'emplacements libres, `_high_water` comme borne de boucle, aucun nœud ni objet par projectile. Simulation dans `_physics_process` (une lecture de `GameClock.scale()` par tick), rendu dans `_process` par `MultiMesh.set_instance_transform_2d()` (le `buffer` en bloc n'a pas été nécessaire).
- Compteurs lus par la surcouche F3 via le groupe `Const.GROUP_BULLET_MANAGERS`, à 2 Hz.
- Scène de test : murs en code, quatre émetteurs, angle d'or (pas de RNG), 8 tirs maximum par tick jusqu'à 400 ; `process_physics_priority = 1` pour que le compte lu après un tick soit celui après recharge.

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-20).
- **T1 à T8 et T11 faits (2026-11-20).** `BulletParams`, `BulletManager` (pool, `fire`, murs par cellule de `TileMapLayer`, pause via `GameClock`, rendu `MultiMeshInstance2D`), compteurs dans F3, scène F5 à 400 projectiles. Aucun appel interdit (`grep` : seuls les occurrences attendues dans `log.gd` et des commentaires).
- **Écart assumé avec la story :** la surcouche F3 caste les nœuds du groupe en `BulletManager` (dépendance de `debug/` vers `combat/`) au lieu de lire des propriétés sans type. La règle d'architecture interdit que du code dépende de `debug/`, pas l'inverse ; le groupe évite seulement un chemin de nœud.
- **`Log.error` dans `fire()`** : uniquement pour un `BulletParams` invalide (invariant violé, jamais en jeu normal), pas dans la boucle.
- **Pas de framework de test** (AR26) : les contrôles sont des scripts jetables, non versionnés.
- **Reste à faire, étapes humaines :**
  - **T9** (CA 7 et 8) : 10 minutes sur la machine de référence (classe GTX 1060). Le rendu WSLg ne la représente pas. Résultat et moteur de rendu à consigner ici ; en cas d'échec, décider du repli (GDExtension ou Forward+) avant la story 1.3.
  - **T10** (CA 9) : fluidité à 144 Hz. Aucune interpolation n'est codée : à ajouter seulement si ça saccade.
- **T9 et T10 reportées (décision de Kroustille, 2026-11-20) :** la mesure de 10 minutes sur machine de référence et le contrôle à 144 Hz ne seront pas faits maintenant. **Les CA 7, 8 et 9 ne sont donc PAS vérifiés.** Le risque n°1 (NFR1) reste ouvert : seules des mesures indicatives existent (~68 µs de simulation par tick pour 400 projectiles, ~267 FPS sous llvmpipe). À faire avant de s'appuyer sur le combat (au plus tard avec l'export de la story 1.8) ; en cas d'échec, décider du repli (GDExtension ou Forward+).

### File List

- `game/combat/bullets/bullet_params.gd` (nouveau, + `.uid`)
- `game/combat/bullets/bullet_manager.gd` (nouveau, + `.uid`)
- `game/debug/bullet_load_test.gd`, `bullet_load_test.tscn` (nouveaux, + `.uid`)
- `game/debug/perf_overlay.gd`, `perf_overlay.tscn` (modifiés : ligne `Bullets | refused`)
- `game/main/main.gd` (modifié : F5, `_show_debug_scene`)
- `game/core/constants.gd` (modifié : `GROUP_BULLET_MANAGERS`)
- `game/project.godot` (modifié : action `debug_load_test`)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modifié)

### Change Log

- 2026-11-20 : `BulletManager` orienté données, scène de test de charge (F5) et compteurs dans F3. T9 (mesure sur machine de référence) et T10 (144 Hz) reportées, voir `deferred-work.md`. Statut `review`.
