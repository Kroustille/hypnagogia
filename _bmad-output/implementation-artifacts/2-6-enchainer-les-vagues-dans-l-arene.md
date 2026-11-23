# Story 2.6 : Enchaîner les vagues dans l'arène

Status: done

## Story

En tant que joueur,
je veux que l'arène m'envoie des vagues d'ennemis variées,
afin de m'entraîner au combat sans fin.

**Exigences couvertes :** FR32, AR24 (F1), ainsi que AR7/AR9 (données), AR27, AR28, AR32.

**Prérequis : la story 2.5 est `done`** (`Arena.spawn_enemy()`, les quatre ennemis, `Enemy`, panneau F1 à touches 6 à 9). Les stories 1.7 et 1.8 restent reportées, ce ne sont pas des prérequis.

**Dernière story de gameplay avant le HUD (2.7) et la télémétrie (2.8).** L'arène, vide jusqu'ici, devient la boucle de jeu du jalon A : des vagues se suivent sans fin. Lean : un `WaveRunner` minimal, une liste de vagues en données, pas de tirage aléatoire (`RunRng` et `EnemySpawn` arrivent avec l'epic 4).

## Critères d'acceptation

1. **Étant donné** l'arène, **quand** une partie démarre, **alors** une première vague apparaît (après un court délai réglable), tirée d'une liste de vagues définie en données : chaque vague est une liste d'entrées (type d'ennemi, nombre).
2. **Étant donné** une vague en cours, **quand** le dernier ennemi meurt, **alors** `Events.room_cleared` est émis (une fois), **et** la vague suivante apparaît après une pause réglable, **et** la liste reboucle en fin de liste.
3. **Étant donné** un build de debug, **quand** on ouvre le panneau F1, **alors** on peut faire apparaître un ennemi choisi (touches 6 à 9, déjà là), tuer tous les ennemis (touche 0) et passer à la vague suivante (touche `-`).

