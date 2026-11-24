# Story 6.5 : S'endormir dans la chambre

Status: review

## Story

En tant que joueur,
je veux commencer chaque nuit dans la chambre et y revenir à chaque réveil,
afin que la boucle de run ait un lieu.

Exigences : FR62, AR20 (`Main` remplace `ActiveScene`, `Run` détruit et recréé) (epics.md, Story 6.5). Architecture : D14 (`Main` persistante, scène active `Bedroom` ou `Run`, relance < 3 s), `bedroom/` (« Hub »).

**Dépend de : 6.4** (issues de run, écran de réveil par issue), 4.11 (`SeedEntry`, `Events.run_requested`), 1.6 (pause, `Main._freeze`), 2.2 (relance directe < 3 s). **Prépare 6.6** (réveil de la chambre : nœud `AlarmClock` prévu ici, vide), **6.7** (profil lu au démarrage) et **6.8** (invite de reprise avant la chambre).

Hors périmètre : heure affichée (6.6), chambre qui change, histoire, journal (jalon C), sprites réels (epic 7).

## Critères d'acceptation

1. **Démarrage dans la chambre** : au lancement, `Main` met `Bedroom` dans `ActiveScene` (plus de `Run` au démarrage). Chambre minimale d'un écran (36×19 tuiles jouables, cadre de murs, caméra fixe via `RoomCamera.target`), personnage libre de ses déplacements aux vitesse et accélération du joueur (`Tuning.PLAYER`), arrêté par les murs et le mobilier, sans tir, dash ni pouvoir.
2. **Dormir** : près du lit (zone `BedZone`), une invite affiche la touche d'interaction lue dans l'`InputMap` (« Dormir (E) », `UI_BEDROOM_SLEEP`) ; l'action **`interact`** (nouvelle ; clavier E, manette X/Carré) fait remplacer `Bedroom` par un `Run` neuf via `Events.run_requested(FLOOR, -1, false, "")`, traité par `Main._start_run` (même chemin que la relance). Une seed tirée au hasard, `seeded = false`.
3. **État de départ** : la `Run` neuve démarre avec 3 cœurs (6 demi-cœurs), 100 de lucidité, 0 Éclat, aucun objet ni consommable ni actif, quelle que soit la run précédente ; rien ne fuit d'une `Run` détruite (test dédié).
4. **Retour à la chambre** : sur l'écran de réveil (mort ou victoire), un second bouton **« Retourner dans la chambre »** (`UI_WAKE_BEDROOM`) et l'action `ui_accept` quand il a le focus renvoient dans la chambre (`wake_up_requested` → `Main._enter_bedroom()`). L'écran garde « Se rendormir (R) » **par défaut et focalisé** : la relance directe démarre en moins de 3 s (mesurée, journalisée comme aujourd'hui : « restart requested N ms »).
5. **Seed avant de s'endormir** : un second point d'interaction près du lit (le bureau, `DeskZone`, « Saisir une seed (E) », `UI_BEDROOM_SEED`) ouvre la fenêtre `SeedEntry` ; une seed valide lance la run (`Events.run_requested(FLOOR, seed, true, "")`), Échap revient à la chambre sans rien changer. Les mouvements sont gelés pendant la saisie (voir pièges).
6. **HUD et carte masqués dans la chambre** (`Hud.visible = false`, `FloorMapView` délié) et réaffichés au départ d'une run ; le menu pause fonctionne dans la chambre (Reprendre, Réglages, Nouvelle partie avec une seed, Quitter).
7. **Une seule scène active** : aucune `Run` ne subsiste dans la chambre ; aucun nœud de la chambre ne subsiste dans la `Run` ; le chargement d'étage en arrière-plan commence au départ de la run (pas dans la chambre).

## Tâches

