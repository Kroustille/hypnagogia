# Story 6.4 : Gagner la nuit

Status: ready-for-dev

## Story

En tant que joueur,
je veux que battre Le Professeur termine la run par une victoire,
afin que la nuit ait une fin.

Exigences : FR56 (Éclats du cauchemar), FR61 (victoire) (epics.md, Story 6.4). GDD, Conditions de victoire : « le personnage se réveille de lui-même » ; au MVP la run se termine toujours après Le Professeur.

**Dépend de : 6.1 à 6.3** (le boss, ses runners et ses signaux), 2.2 (écran de réveil, gel par `Main`), 2.8 (télémétrie), 5.4 (Éclats, `Events.shards_collected`).

Hors périmètre : chambre et retour à la chambre (6.5), heure du réveil (6.6), enregistrement de la première victoire (6.7), enchaînement d'étages (hors MVP).

## Critères d'acceptation

1. **Mort du boss** : à 0 PV, `Boss._on_death()` (crochet de 6.1) : arrête tous ses runners, libère signes et règle en cours, **vide le `BulletManager` ennemi de la salle** (`clear_all()`, les craies disparaissent), fait gagner **10 Éclats** (`BossDef.reward_shards`, donnée ; via `Events.shards_collected`, que `Run` additionne déjà et que le HUD affiche) et émet `Events.boss_defeated(boss_id)`. La barre de vie et le titre de craie disparaissent. Une seule fois (boss tué deux fois = rien de plus).
2. **Salle vidée** : le boss quitte l'arbre ; la salle émet `room_cleared` par le chemin habituel, ses portes s'ouvrent. Aucun butin de salle de combat (`Run._roll_loot` ignore déjà `NIGHTMARE`).
3. **Victoire** : à `boss_defeated`, `Run` vérifie que ce cauchemar est le plus profond débloqué (`Run.deepest_floor_index()`, 0 au MVP : seul Le Professeur existe) ; alors il attend `Tuning.ROOM.boss_victory_delay` (2 s, donnée, compté en ticks du groupe `WORLD`, donc gelé par la pause), joueur **invulnérable** pendant cette attente (`health.set_forced_invulnerability(true)`), portes ignorées (`travel()` refusé), puis `_ended = true` et `Events.run_ended.emit(Run.Outcome.VICTORY)` (`VICTORY = 1`, ajouté après `DEATH = 0`). Une mort du joueur dans l'attente est impossible ; une mort **avant** la mort du boss reste une défaite normale.
4. **Écran de réveil de la victoire** : `Main._on_events_run_ended(outcome)` choisit selon `Run.Outcome` : DEATH inchangé ; VICTORY ouvre l'écran avec le titre « Tu te réveilles de toi-même. » (`UI_WAKE_TITLE_VICTORY`), **sans** la question « Cette mort était-elle juste ? » ni ses boutons ; la seed et le bouton « Se rendormir (R) » restent. Une issue inconnue est journalisée (`Log.warn`) et traitée comme une défaite.
5. **Télémétrie par issue** (deferred 2.8 et 3.1) : `Telemetry._on_events_run_ended(outcome)` ne compte une mort, n'ajoute l'événement `death` et n'ouvre la question en attente que pour `DEATH` ; pour `VICTORY` elle ajoute `victory` (compteur `victories`) ; le `run_end` porte `outcome` (`"death"` / `"victory"`). Le temps par palier de la run est journalisé dans les deux cas.
6. **Salle du boss dans la boucle de run** : `Run.stocks`, `Run.floor_map` et le flux `combat` ne sont **pas** réinitialisés (un seul étage, la run finit au boss). Les entrées correspondantes de `deferred-work.md` restent ouvertes pour le premier étage suivant (acte 1) ; cette story n'enchaîne pas d'étage.
7. **Éclats après la victoire** : les Éclats sont perdus avec la run (règle des runs perdues, 6.7) ; leur seul rôle ici est d'être gagnés et vus (HUD), journalisés par la télémétrie (`shards_changed`).

## Tâches