**Conséquences à tenir** (non écrites dans l'epic) :

4. **Tout vient de `data/waves/arena_waves.tres`** : liste des vagues, délai de la première vague, pause entre vagues, points d'apparition (en tuiles). Aucun nombre de vague dans le code.
5. **Apparition par `room.spawn_enemy()` uniquement** (distance minimale de 3 tuiles au joueur, corps disjoints, noms `<id>_<n>`). Les points d'apparition sont une liste fixe de la donnée, parcourue en continu d'une vague à l'autre (déterministe, sans RNG).
6. **Une vague est finie quand l'arène n'a plus aucun ennemi vivant**, y compris un ennemi créé par F1 pendant la vague. Un ennemi tué pendant la pause (F1) n'émet rien.
7. **Pause, écran de réveil, F4** : le compte à rebours (délai, pause) suit `GameClock.scale(ENEMIES)` : figé en pause et sur l'écran de réveil, ×0,25 sous F4. Ni `Timer` ni `create_timer`.
8. **Relance propre** : la relance détruit la salle et son `WaveRunner` ; aucun `room_cleared` n'est émis par le démontage ; le nouveau `Run` repart de la première vague.
9. **Données invalides** (AR28) : liste vide ou sans aucun ennemi → le runner est inerte (`Log.error` + assertion, arène vide) ; entrée sans ennemi ou de nombre ≤ 0 → ignorée (`Log.error` + assertion) ; vague de plus de `MAX_WAVE_ENEMIES` ennemis → tronquée (`Log.error` + assertion) ; apparition refusée → la vague continue avec les autres, une vague où tout est refusé est sautée (journalisée).
10. **Plafond de projectiles ennemis (report 2.4)** : la plus grosse vague de la liste, réunie en tireuses, ne refuse aucun tir ni ne tronque aucune salve sur 20 s (capacité 512, pire cas mesuré, voir « Stratégie de test »).
11. **Son du télégraphe (report 2.3/2.4)** : tranché sans changer `Audio` (voir décision 5).
12. Les stories 1.1 à 2.5 sont inchangées : les scènes de `game/.scratch` existantes passent sans modification de logique (le harnais `th.gd` désactive les vagues, voir tâche T5).

## Tâches / sous-tâches

- [x] **T1. Lexique et architecture** (AR32, avant le code) : `game-architecture.md`, « Lexique » : `vague ; liste de vagues ; pause entre vagues ; salle vidée | wave ; wave list ; wave pause ; room_cleared` ; « Arborescence » : `rooms/waves/` ; « Signaux » : `Events.room_cleared(room)` (le `lowest_tier` s'y ajoutera avec la lucidité, epic 3).
- [x] **T2. Données** (CA 1, 4) : `rooms/waves/wave_entry.gd` (`WaveEntry` : `enemy: EnemyDef`, `count`), `wave_def.gd` (`WaveDef` : `entries`), `wave_list.gd` (`WaveList` : `waves`, `start_delay`, `pause_duration`, `spawn_slots` en tuiles), `data/waves/arena_waves.tres` (6 vagues, voir « Contenu des vagues »).
- [x] **T3. `WaveRunner`** (CA 1, 2, 5 à 9) : `rooms/waves/wave_runner.gd`, enfant de l'arène créé dans `Arena._ready()` (comme les `BulletManager`) ; `Arena` gagne le signal `emptied` (dernier ennemi parti), `kill_all_enemies()`, `waves_enabled` (statique, vrai par défaut). `Enemy.kill()` public (appelle `_die()`).
- [x] **T4. `Events.room_cleared`** (CA 2) : signal `room_cleared(room: Node)`.
- [x] **T5. Panneau F1** (CA 3) : touche 0 (tuer tout), touche `-` (vague suivante), ligne d'état `wave N pause|fighting`. Harnais `.scratch/th.gd` : `Arena.waves_enabled = false` (les scènes existantes comptent sur une arène vide).
- [x] **T6. Vérifications headless** (CA 1 à 12) : `t_waves`, `t_waves_main`, `t_invalid26`, `run_all.sh` étendu.
- [x] **T7. Régression** : import, `--quit-after 120` propres, `run_all.sh` complet.
- [x] **T8. Reports** : `deferred-work.md` (plafond de projectiles, salve tronquée, son du télégraphe : traités ou reportés, voir « Reports traités » ; entrées NON ÉVALUÉ).

### Review Findings

Revue de code du 2026-11-23 (`gds-code-review`, mode complet, trois couches : Blind Hunter, Edge Case Hunter, Acceptance Auditor ; diff `1c45071..3e9b55d -- game/ _bmad-output/game-architecture.md`). Les CA 1 à 12 sont implémentés. Points demandés : relance en pleine vague ou pendant la pause sûre (tous les `_exit_tree` du sous-arbre passent avant le premier `tree_exited`, le runner est `IDLE` avant le `emptied` du démontage) ; mort pendant la pause sûre (`_freeze` désactive `ActiveScene`, `GameClock.scale` vaut 0) ; F1 0 et `-` sans double `room_cleared` ni compte négatif ; apparition refusée jamais comptée (`remove_child` avant toute connexion) ; morts du même tick : un seul passage à 0 (`_die` gardé, `CONNECT_ONE_SHOT`) ; `Arena.waves_enabled` vrai par défaut, écrit seulement par `.scratch/th.gd`, lu dans `Arena._ready` : pas de fuite en release ni d'une partie à l'autre (report epic 4 déjà inscrit). Reste un `room_cleared` possible **après** `run_ended` (patch 2) et l'ordre émission / état (patch 1). Contrôles de `game/.scratch` non audités (pipeline allégé). 10 patchs, 0 décision (3 tranchées, voir décisions 11 à 13), 2 reports, 13 rejetés.

- [x] [Review][Patch] **`room_cleared` émis avant que le runner quitte `FIGHTING` (réentrance)** [game/rooms/waves/wave_runner.gd:89-91] — Un écouteur qui fait apparaître puis meurt dans la même purge, ou qui démonte la salle (relance), voit encore `FIGHTING` : second `room_cleared` possible, ou runner remis en `WAITING` sur une salle démontée (`_wait()` écrase l'`IDLE` posé par `_exit_tree`). Correctif : dans `_on_room_emptied()`, appeler `_wait(_list.pause_duration)` **avant** `Events.room_cleared.emit(_room)` (le `Log.debug` reste en tête), commentaire `# state first: a listener that re-enters or tears the room down must see WAITING (or IDLE)`.
- [x] [Review][Patch] **`room_cleared` émis après `run_ended` quand le dernier ennemi et le joueur meurent au même tick** [game/rooms/waves/wave_runner.gd:33-53] — `run_ended` → `Main._freeze(true)` désactive `ActiveScene`, mais la purge des `queue_free` a lieu quand même en fin de frame : `tree_exited` → `emptied` → runner encore `FIGHTING` → `room_cleared` d'une partie finie (télémétrie 2.8, loot epic 5). Correctif : à la fin de `_ready()` (après `_room.emptied.connect(...)`), ajouter `Events.run_ended.connect(_on_events_run_ended)` et la méthode `func _on_events_run_ended(_outcome: int) -> void:` / `_state = State.IDLE # a finished run clears no room and spawns no wave`. Pas de déconnexion explicite (nœud libéré avec la salle). Décision 11.
- [x] [Review][Patch] **Un compte à rebours nul part même quand l'horloge est figée** [game/rooms/waves/wave_runner.gd:73-78] — Avec `start_delay` ou `pause_duration` à 0 (permis par `@export_range(0.0, …)`), `_ticks_left <= 1e-6` est vrai alors que `GameClock.scale(ENEMIES) == 0` : une vague apparaît en temps figé (CA 7). Inatteignable avec la donnée actuelle (1 s, 2 s) et la pause actuelle (`ActiveScene` désactivé). Correctif : dans `_physics_process`, après le test d'état : `var step: float = GameClock.scale(GameClock.Group.ENEMIES)` / `if step <= 0.0: return` / `_ticks_left -= step`.
- [x] [Review][Patch] **Vague nulle ou sans entrée ignorée sans journal ; `EnemyDef` sans scène acceptée** [game/rooms/waves/wave_runner.gd:113-130] — AR28 / CA 9 : une entrée invalide est signalée, une vague nulle ou vide disparaît en silence (l'ordre des vagues change sans avertissement) ; une entrée dont `enemy.scene == null` passe la validation puis échoue à chaque apparition, à chaque tour de liste. Correctif : itérer `for index: int in _list.waves.size():` avec `var wave: WaveDef = _list.waves[index]` ; `if wave == null or wave.entries.is_empty():` → `Log.error("room", "wave %d ignored: null or without entries" % index)` + `_assert_failed("a WaveDef needs at least one entry")` + `continue` ; condition d'entrée invalide étendue à `or entry.enemy.scene == null` (message : « it needs an enemy with a scene and a count above 0 »). `t_invalid26` ne crée ni vague nulle ni vague vide : ses `expect()` restent justes.
- [x] [Review][Patch] **Touche `-` du panneau F1 introuvable en AZERTY** [game/debug/debug_panel.gd:68, :240] — `physical_keycode == KEY_MINUS` est la position QWERTY du `-`, soit la touche `)` en AZERTY ; le `-` d'un AZERTY est la touche physique `KEY_6` (apparition d'un Somnambule). Correctif : ligne 68 `KEY_MINUS, KEY_KP_SUBTRACT:` ; ligne 240 `"- next wave (keypad -; ) on AZERTY)"` (`t_waves_main` cherche `"- next wave"` : toujours trouvé). Décision 12.
- [x] [Review][Patch] **Ligne d'état F1 `waiting` au lieu de `pause` (T5)** [game/debug/debug_panel.gd:251] — T5 spécifie `wave N pause|fighting`. Correctif : ne pas toucher `WaveRunner.state_name()` (`t_waves` teste `"WAITING"`) ; dans le panneau : `var state: String = runner.state_name().to_lower()` / `if state == "waiting": state = "pause"` puis `lines.append("wave %d %s" % [runner.wave_number(), state])` (`t_waves_main` cherche `"wave 1 fighting"` : inchangé). Décision 13.
- [x] [Review][Patch] **Commentaire de « tuer tout » contraire au comportement** [game/debug/debug_panel.gd:141] — Il dit « without clearing the room (no Events.room_cleared…) » ; en `FIGHTING`, la touche 0 vide la salle et le runner émet `room_cleared` en fin de frame (Completion Notes, `t_waves_main`). Correctif : `## Kills every living enemy of the active room. During a wave the runner then clears the room (Events.room_cleared), as for player kills.`
- [x] [Review][Patch] **T1 incomplet : l'exemple « Événements » de l'architecture garde l'ancienne signature** [_bmad-output/game-architecture.md:505] — Le code a `room_cleared(room: Node)`. Correctif : après la fin du bloc de code (ligne 510), ajouter la ligne « Signature actuelle (story 2.6) : `room_cleared(room: Node)` ; `Room` et `lowest_tier` arrivent avec la lucidité (epic 3) et les salles (epic 4). »
- [x] [Review][Patch] **Anciennes entrées de `deferred-work.md` qui renvoient encore à la 2.6** [_bmad-output/implementation-artifacts/deferred-work.md:134, 137, 143, 162, 169] — T8 « traités ou reportés ». Correctif : ajouter à la fin de chacune « **Traité par la story 2.6** (voir « Deferred from: story 2-6 ») » ; pour 134, préciser « touches 6 à 9 gardées, 0 et `-` ajoutées (décision 4 de la 2.6) » ; pour 143, « reporté en 7.7 (décision 5) » ; pour 162 et 169, « mesuré : aucun tir refusé ni salve tronquée (CA 10) » ; pour 137, « plafond `MAX_WAVE_ENEMIES` = 12 ».
- [x] [Review][Patch] **Rangement d'`arena.gd`** [game/rooms/arena/arena.gd:24-26, 56, 155-158] — `signal emptied` est coincé entre deux blocs de constantes (ordre GDScript : signaux puis constantes) ; une seule ligne vide avant `player_spawn_position()` ; `Arena._waves` (un `WaveRunner`) se confond avec `WaveRunner._waves` (un tableau). Correctif : déplacer `signal emptied` et ses deux lignes de commentaire (24-26) avant la ligne 11 (première constante) ; ajouter une ligne vide après `return _waves` ; renommer `Arena._waves` en `_wave_runner` (lignes 56, 155, 165).
Correctifs appliqués et vérifiés le 2026-11-23 : les 10 patchs sont faits, `run_all.sh` en mode normal : ALL PASS (703 contrôles).

- [x] [Review][Defer] **`room_cleared` émis pendant que `Enemies` est verrouillé** [game/rooms/arena/arena.gd:292-295] — deferred, epic 5 (effets d'objets, renforts) : `emptied` part du `tree_exited` d'un ennemi, pendant le `remove_child` de `Enemies` (`data.blocked`) ; un écouteur de `room_cleared` qui appellerait `spawn_enemy()` en synchrone aurait « Parent node is busy ». Aucun écouteur aujourd'hui.
- [x] [Review][Defer] **Dossier `.scratch` à exclure de l'export** [game/.scratch] — deferred, story 1.8 : les scènes de vérification (qui écrivent `Arena.waves_enabled`) sont sous `res://` ; jamais chargées par le jeu, mais à exclure du filtre d'export.

## Dev Notes

### État du code touché

- `rooms/arena/arena.gd` : `spawn_enemy(def, requested_px)` fait tout (résolution de position, nom, compte `_alive`, `tree_exited` → `_on_enemy_tree_exited()` décrémente). L'arène démarre vide. Les cibles d'entraînement (`Targets`) ne comptent pas comme ennemis. Zone d'apparition utile : x de 2 à 36 tuiles, y de 2 à 19 (marge d'une tuile contre les murs, origine = coin du cadre).
- `enemies/enemy.gd` : `_die()` privé, désactive (`PROCESS_MODE_DISABLED`), masque, `queue_free()` ; l'ennemi quitte l'arbre en fin de frame.
- `debug/debug_panel.gd` : touches 1 à 9 ; texte d'en-tête `F1 panel (keys 1-9)` vérifié par `t_shooters_main`.
- `autoloads/events.gd` : `player_hit`, `enemy_damaged`, `run_ended` ; pas de `room_cleared`.
- `autoloads/audio.gd` : 3 voix par flux ; `Telegraph.start()` appelle `Audio.play_sfx(sound)`.
- Capacité des projectiles ennemis : 512 (`ENEMY_BULLET_CAPACITY`) ; durée de vie 10 s.

### `WaveRunner`

États : `IDLE` (inerte ou démontage), `WAITING` (compte à rebours en ticks, `-= GameClock.scale(ENEMIES)` par tick physique), `FIGHTING`. Tick de fin de compte à rebours : `_spawn_wave()` ; si au moins un ennemi est apparu → `FIGHTING`, sinon journal et retour à `WAITING` (pause) avec la vague suivante. À `Arena.emptied` en `FIGHTING` : `Events.room_cleared.emit(room)`, journal DEBUG, indice suivant (modulo, vagues vides sautées), `WAITING` avec `pause_duration`. `_exit_tree()` : `IDLE` (un démontage n'émet rien : CA 8). API pour F1 : `force_next_wave()` (tue tout, apparaît tout de suite, sans `room_cleared`), `wave_number()` (1 pour la première, ne reboucle pas), `state_name()`.

Apparition : `spawn_enemy(def, slots[cursor % n] * TILE_SIZE)`, `cursor` +1 par ennemi, jamais remis à zéro dans la salle : une vague ne commence pas toujours au même point. Journaux en DEBUG seulement (`room`), jamais dans `_physics_process` hors transition.

### Contenu des vagues (provisoire, GDD muet : voir décision 2)

Délai de la première vague 1 s, pause 2 s. Vagues (≤ 7 ennemis) : 1) 3 Somnambules ; 2) 2 Veilleuses + 1 Somnambule ; 3) 2 Berceuses + 2 Somnambules ; 4) 2 Moutons ; 5) 1 Veilleuse, 1 Berceuse, 1 Mouton, 1 Somnambule ; 6) 2 Moutons, 2 Berceuses, 2 Somnambules. Huit points d'apparition (coins, milieux de bord).