- [x] `project.godot` : action `interact` (E ; manette bouton X), sans toucher aux autres actions.
- [x] `bedroom/bedroom.tscn` + `bedroom.gd` : murs et sol (placeholders), lit, bureau, **réveil** (`AlarmClock`, `Label` masqué, rempli par 6.6), `BedZone`, `DeskZone` (`Area2D`), invite (`Label`, texte par `tr()` et touche de l'action), signaux `sleep_requested`, `seed_entry_requested`.
- [x] `bedroom/bedroom_walker.gd` : `CharacterBody2D`, `PlayerMotor` (déjà pur : `step(wish, dt)`), `Input.get_vector(move_*)`, `GameClock.scale(PLAYER)`, silhouette placeholder du joueur (16×24).
- [x] `main/main.gd` : `static var start_in_bedroom: bool = true` (les vérifications qui attendent une `Run` au démarrage le mettent à `false`, comme `default_mode`) ; `_ready()` appelle `_enter_bedroom()` ou `_start_run()` ; `_enter_bedroom()` (vide `ActiveScene`, masque HUD/carte, ferme les menus, dégèle) ; `_on_bedroom_sleep_requested`, `_on_bedroom_seed_entry_requested` ; `_start_run` réaffiche le HUD ; `Run.Outcome` inchangé.
- [x] `ui/menus/wake_screen.gd/.tscn` : bouton et signal `wake_up_requested`. `strings.csv` : `UI_BEDROOM_SLEEP`, `UI_BEDROOM_SEED`, `UI_WAKE_BEDROOM`.
- [x] Tests existants qui créent `Main` (`test_floor_start`, `test_seed_flow`, `test_run_requested`, `test_map_hold` et les scènes de `.scratch`) : `Main.start_in_bedroom = false` dans leur préparation ; ne pas modifier leurs assertions.
- [x] Tests.

## État du code concerné

- `Main._ready()` crée HUD, carte, menus, branche `run_ended`/`run_requested`/`run_started`, puis `_start_run()`. `_start_run(options)` : cache l'écran de réveil, ferme les menus, `_clear_active_scene()`, `_freeze(false)`, instancie `RUN_SCENE`, `setup(options)`, `add_child`. `_fresh_seed_options` garde mode et salle, tire une nouvelle seed.
- `_on_run_requested` est **l'unique point de départ d'une run** ; ne pas instancier de `Run` ailleurs.
- `Main._freeze(frozen)` pose `GameClock.paused` et `ActiveScene.process_mode`. `_set_paused` ignore l'écran de réveil ouvert (`_run_over`). `_seed_entry_from_wake` mémorise d'où la fenêtre a été ouverte : ajouter l'origine « chambre ».
- `WakeScreen` : `restart_requested`, `new_seed_requested`, `verdict_given`, garde d'entrée de 0,3 s. 6.4 lui a donné `open(seed_code, outcome)`.
- `RoomCamera.target(player_pos, frame_px, viewport, band_px)` est pure : la chambre l'utilise une fois (pièce d'un écran = caméra fixe centrée).
- `PlayerMotor` ne dépend d'aucun nœud. `Player` lui-même exige une `Room` (`enter_room`), des `BulletManager`, de la lucidité : **ne pas instancier `Player` dans la chambre**.
- `Settings`, `Audio`, `Telemetry` vivent tout le jeu ; `Telemetry` ne compte une run qu'à `run_started` (pas de run dans la chambre).

## Pièges

- `Input.parse_input_event()` s'applique au tick suivant (tests) : attendre un tick après l'appui de `interact`.
- Pendant la saisie de seed, les lettres W/A/S/D/E arrivent aussi à `Input.get_vector` et à `interact` : `Main` **gèle** la chambre (`_freeze(true)`) à l'ouverture de `SeedEntry`, la dégèle à la validation (la run remplace la scène) et à l'annulation.
- Une `Area2D` ne signale pas un corps déjà dedans à l'entrée dans l'arbre : tester l'invite avec un walker posé loin, puis déplacé (`await` un tick physique), pas avec un walker posé dans la zone.
- `_clear_active_scene()` retire d'abord les enfants (leurs groupes cessent de compter) puis `queue_free()` ; la chambre suit la même règle (pas de `free()` dans un callback de signal de la chambre).
- Le walker lit l'`InputMap` dans `_physics_process` et obéit à `GameClock` : gelé par la pause comme le reste. Ne pas utiliser `_unhandled_input` pour le déplacement.
- `Main` ouvre l'écran de réveil à `run_ended`, **dans le tick du coup**, la `Run` figée derrière : « Retourner dans la chambre » détruit la `Run` après coup (signal du bouton), jamais pendant l'émission de `run_ended`.
- Les menus et `HUD` sont des enfants de `UI` : `Hud.visible = false` ne coupe pas ses écouteurs (il suit toujours `Events`) ; ce n'est qu'un masque.
- Texte de touche : lire la première `InputEventKey` de l'action comme `WakeScreen._restart_key_label()` (fonctionne sans fenêtre).

## Tests (GUT)

- `unit/bedroom/test_bedroom_walker` : vitesse maximale et arrêt des murs ; gel sous `GameClock.paused`.
- `integration/bedroom/test_bedroom_flow` : `Main` (start_in_bedroom) démarre sur `Bedroom`, sans `Run` ni HUD visible ; invite visible seulement dans la zone du lit ; `interact` près du lit : une `Run` remplace la chambre, seed non saisie, HUD visible ; `interact` ailleurs : rien.
- `integration/bedroom/test_bedroom_seed` : le bureau ouvre `SeedEntry`, la chambre est gelée pendant la saisie ; seed valide : run `seeded` avec cette seed ; Échap : chambre dégelée, mouvement de nouveau possible.
- `integration/run/test_wake_to_bedroom` : mort puis « Retourner dans la chambre » : `Bedroom` active, `Run` libérée, rien de gelé ; victoire idem ; « Se rendormir » : `Run` neuve, délai journalisé < 3 s.
- `integration/run/test_fresh_run_state` : après une run avec objets, Éclats et cœurs perdus, la suivante repart à 6 demi-cœurs, 100 de lucidité, 0 Éclat, loadout vide, consommable et actif absents.

## Sources

