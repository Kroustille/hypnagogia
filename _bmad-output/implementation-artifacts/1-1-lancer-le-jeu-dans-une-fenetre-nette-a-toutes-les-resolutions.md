---
baseline_commit: b5111df07cd21f1a7930fe3d305a6b522938b398
---

# Story 1.1 : Lancer le jeu dans une fenêtre nette à toutes les résolutions

Status: done

## Story

En tant que développeur,
je veux un projet Godot 4.7.2 initialisé avec son socle (réglages, autoloads, constantes, journal, surcouche de performances),
afin que chaque story suivante parte de fondations conformes à l'architecture.

**Exigences couvertes :** AR1, AR2, AR3, AR4 (sans `RunRng`), AR13, AR24 (F3 seulement), AR27, AR28, NFR7

## Critères d'acceptation

1. **Étant donné** un dépôt sans projet Godot, **quand** le projet est créé dans `game/`, **alors** les réglages effectifs du projet sont : viewport 640×360, stretch `viewport` + `keep` + `integer`, HiDPI autorisé, rendu `gl_compatibility`, filtre de texture `Nearest`, physique à 60 Hz (voir « Piège : valeurs par défaut non écrites »).
2. Les couches de collision 2D sont nommées dans les réglages du projet, et `Const` les référence par des constantes nommées, jamais par des nombres.
3. Les avertissements de typage GDScript sont traités comme des erreurs.
4. `game/.godot/` et `builds/` sont ignorés par git. Les dossiers `art_source/` et `tools/` existent (avec un `.gitkeep`).
5. **Étant donné** le projet créé, **quand** on le lance, **alors** les autoloads `Events`, `Log`, `Settings`, `SaveService`, `Audio` et `GameClock` sont déclarés. Ceux dont aucune story n'a encore besoin restent des coquilles vides (`Events`, `Settings`, `SaveService`, `Audio`).
6. `Log.info(categorie, message)` écrit `[hh:mm:ss.mmm] [INFO] [categorie] message` dans la console et dans `user://logs/`. Les niveaux DEBUG et TRACE sont inactifs en release.
7. `GameClock.scale(groupe)` renvoie l'échelle de chaque groupe (`PLAYER`, `ENEMIES`, `ENEMY_BULLETS`, `PLAYER_BULLETS`, `WORLD`, `FX`) : 1,0 par défaut, et 0 quand le jeu est en pause.
8. La classe statique `Tuning` existe ; chaque story suivante y ajoutera sa Resource.
9. **Étant donné** le jeu lancé, **quand** la fenêtre passe en 1280×720, 1920×1080, 2560×1440 puis 3840×2160, en fenêtré comme en plein écran, **alors** l'image est mise à l'échelle par ×2, ×3, ×4 puis ×6, sans flou.
10. Une fenêtre en 16:10, ou dont la définition n'est pas un multiple exact, affiche des bandes noires.
11. **Étant donné** n'importe quel build (debug ou release), **quand** on appuie sur F3, **alors** une surcouche affiche les FPS et le 1 % low.
12. **Étant donné** l'environnement de développement, **quand** la story est terminée, **alors** l'emplacement de l'éditeur est tranché (Windows, WSLg ou dépôt côté Windows), le MCP Context7 est configuré (GoPeak est reporté, décision de Kroustille du 2026-11-20, voir `game-architecture.md`), et ce choix est consigné.

## Tâches / sous-tâches

- [x] **T1. Installer Godot et trancher l'emplacement de l'éditeur** (CA 12)
  - [x] Faire valider le choix par Kroustille **avant** d'installer quoi que ce soit (recommandation et constats ci-dessous, section « Environnement de développement »).
  - [x] Installer Godot **4.7.2 stable, version standard (sans .NET)** à l'emplacement retenu. Vérifier : `godot --version` commence par `4.7.2.stable`.
  - [x] Les modèles d'export ne sont **pas** nécessaires ici (story 1.8).
- [x] **T2. Arborescence du dépôt et `.gitignore`** (CA 4)
  - [x] Créer `game/`, `art_source/.gitkeep`, `tools/.gitkeep`.
  - [x] Ajouter au `.gitignore` racine (sans effacer les lignes existantes `*:Zone.Identifier`) : `game/.godot/` et `builds/`.
- [x] **T3. Créer `game/project.godot` et ses réglages** (CA 1, 2, 3)
  - [x] Nom `Hypnagogia`, scène principale `res://main/main.tscn`, features `4.7` et `GL Compatibility`.
  - [x] Réglages d'affichage, de rendu et de physique (bloc de référence ci-dessous).
  - [x] Fenêtre de démarrage en 1280×720 (`window_width_override` / `window_height_override`), pour ne pas ouvrir une fenêtre minuscule en 640×360.
  - [x] Nommer les couches de collision 2D (tableau ci-dessous).
  - [x] Passer les avertissements de typage en erreur (bloc ci-dessous).
  - [x] Ajouter l'action `InputMap` `debug_toggle_perf` sur F3 (touche physique).
- [x] **T4. `core/` : `Const` et `Tuning`** (CA 2, 8)
  - [x] `game/core/constants.gd` (`class_name Const`) : `TILE_SIZE`, `VIEWPORT`, masques des couches de collision.
  - [x] `game/core/tuning.gd` (`class_name Tuning`) : classe statique vide, prête à recevoir les `preload` des `.tres`.
