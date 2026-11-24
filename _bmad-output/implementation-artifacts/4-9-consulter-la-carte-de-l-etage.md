# Story 4.9 : Consulter la carte de l'étage

Status: in-progress

## Story

En tant que joueur,
je veux une carte qui se révèle au fil de l'exploration,
afin de m'orienter et de choisir où aller.

Exigences : FR39 (carte) (epics.md, Story 4.9). GDD : carte de l'étage, Tab maintenu / Select maintenu ; « pas de carte à la Slay the Spire » (la carte ne sert qu'à s'orienter dans l'étage en cours). Architecture : `run/floor_map.gd`, `ui/map/floor_map_view.tscn`, AR22 (Control, `tr()`).

**Dépend de : 4.8** (`FloorMap` : `current`, `visited`, `cleared`, `Events.room_entered`) et **4.7** (`FloorLayout`, types de salle, connexions). Indépendante de 4.10 et 4.11.

Hors périmètre : carte des étages précédents (un seul étage au MVP), notes du joueur, icônes définitives (epic 7), choix de porte de fin d'étage 3 (sans carte, epic 11).

## Critères d'acceptation

1. **Action `map`** : nouvelle action d'`InputMap` (`project.godot`) : Tab au clavier, Select de la manette (`JOY_BUTTON_BACK`). Tant qu'elle est **maintenue**, la carte s'affiche par-dessus le jeu ; au relâchement elle disparaît. **Le jeu n'est pas mis en pause** (`GameClock.paused` inchangé, les ennemis bougent, le joueur peut bouger et tirer pendant que la carte est ouverte).
2. **Contenu** : les salles **visitées** sont dessinées pleines ; les salles **adjacentes** à une salle visitée et reliées à elle par une porte (pas les voisines de grille non reliées) apparaissent comme **inexplorées** (contour seul, plus sombre) ; les autres n'existent pas à l'écran. Les connexions entre deux salles connues dont au moins une est visitée sont tracées. La salle actuelle est **mise en évidence** (cadre vif).
3. **Icônes** : le trésor, la boutique et le cauchemar portent leur icône dès qu'ils sont **découverts** (visités ou adjacents-inexplorés connus de la carte) ; une salle vidée se distingue d'une salle visitée non vidée (marque « vidée »). Les grandes salles sont dessinées comme une salle, avec un double trait (une salle = une cellule, 4.7).
4. **Modèle pur** : `FloorMap.entries() -> Array[Dictionary]` (`cell`, `state` : `VISITED` / `UNEXPLORED`, `type`, `size_kind`, `current`, `cleared`, `links` : cellules reliées connues) calculé à partir de `FloorLayout` et de l'état (`visited`, `cleared`, `current`). Aucune lecture de nœud : testable sans scène.
5. **Vue** : `FloorMapView` (`ui/map/floor_map_view.gd/.tscn`, `Control` plein écran dans la couche `UI` de `Main`, ajoutée sous les menus et au-dessus du HUD) ; calcule la géométrie par `static cell_rect(cell, bounds, area)` pour tenir dans la zone libre (sous la bande de HUD de 24 px) quelle que soit l'étendue de l'étage ; dessin en `_draw()` (formes provisoires, pas de texture) ; fond semi-transparent ; libellés par `tr()` (`UI_MAP_TITLE`, légende des 3 icônes).
6. **Visibilité** : jamais visible hors d'une `Run` en cours (pas à l'écran de réveil, pas dans le menu pause, pas en mode ARENA ou ROOM) ; mise à jour à l'ouverture et à chaque `Events.room_entered`/`room_cleared`, pas à chaque frame.
7. **Aucune interférence** : appuyer sur `map` ne consomme pas d'autre action ; en pause, Tab garde son rôle de focus dans les menus.

## Tâches

- [ ] `project.godot` : action `map` (clavier `physical_keycode` Tab, manette bouton Back) ; vérifier qu'aucune action existante ne l'utilise.
- [ ] `FloorMap` : `discovered`, `entries()`, `bounds()` ; `Run` remplit `current/visited/cleared` (4.8) ; `Run` expose `floor_map()` et la vue le lit via `Events` (signal `room_entered`) et un setter de la `Run` courante (`FloorMapView.bind(map, layout)` appelé par `Main` à `run_started`, `unbind` à la destruction) sans autoload.
- [ ] `FloorMapView` (+ scène), `Main` l'ajoute à `UI` (après le HUD, avant les menus) ; état `visible` piloté par `Input.is_action_pressed(&"map")` dans `_process` **et** `Run` active en mode FLOOR et `not GameClock.paused`.
- [ ] `strings.csv` : `UI_MAP_TITLE`, `UI_MAP_LEGEND_TREASURE`, `UI_MAP_LEGEND_SHOP`, `UI_MAP_LEGEND_NIGHTMARE`.
- [ ] Tests GUT : `tests/unit/run/test_floor_map.gd` (états après 0, 1, 3 salles visitées ; adjacence reliée seulement ; icônes ; vidée ; courante ; grandes salles) ; `tests/unit/ui/test_floor_map_view.gd` (`cell_rect` pour trois formes d'étage reste dans la zone et sans chevauchement) ; `tests/integration/ui/test_map_hold.gd` (`Input.action_press(&"map")`, un tick d'attente, visible ; `action_release` : caché ; le temps de jeu avance ; masqué pendant la pause).
- [ ] Capture WSLg de la carte pour juger la lisibilité (NON VÉRIFIÉ par un humain) ; `run_all.sh` du `.scratch`.