### Pièges Godot

- `emptied` part de `tree_exited`, donc en fin de frame de la mort ; au démontage de la salle, les enfants sortent un à un : le `WaveRunner` (dernier enfant ajouté) sort le premier et passe en `IDLE`, mais le test `t_waves_main` le prouve (relance en pleine vague, aucun `room_cleared`).
- `force_next_wave()` apparaît dans la frame de la mort : les morts (`is_dead()`) ne bloquent pas les nouveaux corps (déjà le cas dans `_overlaps_living_enemy`), mais le compte `_alive` les inclut jusqu'à la fin de frame (aucun effet : `emptied` ne part qu'à 0).
- Les tests existants dépendent d'une arène vide : `Arena.waves_enabled` (statique) doit être faux dans `th.gd` avant la création du `Run`.

### Stratégie de test (lean)

`t_waves` (arène via `Run`, `waves_enabled = true`) : première vague après `start_delay` avec les types et nombres de la donnée, noms `<id>_<n>`, distance minimale ; tuer tout → un seul `room_cleared`, pause respectée, vague 2 ; bouclage après la dernière (liste de 2 vagues injectée) ; mort pendant la pause sans événement ; F1 : tuer tout, vague suivante ; pause et F4 figent / ralentissent le compte à rebours ; vague sans apparition possible sautée ; pire cas de projectiles : `MAX_WAVE_ENEMIES` Veilleuses sur 20 s, `refused_count == 0`. `t_waves_main` (`main.tscn`) : démarrage → vague 1, touches 0 et `-`, mort puis relance en pleine vague sans `room_cleared` et vague 1 de nouveau, cinq relances sans fuite de nœuds. `t_invalid26` : données invalides du CA 9 avec assertions annoncées. Puis `--quit-after 120` propre et `run_all.sh` complet.

