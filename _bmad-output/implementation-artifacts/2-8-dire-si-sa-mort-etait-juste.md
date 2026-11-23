# Story 2.8 : Dire si sa mort était juste

Status: done

## Story

En tant que développeur qui fait jouer ses amis,
je veux qu'on demande après chaque mort si elle était juste, et journaliser les sessions,
afin de mesurer les indicateurs de playtest.

Exigences : FR34, NFR12, AR25 (epics.md, Story 2.8). Architecture : D18 « journal JSON de playtest » ; `telemetry/` (`telemetry.gd`, `telemetry_session.gd`) écoute le bus, aucun système ne l'appelle, rien ne dépend de `telemetry/` (game-architecture.md l. 245, 500, 601, 697) ; fichier `user://telemetry/<session>.json`, écrit en continu, vidé en fin de session. Report de 2.2 (deferred-work, décision 20) : la cause de la mort se lit dans la source du dernier `player_hit` avant `run_ended` (ordre tenu : `changed`, `player_hit`, `run_ended`, même tick).

## Critères d'acceptation

1. **Question** : l'écran de réveil affiche « Cette mort était-elle juste ? » avec deux boutons Oui et Non, en plus du bouton de relance. Même garde d'entrée de 0,3 s que la relance.
2. **Ne bloque pas** : la relance reste possible (touche ou bouton) sans répondre ; une réponse ne relance pas, ne retire pas la relance, et ne peut être donnée qu'une fois par mort (les boutons se désactivent, la question devient « Noté. »). Relancer sans répondre enregistre une absence de réponse (`no_answer`).
3. **Télémétrie par le bus uniquement** : autoload `Telemetry` (`telemetry/telemetry.gd`) qui n'écoute que `Events` ; aucun autre code ne l'appelle ni ne la référence. Nouveaux signaux : `Events.run_started()` (émis par `Run`) et `Events.death_judged(just: bool)` (émis par `Main` à la réponse du joueur, l'écran de réveil ne connaît que Main).
4. **Journal** : `user://telemetry/<session>.json`, réécrit à chaque événement (une plantade ne perd rien). Événements : début de session, début de partie, mort et sa cause (nom de la `DamageInfo.Source` du dernier `player_hit`, `unknown` sinon), réponse, absence de réponse, fin de session (fermeture de la fenêtre ou `quit()`).
5. **Indicateurs par session** (`summary`) : durée de jeu (`play_seconds`), nombre de parties (`runs`), `deaths`, `yes`, `no`, `no_answer`, taux de oui (`yes_rate` = oui / (oui + non), `null` sans réponse).
6. **Builds des amis** : l'autoload n'est pas protégé par `OS.is_debug_build()` ; aucun `debug/` impliqué.
7. Textes par `tr()` et `strings.csv`, aucun texte en dur.

## Tâches

- [x] `Events.run_started`, `Events.death_judged(just)` ; `Run` émet `run_started` à la fin de `_ready`. Commentaire de `run_ended` mis à jour.
- [x] `telemetry/telemetry_session.gd` (`RefCounted`, pur : événements, agrégats, `to_dict()`), `telemetry/telemetry.gd` (autoload : écoute, horloge, écriture), déclaré dans `project.godot` après `Audio`.
- [x] Écran de réveil : question, Oui, Non, signal `verdict_given(just)`, états (garde, répondu) ; `Main` relaie sur `Events.death_judged`.
- [x] Clés `UI_WAKE_QUESTION`, `UI_WAKE_YES`, `UI_WAKE_NO`, `UI_WAKE_ANSWERED` dans `strings.csv`.
- [x] Vérifications headless (`.scratch/t_telemetry.gd`, ajoutée à `run_all.sh`), `--quit-after 120` propre.

### Review Findings

Revue complète (3 couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor), diff `106ff91..43dbd6d`. 7 patch, 4 defer, 9 rejetés. Attribution de la cause vérifiée : `changed` → `player_hit` → `died` → `run_ended` dans le même tick, le dernier coup est toujours le coup mortel. Aucune donnée personnelle (horodatage local et compteurs seulement). Les 4 nouveaux textes passent par `tr()` et `strings.csv`.

- [x] [Review][Patch] Écriture non atomique : `FileAccess.open(WRITE)` vide le fichier avant d'écrire, une plantade pendant l'écriture perd toute la session (contredit CA4) ; résultat de `store_string` ignoré [game/telemetry/telemetry.gd:89-93] — reprendre l'approche de `Settings._save` : écrire dans `_path + ".tmp"`, `var ok: bool = file.store_string(json)`, `file.close()`, avertir et sortir si `not ok`, puis `DirAccess.rename_absolute(tmp_path, _path)` et avertir si `!= OK`.
- [x] [Review][Patch] `user://` non inscriptible : échec de `make_dir_recursive_absolute` ignoré, puis un avertissement à chaque événement, sous la catégorie `run` [game/telemetry/telemetry.gd:19, 90-92] — `var dir_err: Error = DirAccess.make_dir_recursive_absolute(DIRECTORY)` ; si `!= OK`, un seul `Log.warn("save", …)` et `_disabled = true` ; `_write()` sort tôt si `_disabled` et le met à vrai au premier échec d'ouverture ou de renommage (un seul avertissement par session). Catégorie `save` (E/S fichier) au lieu de `run`.
- [x] [Review][Patch] Collision d'identifiant de session : deux processus lancés dans la même seconde (dont les scènes parallèles de `run_all.sh`, qui peuvent écraser le fichier relu par `t_telemetry`) peuvent passer le test `file_exists` avant la première écriture [game/telemetry/telemetry.gd:20] — `var session_id: String = "%s-%d" % [stamp, OS.get_process_id()]`, boucle de suffixe `-n` conservée en secours.
- [x] [Review][Patch] Croissance sans fin de `user://telemetry/` : un fichier par lancement, jamais supprimé [game/telemetry/telemetry.gd:19] — `const MAX_SESSION_FILES: int = 100` ; après la création du dossier, lister `DirAccess.get_files_at(DIRECTORY)` filtré sur `.json`, trier (noms horodatés), supprimer par `DirAccess.remove_absolute(DIRECTORY.path_join(name))` les plus anciens au-delà de `MAX_SESSION_FILES - 1` (place pour la nouvelle session).
- [x] [Review][Patch] Cause lue par position dans `Source.keys()` et non par valeur : faux nom si une valeur explicite de l'enum n'est plus contiguë (fosses en 4.3) [game/telemetry/telemetry.gd:72-76] — `var key: Variant = DamageInfo.Source.find_key(_last_hit_source)` puis `var cause: String = str(key).to_lower() if key != null else "unknown"` (supprime `names`).
- [x] [Review][Patch] Oui/Non désactivés restent focalisables : un joueur manette qui pousse encore le stick gauche à la mort (`ui_down` par défaut inclut le stick) envoie le focus sur Oui pendant la garde, puis A répond « Oui » au lieu de relancer (fausse le `yes_rate`) ; idem après une réponse [game/ui/menus/wake_screen.gd:101-103] — `var active: bool = enabled and not _answered` ; `disabled = not active` sur les deux boutons ; `var mode: Control.FocusMode = Control.FOCUS_ALL if active else Control.FOCUS_NONE` appliqué à `_yes_button.focus_mode` et `_no_button.focus_mode`.
- [x] [Review][Patch] Architecture non mise à jour pour le nouvel autoload [_bmad-output/game-architecture.md:216, 1006] — ajouter `Telemetry` (dans `telemetry/`, hors `autoloads/`, écoute le bus) à la ligne « Application » du tableau des niveaux d'état (l. 216) et à la liste des autoloads à déclarer (l. 1006).
- [x] [Review][Defer] `run_ended` ignore l'issue : toute fin de partie est comptée comme une mort (et ouvre une question) [game/telemetry/telemetry.gd:71] — deferred, story 6.4 (seule `DEATH` existe aujourd'hui).
- [x] [Review][Defer] Source de coup périmée pour une mort sans `player_hit` [game/telemetry/telemetry.gd:61-66] — deferred, story 4.3 (aucune mort sans coup aujourd'hui).
- [x] [Review][Defer] Lancements de dev et scènes headless écrivent leur session dans `user://telemetry/` [game/telemetry/telemetry.gd:16-32] — deferred, story 1.8.
- [x] [Review][Defer] Télémétrie écrite sans prévenir le joueur ni option pour la couper [game/telemetry/telemetry.gd:2-5] — deferred, story 1.8 / préparation du playtest du jalon A.

Correctifs des 7 patchs appliqués et vérifiés (`run_all.sh` ALL PASS, scène `t_telemetry` étendue : écriture atomique, id unique, dossier plafonné à 100, cause par valeur, boutons désactivés non focalisables).

## État du code concerné

- `Run._on_player_died` émet `Events.run_ended(DEATH)` ; `Main._on_events_run_ended` gèle et ouvre `WakeScreen` ; relance par `restart_requested` → `Main._start_run()` (nouveau `Run`).
- `Events.player_hit(damage, source)` : `source` = `DamageInfo.Source` en entier (`PLAYER_SHOT 0, ENEMY_BULLET 1, DEBUG 2, CONTACT 3`).
- `WakeScreen` : garde `_armed` comptée en ticks physiques bruts (le jeu est gelé), bouton `RestartButton` focalisé, `Panel/Items` en `VBoxContainer`.
- `SaveService` est une coquille vide (6.8) : la télémétrie écrit elle-même, ce n'est pas une sauvegarde.
- Pas d'ennemi nommé dans `player_hit` : la cause est la source du coup, pas l'ennemi (voir décision 3).

## Pièges

- Un autoload ne voit pas `class_name` d'un dossier de fonctionnalité en cycle : `Telemetry` utilise `DamageInfo.Source` (lecture seule) ; rien ne l'importe en retour.
- `_exit_tree` d'un autoload tourne à `quit()` : fin de session idempotente (`_ended`), plus `NOTIFICATION_WM_CLOSE_REQUEST`.
- La réponse arrive pendant que le jeu est gelé : la télémétrie utilise `Time.get_ticks_msec()`, jamais `GameClock`.
- Tests : le fichier de session de la scène est dans `user://telemetry/` ; la scène le relit puis le supprime.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Réponse = deux boutons sur l'écran de réveil, sans touche dédiée** — Raison : le CA demande Oui et Non ; pas de nouvelle action d'entrée pour un outil de playtest ; la relance garde le focus par défaut (Entrée/relance sans répondre = `no_answer`).
2. **Une réponse ne relance pas** et ne se donne qu'une fois — Raison : « ne bloque pas la relance », réponse non ambiguë dans le journal.
3. **Cause de la mort = nom de la `DamageInfo.Source`** du dernier `player_hit` (`enemy_bullet`, `contact`…), sans identité d'ennemi — Raison : `player_hit` porte seulement la source (primitives sur le bus) ; enrichir le signal attend un besoin réel (3.x). Limite consignée dans deferred-work.
4. **`no_answer` aussi si la session se ferme sur un écran de réveil sans réponse** — Raison : un joueur qui quitte sans répondre n'a pas répondu ; cohérent avec le taux.
5. **Durée de jeu = temps réel de la session** (de l'autoload à la sortie, pauses comprises) — Raison : simple et suffisant pour le playtest ; temps par palier (NFR12) arrive avec l'epic 3.
6. **Réécriture complète du fichier à chaque événement** — Raison : quelques dizaines d'événements par session, aucune perte en cas de plantade, pas de tampon à vider.
7. **`yes_rate` = oui / (oui + non)**, les absences exclues (comptées à part dans `no_answer`) ; `null` si aucune réponse.
8. **Identifiant de session** = date et heure locales `AAAAMMJJ-HHMMSS`, suffixé `-n` en cas de collision de nom.
9. **Revue : croissance du dossier de télémétrie** — Choix : garder les 100 sessions les plus récentes (patch) plutôt que couper la télémétrie en headless (reporté à 1.8). Raison : borne simple qui protège les machines des amis ; 100 lancements laissent largement le temps d'envoyer les fichiers.
10. **Revue : collision d'identifiant** — Choix : suffixer l'identifiant par l'identifiant de processus (modifie la décision 8). Raison : supprime la course entre `file_exists` et la première écriture, sans verrou de fichier.
11. **Revue : issue de `run_ended` ignorée** — Choix : reporter à 6.4 plutôt que corriger maintenant. Raison : seule l'issue `DEATH` existe ; `Run` n'est pas référencé par la télémétrie (chaîne de préchargement), la victoire tranchera la forme (événement `run_end` distinct).
12. **Revue : catégorie de journal d'un échec d'écriture** — Choix : `save` (catégorie existante des E/S fichier) plutôt qu'une nouvelle catégorie `telemetry`. Raison : pas de changement de `Log.CATEGORIES` ni de l'architecture.
13. **Revue : focus initial sur la relance** (signalé comme biais des réponses) — Choix : rejeté, la décision 1 est maintenue ; seul le focus sur des boutons désactivés est corrigé. Raison : la relance ne doit pas être ralentie par la question.

## Vérifications prévues (`.scratch/t_telemetry.gd`, sur `main.tscn`)

- `TelemetrySession` pur : agrégats (runs, morts, oui/non/absence, `yes_rate`, `null` sans réponse), cause `unknown` sans coup.
- Dans le jeu : l'écran de réveil a Oui, Non, relance ; Oui enregistre `answer just=true` et désactive les boutons, la relance reste possible ; mort suivante relancée sans répondre : `no_answer` ; cause = `debug` pour un coup `DEBUG` ; réponse refusée pendant la garde.
- Le fichier JSON existe, se relit (`JSON.parse`), `summary` cohérent ; fin de session par `Telemetry.end_session()` ajoute `session_end`.
- Aucun code hors `telemetry/` ne référence `Telemetry` (hors `.scratch`).

## Fichiers prévus

`game/telemetry/{telemetry.gd,telemetry_session.gd}`, `game/autoloads/events.gd`, `game/run/run.gd`, `game/main/main.gd`, `game/ui/menus/wake_screen.{gd,tscn}`, `game/localization/strings.csv`, `game/project.godot`, `game/.scratch/t_telemetry.*` (non versionné).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `Telemetry` (autoload, `telemetry/`) n'écoute que `Events` : `run_started` (nouveau, émis par `Run`), `player_hit`, `run_ended`, `death_judged` (nouveau, émis par `Main` depuis `WakeScreen.verdict_given`). `TelemetrySession` (pur) tient événements et indicateurs ; fichier réécrit à chaque événement dans `user://telemetry/<session>.json`, `session_end` à `quit()` ou fermeture.
- Écran de réveil : question, Oui, Non (désactivés pendant la garde, une réponse par mort, le focus revient sur la relance, aucune relance automatique). Relancer sans répondre donne `no_answer`.
- Vérifié : `t_telemetry` 24 contrôles (agrégats purs, réponse, garde, absence, cause jamais périmée, fichier relu, fin de session, aucune référence à `Telemetry` hors du dossier) ; `run_all.sh` en mode normal : 752 contrôles, toutes les scènes PASS ; `--quit-after 120` propre.
- **NON ÉVALUÉ** (humain) : présentation de la question à l'écran, navigation manette ; **NON VÉRIFIÉ** : écriture sur un build Windows exporté (voir deferred-work).
- Aucun écart aux décisions ci-dessus.

### File List

- `game/telemetry/telemetry.gd`, `telemetry_session.gd` (+ `.uid`) (NEW)
- `game/autoloads/events.gd`, `game/run/run.gd`, `game/main/main.gd`, `game/ui/menus/wake_screen.gd`, `wake_screen.tscn`, `game/localization/strings.csv`, `game/project.godot` (UPDATE)
- ce fichier, `sprint-status.yaml`, `deferred-work.md` (UPDATE)