- [x] **T5. Autoloads** (CA 5, 6, 7)
  - [x] `game/autoloads/log.gd` : API `error/warn/info/debug/trace`, format, filtrage release, TRACE par catégorie.
  - [x] `game/autoloads/game_clock.gd` : enum `Group`, `scale()`, `paused`.
  - [x] Coquilles : `events.gd`, `settings.gd`, `save_service.gd`, `audio.gd`.
  - [x] Déclarer les autoloads dans cet ordre : `Log`, `Events`, `GameClock`, `Settings`, `SaveService`, `Audio`.
- [x] **T6. Scène `Main` et mire de netteté** (CA 9, 10)
  - [x] `game/main/main.tscn` + `main.gd` : racine `Main` (Node), enfants `ActiveScene` (Node) et `UI` (CanvasLayer).
  - [x] En build de debug seulement, `Main` instancie `res://debug/scale_test_pattern.tscn` sous `ActiveScene` (mire provisoire, remplacée par l'arène en story 1.3).
  - [x] `Main` journalise la taille de fenêtre et le facteur d'échelle à chaque `size_changed` (jamais par frame).
- [x] **T7. Surcouche de performances F3** (CA 11)
  - [x] `game/debug/perf_overlay.tscn` + `perf_overlay.gd`, instanciée par `Main` sous `UI` dans **tous** les builds, masquée au démarrage.
  - [x] Affiche FPS, 1 % low, et la taille de fenêtre avec le facteur d'échelle (aide à vérifier le CA 9).
  - [x] Bascule par l'action `debug_toggle_perf` ; `process_mode = PROCESS_MODE_ALWAYS`.
- [x] **T8. Configurer les MCP et consigner le choix** (CA 12)
  - [x] Configurer Context7 (`.mcp.json`) ; GoPeak reporté (CWE-78 sur le paquet npm), voir `game-architecture.md`.
  - [x] Consigner l'emplacement de l'éditeur, le chemin `GODOT_PATH` et les commandes MCP dans `_bmad-output/game-architecture.md`, section « Environnement de développement » : remplacer les mentions « à trancher à l'installation ».
  - [x] Prévenir Kroustille qu'il faut relancer la session Claude Code pour charger les MCP. La vérification de leur chargement se fait après relance.
- [x] **T9. Vérifications** (tous les CA ; voir « Stratégie de test »)
  - [x] Import et analyse en headless sans aucune erreur de script.
  - [x] Lancement fenêtré : mire nette, F3, logs dans la console et dans `user://logs/godot.log`.
  - [x] Résolutions et bandes noires (CA 9, 10), avec les limites de l'écran disponible consignées.
  - [x] Recherche dans le code : aucun `print(` hors de `log.gd`, aucun `Timer`, `create_timer`, `time_scale`, `randf`, `randi`, `randomize`, `shuffle`, `pick_random`.

### Review Findings

Revue de code du 2026-11-20 (Blind Hunter, Edge Case Hunter, Acceptance Auditor).

- [x] [Review][Patch] Fenêtre plus petite que 640×360 : imposer une taille minimale `Const.VIEWPORT` via `Window.min_size` (décision de Kroustille, 2026-11-20) ; le facteur ×1 forcé devient alors exact [game/main/main.gd, game/project.godot]
- [x] [Review][Patch] `Main` écrit une ligne `Log.info` à chaque `size_changed` : ne journaliser que lorsque le facteur d'échelle change (décision de Kroustille, 2026-11-20) [game/main/main.gd:35]
- [x] [Review][Patch] Couleur des bandes (CA 10) non fixée : définir `rendering/environment/defaults/default_clear_color` en noir et vérifier visuellement [game/project.godot]
- [x] [Review][Patch] Calcul du facteur d'échelle dupliqué : le centraliser en un seul endroit, avec garde pour une fenêtre 0×0 (minimisée) [game/main/main.gd:37, game/debug/perf_overlay.gd:48]
- [x] [Review][Patch] CA 12 / GoPeak : aligner la documentation sur la décision de reporter GoPeak (lignes 928 et 961-962 de `game-architecture.md`, commentaire `.mcp.json` du `.gitignore`, libellé du CA 12 et de T8) [_bmad-output/game-architecture.md, .gitignore]
- [x] [Review][Patch] Horodatage lu en deux appels d'horloge, décalage possible à la frontière d'une seconde : une seule lecture [game/autoloads/log.gd:63]
- [x] [Review][Patch] Surcouche F3 : mesurer le delta réel avec `Time.get_ticks_usec()` (indépendant de `Engine.time_scale`) et remettre le tampon à zéro à l'affichage [game/debug/perf_overlay.gd]
- [x] [Review][Patch] Surcouche F3 : texte sans contour ni fond, illisible sur la mire claire [game/debug/perf_overlay.tscn]
- [x] [Review][Patch] `Const.VIEWPORT` duplique `viewport_width/height` de `project.godot` : l'ajouter au contrôle de cohérence de `Main` en debug [game/main/main.gd]
- [x] [Review][Patch] `.gitignore` : ancrer `builds/` en `/builds/` [.gitignore:3]
- [x] [Review][Defer] `GameClock.paused` indépendant de `SceneTree.paused` [game/autoloads/game_clock.gd] — deferred, à trancher à la story 1.6 (pause)
- [x] [Review][Defer] CA 9 et CA 11 : plein écran à ×2/×3/×4, HiDPI et build release non couverts par les mesures [—] — deferred, story 1.8 (export et mesures)
- [x] [Review][Defer] `GameClock` sans API pour modifier les échelles (hitstop, ralenti) [game/autoloads/game_clock.gd] — deferred, à créer quand une story en aura besoin

Écartés comme bruit (17) : F3 en `physical_keycode` (correct), surcoût de l'overlay en release (voulu par la story), `assert` en boucle (debug seulement), `Dictionary[Group, float]` (import headless propre), doublon `push_error` + `print` (voulu : visible dans le débogueur), noms d'autoloads, `@abstract` sur `Tuning`, coût de la mire, `.uid` et `icon.svg` « absents » (exclus du diff fourni aux relecteurs), `file_logging`, renderer et features (imposés par la story), absence de tests (AR26), `GameClock.scale()` hors enum, ombrage de `size`.

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

C'est la toute première story du code : **aucun fichier Godot n'existe**. Le dépôt ne contient que `_bmad/`, `_bmad-output/`, `docs/` (vide), `.claude/`, `CLAUDE.md` et un `.gitignore` (une seule règle, `*:Zone.Identifier`, à garder).

**Hors périmètre** (stories suivantes ; ne pas anticiper) :

| Élément | Story |
|---|---|
| `RunRng` | 4.x (AR14), exclu explicitement d'AR4 ici |
| `BulletManager`, test de charge F5, nombre de projectiles dans F3 | 1.2 |
| Arène, joueur, caméra, bande de HUD de 24 px, F2, `PlayerTuning` | 1.3 |
| Dash, ralenti F4 (`GameClock`), tampon d'entrée | 1.4 |
| Tir, bus audio, pool de `Audio` | 1.5 |
| Pause effective (menu, `process_mode`), `Settings` → `settings.cfg`, localisation `strings.csv`, `Theme` | 1.6 |
| Actions `InputMap` de jeu (`move_*`, `shoot`…), bascule de périphérique | 1.3 et 1.7 |
| VSync par défaut et interpolation physique 2D (AR12) | 1.3 et 1.8 |
| Exports, filtres d'export qui retirent les outils de triche | 1.8 |
| Framework de test (GUT ou GdUnit4) | avant le jalon B (AR26) |
| Plugins éditeur et runtime de GoPeak (`addons/`) | seulement s'ils deviennent utiles |

### Réglages de `project.godot` (CA 1, 3)

Valeurs de référence (architecture, « Initialisation du projet ») :

```ini
[application]
config/name="Hypnagogia"
run/main_scene="res://main/main.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]
window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"
window/dpi/allow_hidpi=true

[physics]
common/physics_ticks_per_second=60

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0   ; 0 = Nearest

[debug]
gdscript/warnings/untyped_declaration=2             ; 2 = Error
gdscript/warnings/unsafe_property_access=2
gdscript/warnings/unsafe_method_access=2
gdscript/warnings/unsafe_cast=2
gdscript/warnings/unsafe_call_argument=2
```

- **Ne pas** passer `inferred_declaration` en erreur : l'architecture autorise `:=` quand le type est évident.
- Laisser `debug/gdscript/warnings/exclude_addons` à sa valeur par défaut (`true`), pour que d'éventuels addons tiers ne bloquent pas le projet.
- Les avertissements `unsafe_*` en erreur imposent de typer les retours de `get_node()` et autres `Variant` (`as`, ou `%NomUnique` avec un type déclaré).

**Piège : valeurs par défaut non écrites.** Godot n'écrit pas dans `project.godot` une valeur égale à la valeur par défaut du moteur, et il les retire au prochain enregistrement. C'est en général le cas de `physics_ticks_per_second=60` et de `allow_hidpi=true`. Le CA 1 se vérifie donc sur les **réglages effectifs** (`ProjectSettings.get_setting(...)`, voir T9), pas seulement sur le texte du fichier.

**Piège Godot 4.7 : nouveaux défauts de stretch.** D'après le guide de migration 4.6 → 4.7, un projet **créé** en 4.7 démarre en `canvas_items` + `expand`. Ces deux valeurs sont l'inverse de ce qu'il faut : c'est l'image en 640×360 (`viewport`) qui garantit le pixel art net, et `keep` qui produit les bandes noires. Après création ou après passage dans l'éditeur, relire `project.godot` et vérifier `mode`, `aspect` et `scale_mode` à l'exécution. (Je n'ai pas pu lire le guide en entier : la page a refusé l'accès. À vérifier dans `ProjectSettings`.)

**Mise à l'échelle sans flou.** En mode `viewport`, Godot dessine en 640×360, puis agrandit l'image. Avec `scale_mode=integer`, le facteur est `min(⌊L/640⌋, ⌊H/360⌋)`, et le reste devient des bandes noires. Exemples attendus : 1280×720 → ×2 ; 1920×1080 → ×3 ; 2560×1440 → ×4 ; 3840×2160 → ×6 ; 2560×1600 (16:10) → ×4 avec des bandes en haut et en bas ; 1366×768 → ×2 avec des bandes. Si la mire apparaît floue malgré tout, chercher d'abord un réglage de filtre propre à l'agrandissement du viewport (les notes de 4.7 mentionnent de nouvelles options d'agrandissement au plus proche voisin), puis consigner ce qui a été fait.

**HiDPI.** Avec `allow_hidpi=true`, Godot est « DPI aware » sous Windows : la mise à l'échelle 125 % ou 150 % de Windows n'ajoute pas de flou bitmap. Retina (macOS) se vérifie en story 1.8.

### Couches de collision (CA 2)

Nommer les couches dans `[layer_names]`. Liste minimale tirée de l'architecture (murs, obstacles hauts et bas, meubles, joueur, ennemis, hitbox et hurtbox, ramassables, déclencheurs). Les projectiles n'utilisent pas la physique (D1), et les trous se testent par lecture de cellule (AR29) : ni les uns ni les autres n'ont de couche.

| N° | Nom (`layer_names/2d_physics/layer_N`) | Constante `Const` |
|---|---|---|
| 1 | `walls` | `LAYER_WALLS` |
| 2 | `high_obstacles` | `LAYER_HIGH_OBSTACLES` |
| 3 | `low_obstacles` | `LAYER_LOW_OBSTACLES` |
| 4 | `furniture` | `LAYER_FURNITURE` |
| 5 | `player` | `LAYER_PLAYER` |
| 6 | `enemies` | `LAYER_ENEMIES` |
| 7 | `player_hurtbox` | `LAYER_PLAYER_HURTBOX` |
| 8 | `enemy_hurtbox` | `LAYER_ENEMY_HURTBOX` |
| 9 | `pickups` | `LAYER_PICKUPS` |
| 10 | `triggers` | `LAYER_TRIGGERS` |

- Dans `Const`, les constantes sont des **masques de bits** (`const LAYER_WALLS: int = 1 << 0`), à affecter à `collision_layer` / `collision_mask`. Un commentaire en tête rappelle qu'elles doivent rester alignées sur les noms du projet.
- Garde-fou peu coûteux, recommandé : en debug, au `_ready()` de `Main`, `assert` que `ProjectSettings.get_setting("layer_names/2d_physics/layer_1") == "walls"` (et ainsi de suite, en boucle sur une table de `Const`).

### `Const` et `Tuning` (AR4, CA 2, 8)

```gdscript
# game/core/constants.gd
class_name Const

const TILE_SIZE: int = 16
const VIEWPORT: Vector2i = Vector2i(640, 360)

# Physics layer bitmasks. Must match [layer_names] in project.godot.
const LAYER_WALLS: int = 1 << 0
# ...
```

```gdscript
# game/core/tuning.gd
@abstract class_name Tuning
# Preloads balancing Resources from res://data/tuning/. Each story adds its own, e.g.:
# const PLAYER: PlayerTuning = preload("res://data/tuning/player_tuning.tres")
```

- `@abstract` (Godot ≥ 4.5) empêche d'instancier la classe. S'il pose problème, le retirer : la classe reste utilisée seulement pour ses constantes.
- `Tuning` est une classe, **pas un autoload** (architecture, « Accès aux données »).
- Ne pas créer `data/` maintenant : la première Resource arrive en 1.3. `data/` ne contiendra que des `.tres`.

### Autoloads (AR1, AR13, AR27, CA 5 à 7)

**Piège bloquant : pas de `class_name` dans un script d'autoload.** Un script enregistré comme autoload `Log` qui déclare aussi `class_name Log` provoque l'erreur « Class "Log" hides an autoload singleton ». Les six scripts d'autoload n'ont **pas** de `class_name`.

Déclaration (`*` = singleton actif) :

```ini
[autoload]
Log="*res://autoloads/log.gd"
Events="*res://autoloads/events.gd"
GameClock="*res://autoloads/game_clock.gd"
Settings="*res://autoloads/settings.gd"
SaveService="*res://autoloads/save_service.gd"
Audio="*res://autoloads/audio.gd"
```

`Log` d'abord, pour que les autres autoloads puissent journaliser dès leur `_ready()`. Les quatre coquilles sont un `extends Node` avec une ligne de commentaire (en anglais) qui dit leur rôle futur et la story qui le remplira. Pas de méthodes inventées.

**`Log` (`autoloads/log.gd`)**

- API : `error`, `warn`, `info`, `debug` et `trace`, toutes en `(category: String, message: String) -> void`.
- Format exact : `[hh:mm:ss.mmm] [NIVEAU] [categorie] message`, avec un niveau en majuscules (`ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`).
- Heure locale : `Time.get_time_string_from_system()` donne `hh:mm:ss`. Les millisecondes viennent de la partie fractionnaire de `Time.get_unix_time_from_system()`, formatées sur 3 chiffres (`%03d`).
- Sortie : `print()` de la ligne formatée. C'est le **seul** `print()` autorisé dans le projet. ERROR envoie aussi la ligne à `push_error()`, et WARN à `push_warning()` : elles apparaissent alors dans le débogueur de l'éditeur. Le doublon dans le fichier de log est accepté.
- Fichier : on s'appuie sur la journalisation intégrée de Godot (`user://logs/godot.log`, active par défaut sur desktop, avec rotation). On ne réimplémente pas l'écriture de fichier. Si `debug/file_logging/enable_file_logging.pc` n'est pas actif, l'activer.
- Filtrage : DEBUG et TRACE ne font rien si `OS.is_debug_build()` est faux (valeur mise en cache au `_ready()`). TRACE est en plus désactivé par catégorie par défaut : `set_trace_enabled(category: String, enabled: bool)`.
- Catégories de l'architecture : `run`, `room`, `combat`, `lucidity`, `items`, `gen`, `save`, `input`, `audio`, `ui`. Les exposer en constante (`const CATEGORIES: PackedStringArray`). En debug, une catégorie inconnue déclenche un `assert` ; en release, la ligne est écrite quand même (AR28 : le jeu ne s'arrête jamais).
- Jamais de log dans une boucle par frame : les données par frame passent par la surcouche F3.

**`GameClock` (`autoloads/game_clock.gd`)**, d'après P4 :

```gdscript
extends Node

enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }

var paused: bool = false
var _scales: Dictionary[Group, float] = {}

func _init() -> void:
	for group: Group in Group.values():
		_scales[group] = 1.0

func scale(group: Group) -> float:
	return 0.0 if paused else _scales[group]
```

- Initialiser toutes les clés et lire par `_scales[group]` : avec un dictionnaire typé, l'indexation renvoie un `float`, alors que `_scales.get(group, 1.0)` renvoie un `Variant`, ce qui déclencherait un avertissement `unsafe_*`, donc une erreur.
- Si `for group: Group in Group.values()` est refusé par l'analyseur (`values()` renvoie un `Array` non typé), itérer sur `Group.values()` sans type et caster avec `as int`. L'important : aucun avertissement.
- Pas de `set_scale_for()` maintenant : il arrive avec Réveil cassé (5.8), et le ralenti F4 arrive en 1.4.
- `paused` est un simple drapeau. Le menu de pause et le `process_mode` arrivent en 1.6.
- Interdits, dès maintenant et pour tout le projet : `Engine.time_scale` ≠ 1, nœuds `Timer` et `create_timer()` pour le gameplay.

### `Main`, mire et surcouche F3 (AR20 partiel, AR24, CA 9 à 11)

Arbre de `main/main.tscn` (sous-ensemble de D14) :

```
Main (Node)              — main.gd
├── ActiveScene (Node)   — accueillera Bedroom ou Run ; ici, la mire en debug
└── UI (CanvasLayer)     — PerfOverlay
```

- `Transition` (CanvasLayer) n'est pas créé ici : il arrive avec les transitions (Epic 6).
- **Mire** (`debug/scale_test_pattern.tscn`, racine `ScaleTestPattern`, un `Node2D` qui dessine dans `_draw()`) : un cadre de 1 px exactement sur les bords de 640×360, une grille d'une ligne de 1 px toutes les 16 px, et un damier de 1 px dans un coin. Toute interpolation se voit aussitôt : lignes baveuses, damier gris. Couleurs en dur autorisées (outil de debug, pas une valeur de gameplay).
- `Main` charge la mire avec `load()`, pas `preload()`, et seulement si `OS.is_debug_build()`. Le build de release (1.8) pourra ainsi exclure les outils de debug.
- **La surcouche F3 existe dans tous les builds** (architecture, « Outils de debug »). `Main` l'instancie donc toujours. Elle vit dans `debug/` comme le prévoit l'arborescence. En story 1.8, le filtre d'export devra garder `perf_overlay.*` : le noter dans les Completion Notes.
- Calcul de la surcouche :
  - `_process(delta)` enregistre la durée de chaque frame dans un tampon circulaire préalloué (`PackedFloat32Array` de 1 000 entrées, aucune allocation par frame).
  - Le texte se met à jour deux fois par seconde.
  - FPS : `Engine.get_frames_per_second()`.
  - 1 % low : `1.0 / durée` au 99e centile des durées du tampon (tri d'une copie, deux fois par seconde seulement).
  - Le `delta` réel (pas `GameClock`) : la surcouche mesure le moteur, pas le jeu, et continue de tourner en pause.
- Ligne affichée, par exemple : `FPS 60 | 1% low 58 | 1920x1080 x3`. Facteur : `mini(size.x / Const.VIEWPORT.x, size.y / Const.VIEWPORT.y)` sur `get_window().size`.
- **Textes de la surcouche** : ce sont des relevés techniques (unités et abréviations), pas du texte de jeu. Ils ne passent pas par `tr()`, et la localisation n'existe pas encore (1.6). L'exemption ne vaut que pour `debug/` ; la noter dans un commentaire du script pour la revue de code. *(Point à confirmer, voir Questions ouvertes.)*
- Entrée : `_unhandled_input(event)` + `event.is_action_pressed("debug_toggle_perf")`. L'action est déclarée dans l'`InputMap` du projet (AR12 : toutes les commandes passent par des actions), sur la **touche physique** F3.
- Le journal de taille de fenêtre (`Log.info("ui", "window resized size=%s scale=x%d" % [...])`) est branché sur `get_window().size_changed`, jamais par frame.

### Environnement de développement (AR3, CA 12)

**Constats sur la machine, le 2026-11-20 :**

- Le dépôt est sous **WSL2** (`/home/kroustille/hypnagogia`), et **WSLg** est disponible (`WAYLAND_DISPLAY=wayland-0`, `DISPLAY=:0`).
- **Godot n'est installé nulle part** (absent du `PATH` WSL et de `C:\Program Files`).
- Node.js v26 et `npx` sont présents (GoPeak demande Node 18 ou plus).
- Aucun serveur MCP n'est configuré, ni global ni pour ce projet.

**Options :**

| Option | Pour | Contre |
|---|---|---|
| **A. Éditeur Linux via WSLg** (recommandé pour l'itération) | GoPeak (lancé par `npx` dans WSL) lance directement le binaire Linux ; `GODOT_PATH` simple ; pas d'accès disque entre Windows et WSL ; Claude Code et Godot voient les mêmes chemins | GPU passé par Mesa/d3d12 : les mesures de performances et de latence n'y sont **pas** représentatives (1.2 et 1.8 se mesurent sur un export Windows natif) ; la manette n'est pas transmise à WSL sans `usbipd` (1.7 se teste sous Windows) |
| B. Éditeur Windows sur le dépôt WSL (`\\wsl$\...`) | Rendu et manette natifs | Accès disque lent et surveillance de fichiers peu fiable sur `\\wsl$` ; GoPeak dans WSL devrait lancer un `.exe` Windows sur des chemins UNC |
| C. Dépôt déplacé côté Windows | Tout natif sous Windows | Claude Code dans WSL travaillerait sur `/mnt/c`, lent ; changement de flux de travail |

**Recommandation : A.** Installer le binaire officiel Linux x86_64 de Godot 4.7.2 stable (archive `Godot_v4.7.2-stable_linux.x86_64.zip` des releases GitHub de `godotengine/godot`) dans un dossier hors du dépôt (par exemple `~/.local/opt/godot/`), avec un lien `~/.local/bin/godot`. Les vérifications de performances, de latence et de manette se feront sur des exports Windows (1.2, 1.7, 1.8). **Le choix revient à Kroustille** : le lui présenter et attendre sa réponse avant d'installer.

**MCP (Claude Code, portée locale par défaut, car `GODOT_PATH` dépend de la machine) :**

```bash
claude mcp add godot -e GODOT_PATH=<chemin absolu du binaire Godot 4.7.2> -- npx -y gopeak
```

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

- D'après le README de GoPeak (lu sur des miroirs ; le dépôt `HaD0Yun/Gopeak-godot-mcp` fait foi) : nom de serveur `godot`, `npx -y gopeak`, variable `GODOT_PATH`, profil d'outils `GOPEAK_TOOL_PROFILE=compact` par défaut. Les plugins éditeur et runtime (script `install-addon.sh`, port 7777) ne servent qu'aux outils de pont et d'inspection en direct : **ne pas les installer dans cette story**, et ne jamais exécuter un `curl | bash` sans accord explicite.
- Relire les deux README au moment de l'installation : les noms de paquets peuvent avoir changé.
- Les MCP ne se chargent qu'au **redémarrage** de la session Claude Code. L'agent ne peut pas vérifier leur chargement dans sa propre session : il le signale à Kroustille, qui vérifie après relance (`claude mcp list`).

**Où consigner le choix :** dans `_bmad-output/game-architecture.md`, section « Environnement de développement » (en français) : option retenue, emplacement du binaire, `GODOT_PATH`, commandes MCP, et ce qui doit être testé hors WSL. Retirer les deux mentions « à trancher à l'installation » (sections « Environnement de développement : MCP » et « Outillage IA »). Le résumer aussi dans les Completion Notes.

### Règles d'architecture qui s'appliquent dès cette story

- **GDScript typé statiquement partout** (AR2). `:=` seulement quand le type est évident. Pas de C# ni de GDExtension.
- **Nommage** (AR32) : fichiers et dossiers en `snake_case` ; un script par classe ; nœud racine d'une scène en `PascalCase` (`main.tscn` → `Main`) ; constantes en `UPPER_SNAKE_CASE` ; membres privés préfixés par `_` ; gestionnaires `_on_<émetteur>_<signal>` (par exemple `_on_window_size_changed`).
- **Code, commentaires, logs et noms de fichiers en anglais.**
- **Frontières** : `autoloads/` et `core/` ne dépendent d'aucun dossier de fonctionnalité. Rien ne dépend de `debug/`, sauf `Main`, qui instancie la surcouche et, en debug seulement, la mire.
- **Erreurs** (AR28) : `assert` + `Log.error` pour un invariant violé ; une valeur sûre en repli pour une erreur récupérable. En release, jamais d'arrêt.
- **Pas de chemins `/root/...`, pas de `get_parent().get_parent()`.** Les dépendances internes à une scène passent par `@export` ou `%NomUnique`.

### Arborescence attendue à la fin de la story

```
hypnagogia/
├── .gitignore              (UPDATE : + game/.godot/, builds/)
├── art_source/.gitkeep     (NEW)
├── tools/.gitkeep          (NEW)
└── game/                   (NEW)
    ├── project.godot
    ├── icon.svg            (généré par Godot, à garder)
    ├── autoloads/          log.gd, events.gd, game_clock.gd, settings.gd, save_service.gd, audio.gd
    ├── core/               constants.gd, tuning.gd
    ├── main/               main.tscn, main.gd
    └── debug/              perf_overlay.tscn, perf_overlay.gd, scale_test_pattern.tscn, scale_test_pattern.gd
```

Godot génère aussi des fichiers `*.uid` à côté des scripts (Godot ≥ 4.4) : ils **se versionnent**. Il peut générer `game/.gitignore` et `game/.gitattributes` ; les garder s'ils apparaissent. Ne pas créer de dossiers vides « pour plus tard » (`player/`, `data/`…).

### Stratégie de test

Aucun framework de test n'est choisi (AR26 : avant le jalon B). Les vérifications sont des commandes et des contrôles manuels, consignés dans les Completion Notes.

1. **Analyse et import en headless :** `godot --headless --path game --import`, puis `godot --headless --path game --quit-after 60`. Zéro `SCRIPT ERROR`, zéro `Parse Error`, et la ligne de démarrage de `Log` présente si on en ajoute une.
2. **Réglages effectifs (CA 1, 3)** : un script jetable lancé avec `godot --headless --path game --script <fichier>`, **gardé dans le scratchpad, pas dans le dépôt**, qui affiche les `ProjectSettings.get_setting()` du CA 1 et les niveaux d'avertissement.
3. **Typage en erreur (CA 3)** : ajouter temporairement `var x = 1` dans un script, vérifier que l'analyse échoue, puis retirer la ligne.
4. **Log (CA 6)** : vérifier une ligne INFO dans la sortie console et dans `user://logs/godot.log` (sous Linux : `~/.local/share/godot/app_userdata/Hypnagogia/logs/`). DEBUG est visible en debug ; le filtrage en release se vérifie en 1.8, ou dès maintenant par revue du code (une seule condition sur `OS.is_debug_build()`).
5. **`GameClock` (CA 7)** : en debug, un `assert` au démarrage ou un essai rapide dans le script jetable : `scale()` vaut 1,0 pour chaque groupe, et 0,0 avec `paused = true`.
6. **Résolutions (CA 9, 10)** : `godot --path game --resolution 1920x1080`, `--resolution 2560x1600`, `--resolution 1366x768`, et `--fullscreen`. Lire le facteur affiché par F3, inspecter la mire (aucun flou), et vérifier les bandes noires. Les résolutions plus grandes que l'écran disponible (1440p, 4K) ne se testent pas en fenêtré : consigner ce qui a été vérifié et ce qui reste à faire sur un écran adapté.
7. **F3 (CA 11)** : la surcouche apparaît et disparaît, et les valeurs sont plausibles. En release : vérifié en 1.8.
8. **Recherche des interdits** : `grep -rnE 'print\(|Timer|create_timer|time_scale|randf|randi|randomize|shuffle|pick_random' game --include=*.gd`. Seul le `print(` de `log.gd` est attendu.

### Commit

D'après les règles du projet : commit directement sur `main`, au format Conventional Commits, en anglais. Par exemple `feat(core): bootstrap godot project with autoloads and perf overlay`. La mise à jour de l'architecture peut aller dans un commit `docs(architecture): record editor location and mcp setup`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture (« Structure du projet »).
- **Écarts assumés :**
  - `debug/scale_test_pattern.*` n'est pas dans l'arborescence : c'est un outil provisoire de vérification du CA 9.
  - L'action `InputMap` `debug_toggle_perf` n'est pas dans la liste des actions de D6, qui ne couvre que les commandes de jeu.
  - L'arbre de `Main` est réduit (sans `Transition`).
  - Liste des couches de collision : l'architecture demande qu'elles soient nommées sans en fixer la liste. Elle est fixée ici.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md` et de la mémoire du projet :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, à l'impératif, en minuscules, sans point final). Commits directement sur `main`, sans branche.
- Textes affichés au joueur : fichiers de localisation, jamais en dur (exemption limitée à `debug/`, voir plus haut).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige, sans abstraction anticipée.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.1]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR1 à AR4, AR13, AR24, AR27, AR28)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences non fonctionnelles] (NFR7)
- [Source: _bmad-output/game-architecture.md#Initialisation du projet]
- [Source: _bmad-output/game-architecture.md#Environnement de développement : MCP]
- [Source: _bmad-output/game-architecture.md#Gestion des erreurs], [#Logs], [#Configuration], [#Outils de debug]
- [Source: _bmad-output/game-architecture.md#Structure du projet] (arborescence, frontières, nommage)
- [Source: _bmad-output/game-architecture.md#P4. Temps par groupe]
- [Source: _bmad-output/game-architecture.md#Scènes (D14)]
- [Source: _bmad-output/game-architecture.md#Environnement de développement]
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Plateforme]
- [Externe : guide de migration Godot 4.6 → 4.7, docs.godotengine.org, « Breaking changes » (nouveaux défauts de stretch)]
- [Externe : README de GoPeak, HaD0Yun/Gopeak-godot-mcp (installation par `npx -y gopeak`, `GODOT_PATH`)]

### Questions ouvertes (sans effet bloquant)

1. **Textes de la surcouche F3** : l'exemption de localisation pour les relevés techniques de `debug/` convient-elle, ou faut-il des clés `tr()` dès que `strings.csv` existera (1.6) ?
2. **Emplacement de l'éditeur** : la recommandation (WSLg) attend la validation de Kroustille au début de T1.

## Dev Agent Record

### Agent Model Used

claude-sonnet-5-5

### Debug Log References

- `godot --headless --path game --import`, puis `--quit-after 60` : aucune erreur de script ; ligne `[INFO] [ui] window resized size=64x64 scale=x1`.
- Réglages effectifs relus par `ProjectSettings.get_setting()` (script jetable, hors dépôt) : viewport 640×360, stretch `viewport`/`keep`/`integer`, HiDPI vrai, `gl_compatibility`, filtre 0 (Nearest), 60 ticks physiques, cinq avertissements `unsafe_*`/`untyped` à 2, couches 1 et 10 nommées. `inferred_declaration` reste à 0.
- CA 3 : un `var x = 1` temporaire échoue (`Variable "x" has no static type. (Warning treated as error.)`), puis a été retiré.
- Autoloads : les six sont présents ; `GameClock.scale()` renvoie 1,0 pour chacun des six groupes et 0,0 avec `paused = true`.
- `Main` instancié en headless : `ActiveScene` contient `ScaleTestPattern` ; la surcouche est masquée au départ, visible après une action `debug_toggle_perf` simulée, et affiche `FPS .. | 1% low .. | WxH xN`.
- Recherche des interdits : seul `print(line)` de `log.gd` (plus deux commentaires qui citent les API interdites).

### Implementation Plan

Socle posé tel que décrit dans les Dev Notes : `project.godot` écrit à la main (valeurs de référence), `Const` en masques de bits avec une table de noms pour le garde-fou de `Main`, `Log` sur `print()` + journal intégré de Godot, `GameClock` avec dictionnaire typé, quatre autoloads en coquille, `Main` + mire de netteté (debug seulement) + surcouche F3 (tampon circulaire de 1 000 frames, rafraîchie deux fois par seconde).

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-20).
- **Éditeur (CA 12) :** option A validée par Kroustille (Linux via WSLg). Godot 4.7.2 stable (standard) installé dans `~/.local/opt/godot/`, lien `~/.local/bin/godot`, SHA-512 vérifié, `godot --version` = `4.7.2.stable.official.ed1daf0bf`. Choix consigné dans `_bmad-output/game-architecture.md`.
- Pour la story 1.8 : le filtre d'export devra garder `perf_overlay.*` (F3 existe dans tous les builds) et pourra exclure `debug/scale_test_pattern.*`.
- Exemption de localisation des textes de la surcouche F3 : notée en commentaire dans `perf_overlay.gd` (question ouverte 1 de la story, à confirmer en revue).
- **Vérifications fenêtrées (T9), après installation des bibliothèques graphiques par Kroustille :** écran 3840×2160, rendu logiciel Mesa llvmpipe (VSync non supporté, ~270 FPS). Facteur d'échelle et décalage mesurés par `Window.get_screen_transform()` (script jetable hors dépôt) : 1280×720 → ×2 ; 1920×1080 → ×3 ; 2560×1440 → ×4 ; 3840×2160 → ×6 ; plein écran (3840×2160) → ×6 ; 2560×1600 → ×4 avec 80 px de bande en haut et en bas ; 1366×768 → ×2 avec décalage (43, 24), donc bandes noires. Tous les facteurs sont entiers et les décalages sont des entiers (CA 9, 10).
- F3 en fenêtré : la surcouche s'affiche (`FPS .. | 1% low .. | 1920x1080 x3`) et se masque au second appui. Le FPS vaut 1 pendant la première seconde (compteur du moteur) puis suit la valeur réelle ; le « 1 % low » du début est faussé par les frames de démarrage, qui restent dans le tampon de 1 000 entrées. Le log `[INFO] [ui] window resized ...` apparaît dans la console et dans `user://logs/godot.log` (CA 6).
- **Netteté de la mire confirmée à l'œil par Kroustille** (grille et damier nets, sans case grise). Le cadre blanc de 1 px, exactement sur le bord, est rogné par le contour de la fenêtre WSLg ; les pixels rendus ont été vérifiés (bords blancs, image 640×360). Les avertissements audio (pas de carte son, `libpulse` absent) sont sans effet pour cette story.
- **MCP (T8) — écart assumé sur le CA 12 :** le CLI `claude` n'existe pas dans le WSL. Context7 est déclaré dans `.mcp.json` (racine, ignoré par git) et démarre (vérifié par une requête `initialize`). **GoPeak est volontairement reporté (décision de Kroustille)** : `gopeak` 2.3.8 sur npm est déprécié pour une injection de commande (CWE-78) et n'est plus publié sur npm ; les versions corrigées (≥ 2.4.1) sont sur GitHub (`HaD0Yun/Doyunha-Gopeak`). Il pourra être ajouté plus tard à `.mcp.json`. Relancer la session Claude Code pour charger Context7 (non vérifié depuis cette session).
- Régression finale (2026-11-20) : import et lancement headless sans erreur, autoloads et `GameClock` conformes, `Main` + F3 conformes, aucun appel interdit hors `log.gd`. Pas de framework de test à ce stade (AR26) : les vérifications sont des commandes et des contrôles manuels.

### File List

- `.gitignore` (modifié : `game/.godot/`, `builds/`, `.mcp.json`)
- `.mcp.json` (nouveau, ignoré par git : Context7 seulement)
- `art_source/.gitkeep` (nouveau)
- `tools/.gitkeep` (nouveau)
- `game/project.godot` (nouveau)
- `game/icon.svg` (nouveau, + `.import` généré)
- `game/core/constants.gd`, `game/core/tuning.gd` (nouveaux, + `.uid`)
- `game/autoloads/log.gd`, `game_clock.gd`, `events.gd`, `settings.gd`, `save_service.gd`, `audio.gd` (nouveaux, + `.uid`)
- `game/main/main.gd`, `game/main/main.tscn` (nouveaux, + `.uid`)
- `game/debug/perf_overlay.gd`, `perf_overlay.tscn`, `scale_test_pattern.gd`, `scale_test_pattern.tscn` (nouveaux, + `.uid`)
- `_bmad-output/game-architecture.md` (modifié : environnement de développement)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modifié)

### Change Log

- 2026-11-20 : socle du projet Godot (réglages, `Const`, `Tuning`, autoloads, `Main`, mire, surcouche F3) et choix de l'éditeur consignés. Vérifications fenêtrées faites ; Context7 configuré, GoPeak reporté. Story passée en `review`.
