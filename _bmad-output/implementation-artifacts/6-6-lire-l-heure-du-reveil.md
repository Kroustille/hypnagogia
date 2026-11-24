# Story 6.6 : Lire l'heure du réveil

Status: done

## Story

En tant que joueur,
je veux que le réveil de la chambre affiche l'heure à laquelle je me suis réveillé,
afin de mesurer jusqu'où j'ai tenu.

Exigences : FR63 (epics.md, Story 6.6). GDD, Conditions de victoire, « L'heure du réveil » : la nuit commence à 23:00, chaque phase couvre 78 min, l'heure avance au prorata des salles de combat vidées, battre le cauchemar amène à l'heure de fin de phase (00:18). Architecture : `run/wake_clock.gd` (« Boucle de run, carte, heure du réveil, instantané »), `wake_time`.

**Dépend de : 6.5** (la chambre, son nœud `AlarmClock`, `Main._enter_bedroom`), 6.4 (issues, `Run.Outcome`, écran de réveil), 4.8 (`FloorMap.cleared`, `FloorLayout`). **Prépare 6.7** (l'heure de la dernière run sera persistée dans `profile.json`) et **6.8** (l'instantané porte l'heure).

Hors périmètre : étage secret (horloge bloquée sur 4:12), phases suivantes, indices de la chambre (jalon C).

## Critères d'acceptation

1. **`WakeClock`** (`run/wake_clock.gd`, `RefCounted` pur, sans nœud) lit `data/tuning/wake_tuning.tres` (`WakeTuning`, `Tuning.WAKE`) : `start_minute_of_day = 1380` (23:00), `phase_minutes = 78`, `death_cap_margin_minutes = 1`. Au début d'une run elle marque 23:00 ; la phase de l'Endormissement couvre 78 min ; aucune valeur en dur dans le script.
2. **Mort au prorata** : `minute_at(floor_index, cleared_combat_rooms, total_combat_rooms)` = début + `floor_index × phase` + `floori(phase × cleared / total)`. Exemple de l'epic : 6 salles de combat vidées sur 12, **23:39**. 0 vidée : 23:00. Les salles de départ, trésor, boutique et cauchemar ne comptent ni au numérateur ni au dénominateur ; `total` = nombre de cellules `COMBAT` du `FloorLayout` réel (12 par `onset.tres`, mais lu du plan, pas supposé).
3. **Victoire** : Le Professeur battu : l'heure est **00:18** (début + phase, fin de la phase).
4. **Plafond de la mort** : une mort ne lit jamais l'heure de fin de phase (celle de la victoire) : elle est plafonnée à `phase − death_cap_margin_minutes` (00:17), y compris un joueur qui meurt face au boss avec les 12 salles vidées.
5. **Formatage** : `WakeClock.format(minute) -> String` rend `HH:MM` sur 24 h, minuit franchi (`1458 → "00:18"`) ; entrées négatives ou non finies refusées (`--:--`, erreur journalisée).
6. **Calcul à la fin de la run** : `Run` calcule l'heure **avant** d'émettre `run_ended` (à la mort comme à la victoire), la range dans `RunState.wake_minute` et émet `Events.wake_time_set(minute)` juste avant `run_ended`. Les écouteurs de `run_ended` (Main, télémétrie, 6.7) lisent donc l'heure déjà posée. Sans plan d'étage (repli sur l'arène, salle seule) : 23:00, avec un `Log.warn`.
7. **Écran de réveil** : affiche l'heure (« Réveil : 23:39 », `UI_WAKE_TIME`), pour la mort comme pour la victoire.
8. **Chambre** : le réveil de la chambre (`AlarmClock` de 6.5) affiche l'heure de la **dernière run** ; `Main` retient `_last_wake_minute` en mémoire (−1 avant toute run : le réveil marque alors 23:00) et le donne à la chambre à chaque `_enter_bedroom()`. La persistance entre deux lancements du jeu est faite par 6.7.
9. **Télémétrie** : `run_end` porte `wake_minute` et `wake` (`HH:MM`).

## Tâches

- [x] `core/wake_tuning.gd`, `data/tuning/wake_tuning.tres`, `core/tuning.gd` (`WAKE`). Valeurs bornées : `phase_minutes > 0`, `0 <= start < 1440`, marge < phase.
- [x] `run/wake_clock.gd` : `start_minute()`, `minute_at(...)`, `minute_after_boss(floor_index)`, `minute_at_death(...)` (plafond), `static format()` ; `RunState.wake_minute` ; `Events.wake_time_set(minute: int)`.
- [x] `run/run.gd` : `_wake_minute_for(outcome)` : compte les cellules `COMBAT` de `floor_layout` et celles de `floor_map.cleared` ; appelé aux deux émissions de `run_ended` (mort, victoire), avant `run_ended`.
- [x] `ui/menus/wake_screen.gd` : ligne d'heure ; `main/main.gd` : lecture de l'heure (via l'`Events.wake_time_set`, pas `Run`), `_last_wake_minute`, passage à `Bedroom.set_clock_minute()`.
- [x] `bedroom/bedroom.gd` : `set_clock_minute(minute)` (texte du `AlarmClock`) ; `telemetry` : champs `wake`.
- [x] `strings.csv` : `UI_WAKE_TIME`.
- [x] Tests.

## État du code concerné

- `FloorMap.cleared` contient **toute cellule sans combat** (départ, trésor, boutique : `Run._enter_cell` les marque vidées en entrant) en plus des combats gagnés : il faut croiser avec `FloorLayout.cells[cell].room_type == COMBAT` ; `FloorLayout.cells_of_type(COMBAT)` donne le dénominateur. La salle de cauchemar n'est pas `COMBAT`.
- `Run._on_player_died()` et (6.4) `_finish_victory()` posent `_ended` puis émettent `run_ended`. Aucun écouteur de `run_ended` ne connaît l'heure aujourd'hui.
- `Main._on_events_run_ended(outcome)` ouvre l'écran de réveil (6.4) ; `Main` possède déjà `_seed_code()` lu depuis le `Run` ; l'heure arrive par le bus (cohérence : les écouteurs du bus ne cherchent pas dans l'arbre).
- `Telemetry._on_events_run_ended` écrit `run_end` (6.4 : avec `outcome`).
- Le réveil (`AlarmClock`) et `Bedroom.set_clock_minute` ne sont qu'un `Label` ici ; un sprite d'horloge arrive en epic 7.

## Pièges

- `floori(78.0 × 5 / 12)` = 32 (pas 32,5) : l'heure n'avance qu'à la salle **terminée** ; ne pas arrondir au plus proche (le test 6/12 = 39 passe dans les deux cas, 7/12 = 45 aussi : prendre 5/12 comme cas qui les sépare).
- Division par zéro : un plan sans salle de combat (étage de test) renvoie le début sans diviser.
- `minute_at` > 1440 : le modulo se fait dans `format()`, jamais dans le calcul (la comparaison « plus loin = plus tard » reste vraie sur plusieurs phases).
- `Events.wake_time_set` doit être émis **avant** `run_ended` et jamais après ; une deuxième émission dans la même run (relance, mort en double) est un bug : `_ended` la protège déjà.
- `strings.csv` : `UI_WAKE_TIME` contient `%s` ; passer par `tr(...) % WakeClock.format(minute)`.
- Tests : ne rien écrire hors de `user://` de test (`tools/run_tests.sh` isole `XDG_DATA_HOME`).

## Tests (GUT)

- `unit/run/test_wake_clock` : début 23:00 ; 6/12 → 23:39 ; 0/12 → 23:00 ; 5/12 → 23:32 ; 12/12 mort → 00:17 (plafond), victoire → 00:18 ; total nul sans plantage ; `format(1458) == "00:18"`, `format(1380) == "23:00"`, valeur invalide ; `floor_index = 1` décale d'une phase ; `wake_tuning.tres` valide.
- `integration/run/test_wake_time_flow` : plan réel, N salles de combat vidées par les outils de débogage, mort : `wake_time_set` avant `run_ended`, minute attendue ; victoire : 00:18 ; l'écran de réveil montre l'heure ; après « Retourner dans la chambre », le réveil de la chambre la montre ; avant toute run il marque 23:00.
- `unit/telemetry/test_outcome_record` (compléter) : `wake` dans `run_end`.

## Sources

epics.md (Story 6.6) ; GDD, Conditions de victoire (l'heure du réveil, exemple 00:18) ; architecture (`run/wake_clock.gd`, glossaire `wake_time`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Mort plafonnée à 00:17** (phase − 1 min). Le GDD définit l'heure au prorata des salles de combat et la victoire à 00:18 ; sans plafond, mourir face au boss après avoir vidé toutes les salles donnerait l'heure de la victoire. **S'écarte du texte du GDD à la marge** ; donnée dans `WakeTuning`, supprimable en mettant la marge à 0.
2. **`floori`** pour le prorata : l'heure n'avance qu'à la salle vidée.
3. **L'heure est calculée par `Run` et publiée par `Events.wake_time_set`** (avant `run_ended`) ; ni `Main` ni 6.7 ne la recalculent.
4. **Dénominateur = cellules `COMBAT` du plan réel**, pas la constante `combat_rooms` de `onset.tres`.
5. **Avant toute run : le réveil marque 23:00** (début de la nuit). Le GDD ne dit rien du premier lancement.
6. **L'heure de la dernière run est gardée en mémoire par `Main`** ici et persistée par 6.7 (dépendance dans l'ordre des stories, pas de lecture de `profile.json` avant qu'il existe).
7. **(revue) `Log.info` et non `Log.warn` sans plan d'étage (écart à l'AC6) : accepté.** Un warning à chaque mort en arène ou en salle seule (sans plan par conception) serait du bruit, et filtrer ce warning dans `run_all.sh` cacherait le motif. Le seul cas anormal (repli AR28) journalise déjà un `Log.error`. L'AC6 se lit « 23:00, journalisé ».
8. **(revue) Victoire sans plan d'étage (F1, salle du boss seule) : 23:00**, comme le dit l'AC6, et non 00:18 : chemin de débogage seulement, l'heure n'y mesure rien.
9. **(revue) Plafond de la mort à 00:17 confirmé** comme lecture fidèle de l'intention du GDD (« un score déguisé » : une mort ne se lit jamais comme une victoire) ; seul le cas 12/12 change ; reste à valider (décision 1).

### Review Findings

- [x] [Review][Patch] L'heure lit `floor_layout`, qui peut être un plan jamais joué : F1 G (`log_floor_map()` → `ensure_floor()`) en run d'arène ou de salle seule le génère, et les vagues de l'arène marquent `Vector2i.ZERO` vidée ⇒ l'heure d'une mort (ou d'une victoire, 00:18) dépend du journal de la carte [game/run/run.gd:509-517] — lire le plan joué : `var layout: FloorLayout = floor_map.layout`, `if layout == null or not layout.valid:` (branche 23:00), puis `layout.cells_of_type(...)`, `layout.has_cell(cell)`, `layout.cells[cell]` ; `floor_map.layout` n'est posé que par `_start_floor` et remis à null à chaque repli.
- [x] [Review][Patch] `WakeTuning.is_valid()` n'est appelé qu'en test : une marge ≥ phase (permise par `@export_range … "or_greater"`) donne une mort avant le début de l'étage, voire une minute négative (heure masquée, `Log.error`) [game/run/wake_clock.gd:23] — `var cap: int = maxi(_floor_start(floor_index), _floor_start(floor_index) + _tuning.phase_minutes - _tuning.death_cap_margin_minutes)`.
- [x] [Review][Patch] Division entière sans annotation, contrairement à la convention du projet (`game/ui/hud/hud.gd:45`) [game/run/wake_clock.gd:56] — ajouter `@warning_ignore("integer_division")` sur la ligne au-dessus du `return pattern % [wrapped / 60, wrapped % 60]`.
- [x] [Review][Patch] Le commentaire de `_on_events_run_ended` (« Only a defeat is a death… ») documente maintenant `_on_events_wake_time_set`, inséré entre lui et sa fonction [game/telemetry/telemetry.gd:134-139] — déplacer `_on_events_wake_time_set` et sa ligne de doc au-dessus du bloc « Only a defeat is a death… ».

Correctifs de revue appliqués et vérifiés (GUT complet vert, commit `fix(run): apply story 6.6 code review patches`).

## Dev Agent Record

### Notes de complétion

Implémenté comme spécifié. Vérifié : `tools/run_tests.sh` 769 verts (dont `test_wake_clock`, `test_wake_time_flow`, `test_outcome_record`), `run_all.sh` normal ALL PASS, `--quit-after 120` propre.

Écarts / décisions de dev :
- Sans plan d'étage, le message est un `Log.info` et non un `Log.warn` : l'arène et les salles seules n'ont pas de plan par conception, et les scènes de régression (`run_all.sh`) interdisent tout WARNING moteur.
- Le format `HH:MM` passe par `UI_CLOCK_FORMAT` (strings.csv), avec repli `%02d:%02d` si les traductions ne sont pas chargées. `format()` prend un `int` : le cas « non fini » n'existe pas, seul le négatif est refusé.
- La télémétrie lit l'heure via `Events.wake_time_set` (champ `_wake_minute`, remis à -1 après `run_end`) ; `run_end` porte `wake_minute` et `wake` (vide si inconnue).
- Non évalué (humain) : lisibilité de la ligne d'heure sur l'écran de réveil et du réveil (simple `Label`) ; sprite d'horloge en epic 7.

### Liste des fichiers

Nouveaux : `core/wake_tuning.gd`, `data/tuning/wake_tuning.tres`, `run/wake_clock.gd`, `tests/unit/run/test_wake_clock.gd`, `tests/integration/run/test_wake_time_flow.gd`.
Modifiés : `core/tuning.gd`, `autoloads/events.gd`, `run/run_state.gd`, `run/run.gd`, `main/main.gd`, `ui/menus/wake_screen.gd/.tscn`, `bedroom/bedroom.gd/.tscn`, `telemetry/telemetry.gd`, `telemetry/telemetry_session.gd`, `localization/strings.csv`, `tests/unit/telemetry/test_outcome_record.gd`.

### Journal des modifications

- 2026-11-24 : implémentation de la story 6.6 (heure du réveil), passée en review.
- 2026-11-24 : revue de code (3 couches) : 4 correctifs à appliquer, 2 reports, 3 décisions ; retour en in-progress.