## État du code concerné

- `FloorMap` (4.8) ne porte que `current`, `visited`, `cleared`. `FloorLayout` (4.7) : `cells`, connexions, `door_sides(cell)`, types de salle (`Room.RoomType`), tailles.
- `Main._setup_menus()` ajoute wake screen, pause, réglages en dernier dans `UI` ; le HUD est `move_child(hud, 0)` ; le `PerfOverlay` est dans `main.tscn`. La vue de la carte s'insère entre le HUD et les menus.
- Aucune entrée de manette « Select » n'est définie ; `pause` utilise Échap / Start. `Input.is_action_pressed` ne dépend pas de la pause (autoloads et UI tournent pendant le gel : `Main` gèle `ActiveScene`, pas `UI`).
- Textes : `strings.csv` (clé, `fr`) ; tout texte passe par `tr(&"CLE")`.

## Pièges

- Tab est aussi `ui_focus_next` : si la vue est un `Control` avec `focus_mode`, elle volerait la navigation. Elle reste `mouse_filter = IGNORE`, `focus_mode = NONE`, et lit l'état par `Input`, pas par `_input`.
- Une `Control` dessinée par `_draw()` ne se redessine qu'avec `queue_redraw()` : l'appeler sur changement de modèle seulement.
- La couche `UI` suit le viewport (640×360) et pas la caméra : positions en pixels d'écran ; ne rien supposer des coordonnées du monde.
- L'échelle entière du stretch rend les traits d'un pixel nets ; dessiner avec des coordonnées entières (`Rect2` arrondi) pour éviter un flou.
- Le temps de jeu : l'overlay ne doit rien écrire dans `GameClock`.
- `Dictionary` d'entrées : trier par cellule (y, x) pour un ordre de dessin et de test stable.

## Fichiers prévus