epics.md (Story 6.5) ; GDD, Point de départ (3 cœurs, 100 de lucidité, 0 Éclat), Boucle de run (s'endormir depuis la chambre), Relance < 3 s ; architecture D14, AR20 ; stories 2.2 et 4.11.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Personnage de la chambre = marcheur minimal (`BedroomWalker`), pas le `Player`.** Raison : le `Player` est couplé à une `Room` (tir, lucidité, pas de sol sans salle) ; la chambre n'a besoin que de marcher. Écart à l'esprit d'AR20 sans le contredire.
2. **L'écran de réveil garde « Se rendormir » comme action par défaut** et ajoute « Retourner dans la chambre ». L'AC demande à la fois de revenir à la chambre et de garder la relance directe : les deux boutons réconcilient. Si tu préfères que la chambre soit le passage obligé, c'est un changement de focus et de bouton.
3. **Action d'entrée `interact` (E) créée**, touche et manette par défaut décidées ici ; remappage avec la story 1.7 (reportée).
4. **Bureau = saisie de seed**, le lit = dormir. L'AC dit « une option près du lit » ; un second objet évite un menu dans le lit.
5. **HUD masqué dans la chambre** (valeurs d'une run finie sans sens).
6. **`Main.start_in_bedroom` statique** (comme `default_mode`) : les vérifications existantes ne changent pas d'assertions.
7. **Pas de fondu entre la chambre et la run** : même échange immédiat que la relance. Un fondu est possible plus tard (`Transition`).
8. **La seed saisie est une run unique** (comportement de 4.11 conservé : « Se rendormir » après tire une nouvelle seed).
9. **Touche d'`interact` = X (clavier) et bouton A/Croix (manette), pas E / X-Carré.** Raison : E (`use_active`) et le bouton 2 de la manette (X/Carré, `use_active`) sont déjà pris ; `F` est pris par le panneau debug F1 (nouvelle run sur l'étage). X est libre côté debug (liste des touches du panneau relue) et sous la main gauche ; le bouton 0 est libre dans l'`InputMap` (il sert aussi à `ui_accept` dans les menus, sans conflit : la chambre est gelée ou les menus ont le focus). Les textes (« Dormir (X) ») lisent la touche dans l'`InputMap`.
10. **Pas de modification des tests existants** : `Main.start_in_bedroom = false` est posé une fois pour la suite GUT par un script `pre_run_script` (`tests/support/pre_run.gd`, branché dans `.gutconfig.json`) ; les tests de la chambre le remettent à `true` puis à `false`. Les scènes de `.scratch` le posent dans `th.gd` et `t_floor_main.gd`. Le défaut du jeu reste `true`.
11. **Origine de la fenêtre de seed** : le booléen `_seed_entry_from_wake` devient l'énum `Main.SeedOrigin { PAUSE, WAKE, BEDROOM }` ; Échap depuis la chambre dégèle et lâche le focus (sans rouvrir de menu).
12. **Chambre construite à la main (nœuds `StaticBody2D`/`ColorRect`), hors générateur de salles et validateur** : l'histoire ne les demande pas.

## Dev Agent Record

### Notes de complétion

- `Main` démarre dans la `Bedroom` (`start_in_bedroom`, vrai par défaut) ; `_enter_bedroom()` masque le HUD, délie la carte, ferme les menus, dégèle ; `_start_run` réaffiche le HUD. « Dormir » (`interact` près du lit) passe par `Events.run_requested(FLOOR, -1, false, "")`, le bureau gèle la chambre et ouvre `SeedEntry`.
- L'écran de réveil a un bouton `BedroomButton` / signal `wake_up_requested` ; « Se rendormir » reste focalisé par défaut. Le bouton partage la garde d'entrée de 0,3 s.
- Vérifié : GUT complet vert (752 tests dont les 18 nouveaux : walker, flux, seed, réveil vers la chambre, état neuf) ; `run_all.sh` normal ALL PASS ; `--quit-after 120` propre (la caméra de la chambre est en `process_callback = 0` comme celle des salles, sinon avertissement d'interpolation physique).
- NON ÉVALUÉ (humain) : sensation du marcheur (vitesse identique au joueur, pas d'accélération supplémentaire), lisibilité des placeholders (lit, bureau, invite), manette réelle (bouton A pour `interact`, navigation entre les trois boutons de l'écran de réveil).

### Liste des fichiers

`game/bedroom/{bedroom.gd,bedroom.tscn,bedroom_walker.gd}` (nouveaux), `game/main/main.gd`, `game/ui/menus/wake_screen.{gd,tscn}`, `game/project.godot` (action `interact`), `game/localization/strings.csv`, `game/.gutconfig.json`, `game/tests/support/pre_run.gd`, `game/tests/unit/bedroom/test_bedroom_walker.gd`, `game/tests/integration/bedroom/{test_bedroom_flow,test_bedroom_seed}.gd`, `game/tests/integration/run/{test_wake_to_bedroom,test_fresh_run_state}.gd`.

### Journal des modifications

- 2026-11-24 : chambre, marcheur, action `interact`, retour à la chambre depuis l'écran de réveil, tests ; statut `review`.
