# Story 1.6 : Mettre en pause et régler le jeu

Status: ready-for-dev

## Story

En tant que joueur,
je veux mettre le jeu en pause et régler le son, l'affichage et la VSync,
afin de jouer dans de bonnes conditions.

**Exigences couvertes :** FR6 (chiffres de dégâts), FR10, FR66 (sans les touches), AR18 (`settings.cfg`), AR22, NFR10, ainsi que AR8, AR13, AR27, AR28, AR32.

**Prérequis : la story 1.5 est `done`** (vérifié à la création de ce fichier : `Audio`, bus `Master`/`Music`/`SFX`/`UI`, `Hurtbox`, `TrainingTarget`, `Reticle` existent dans le dépôt).

## Critères d'acceptation

1. **Étant donné** une partie en cours, **quand** le joueur appuie sur Échap ou sur Start, **alors** le jeu se fige par `GameClock` et `process_mode`, sans toucher à `Engine.time_scale`, **et** un menu de pause propose Reprendre, Réglages et Quitter.
2. **Étant donné** le menu des réglages, **quand** le joueur change les volumes (`Master`, `Music`, `SFX`, `UI`), le mode fenêtré ou plein écran, la VSync ou l'affichage des chiffres de dégâts, **alors** le changement s'applique aussitôt et s'écrit dans `user://settings.cfg`, de façon atomique (fichier temporaire, puis renommage), **et** les réglages sont restaurés au lancement suivant, **et** par défaut, la VSync est activée et les chiffres de dégâts sont désactivés.
3. **Étant donné** les chiffres de dégâts activés, **quand** un tir touche la cible d'entraînement, **alors** les dégâts s'affichent au-dessus d'elle.
4. **Étant donné** un `settings.cfg` absent ou illisible, **quand** le jeu démarre, **alors** il démarre avec les réglages par défaut, et un avertissement est journalisé.
5. **Étant donné** les menus, **quand** ils s'affichent, **alors** tous leurs textes passent par `tr("CLE")`, depuis `localization/strings.csv`, avec le français comme langue de référence, **et** ils utilisent le `Theme` unique et une police pixel.