`project.godot`, `run/floor_map.gd`, `run/run.gd`, `main/main.gd`, `ui/map/floor_map_view.gd/.tscn`, `localization/strings.csv`, `tests/**`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **« Découvert » = visité ou adjacent relié** : le trésor, la boutique et le cauchemar montrent leur icône dès qu'ils sont adjacents à une salle visitée (comme Isaac), pas seulement après visite. L'epic ne tranche pas ; le GDD interdit seulement une carte « à la Slay the Spire ».
2. **Les voisins non reliés par une porte restent invisibles** (une salle adjacente sur la grille mais sans porte n'est pas « adjacente » pour le joueur).
3. **Select = bouton Back de la manette** (Godot) ; Tab au clavier ; pas de réassignation avant l'epic 7.
4. **Carte masquée en pause, sur l'écran de réveil et hors mode étage** : un dessin par-dessus un menu n'aurait pas de sens.
5. **Pas de légende des types de salle courants** (combat, départ) : seules les trois icônes spéciales ont une légende.
6. **Marque « vidée »** ajoutée (non demandée) : elle aide à choisir où aller et ne coûte qu'un dessin.

7. **Géométrie stable** : la carte se dimensionne sur l étendue de tout l étage (pas sur les salles découvertes) pour ne pas se redimensionner à chaque salle ; elle révèle donc l emprise de l étage, pas son contenu.
8. `FloorMap.entries()` n a pas d argument : `Run` pose `FloorMap.layout`.
9. **Revue : icônes dès l'adjacence (décision 1) confirmée** : l'epic dit « une fois découverts » et l'AC 2 montre déjà les salles adjacentes reliées ; convention Isaac, aucun changement.
10. **Revue : la décision 7 est remplacée** : se caler sur l'emprise réelle de l'étage révèle sa forme (où la salle de départ se place dans le cadre dit où est le reste), contre « la carte se révèle au fil de l'exploration » (GDD). Choix : se caler sur la grille fixe du générateur (`FloorDef` 9×7, départ au centre) : géométrie toujours stable, aucune information. Converti en patch.
11. **Revue : le fond de la carte laisse la bande de HUD visible** : le jeu continue pendant que la carte est ouverte, les cœurs doivent rester lisibles. Converti en patch.

### Review Findings

Revue de code (Opus 5.5, 2026-11-24), trois couches (Blind Hunter, Edge Case Hunter, Acceptance Auditor) en passes isolées. Tests GUT de la story : 8/8, 4/4, 5/5.

- [ ] [Review][Patch] **Carte visible en mode arène après un repli** (AC 6) [`game/run/run.gd:256` et `:114`] : `_fall_back_to_arena()` remet `floor_layout` à null mais pas `floor_map.layout`, et `_start_floor()` pose `floor_map.layout` (`:106`) avant `_enter_cell(layout.start)` puis tombe sur l'arène si l'entrée échoue. Constaté par une scène jetable : après `_fall_back_to_arena()`, Tab affiche l'ancien étage par-dessus l'arène. Correction : `floor_map.layout = null` à côté de `floor_layout = null` (`:256`) et après `_loader = null` (`:114`).
- [ ] [Review][Patch] **La carte révèle l'emprise de l'étage** (décision 10) [`game/run/floor_map.gd:82` `bounds()`] : ajouter `var grid: Rect2i` à `FloorLayout`, posé par `FloorGenerator` (`layout.grid = bounds`, `game/generation/floor_generator.gd:41`) ; `bounds()` rend `layout.grid` quand il n'est pas vide (repli : le calcul actuel). Adapter `test_the_bounds_cover_the_whole_floor` et la décision 7 / la note de `deferred-work.md`.
- [ ] [Review][Patch] **Le fond assombrit le HUD pendant qu'on joue** (décision 11) [`game/ui/map/floor_map_view.gd:96`] : `draw_rect(Rect2(0, Const.HUD_BAND_HEIGHT, size.x, size.y - Const.HUD_BAND_HEIGHT), COLOR_BACKDROP)` au lieu du plein écran.
- [ ] [Review][Patch] **`Main` lie la carte à la première `Run` du groupe** [`game/main/main.gd:191`] : une `Run` hors de ce `Main` (autre `Main` dans l'arbre, scène de vérification) serait prise. Prendre la `Run` parmi les enfants de `_active_scene` (`for child in _active_scene.get_children(): if child is Run`).

Vérifié sans remarque : `entries()`/`discovered()` (adjacence par porte seulement, liens connus avec au moins une salle visitée, tri y puis x), ordre des abonnés à `room_cleared` (la `Run` marque avant que la vue relise), rafraîchissement au voyage, à la mort (masquée par `GameClock.paused`), au redémarrage (`unbind` puis `bind`) et au test de charge ; aucune écriture dans `GameClock` ; `mouse_filter` IGNORE, `focus_mode` NONE, lecture par `Input` (Tab garde `ui_focus_next` dans les menus) ; Tab et `JOY_BUTTON_BACK` (4) libres ailleurs ; couche : au-dessus du HUD, sous le `PerfOverlay`, le panneau de debug et les menus ; coordonnées entières ; 4 clés dans `strings.csv`. NON ÉVALUÉ : lisibilité réelle à 640×360 (pas de capture), déjà dans `deferred-work.md`.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `map` (Tab / `JOY_BUTTON_BACK`) ajoutée à `project.godot`. `FloorMap` : `layout` (posé par `Run._start_floor`), `State`, `entries()`, `discovered()`, `bounds()`. `FloorMapView` (Control plein écran, `_draw()`), insérée par `Main` à l indice 1 de `UI` (sous les menus, au-dessus du HUD), liée à `Run.floor_map` à `run_started`, déliée à `_clear_active_scene`. Visible si `map` est tenue, `layout` non nul et `not GameClock.paused` ; rafraîchie sur `room_entered`/`room_cleared`.
- Tests : GUT `test_floor_map_entries`, `test_floor_map_view`, `test_map_hold` ; `tools/run_tests.sh` 286/286, `run_all.sh` ALL PASS, `--quit-after 120` propre.
- NON VÉRIFIÉ par un humain : lisibilité réelle à 640×360 (pas de capture WSLg faite), icônes provisoires, Select sur une vraie manette. Voir `deferred-work.md`.

### File List

- `game/project.godot`, `game/localization/strings.csv`, `game/run/floor_map.gd`, `game/run/run.gd`, `game/main/main.gd`
- `game/ui/map/floor_map_view.gd`, `game/ui/map/floor_map_view.tscn`
- `game/tests/unit/run/test_floor_map_entries.gd`, `game/tests/unit/ui/test_floor_map_view.gd`, `game/tests/integration/ui/test_map_hold.gd`