**NON ÉVALUÉ / NON VÉRIFIÉ (humains)** : difficulté et rythme des vagues, durée de la pause, lisibilité de 6 ennemis, son quand plusieurs télégraphes partent ensemble, rendu fenêtré. Pas de capture fenêtrée (pipeline allégé).

### Reports traités par cette story

- Plafond de projectiles ennemis et salve tronquée (2.4) : mesuré (CA 10), plafond de vague `MAX_WAVE_ENEMIES` ; reste à surveiller avec les ennemis de l'acte 1.
- Son du télégraphe au-delà de 3 voix (2.3, 2.4) : décision 5.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Où vit la logique** : un `WaveRunner` enfant de l'arène (et non `Run`), liste en `WaveList` (`.tres`) — Raison : l'architecture dit « chaque salle fixe ses vagues » (epic 4 : une salle = ses vagues) ; le runner suivra la salle.
2. **Contenu, tailles et rythme des vagues** : 6 vagues de 2 à 7 ennemis, première vague après 1 s, pause 2 s — Raison : le GDD ne donne ni liste ni durée (≈ 45 s par salle, soit 2 à 3 vagues ; la liste sert l'entraînement sans fin) ; croissance douce, mélange des types. **NON ÉVALUÉ.**
3. **Points d'apparition fixes parcourus en continu, sans RNG** — Raison : `RunRng` et `EnemySpawn` arrivent avec l'epic 4 ; déterministe et testable ; `spawn_enemy()` repousse déjà les points trop proches ou occupés.
4. **F1 : touches 6 à 9 gardées (ennemi choisi par touche), 0 = tuer tout, `-` = vague suivante** — Question : le plan de la 2.5 parlait de remplacer la 6 par un sélecteur. Choix : ne rien casser. Raison : le « choix » est déjà la touche ; un sélecteur ajouterait du code et des tests sans gain ; l'en-tête reste `keys 1-9`, deux lignes s'ajoutent.
5. **Son du télégraphe : plafond de 3 voix gardé** — Raison : les voix identiques simultanées n'ajoutent que du volume ; l'animation annonce chaque attaque ; un plafond par ennemi ou un son positionnel appartient à la 7.7. **NON ÉVALUÉ à l'oreille.**
6. **`room_cleared(room: Node)`** — Raison : l'architecture prévoit `(room, lowest_tier)` ; `Room` et la lucidité n'existent pas encore, `autoloads/` ne dépend d'aucun dossier de fonctionnalité ; le palier s'ajoutera avec l'epic 3.
7. **`Arena.waves_enabled` statique** pour couper les vagues dans les scènes de test — Raison : les scènes existantes (2.1 à 2.5) comptent sur une arène vide et créent leur `Run` elles-mêmes ; une variable statique évite de toucher chacune. Vraie par défaut, jamais écrite par le code du jeu.
8. **Vague finie = plus aucun ennemi vivant dans l'arène** (F1 compris) ; **« vague suivante » de F1 tue tout sans `room_cleared`** — Raison : un `room_cleared` forcé fausserait les futurs effets d'objets (loot, 2.8).
9. **Le compte à rebours suit `GameClock.scale(ENEMIES)`** — Raison : même règle que les ennemis (pause, F4) ; pas de groupe d'horloge propre aux salles avant l'epic 4.
10. **Une vague où rien n'apparaît est sautée** (journal, pas d'attente infinie) — Raison : AR28, la salle ne doit jamais se bloquer.
11. **(Revue) Pas de `room_cleared` après `run_ended`** — Question : dernier ennemi et joueur morts au même tick, la salle compte-t-elle comme vidée ? Choix : non, le runner passe en `IDLE` sur `run_ended`. Raison : la partie est finie ; la télémétrie (2.8) et le loot (epic 5) ne doivent rien recevoir d'une partie morte.
12. **(Revue) Touche « vague suivante » : `-` physique QWERTY + `-` du pavé numérique** — Question : le `-` d'un AZERTY est la touche 6 physique. Choix : garder la position physique (comme les touches 0 à 9) et ajouter `KEY_KP_SUBTRACT`, le libellé le dit. Raison : passer à `keycode` pour cette seule touche ferait entrer en conflit le `-` AZERTY et la touche 6 ; le pavé est le même partout.
13. **(Revue) Ligne d'état F1 : `pause` au lieu de `waiting`** — Choix : traduire dans le panneau seulement, `state_name()` reste le nom de l'état. Raison : T5 nomme `pause|fighting` ; `t_waves` lit `state_name()`.