**Conséquences à tenir pour que le système reste cohérent de bout en bout** (non écrites dans l'epic, mais exigées par l'architecture, par les reports des stories précédentes ou par l'état du dépôt) :

6. **Une seule source de vérité pour la pause** (report de la revue de 1.1) : seul `Main` met le jeu en pause et le reprend, en écrivant **ensemble** `GameClock.paused` et `ActiveScene.process_mode`. `get_tree().paused` n'est **jamais** utilisé. Aucun autre script n'écrit `GameClock.paused`.
7. **Pendant la pause** : le joueur ne bouge pas, ne dashe pas, ne tire pas ; les tirs en vol, le recul, le flash de la cible et les chiffres de dégâts se figent ; à la reprise, tout repart exactement d'où il en était (aucun tir parasite au clic sur « Reprendre », aucun dash ni tir tamponné pendant la pause).
8. **Curseur** (report de 1.5) : le curseur système est **visible** pendant la pause et le réticule est masqué ; à la reprise, le curseur est de nouveau caché et le réticule réapparaît. Le test de charge (F5) garde le curseur visible.
9. **Navigation complète au clavier et à la manette** : le premier bouton prend le focus à l'ouverture de chaque menu ; flèches, croix directionnelle et stick gauche naviguent (`ui_*` par défaut) ; A ou Entrée valide ; Échap, Start ou B revient en arrière (réglages → pause → jeu).
10. **La pause et les réglages fonctionnent en release** : aujourd'hui, `Main._unhandled_input()` sort dès le début hors build de debug ; seules F4 et F5 doivent rester réservées au debug. F2 et F3 continuent de marcher pendant la pause ; F4 et F5 sont ignorées pendant la pause.
11. Le son continue de jouer pendant la pause (les lecteurs d'`Audio` ne sont pas dans `ActiveScene` : rien à changer, mais à vérifier) ; un changement de volume s'entend aussitôt.
12. Marche, dash, tir, F2, F3, F4, F5 et le test de charge de 1.1 à 1.5 sont inchangés quand le jeu n'est pas en pause.

## Tâches / sous-tâches

- [ ] **T1. Lexique** (AR32 : un terme entre dans le lexique **avant** le code)
  - [ ] `game-architecture.md`, section « Lexique » : ajouter `Pause ; menu de pause ; réglages ; volume ; plein écran ; VSync ; chiffres de dégâts | pause ; pause_menu ; settings ; volume ; fullscreen ; vsync ; damage_numbers`.
  - [ ] `game-architecture.md`, section « Temps (D7) » : consigner la règle de la pause (CA 6) en une ligne.
- [ ] **T2. Localisation** (CA 5, NFR10)
  - [ ] `game/localization/strings.csv` (voir « Localisation »), import, traduction déclarée dans `project.godot`, langue de repli `fr`.
- [ ] **T3. Police pixel et `Theme`** (CA 5, AR22)
  - [ ] Police pixel libre de droits avec les accents français, sa licence à côté, import sans anticrénelage (voir « Police et `Theme` »).
  - [ ] `game/ui/theme/theme.tres`, déclaré comme thème du projet (`gui/theme/custom`).
- [ ] **T4. `Settings`** (CA 2, 4)
  - [ ] `autoloads/settings.gd` : valeurs, valeurs par défaut, chargement, validation, application, écriture atomique (voir « `Settings` »).
- [ ] **T5. Action `pause`** (CA 1)
  - [ ] `project.godot` : action `pause` (Échap, Start) (voir « Entrées »).
- [ ] **T6. Pause dans `Main`** (CA 1, 6, 7, 10)
  - [ ] `main/main.gd` : `_set_paused()`, menus instanciés dans `UI`, gestion des entrées réorganisée (voir « `Main` et la pause »).
- [ ] **T7. Menus** (CA 1, 2, 5, 9)
  - [ ] `ui/menus/pause_menu.tscn/.gd` et `ui/menus/settings_menu.tscn/.gd` (voir « Menus »).
- [ ] **T8. Curseur et réticule pendant la pause** (CA 8)
  - [ ] `player/reticle.gd` : `NOTIFICATION_DISABLED` / `NOTIFICATION_ENABLED` (voir « Réticule »).
- [ ] **T9. Chiffres de dégâts** (CA 3)
  - [ ] `Events.enemy_damaged`, émis par `Hurtbox.receive()` ; `vfx/damage_numbers.gd` et `vfx/damage_number.gd` ; ajout dans l'arène (voir « Chiffres de dégâts »).
- [ ] **T10. Vérifications headless** (CA 1 à 12) : scripts jetables du scratchpad (voir « Stratégie de test »).
- [ ] **T11. Vérifications fenêtrées sous WSLg** (CA 1, 2, 3, 5, 7, 8, 9) : menus, police nette, plein écran, curseur, captures.
- [ ] **T12. Régression** : import et lancement sans erreur, recherche des interdits, marche, dash, tir, F2 à F5 conformes.
- [ ] **T13. Reports** : mettre à jour `deferred-work.md` (entrées résolues : `GameClock.paused` ↔ `SceneTree.paused`, curseur en pause, lecteurs `Audio` figés en pause ; ce qui n'a pas pu être vérifié : manette réelle, plein écran sous Windows, VSync réelle).

## Dev Notes

### Ce que cette story pose, et ce qu'elle ne pose pas

Un menu de pause, un menu de réglages persistants, une police et un thème, la localisation, et les chiffres de dégâts. **Hors périmètre** (ne pas anticiper) :

| Élément | Story |
|---|---|
| Menu des touches, réassignation, section `[input]` de `settings.cfg`, bascule automatique clavier-souris ↔ manette, toutes les autres actions de l'architecture (`power_*`, `map`…) | 1.7 |
| Mesure de latence, choix VSync désactivée ou mailbox, export | 1.8 |
| Réglages d'accessibilité (distorsions, tremblements, photosensibilité) | FR67, Epic 3 |
| Seed affichée dans le menu pause, « sauvegarder et quitter », `run.json`, `profile.json` | 4.11, 6.8 |
| Écran de mort, « cette mort était-elle juste ? » | 2.2, 2.8 |
| HUD | 2.7 |
| Sons d'interface (bus `UI`), musique (bus `Music`), filtre passe-bas | 3.x, 7.x |
| Pause automatique à la perte du focus de la fenêtre | non demandée (question ouverte) |
| Langue autre que le français, choix de la langue | non demandé |

### État actuel du dépôt (stories 1.1 à 1.5 `done`)

- **Autoloads** (ordre dans `project.godot`) : `Log`, `Events`, `GameClock`, `Settings`, `SaveService`, `Audio`.
  - `Settings` : **coquille vide** (`extends Node` + commentaire « filled by story 1.6 »). `Events` : coquille vide. `SaveService` : coquille vide, **ne pas y toucher** (6.8).
  - `GameClock` : `enum Group`, `var paused: bool`, `global_multiplier` borné à [0, 1] (F4), `scale(group)` renvoie 0 si `paused`. **Personne n'écrit `paused` aujourd'hui.**
  - `Audio` : pool de 16 `AudioStreamPlayer` sur le bus `SFX`, enfants de l'autoload (donc hors d'`ActiveScene`) ; `play_sfx(stream, max_voices)`. Ne pas modifier.
  - `Log` : catégories `run`, `room`, `combat`, `lucidity`, `items`, `gen`, `save`, `input`, `audio`, `ui`. Utiliser `ui` pour les menus, `save` pour `settings.cfg`.
- **`default_bus_layout.tres`** : `Master`, `Music`, `SFX`, `UI` (les trois derniers envoyés vers `Master`, 0 dB).
- **`Main`** (`main/main.gd` + `main.tscn`) : nœuds `ActiveScene` (`%ActiveScene`, `Node`) et `UI` (`%UI`, `CanvasLayer`, qui contient `PerfOverlay`). `_ready()` : vérifications de debug, `CollisionDrawer` ajouté à `UI` en debug, `_show_scene(ARENA_PATH)`, suivi de la taille de fenêtre. **`_unhandled_input()` commence par `if not OS.is_debug_build(): return`**, puis gère F5 (`debug_load_test`) et F4 (`debug_slow_motion`). `_show_scene(path)` retire puis libère l'enfant d'`ActiveScene` et instancie la nouvelle scène.
- **`PerfOverlay`** (F3) et **`CollisionDrawer`** (F2) : `process_mode = PROCESS_MODE_ALWAYS`, enfants de `UI` (hors d'`ActiveScene`) : ils continuent de marcher pendant la pause sans modification. Le `Label` de `PerfOverlay` (300×40 px) prendra la police du thème du projet : vérifier qu'il reste lisible et non tronqué.
- **`Arena`** (`rooms/arena/arena.gd`) : construit `Floor` et `Walls` en code, crée `PlayerBullets` (`BulletManager`, camp `PLAYER`) en code dans `_setup_player_bullets()`, enregistre la `Hurtbox` des 3 `TrainingTarget` (conteneur `%Targets`). Les enfants (`Player`, cibles) ont déjà fait leur `_ready()` quand `Arena._ready()` démarre.
- **`Hurtbox`** (`combat/hurtbox.gd`) : `@export var camp: BulletManager.Camp`, `receive(info)` émet seulement le signal local `damage_received(info)`, `world_rect()` en coordonnées globales. **C'est le point de passage unique de tous les dégâts.**
- **`TrainingTarget`** : sprite 16×24 centré, `Hurtbox` 12×20, `HitFeedback` sur `GameClock.Group.ENEMIES`. Indestructible.
- **`Reticle`** (`player/reticle.gd`, enfant du joueur, `top_level`) : cache le curseur dans `_enter_tree()`, le rend dans `_exit_tree()`, se place dans `_process()`. Le joueur et son réticule sont dans `ActiveScene`.
- **`Player`** lit ses entrées dans `_physics_process` (`move_*`, `dash`, `shoot`, `aim_*`, position de la souris). Tous les compteurs du jeu sont des ticks pondérés par `GameClock.scale(groupe)`.
- **Aucun dossier `ui/` ni `localization/`**, aucun `Theme`, aucune police dans le projet. Aucune traduction déclarée dans `project.godot`.
- `project.godot` : fenêtre 1280×720 (`window_width_override`), stretch `viewport` + `keep` + `integer`, VSync non précisée (donc activée, valeur par défaut de Godot), interpolation physique 2D activée.
- Environnement : Godot 4.7.2 via WSLg, `godot` dans le `PATH`. Pas de manette sous WSL. Pas de `python3` (`uv run python …`). `curl` disponible. Les `*.import` et `*.uid` sont versionnés.

### Leçons des stories 1.1 à 1.5 à appliquer

- **Typage strict, avertissements en erreur** (`untyped_declaration`, `unsafe_*` à 2). Une valeur lue d'un `ConfigFile` est un `Variant` : la tester par `typeof()` (ou `is`) avant de l'affecter à une variable typée, jamais `float(...)` sur un `Variant` douteux.
- **Calculer la valeur sûre avant de journaliser** (revue de 1.3), et ne jamais planter sur une donnée invalide (AR28) : un réglage illisible retombe sur sa valeur par défaut.
- **Injection** : `setup()` avant `add_child()` ; signaux locaux vers le parent ; pas de `/root/...` ni `get_parent().get_parent()`.
- **Un nœud déplacé dans `_process` désactive l'interpolation physique** (`physics_interpolation_mode = OFF`) : c'est le cas des chiffres de dégâts s'ils bougent dans `_process` (préférer `_physics_process` et les ticks, voir plus bas).
- **Vérifications** : `godot --headless --path game --import`, puis `godot --headless --path game --quit-after <n>`. Zéro `SCRIPT ERROR`, zéro `Parse Error`. Les vérifications tournent comme une **scène** du scratchpad (`godot --headless --path game --scene <scène>`), car `--script` ne résout pas les autoloads. `Input.parse_input_event()` est appliqué **au tick suivant** : attendre un tick après un événement simulé.
- **En headless** : `Input.mouse_mode` est ignoré (reste `VISIBLE`), le mode de fenêtre et la VSync sont sans effet, le pilote audio est factice. Ces points se vérifient **en fenêtré** sous WSLg.
- **Fichiers générés par Godot** : versionner les `.uid` et `.import`. Pour les `.translation` générés par l'import du CSV, voir « Localisation ».

### `Settings` (AR18, D12, « Configuration »)

`autoloads/settings.gd` remplace la coquille. **Service d'application, aucun état de run.** Il détient les réglages du joueur, les applique au moteur et les écrit dans `user://settings.cfg` (`ConfigFile`).

**Contenu du fichier** (sections et clés en anglais ; la section `[input]` viendra avec 1.7, ne pas la créer) :

| Section | Clé | Type | Défaut | Application |
|---|---|---|---|---|
| `audio` | `master` | `float` linéaire [0, 1] | 1,0 | volume du bus `Master` |
| `audio` | `music` | `float` [0, 1] | 1,0 | bus `Music` |
| `audio` | `sfx` | `float` [0, 1] | 1,0 | bus `SFX` |
| `audio` | `ui` | `float` [0, 1] | 1,0 | bus `UI` |
| `display` | `fullscreen` | `bool` | `false` | mode de la fenêtre |
| `display` | `vsync` | `bool` | **`true`** | mode VSync |
| `display` | `damage_numbers` | `bool` | **`false`** | lu par les chiffres de dégâts au moment d'un coup |

- Ces valeurs par défaut ne sont pas des valeurs de gameplay du GDD (NFR9) : ce sont des préférences, définies **à un seul endroit**, dans `Settings` (constantes). Ne pas créer de `.tres` pour elles.
- **API publique** (proposition, à garder petite) :

```gdscript
signal changed                                  # local: any setting changed (menus refresh their widgets)

const FILE_PATH: String = "user://settings.cfg"

var fullscreen: bool                            # read-only from outside: use the setters below
var vsync: bool
var damage_numbers: bool

func volume(bus: StringName) -> float           # linear [0, 1]
func set_volume(bus: StringName, linear: float) -> void      # applies and saves
func preview_volume(bus: StringName, linear: float) -> void  # applies only (slider being dragged)
func set_fullscreen(value: bool) -> void        # applies and saves
func set_vsync(value: bool) -> void
func set_damage_numbers(value: bool) -> void
```

  - Les noms de bus viennent des constantes `&"Master"`, `&"Music"`, `&"SFX"`, `&"UI"` (déclarées une fois dans `Settings` ; `Audio.SFX_BUS` existe déjà, ne pas le dupliquer de façon divergente : réutiliser `Audio.SFX_BUS` ou centraliser, au choix, mais un seul littéral par bus). Un bus inconnu : `Log.error("audio", ...)` + `assert`, rien n'est appliqué.
  - Toute valeur est **bornée** avant d'être gardée (`clampf(linear, 0.0, 1.0)`, et une valeur non finie retombe sur le défaut).
  - Un setter qui reçoit la valeur courante ne réécrit pas le fichier.
- **Application au moteur** :
  - volume : `AudioServer.set_bus_volume_linear(index, linear)` (existe en 4.7, équivaut à `set_bus_volume_db(linear_to_db(v))`) **et** `AudioServer.set_bus_mute(index, linear <= 0.0)` (`linear_to_db(0)` vaut −∞) ;
  - plein écran : `get_window().mode = Window.MODE_FULLSCREEN` ou `Window.MODE_WINDOWED` (plein écran **sans bordure**, pas `MODE_EXCLUSIVE_FULLSCREEN` : le choix exclusif, s'il améliore la latence, revient à la story 1.8) ; en revenant au fenêtré, vérifier que la fenêtre retrouve au moins 1280×720 et que `Main` relogue le bon facteur d'échelle ;
  - VSync : `DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)` ou `VSYNC_DISABLED` (mailbox : story 1.8).
- **Démarrage** (`_ready()`) : charger, valider, appliquer tout. **Ne jamais écrire** le fichier au démarrage : un fichier absent reste absent jusqu'au premier changement de réglage.
  - `config.load(FILE_PATH)` renvoie `ERR_FILE_NOT_FOUND` → `Log.warn("save", "settings.cfg missing, using defaults")` (CA 4 l'exige, même au premier lancement).
  - Toute autre erreur (fichier illisible) → renommer le fichier en `settings.cfg.corrupt` (AR18 ; écraser un ancien `.corrupt`), `Log.warn("save", ...)` avec le code d'erreur, valeurs par défaut.
  - Clé absente → défaut, sans log. Clé de mauvais type ou hors bornes → défaut (ou valeur bornée), **un** `Log.warn` par clé fautive.
  - L'ordre des autoloads place `Settings` après `Log` et avant `Audio` : les bus existent déjà (chargés par l'`AudioServer` au démarrage du moteur), le vérifier une fois (`AudioServer.get_bus_index(&"Music") != -1`).
- **Écriture atomique** (`_save()`, appelée par chaque setter qui change une valeur) :
  1. remplir un `ConfigFile` neuf depuis les valeurs courantes ;
  2. `config.save(FILE_PATH + ".tmp")` ; en cas d'erreur, `Log.error("save", ...)` et s'arrêter (le fichier existant reste intact) ;
  3. `DirAccess.rename_absolute(tmp, FILE_PATH)` ; en cas d'erreur, `Log.error`. **À vérifier** (Context7 ou essai) : sous Windows, `rename` doit remplacer un fichier existant. Si ce n'est pas le cas en 4.7.2, supprimer la cible juste avant de renommer et consigner la fenêtre non atomique dans les décisions.
  - Aucun log à chaque écriture réussie (`Log.debug` au plus).
  - L'architecture prévoit l'écriture atomique aussi pour `run.json` et `profile.json` (6.8) : **ne pas factoriser maintenant** (prototype rapide) ; une fonction privée dans `Settings` suffit, la story 6.8 la déplacera si besoin.
- **Curseur de volume glissé** : `HSlider.value_changed` arrive à chaque pixel. Le menu appelle `preview_volume()` pendant le glissement (entre `drag_started` et `drag_ended`) et `set_volume()` à `drag_ended` et pour tout changement hors glissement (clavier, manette, clic sur la piste). Le son change donc aussitôt (CA 2) sans écrire 60 fichiers par seconde.
- **Testabilité** : prévoir une méthode publique `load_from(path: String)` (ou un chemin modifiable) pour que les scripts de vérification travaillent sur `user://settings_test.cfg` sans écraser les réglages réels de Kroustille. Sinon, sauvegarder et restaurer le vrai fichier autour des tests.

### Entrées (D6, AR12)

Dans `project.godot`, section `[input]`, même forme que les actions existantes :

| Action | Clavier | Manette |
|---|---|---|
| `pause` | Échap (`physical_keycode` 4194305, `KEY_ESCAPE`) | Start (`InputEventJoypadButton`, `button_index` 6, `JOY_BUTTON_START`) |

- Le nom `pause` est celui de l'architecture (D6). Ne pas créer d'autres actions (1.7).
- La navigation dans les menus utilise les actions `ui_*` intégrées de Godot (`ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_accept`, `ui_cancel`), qui couvrent déjà flèches, croix directionnelle, stick gauche, Entrée/Espace, A et B, Échap. Ne pas les redéfinir. Vérifier une fois par `InputMap.action_get_events(&"ui_down")` qu'un événement de manette y figure.
- Formes sérialisées : clavier comme `dash` (`InputEventKey`, `physical_keycode`) ; Start comme le RB de `dash` (`InputEventJoypadButton`, `"button_index":6,"pressure":0.0,"pressed":true`). Puis `godot --headless --path game --import` et vérifier qu'aucun bruit parasite n'apparaît dans `project.godot`.

### `Main` et la pause (D7, D14, CA 1, 6, 7, 10)

Décision qui règle le report de la revue de 1.1 : **la pause n'utilise pas `SceneTree.paused`**. Mettre l'arbre en pause figerait aussi les autoloads (les lecteurs d'`Audio`, donc les sons d'interface à venir) et `Main` lui-même ; il faudrait passer une dizaine de nœuds en `PROCESS_MODE_ALWAYS`. À la place, `Main` désactive **seulement l'arbre de jeu** :

```gdscript
## The only place that pauses or resumes the game (story 1.6). Never use get_tree().paused.
func _set_paused(value: bool) -> void:
	if value == GameClock.paused:
		return
	GameClock.paused = value
	_active_scene.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	...  # show or hide the pause menu, focus
	Log.info("ui", "game %s" % ("paused" if value else "resumed"))
```

- `PROCESS_MODE_DISABLED` coupe `_process`, `_physics_process` **et** les rappels d'entrée de tout ce qui est sous `ActiveScene` (joueur, réticule, `BulletManager`, cibles, `HitFeedback`, chiffres de dégâts) ; `GameClock.paused` met à 0 toute échelle lue ailleurs (rien aujourd'hui, mais c'est l'API que le gameplay lit). Les deux sont écrits **au même endroit**, jamais séparément.
- `UI` (menus, F2, F3) et les autoloads ne sont pas sous `ActiveScene` : ils continuent de tourner. Aucun `process_mode = ALWAYS` à ajouter aux menus.
- **Interpolation physique** : un nœud interpolé qui cesse d'être traité garde ses deux transformations de tick ; vérifier **en fenêtré**, joueur lancé à pleine vitesse au moment de la pause, que le sprite ne tremble pas. S'il tremble, appeler `reset_physics_interpolation()` sur les nœuds concernés au moment de la pause (vérifier dans la doc 4.7 si l'appel se propage aux enfants) et le consigner.
- **Entrées de `Main`** — réorganiser `_unhandled_input()` :
  1. `pause` (tous builds) : si le jeu n'est pas en pause → `_set_paused(true)`, `set_input_as_handled()`. Quand le jeu est en pause, ce sont les menus qui consomment `pause` et `ui_cancel` (ils reçoivent l'entrée **avant** `Main`, car ils sont plus profonds dans l'arbre : à vérifier) et demandent la reprise par signal.
  2. F5 et F4 (debug seulement, comme aujourd'hui) **et seulement hors pause** : une scène chargée sous un `ActiveScene` désactivé serait figée.
  3. Le reste ne change pas (`_show_scene`, suivi de la fenêtre, vérifications de debug).
- Les menus sont **instanciés par `Main` dans `UI`** au démarrage (cachés), dans cet ordre : après `PerfOverlay`, pour être dessinés au-dessus. `Main` relie leurs signaux locaux :
  - `PauseMenu.resume_requested` → `_set_paused(false)` ;
  - `PauseMenu.settings_requested` → cacher le menu de pause, montrer `SettingsMenu` ;
  - `PauseMenu.quit_requested` → `Log.info("ui", "quit requested from the pause menu")`, puis `get_tree().quit()` (au jalon A il n'y a pas d'écran titre : Quitter ferme le jeu ; les réglages sont déjà écrits) ;
  - `SettingsMenu.back_requested` → cacher les réglages, remontrer le menu de pause, focus sur le bouton Réglages.
- **Aucun tir parasite à la reprise** : les `Button` gardent `action_mode = ACTION_MODE_BUTTON_RELEASE` (défaut). Le clic qui valide « Reprendre » est donc déjà relâché quand le joueur relit `shoot`. Le vérifier en fenêtré (clic sur Reprendre → aucun tir).
- Pause pendant le test de charge (F5) : autorisée, sans effet particulier (le test de charge se fige aussi).

### Menus (FR10, FR66, AR22, CA 1, 2, 5, 9)

Deux scènes dans `game/ui/menus/` (arborescence de l'architecture : « menus : pause, death, settings, keybinds, seed_entry »). Nœuds `Control`, conteneurs (`CenterContainer`, `PanelContainer`, `VBoxContainer`, `GridContainer`), **aucune position en dur** hormis des marges. Racine plein écran (`anchors_preset = 15`), avec un fond `ColorRect` sombre semi-transparent (`mouse_filter = STOP` : il bloque les clics vers le jeu).

**`PauseMenu`** (`pause_menu.tscn`, `class_name PauseMenu extends Control`) :
- Titre (`UI_PAUSE_TITLE`) et trois `Button` : Reprendre, Réglages, Quitter.
- Signaux locaux : `resume_requested`, `settings_requested`, `quit_requested`.
- `open()` : `show()`, focus sur Reprendre. `_unhandled_input` : `pause` ou `ui_cancel` → `resume_requested.emit()` + `set_input_as_handled()` (seulement si visible).

**`SettingsMenu`** (`settings_menu.tscn`, `class_name SettingsMenu extends Control`) :
- Titre (`UI_SETTINGS_TITLE`) ; quatre lignes de volume (libellé, `HSlider` de 0 à 100 au pas de 5, valeur affichée en pourcentage) ; trois `CheckButton` (plein écran, VSync, chiffres de dégâts) ; un bouton Retour.
- `open()` : relit **toutes** les valeurs dans `Settings` (sans déclencher d'écriture : utiliser `set_value_no_signal()` / `set_pressed_no_signal()`), `show()`, focus sur le premier curseur.
- Les widgets appellent les setters de `Settings` (règle des frontières : `ui/` ne modifie que les réglages, et seulement via `Settings`). Curseurs : `preview_volume()` pendant le glissement, `set_volume()` sinon (voir « `Settings` »).
- `_unhandled_input` : `pause` ou `ui_cancel` → `back_requested.emit()` (seulement si visible).
- Signal local : `back_requested`.
- Tout tient dans 640×360 avec la bande de HUD libre ou non (le menu recouvre l'écran) : 1 titre + 8 lignes d'environ 18 px. Vérifier sur une capture qu'aucun texte n'est coupé.

**Textes** (CA 5) : tous assignés **en code** par `tr(&"CLE")` dans `_ready()` (le critère cite `tr("CLE")` : pas de texte littéral dans les `.tscn`, ni de reliance implicite sur la traduction automatique des `Control`). Les pourcentages par `tr(&"UI_SETTINGS_PERCENT") % valeur`. Aucun texte français dans le code.

**Focus visible** : le thème doit dessiner un style `focus` net (contour 1 px), sinon la navigation à la manette est aveugle.

### Localisation (NFR10, AR22, D16)

`game/localization/strings.csv`, UTF-8, séparateur virgule, première ligne `keys,fr` (Godot 4.7 : la première colonne contient les clés, son en-tête est libre ; les autres en-têtes sont des locales ; les colonnes qui commencent par `_` sont ignorées — une colonne `_comment` est permise). Clés `UPPER_SNAKE_CASE` préfixées par domaine (architecture, « Assets ») :

```csv
keys,fr
UI_PAUSE_TITLE,Pause
UI_PAUSE_RESUME,Reprendre
UI_PAUSE_SETTINGS,Réglages
UI_PAUSE_QUIT,Quitter
UI_SETTINGS_TITLE,Réglages
UI_SETTINGS_VOLUME_MASTER,Volume général
UI_SETTINGS_VOLUME_MUSIC,Musique
UI_SETTINGS_VOLUME_SFX,Effets sonores
UI_SETTINGS_VOLUME_UI,Interface
UI_SETTINGS_FULLSCREEN,Plein écran
UI_SETTINGS_VSYNC,Synchronisation verticale
UI_SETTINGS_DAMAGE_NUMBERS,Chiffres de dégâts
UI_SETTINGS_BACK,Retour
UI_SETTINGS_PERCENT,%d %%
```

- `UI_SETTINGS_PERCENT` : espace **insécable** (U+00A0) entre le nombre et `%` (typographie française) ; `%%` parce que la chaîne passe par l'opérateur `%` de GDScript. Vérifier que la police a le glyphe U+00A0 (sinon espace normale, à consigner).
- L'import du CSV génère `strings.fr.translation` et l'ajoute à `internationalization/locale/translations` dans `project.godot` (en headless, vérifier que l'import le fait ; sinon l'écrire à la main).
- **Langue de repli** : `internationalization/locale/fallback="fr"` dans `project.godot`. Sans cela, sur un système en anglais, Godot cherche `en`, ne trouve rien et affiche **les clés**. Vérifier : `TranslationServer.translate(&"UI_PAUSE_RESUME") == "Reprendre"` quelle que soit la locale du système (forcer `TranslationServer.set_locale("en")` dans un test).
- Versionnage : le `.csv`, son `.csv.import` ; le `.translation` généré est régénérable (regarder où Godot l'écrit ; s'il est à côté du CSV, le versionner seulement si l'export en a besoin sans réimport, sinon l'ignorer). Consigner le choix.
- Les chiffres de dégâts sont des **nombres**, pas des textes : pas de `tr()` pour eux (à consigner).

### Police et `Theme` (AR22, D16, CA 5)

**Police pixel** : aucune n'existe dans le dépôt ni sur la machine (seule DejaVu, non pixel). En télécharger une, avec ces critères :

- licence **CC0 ou SIL OFL** (redistribuable dans un jeu commercial), **vérifiée sur la page d'origine au moment du téléchargement** ; copier le fichier de licence à côté de la police (`ui/theme/fonts/<nom>_LICENSE.txt`) et citer la source dans les Completion Notes ;
- glyphes **Latin-1** au minimum (é, è, ê, à, â, ç, ù, ô, î, ï, plus `%` et U+00A0) : tester l'affichage de « Réglages », « général », « écran », « dégâts » sur une capture ;
- hauteur utile **lisible à 640×360** (environ 8 à 12 px de capitales), et **une taille native** à laquelle elle est nette ;
- candidats possibles (à vérifier, pas une obligation) : Pixel Operator (Jayvee Enaguas), m5x7 / m6x11 (Daniel Linssen). Si aucun ne convient ou si le téléchargement échoue, **s'arrêter et demander à Kroustille** plutôt que de dessiner une police.

Emplacement : `game/ui/theme/fonts/` (architecture). Téléchargement par `curl` dans un dossier vide du scratchpad, vérification, puis copie dans le dépôt.

**Import net** : dans le `.ttf.import` (ou par `FontFile` en `.tres`), anticrénelage **désactivé** (`antialiasing=0`), `hinting=0`, `subpixel_positioning=0`, `generate_mipmaps=false`, `multichannel_signed_distance_field=false`. Vérifier les noms exacts des options d'import en 4.7 (Context7, `ResourceImporterDynamicFont`) puis réimporter. La police s'utilise **à sa taille native** (ou un multiple entier) : c'est le viewport 640×360 qui est mis à l'échelle ×2, ×3…, pas la police.

**`ui/theme/theme.tres`** (`Theme`, écrit à la main ou en code puis sauvegardé une fois ; c'est un `.tres` de `ui/`, pas de `data/`) :
- `default_font` = la police pixel, `default_font_size` = sa taille native ;
- `StyleBoxFlat` sans arrondi ni anticrénelage (`anti_aliasing = false`) pour `Button` (`normal`, `hover`, `pressed`, `focus`, `disabled`), `PanelContainer`/`Panel` (`panel`), et un style `focus` à contour 1 px bien visible ; couleurs **provisoires** (palette de l'Endormissement : story 7.2) ;
- `HSlider` et `CheckButton` peuvent garder les icônes par défaut si elles restent nettes ; sinon, des `StyleBoxFlat` simples.
- Déclaré thème du projet : `gui/theme/custom="res://ui/theme/theme.tres"` dans `project.godot`. Tous les `Control` l'utilisent, y compris le `Label` de `PerfOverlay` et ceux des chiffres de dégâts : **un seul thème** (D16). Ne pas affecter `theme` nœud par nœud.

### Réticule et curseur pendant la pause (CA 8)

`player/reticle.gd` est sous `ActiveScene` : désactivé pendant la pause, son `_process` ne tourne plus. Il reçoit `NOTIFICATION_DISABLED` quand un ancêtre passe en `PROCESS_MODE_DISABLED`, et `NOTIFICATION_ENABLED` au retour (constantes de `Node` ; **vérifier en 4.7** que le changement de `process_mode` d'un ancêtre les propage, par un essai headless qui compte les notifications) :

```gdscript
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DISABLED:
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		NOTIFICATION_ENABLED:
			visible = true
			if _player != null:
				Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
```

- Le réticule reste propriétaire du curseur (comme en 1.5) : `Main` ne touche pas à `Input.mouse_mode`.
- Si les notifications ne se propagent pas, repli : `Main` émet `Events.game_paused(paused: bool)` après `_set_paused()`, et le réticule s'y abonne. Consigner le choix.
- `Input.mouse_mode` est ignoré en headless : CA 8 se vérifie en fenêtré.

### Chiffres de dégâts (FR6, CA 3)

Désactivés par défaut. Quand `Settings.damage_numbers` est vrai, chaque coup sur une `Hurtbox` du camp ennemi affiche son montant au-dessus de la cible.

**Pourquoi par `Events`** : `Hurtbox.receive()` est le point de passage unique des dégâts ; les ennemis de l'epic 2 en bénéficieront sans code ; la télémétrie (AR25) pourra écouter le même signal ; et le chiffre doit **survivre à sa cible** (un ennemi tué par le coup, story 2.1), donc il ne peut pas être son enfant.

1. **`autoloads/events.gd`** : premier signal du bus.

```gdscript
## An enemy hurtbox took damage. world_position: top center of its rectangle (damage numbers, telemetry).
signal enemy_damaged(world_position: Vector2, amount: float)
```

   Types primitifs seulement : `autoloads/` ne dépend d'aucun dossier de fonctionnalité (pas de `BulletManager.Camp` ni de `DamageInfo` dans la signature).

2. **`combat/hurtbox.gd`**, `receive()` : après `damage_received.emit(info)`, si `camp == BulletManager.Camp.ENEMY` et que le rectangle existe, `Events.enemy_damaged.emit(Vector2(rect.get_center().x, rect.position.y), info.amount)`. Aucun log.

3. **`vfx/damage_numbers.gd`** (`class_name DamageNumbers extends Node2D`) : couche des chiffres d'une salle, dans le monde.
   - Créée **en code** par `Arena._ready()` et ajoutée **après** `PlayerBullets` (dessinée au-dessus des tirs) ; à l'origine de l'arène.
   - `_ready()` : `Events.enemy_damaged.connect(_on_events_enemy_damaged)` ; `_exit_tree()` : déconnecter (l'arène est recréée par F5).
   - `_on_events_enemy_damaged(world_position, amount)` : si `not Settings.damage_numbers`, ne rien faire ; sinon créer un `DamageNumber` (`setup(amount)` **avant** `add_child()`), position = `to_local(world_position)` + un petit décalage vers le haut.
   - Pas de pool : quelques nœuds par seconde au plus (4 tirs/s). L'architecture n'impose un pool qu'aux projectiles et effets d'impact ; si le profilage le demande plus tard, on en ajoutera un.
   - Activer le réglage pendant la partie prend effet au coup suivant (la valeur est lue à chaque coup) ; le désactiver laisse finir les chiffres déjà affichés.

4. **`vfx/damage_number.gd`** (`class_name DamageNumber extends Label`, ou un `Node2D` qui contient un `Label`) :
   - texte `str(roundi(amount))` (10 pour un tir) ; police du thème du projet ;
   - monte de quelques pixels puis disparaît (transparence), en **ticks de jeu** du groupe `GameClock.Group.FX`, dans `_physics_process` (figé en pause, ralenti sous F4) ; pas de `Timer`, pas de `Tween` lié au temps réel ;
   - position arrondie au pixel entier à chaque tick (netteté de la police pixel) ; `physics_interpolation_mode = OFF` si le mouvement saccade ou traîne ;
   - les valeurs de présentation (durée ≈ 0,5 s, montée ≈ 8 px, couleur blanche avec contour sombre) ne figurent pas dans le GDD : **constantes locales visuelles**, comme celles du réticule, à commenter « placeholder until epic 7 » ;
   - texte centré au-dessus du point d'impact (largeur du `Label` calculée ou `horizontal_alignment = CENTER` avec une largeur fixe) ;
   - se libère tout seul (`queue_free()`) à la fin.

5. Les chiffres sont sous `ActiveScene` → figés pendant la pause (CA 7), détruits avec l'arène (F5).

### Règles d'architecture qui s'appliquent

- GDScript typé partout (AR2) ; fichiers et dossiers en `snake_case`, un script par classe, nœud racine d'une scène en `PascalCase` (`pause_menu.tscn` → `PauseMenu`), constantes `UPPER_SNAKE_CASE`, membres privés `_`, signaux au passé (`resume_requested`, `enemy_damaged`), gestionnaires `_on_<émetteur>_<signal>` (`_on_pause_menu_resume_requested`, `_on_events_enemy_damaged`). Code, commentaires, logs et noms de fichiers **en anglais**.
- **Temps** (AR13) : pas de `Timer`, `create_timer`, `Engine.time_scale`, ni `SceneTree.paused`. Les chiffres de dégâts comptent en ticks × `GameClock.scale(FX)`.
- **Communication** (D3) : enfant → parent par signal local (menus → `Main`) ; parent → enfant par appel direct (`Main` → `open()`) ; transverse par `Events` (`enemy_damaged`). Le bus ne porte que des notifications.
- **Frontières** : `ui/` ne lit l'état que par signaux et ne modifie que les réglages via `Settings` ; `autoloads/` et `core/` ne dépendent d'aucun dossier de fonctionnalité ; `vfx/` ne dépend que des autoloads et de `core/` ; rien ne dépend de `debug/`.
- **Textes** : `tr()` partout dans `ui/` ; aucune chaîne française dans le code ; les textes techniques de `debug/` restent exemptés (déjà documenté).
- **Logs** (AR27) : `Log.info("ui", ...)` pour pause, reprise et quitter ; `Log.warn("save", ...)` pour un fichier absent ou illisible ; rien par frame, rien par coup.
- **Erreurs** (AR28) : un réglage invalide ou un fichier illisible ne bloque jamais le démarrage ; une écriture qui échoue est journalisée et le jeu continue.
- **Données** (AR9) : aucune valeur du GDD n'est concernée par cette story ; ne rien ajouter à `Tuning`.

### Arborescence attendue à la fin de la story

```
game/
├── project.godot                         (UPDATE : action pause, gui/theme/custom, traductions, langue de repli)
├── autoloads/
│   ├── settings.gd                       (UPDATE : réglages persistants)
│   └── events.gd                         (UPDATE : enemy_damaged)
├── main/main.gd                          (UPDATE : pause, menus, entrées)
├── combat/hurtbox.gd                     (UPDATE : émet enemy_damaged)
├── player/reticle.gd                     (UPDATE : curseur pendant la pause)
├── rooms/arena/arena.gd                  (UPDATE : couche DamageNumbers)
├── vfx/
│   ├── damage_numbers.gd                 (NEW)
│   └── damage_number.gd                  (NEW)
├── ui/
│   ├── theme/
│   │   ├── theme.tres                    (NEW)
│   │   └── fonts/<police>.ttf + licence  (NEW, + .import)
│   └── menus/
│       ├── pause_menu.tscn / .gd         (NEW)
│       └── settings_menu.tscn / .gd      (NEW)
└── localization/strings.csv              (NEW, + .import)
```

Mettre à jour aussi `_bmad-output/game-architecture.md` (T1) et `deferred-work.md` (T13). Ne pas toucher à `audio.gd`, `game_clock.gd` (sauf si le repli `Events.game_paused` est retenu : alors `events.gd` seulement), `player.gd`, `bullet_manager.gd`, `save_service.gd`, ni aux scènes de `debug/`.

### Stratégie de test

Aucun framework de test (AR26 : avant le jalon B). Scripts jetables du scratchpad, lancés comme scène (`godot --headless --path game --scene <scène>`), avec `await get_tree().physics_frame` pour avancer au tick. Les réglages réels ne doivent pas être écrasés (voir « Testabilité »).

1. **Import et lancement** : `--import` puis `--quit-after 120` : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucun avertissement nouveau ; `project.godot` sans bruit parasite ; la police, le CSV et le thème sont importés.
2. **Localisation** : avec `TranslationServer.set_locale("en")` puis `"fr"`, `tr(&"UI_PAUSE_RESUME") == "Reprendre"` et `tr(&"UI_SETTINGS_FULLSCREEN") == "Plein écran"` ; aucune clé du CSV ne se traduit par elle-même ; recherche de chaînes littérales françaises dans `game/ui/` et `game/vfx/` : aucune.
3. **`Settings`** :
   - fichier absent → valeurs par défaut (`vsync == true`, `damage_numbers == false`, volumes à 1,0, `fullscreen == false`) et **un** `Log.warn` ; aucun fichier créé au démarrage ;
   - fichier illisible (texte invalide écrit à la main) → défauts, `Log.warn`, fichier renommé en `.corrupt` ;
   - clé de mauvais type (`master="abc"`) ou hors bornes (`sfx=5.0`) → défaut ou borne, un `Log.warn` par clé ;
   - `set_volume(&"SFX", 0.5)` → `AudioServer.get_bus_volume_linear(SFX) ≈ 0.5`, le fichier contient `sfx=0.5`, aucun `.tmp` ne traîne ; `set_volume(&"Music", 0.0)` → bus `Music` muet ; `preview_volume()` applique sans écrire (date de modification ou contenu inchangé) ;
   - `set_damage_numbers(true)`, `set_vsync(false)`, `set_fullscreen(true)` → écrits ; **relancer le jeu** (nouveau processus) et constater la restauration des sept valeurs (CA 2) ; puis remettre les valeurs par défaut ;
   - bus inconnu → refus, `Log.error`.
4. **Pause** (dans l'arène, attendre un tick après l'entrée) :
   - action `pause` simulée (`Input.parse_input_event` d'un `InputEventAction` ou d'une touche Échap, attendre un tick) → `GameClock.paused == true`, `ActiveScene.process_mode == PROCESS_MODE_DISABLED`, `get_tree().paused == false`, `Engine.time_scale == 1.0`, menu de pause visible avec focus sur Reprendre ;
   - pendant 60 ticks de pause avec `move_right`, `shoot` et `dash` tenus : position du joueur, nombre et positions des tirs, paramètre `flash` d'une cible touchée juste avant, position d'un chiffre de dégâts : **inchangés** ;
   - `pause` de nouveau → reprise ; le joueur repart ; un tir en vol reprend sa course à la même vitesse ;
   - `ui_cancel` dans le menu de pause → reprise ; Réglages → menu des réglages, focus sur le premier curseur ; `ui_cancel` → retour au menu de pause, focus sur Réglages ; `pause` depuis les réglages → retour au menu de pause (et non reprise directe) ;
   - F5 et F4 simulés pendant la pause → ignorés (scène et `global_multiplier` inchangés) ; F3 et F2 → basculent ;
   - Quitter → `get_tree().quit()` appelé (vérifier par un log ou en le laissant fermer le processus du test).
   - **Notifications** : compter `NOTIFICATION_DISABLED` / `ENABLED` reçues par le réticule à la pause et à la reprise (1 et 1).
5. **Chiffres de dégâts** :
   - réglage désactivé : un tir touche une cible → `Events.enemy_damaged` émis une fois (position = haut centre du rectangle de la hurtbox, `amount = 10`), **aucun** `DamageNumber` créé ;
   - réglage activé : un `DamageNumber` dont le texte est `"10"`, au-dessus de la cible, qui monte puis se libère au bout de la durée prévue (en ticks) ; figé en pause ; quatre fois plus lent sous F4 ;
   - F5 aller-retour : aucun signal connecté à une couche libérée (pas d'erreur au coup suivant).
6. **Fenêtré sous WSLg** (indicatif, avec captures `get_viewport().get_texture().get_image().save_png()`) :
   - menus de pause et de réglages nets à ×2 et ×3, police pixel sans flou, accents corrects, aucun texte coupé, focus visible ;
   - curseur visible en pause et réticule caché, puis l'inverse à la reprise ; clic sur Reprendre → **aucun tir** ;
   - plein écran puis retour au fenêtré : facteur d'échelle relogué correct, fenêtre ≥ 1280×720 ;
   - joueur lancé à pleine vitesse puis pause : pas de tremblement du sprite (interpolation) ;
   - chiffre de dégâts lisible au-dessus d'une cible ; `PerfOverlay` (F3) toujours lisible avec la nouvelle police ;
   - curseur de volume SFX glissé pendant que le joueur tire (reprendre, tirer, revenir) : le volume change à l'oreille (étape humaine si personne n'écoute : à consigner).
7. **Régression** : marche (96 px/s), dash (48 px), tir (4 tirs/s, 224 px/s), F2, F3, F4, F5 et test de charge (`Bullets 400 | refused 0`) inchangés hors pause.
8. **Recherche des interdits** : `grep -rnE 'print\(|Timer|create_timer|time_scale|tree\(\)\.paused|randf|randi|randomize|shuffle|pick_random|/root/' game --include=*.gd` : seules les occurrences attendues (`log.gd`, commentaires). Aucun `Log.` dans `_process`, `_physics_process` ni dans les gestionnaires par coup.
9. **Étapes humaines** (à consigner, ne pas déclarer vérifiées) : Start et B sur une vraie manette (story 1.7), plein écran et VSync sous Windows natif (story 1.8), volumes à l'oreille.

### Commit

Directement sur `main`, Conventional Commits en anglais, `git push` après chaque commit (consigne du projet). Commiter par tâche cohérente, chaque commit laissant le jeu lançable. Exemples : `docs(architecture): add pause and settings terms to the lexicon` ; `feat(ui): add localization, pixel font and project theme` ; `feat(settings): persist player settings atomically in settings.cfg` ; `feat(ui): add pause and settings menus` ; `feat(combat): show optional damage numbers on enemy hits` ; `docs(story): record story 1.6 implementation progress`.

### Project Structure Notes

- Conforme à l'arborescence de l'architecture : `ui/menus/`, `ui/theme/theme.tres`, `ui/theme/fonts/`, `localization/strings.csv`, `autoloads/settings.gd`.
- **Écarts assumés** :
  - La pause désactive `ActiveScene` (`PROCESS_MODE_DISABLED`) au lieu de mettre le `SceneTree` en pause : l'architecture dit « `GameClock` et `process_mode` de l'arbre de jeu », c'est cette lecture qui est retenue (raisons dans « `Main` et la pause »).
  - Les chiffres de dégâts vivent dans `vfx/` (effet visuel du monde, sous `ActiveScene`), pas dans `ui/` (qui est la couche HUD et menus, hors du monde).
  - `Events.enemy_damaged` est un signal nouveau, non listé par l'architecture : il naît du besoin des chiffres de dégâts et servira à la télémétrie.
  - L'écriture atomique reste privée à `Settings` jusqu'à la story 6.8.

### Project Context Rules

Il n'y a pas de `project-context.md`. Règles tirées de `CLAUDE.md` et de la mémoire du projet :

- Conversation, documents de conception et artefacts BMAD : **français**. Code (identifiants, commentaires, noms de fichiers, messages de log) : **anglais**.
- Commits en anglais, Conventional Commits (`type(scope): description`, impératif, minuscules, sans point final), **directement sur `main`, sans branche**, avec un push vers `origin/main` aussitôt après chaque commit.
- **Textes affichés au joueur : fichiers de localisation, jamais en dur** — c'est le cœur de cette story (première story avec du texte joueur).
- Prototype rapide, itérations courtes : ne poser que ce que cette story exige.

### Décisions prises à la création de la story (modifiables)

1. **Pause = `GameClock.paused` + `ActiveScene` désactivé**, écrits ensemble par `Main` seul ; `SceneTree.paused` jamais utilisé (règle le report de 1.1 ; les lecteurs d'`Audio` ne se figent donc pas, ce qui règle aussi le report de la revue de 1.5 sur les sons d'interface).
2. **Quitter ferme le jeu** (pas d'écran titre au jalon A).
3. **Plein écran sans bordure** (`MODE_FULLSCREEN`) ; l'exclusif reste une option de la story 1.8.
4. **VSync en booléen** (activée / désactivée) ; mailbox éventuelle : story 1.8.
5. **Volumes linéaires de 0 à 100 % au pas de 5 %**, muet à 0, tous à 100 % par défaut.
6. **Curseur glissé : appliqué en continu, écrit au relâchement.**
7. **Fichier absent : avertissement journalisé** (le critère 4 le demande, même au premier lancement). Fichier illisible : renommé en `.corrupt`.
8. **Textes assignés en code par `tr()`**, aucun texte dans les `.tscn`.
9. **Chiffres de dégâts par `Events.enemy_damaged`** émis par `Hurtbox.receive()`, affichés par une couche `DamageNumbers` de la salle, sans pool, en ticks `FX`.
10. **Le réticule garde la propriété du curseur**, par `NOTIFICATION_DISABLED` / `ENABLED`.
11. **Langue de repli `fr`**, pour qu'un système en anglais affiche le français et non les clés.

### Questions ouvertes (sans effet bloquant sur le code)

1. **Pause automatique** quand la fenêtre perd le focus (alt-tab) : utile pour un jeu nerveux, non demandée par le GDD. À trancher au playtest.
2. **Aperçu sonore** en réglant `SFX` (rejouer le son de tir) et `UI` (aucun son d'interface n'existe encore) : non fait ; à ajouter avec les sons de la story 7.7.
3. **Valeurs par défaut des volumes** : 100 % partout ; un `Master` à 80 % est plus prudent pour les oreilles. À juger à l'écoute.
4. **Chiffres de dégâts** : durée, montée et couleur provisoires, à juger à l'œil ; faut-il les cumuler sur une même cible (tirs rapprochés qui se chevauchent) ?
5. **Choix de la police** : définitif ou provisoire jusqu'à l'epic 7 ? Proposé : provisoire, revue avec la story 7.2.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.6]
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences fonctionnelles] (FR6 : chiffres de dégâts désactivés par défaut ; FR10 ; FR66)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences non fonctionnelles] (NFR10)
- [Source: _bmad-output/planning-artifacts/epics.md#Exigences supplémentaires (architecture)] (AR8, AR13, AR18, AR22, AR27, AR28, AR32)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Contrôles] (Pause : Échap, Start)
- [Source: _bmad-output/planning-artifacts/gdds/gdd-hypnagogia-2026-11-20/gdd.md#Armes et tir] (chiffres de dégâts désactivés par défaut)
- [Source: _bmad-output/game-architecture.md#Temps (D7)] (pause par `GameClock` et `process_mode`, `Engine.time_scale` à 1)
- [Source: _bmad-output/game-architecture.md#Persistance des données] (`settings.cfg`, écriture atomique, `.corrupt`)
- [Source: _bmad-output/game-architecture.md#Configuration] (autoload `Settings` → `user://settings.cfg`)
- [Source: _bmad-output/game-architecture.md#UI et localisation (D16)] et [#Conventions de nommage] (clés `UI_PAUSE_RESUME`…)
- [Source: _bmad-output/game-architecture.md#Événements] et [#Frontières architecturales]
- [Source: _bmad-output/game-architecture.md#Structure du projet] (`ui/menus/`, `ui/theme/`, `localization/`)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] (`GameClock.paused` ↔ `SceneTree.paused` à trancher en 1.6 ; curseur en pause ; lecteurs `Audio` figés en pause)
- [Source: _bmad-output/implementation-artifacts/1-5-viser-et-tirer.md] (`Reticle`, `Hurtbox`, `Audio`, leçons de test headless)
- Documentation Godot 4.7 consultée par Context7 à la création : `ResourceImporterCSVTranslation` (première colonne = clés, en-tête libre, colonnes `_` ignorées), `AudioServer.set_bus_volume_linear`, `Node.process_mode` / `can_process()`.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

- Analyse de contexte terminée : guide d'implémentation complet créé (create-story, 2026-11-21).

### File List