- [ ] `boss.gd` : `_on_death()` (arrêt, nettoyage, Éclats, `boss_defeated`) ; `BossDef.reward_shards = 10`. Le nettoyage de `clear_all()` passe par `Room.enemy_bullets()` ; `Hitbox` de règle libéré.
- [ ] `autoloads/events.gd` : `boss_defeated(boss_id: StringName)` ; la doc de `run_ended` cite `VICTORY`.
- [ ] `run/run.gd` : `Outcome { DEATH = 0, VICTORY = 1 }` ; écoute de `boss_defeated` (connectée dans `_ready()`) ; `_physics_process` qui compte le délai (aujourd'hui `Run` n'en a pas : l'ajouter, `set_physics_process(false)` tant qu'il n'est pas utile) ; `deepest_floor_index()` ; garde `_victory_pending` dans `_on_room_door_taken` et `travel`. `core/room_tuning.gd` + `room_tuning.tres` : `boss_victory_delay = 2.0`.
- [ ] `main/main.gd` : `_on_events_run_ended(outcome)` ; `ui/menus/wake_screen.gd` : `open(seed_code, outcome)` (titre, question masquée, focus sur « Se rendormir »). `strings.csv` : `UI_WAKE_TITLE_VICTORY`.
- [ ] `telemetry/telemetry.gd`, `telemetry_session.gd` : issue de la run (voir AC 5) ; tests de télémétrie existants mis à jour sans les affaiblir.
- [ ] `debug/debug_panel.gd` : la touche existante qui tue les ennemis (`K`) doit marcher sur le boss (la mort passe par `kill()` → `_die()` → `_on_death()`).
- [ ] Tests.

## État du code concerné

- `Run.Outcome` n'a que `DEATH`. `Run._on_player_died()` pose `_ended`, journalise `run ended outcome=death`, émet `run_ended(Outcome.DEATH)` ; `Main._on_events_run_ended(_outcome)` ignore l'issue (« Tu te réveilles. »), freeze le jeu et ouvre l'écran de réveil, **synchrone dans le tick** ; la `Room`, le `WaveRunner` et `GameClock` écoutent aussi `run_ended`.
- `Enemy._die()` : `_dead`, `process_mode = DISABLED`, invisible, `queue_free()`. Le crochet `_on_death()` est celui de 6.1.
- `Run._on_events_shards_collected(amount)` → `add_shards()` → `Events.shards_changed` (HUD, télémétrie). `Run._roll_loot` : seulement `COMBAT`.
- `Telemetry._on_events_run_ended` : `deaths` et `death` pour tout fin de run ; `TelemetrySession.run_ended(at)` renvoie les secondes par palier. L'événement `run_end` n'a pas de champ de raison (deferred, revue 3.1).
- `WakeScreen.open(seed_code)` : titre fixe `UI_WAKE_TITLE`, question et boutons Oui/Non toujours présents.
- 6.5 fait de ce même écran la porte vers la chambre ; 6.6 y ajoute l'heure ; 6.7 écoute `boss_defeated` ; 6.8 efface `run.json` à la fin de la run (dans `Run`, aux deux émissions de `run_ended`).

## Pièges

- `Events.boss_defeated` part **dans le tick du coup** (callback de `Hurtbox.damage_received` appelé par le `BulletManager` du joueur) : `clear_all()` sur le manager **ennemi** est sûr (autre instance) ; ne pas libérer de nœud ici, `queue_free()` seulement.
- Le délai de victoire compte en ticks (`GameClock.scale(WORLD)`), pas en `Timer`. L'invulnérabilité forcée est remise à `false` si le `Run` est détruit avant la fin (déjà vrai : le joueur vit dans le `Run`).
- Une seule émission de `run_ended` par run : `_ended` posé avant d'émettre, comme pour la mort. Un coup mortel **le même tick** que la mort du boss : si le joueur meurt avant `boss_defeated`, c'est la mort (le boss qui meurt ensuite ne déclenche plus de victoire : tester l'ordre).
- `Main` gèle le jeu au `run_ended` ; l'attente de 2 s se fait donc **avant** l'émission : la barre de vie a déjà disparu et la salle est ouverte pendant ces 2 s.
- `WakeScreen` : la garde d'entrée de 0,3 s s'applique aux deux issues ; les boutons Oui/Non non focalisables sont déjà gérés par `_set_answers_enabled`, les masquer avec `visible = false` en victoire, pas seulement `disabled`.
- Une issue entière hors énumération reçue de la scène de test : ne pas planter, `Log.warn`.

## Tests (GUT)

- `integration/bosses/test_boss_defeat` : tuer le boss (coups réels via `Boss.debug_set_hp_fraction(0.001)` + un tir) : `enemy_bullets().active_count == 0`, +10 Éclats une seule fois, `boss_defeated` émis une fois, portes ouvertes, barre masquée ; `Boss.kill()` deux fois : un seul effet.
- `integration/run/test_victory_flow` : après `boss_defeated`, pas de `run_ended` avant `boss_victory_delay` ; `run_ended(VICTORY)` ensuite, une seule fois ; pendant l'attente le joueur est invulnérable et `travel()` ne fait rien ; mort du joueur avant la mort du boss : `DEATH`, jamais `VICTORY` ; la pause gèle le délai.
- `unit/ui/test_wake_screen` (ou intégration) : victoire = titre « de toi-même », question masquée ; défaite inchangée ; issue inconnue traitée en défaite.
- `unit/telemetry/test_outcome_record` : victoire sans `death` ni question, `victories` à 1, `run_end.outcome` ; défaite comme avant.

## Sources

epics.md (Story 6.4) ; GDD, Conditions de victoire (réveil de soi-même, un seul étage au MVP) ; deferred-work : `Main._on_events_run_ended` ignore `outcome`, `Telemetry` ignore l'issue, `run_end` ambigu.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Délai de victoire de 2 s avec invulnérabilité forcée** avant `run_ended`. L'AC enchaîne mort du boss et réveil sans durée ; deux secondes laissent voir la craie s'effacer et les Éclats arriver. Valeur dans `RoomTuning`, NON ÉVALUÉ (ressenti).
2. **`Run.deepest_floor_index()` renvoie 0 au MVP** (constante documentée, point d'ancrage des déblocages de l'acte 1). Un boss d'un étage moins profond ne finit pas la run : journalisé, rien de plus (non atteignable au MVP).
3. **Les Éclats du boss passent par `shards_collected`** (même chemin que les ramassages) plutôt qu'un appel direct à `Run.add_shards`. Raison : `bosses/` ne dépend pas de `run/`.
4. **Écran de réveil de victoire sans question de justesse.** La question vise la mort méritée (GDD) ; une victoire n'a rien à juger.
5. **Les entrées de `deferred-work.md` sur l'enchaînement d'étages** (`Run.stocks`, carte, flux `combat` sans indice d'étage) **ne sont pas traitées par l'epic 6** : un seul étage au MVP. À traiter avec le premier second étage ; `RunSnapshot` (6.8) enregistre `floor_index` pour ne pas les rendre plus chères.
6. **Télémétrie : `run_end` reçoit `outcome` ; pas de `reason` (`restarted`, `session_end`)** : le reste du point deferred 3.1 est laissé en l'état.

## Dev Agent Record

### Notes de complétion

### Liste des fichiers

### Journal des modifications