### Références

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.6]
- [Source: gdds/gdd-hypnagogia-2026-11-20/gdd.md#Ennemis et IA, #Arènes et salles] (4 ennemis du jalon A ; « chaque salle fixe ses emplacements et ses vagues » ; jamais à moins de 3 tuiles du joueur)
- [Source: _bmad-output/game-architecture.md#Création d'entités, #Temps (D7), #Signaux, #Panneau F1]
- [Source: _bmad-output/implementation-artifacts/2-5-affronter-le-mouton.md] (décisions 12, `spawn_enemy`), `2-3`, `2-4` (reports), `deferred-work.md` (entrées 2.6)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Debug Log References

- Mutations sautées (pipeline allégé). Scènes ajoutées (`game/.scratch`, hors git) : `t_waves` (61 contrôles : délai, composition par la donnée, noms, `room_cleared` une fois au dernier mort, pause, bouclage, ennemi F1 pendant la vague, `force_next_wave`, pause/F4, vagues coupées, démontage, pire cas de projectiles 12 Veilleuses 20 s), `t_waves_main` (13 : touches 0 et `-`, ligne du panneau, mort puis relance en pleine vague, cinq relances), `t_invalid26` (8 contrôles, 7 assertions annoncées = vues). `th.gd` : `Arena.waves_enabled = false`. `run_all.sh` : 3 scènes et 4 contrôles de journal.
- Piège rencontré : le moteur signale « resources still in use » si un son de télégraphe joue à la sortie ; `t_waves` attend 60 ticks avant de finir.

### Completion Notes List

- T1 à T4 : lexique et architecture avant le code ; `WaveEntry` / `WaveDef` / `WaveList` / `WaveRunner` dans `rooms/waves/`, `data/waves/arena_waves.tres` (6 vagues, 1 s, 2 s, 8 points), `Arena` : signal `emptied`, `kill_all_enemies()`, `wave_runner()`, `waves_enabled`, `Enemy.kill()`, `Events.room_cleared(room)`.
- T5 : panneau F1 : touche 0, touche `-`, ligne `wave N état`. Les touches 6 à 9 restent (décision 4).
- T6 à T8 : voir Debug Log ; `run_all.sh` ALL PASS (15 scènes, 699 contrôles ; import et `--quit-after 120` propres) ; `deferred-work.md` mis à jour (plafond de projectiles mesuré, salve tronquée non constatée, son du télégraphe, NON ÉVALUÉ / NON VÉRIFIÉ).
- Aucun écart aux « Décisions prises sans Kroustille ». Précision : « tuer tout » (F1 0) vide la salle comme un joueur (émet `room_cleared`) ; seule « vague suivante » ne l'émet pas.

### File List

- `_bmad-output/game-architecture.md`, `_bmad-output/implementation-artifacts/deferred-work.md`, `sprint-status.yaml`, ce fichier (UPDATE)
- `game/rooms/waves/wave_entry.gd`, `wave_def.gd`, `wave_list.gd`, `wave_runner.gd` (+ `.uid`) (NEW)
- `game/data/waves/arena_waves.tres` (NEW)
- `game/rooms/arena/arena.gd`, `game/enemies/enemy.gd`, `game/autoloads/events.gd`, `game/debug/debug_panel.gd` (UPDATE)
