# Story 6.9 : Tenir vingt nuits sans faille

Status: in-progress

## Story

En tant que développeur,
je veux vérifier les chargements, la stabilité et les indicateurs du jalon B sur des runs complètes,
afin de livrer un MVP fiable au premier cercle.

Exigences : NFR3 (chargement d'étage), NFR4, NFR12 (indicateurs du jalon B) (epics.md, Story 6.9). GDD, Indicateurs techniques (aucun crash sur 20 runs MVP consécutives ; relance < 3 s ; même seed + mêmes déblocages = même étage et mêmes objets, vérifié sur 10 seeds) et de gameplay (jalon B : ≥ 3 runs d'affilée par session, durée médiane 12 à 18 min, ≥ 25 % de la run sous Lucide, Le Professeur 30 à 50 % de victoires dès la 5e tentative).

**Dépend de : 6.1 à 6.8** (la boucle complète : chambre, étage, boss, victoire, profil, reprise), 2.8 (télémétrie). C'est la dernière story de l'epic : elle ne crée pas de mécanique.

Hors périmètre : jouer les 20 nuits à la main (l'humain les consigne, voir décision 2), réglage de l'équilibre du boss, mesures de FPS à 400 projectiles (story 1.2).

## Critères d'acceptation

1. **Chargement d'étage < 2 s** : de l'appui sur `interact` près du lit (ou de « Se rendormir ») au premier tick où le joueur contrôle la salle de départ, moins de 2 s. `Run` mesure son démarrage (`Time.get_ticks_msec()` de `_ready()` à `Events.run_started`) et `Main` la durée complète depuis la demande ; les deux sont journalisés (`Log.info("run", "floor ready in N ms")`) et écrits dans la télémétrie. Un contrôle headless affirme ≤ 2 000 ms sur la machine de test (valeur de seuil en données du test, pas du jeu).
2. **Soak automatisé de 20 runs complètes** : un outil headless (`debug/soak_runner.tscn/.gd`, lancé par `tools/soak.sh`) enchaîne **20 runs** depuis la chambre, issues mêlées (au moins 8 victoires et 8 morts, motif fixe : 20 seeds de la liste du script) ; chaque run traverse **toutes** les salles de combat du chemin vers le cauchemar par les vraies portes et transitions (`Run.travel`), vide les salles par les outils de débogage (`kill_all_enemies` / vague forcée), joue le **vrai combat du Professeur** (trois phases, Interro surprise une fois sur deux) avec des coups simulés, puis soit gagne soit meurt (mort dans une salle quelconque, au boss, pendant l'annonce). Entre chaque run : écran de réveil, retour à la chambre, relance directe un coup sur deux.
3. **Aucun crash ni fuite** : zéro `SCRIPT ERROR`, zéro `Parse Error`, aucune erreur de physique, zéro `ERROR`/`push_error` du jeu ; après chacune des 20 runs, le nombre d'objets (`Performance.OBJECT_COUNT`), de nœuds (`OBJECT_NODE_COUNT`) et d'orphelins (`OBJECT_ORPHAN_NODE_COUNT`) revient à ± une marge fixe de sa valeur après la run 1 (pas de croissance monotone), et aucun jeton `ResourceLoader` ne reste ouvert (`RoomLoader.collect_orphans(true)` rend 0). Le résultat est **consigné** dans la story (tableau : run, seed, issue, durée, heure du réveil, objets en mémoire) et dans le journal.
4. **Même seed, mêmes déblocages = même étage et mêmes objets, sur 10 seeds** (indicateur technique du GDD) : pour 10 seeds, deux `Run` successives donnent le même `FloorLayout.to_text()`, les mêmes offres de la salle trésor et de la boutique (premier passage), les mêmes ids d'ennemis par salle. Test GUT, pas du soak.
5. **Télémétrie de session** (`telemetry/*.json`) : le journal donne, par session, `runs` (déjà), **la durée de chaque run** (`runs_detail[i].duration_seconds`, `outcome`, `wake`, `seed`), **l'issue de chaque tentative contre Le Professeur** (`boss_attempts[i].outcome` = `victory` / `death` / `abandoned`, avec la fraction de PV restants et la phase atteinte), et **le temps passé sous Lucide** (`below_lucid_seconds` et `below_lucid_share` = secondes dans les paliers sous Lucide / durée de la run, par run et pour la session). Les clés existantes (`summary.tier_seconds`, `deaths`, …) ne changent pas de sens.
6. **Une tentative contre Le Professeur** commence à `Events.boss_engaged` et se clôt à `boss_defeated`/`run_ended` (victoire, mort) ou à la relance/sortie sans fin de run (`abandoned`) ; une run qui meurt avant le boss n'a **aucune** tentative.
7. **Relance < 3 s** (déjà journalisée par `Main`) apparaît dans le soak : toutes les relances directes du soak affichent moins de 3 000 ms (compte à rebours en ticks simulés, pas en horloge murale).

## Tâches

- [x] `telemetry/telemetry_session.gd` : `runs_detail`, `boss_attempts`, durées par run (ticks ou secondes de session, mêmes sources que `tier_seconds`), parts sous Lucide ; `telemetry.gd` écoute `Events.boss_engaged`, `boss_health_changed`, `boss_phase_changed`, `boss_defeated`, `wake_time_set`, `run_ended(outcome)` (6.4) et `Events.floor_ready` si créé ; `to_dict` : sections `runs_detail`, `boss_attempts`, `summary.below_lucid_*`.
- [x] `run/run.gd` : mesure `startup_ms` et journalise ; `main/main.gd` : durée de la demande à `run_started`.
- [x] `debug/soak_runner.gd` + `.tscn`, `tools/soak.sh` (lance Godot en `--fixed-fps 60` plus rapide que le temps réel, comme `FAST=1`, et affirme les critères 2 et 3, code de sortie non nul en cas d'échec) ; résultat texte dans `tools/` sorti, **non versionné**.
- [x] Tests GUT : télémétrie, déterminisme de 10 seeds, seuil de chargement.
- [x] Consigner dans cette story les résultats du soak (20 lignes) et ce qui reste NON VÉRIFIÉ.

## État du code concerné

- `TelemetrySession` : `runs`, `deaths`, `yes/no`, `tier_seconds` (5 valeurs), `_run_tier_seconds`, `item_taken`, `run_ended(at)` renvoie les secondes par palier de la run ; `to_dict(at)` → `summary` (play_seconds, runs, deaths, réponses, tier_seconds, spends, items). Avant 6.4 toute fin de run est une mort ; 6.4 distingue les issues et ajoute `outcome` à `run_end` ; 6.6 ajoute `wake`.
- `Telemetry` : autoload dans `telemetry/` qui écoute `Events` seulement ; fichier `user://telemetry/<session>.json` écrit en `.tmp` puis renommé ; **bascule en `_disabled`** si l'écriture est impossible.
- Chargement : `Run._start_floor()` charge la salle de départ **synchrone** et demande les autres en arrière-plan (`RoomLoader.request_all`) ; `Main._start_run` détruit l'ancienne `Run` avant (le pool de projectiles et les salles de l'étage 1 restent en cache).
- Déterminisme : `FloorGenerator.generate(def, pool, rng, floor_index)` ; trésor et boutique tirent sur les flux `treasure`/`shop` à la **première entrée** (`_stock_treasure`, `_stock_shop`).
- Outils utilisables par le soak : `Room.kill_all_enemies()`, `WaveRunner.force_next_wave()`, `Run.travel(side)`, `Run.floor_map`, `Boss.debug_set_hp_fraction(f)` (6.1), `Health.apply_damage` pour mourir ; `tools/run_tests.sh` pour GUT.
- Sauvegarde : 6.8 écrit `run.json` à chaque entrée de salle ; le soak l'exerce 20 fois et l'efface à chaque fin de run.

## Pièges

- **Le soak est un test de stabilité, pas de jeu** : il ne prouve ni l'équilibre ni la lisibilité. Les 20 runs jouées à la main (indicateur du GDD) sont à faire par un humain sur la machine de référence : NON VÉRIFIÉ ici, consigné comme tel.
- Plus rapide que le temps réel : l'audio garde son rythme réel (une vérification de voix échoue en mode rapide, voir le brief) ; le soak coupe l'audio (`AudioServer.set_bus_mute`) et ne compte jamais en millisecondes d'horloge murale pour les durées de jeu.
- `Performance.get_monitor` : lire les orphelins **après** `await get_tree().process_frame` et deux ticks, le temps que les `queue_free()` partent ; comparer à une marge, pas à une valeur exacte.
- Vider une salle par `kill_all_enemies()` ne fait pas passer par `room_cleared` si on le fait n'importe comment : utiliser le chemin du `WaveRunner` (`force_next_wave` jusqu'à `DONE`), sinon les portes ne s'ouvrent pas et `travel()` ne trouve pas de porte.
- `Run.travel` utilise la transition (fondu) : attendre `is_traveling() == false` avant la suite ; ne pas enchaîner deux voyages dans le même tick.
- Le soak tourne contre le vrai `Main` (`start_in_bedroom = true`) pour mesurer la chambre → run ; il écrit dans un dossier de données **temporaire** (`SaveService.set_directory`), jamais dans le profil du joueur.
- La durée d'une run en télémétrie doit être en temps de jeu (ticks scalés, pause exclue) : une pause de 10 minutes ne compte pas ; les durées médianes du GDD (12 à 18 min) s'entendent hors pause.
- Une télémétrie désactivée (`_disabled`) ne doit pas faire échouer le soak : le critère 5 est lu d'un `TelemetrySession` en mémoire, pas du disque, sauf un test d'intégration dédié.

## Tests (GUT)

- `unit/telemetry/test_session_summary` : deux runs (une victoire, une mort) : `runs_detail` à 2 entrées avec durée et issue ; `below_lucid_seconds` = somme des paliers 1..4 ; part entre 0 et 1 ; tentative contre le Professeur : victoire, mort au boss (phase atteinte, PV restants), abandon par relance, aucune tentative pour une mort avant le boss.
- `integration/telemetry/test_boss_attempts` : événements réels (`boss_engaged`, coups, `run_ended`) alimentent la session ; relance sans fin de run = `abandoned`.
- `integration/generation/test_seed_determinism` : 10 seeds, deux `Run` chacune, plan et offres identiques.
- `integration/run/test_floor_load_time` : de la demande de run à `run_started` en ticks et en ms : ≤ 2 000 ms ; journal « floor ready ».
- Soak : `tools/soak.sh` (20 runs), code de sortie 0.

## Sources

epics.md (Story 6.9) ; GDD, Indicateurs de réussite (techniques et gameplay) ; architecture (chargement en arrière-plan, relance < 3 s, télémétrie dans `telemetry/`) ; brief du pipeline (exécution rapide, scènes de vérification).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Soak automatisé de 20 runs + 10 seeds en test + mesures de télémétrie**, à la place de 20 parties jouées par l'agent. L'epic parle de « jouées sur la machine de référence » : l'automatisme détecte plantages et fuites ; **les 20 nuits jouées à la main restent à ta charge** (NON VÉRIFIÉ).
2. **« Temps passé sous Lucide » lu comme le temps dans les paliers sous Lucide** (Flottant à Abandon total), par run et par session, **plus** la part de la run (l'indicateur du GDD est « au moins 25 % de la run sous le palier Lucide »). Une autre lecture (temps *au* palier Lucide) se déduit de `tier_seconds[0]`, déjà écrit.
3. **Une tentative contre Le Professeur commence à `boss_engaged`** (le boss apparaît), pas à l'entrée de la salle : mourir avant qu'il apparaisse n'en est pas une.
4. **Seuil de 2 s mesuré en headless** ; il ne remplace pas la mesure sur la machine de référence (disque, GPU), NON VÉRIFIÉ.
5. **Marge de fuite fixe** pour les objets et nœuds (pas d'exigence d'égalité exacte) : les caches de ressources grossissent légitimement à la première run.
6. **Le soak n'est pas dans la suite GUT** : script dédié, lancé à la main et par l'orchestrateur à la fin de l'epic.

7. **Part sous Lucide = temps sous Lucide / somme des secondes de paliers de la run** (pas / `duration_seconds`) : `tier_seconds` suit l'horloge murale de la télémétrie (pause comprise), `duration_seconds` le temps de jeu ; les diviser l'un par l'autre mélangerait deux horloges. Les deux chiffres sont écrits ; sans pause, ils coïncident.
8. **Durée de run = temps de jeu compté en images** : `Telemetry._process` additionne `delta` hors `GameClock.paused` (pause et écran de réveil exclus) ; la session reste pure (`advance_play`), sans horloge.
9. **Nouveau signal `Events.floor_ready(startup_ms, load_ms)`**, émis par `Main` à `run_started` (durée de `Run._ready()` jusqu'à `run_started`, et durée depuis la demande de nuit) ; écrit dans `run_start` et `runs_detail`. Seuils 2 000 ms (chargement) et 3 000 ms (relance) en données du test et du soak.
10. **Le soak n'est pas dans `tools/run_tests.sh`** : il a besoin du vrai `Main` et d'un code de sortie propre ; il dure une dizaine de secondes seulement (20 nuits, `--fixed-fps 60`), donc `tools/soak.sh` à part (opt-in, lancé par l'orchestrateur en fin d'epic), `SOAK_RUNS` / `SOAK_MAX_SECONDS` pour le raccourcir.
11. **Les 20 nuits mêlent quatre départs** (lit, « Se rendormir », seed saisie depuis la chambre, seed saisie depuis l'écran de réveil) : le lit et « Se rendormir » tirent une seed au hasard (consignée dans le tableau, rejouable en la saisissant) ; les deux autres prennent la liste du script. Fins : 10 victoires, 4 morts en salle, 3 pendant l'annonce, 3 au combat. L'Interro surprise est forcée (jauge à 0) une nuit de boss sur deux.
12. **Marges de fuite** : objets ± 300, nœuds ± 20, orphelins + 5 par rapport à la première nuit du même type de départ (depuis la chambre / relance directe) ; mémoire statique : pas plus de 1,5× d'écart entre le premier et le dernier cinquième. *(Revue : resserrées par un patch, voir Review Findings.)*
13. **(revue) Le soak garde 3 000 ms de chargement pour les relances et les seeds saisies** au lieu des 2 s du CA 1 : le seuil de 2 s de chaque nouvelle nuit est tenu par `test_floor_load_time` (quatre nuits par `run_requested`, le chemin de « Se rendormir ») ; les deux mesures restent en headless (NON VÉRIFIÉ sur la machine de référence).
14. **(revue) Le contrôle de l'Interro dans le soak reste « au moins une »** (21 Interros pour 24 nuits forcées sur 60 : une mort pendant l'annonce peut précéder le déclenchement) : le soak cherche des plantages, pas un compte exact.

## Dev Agent Record

### Notes de complétion

- Télémétrie (`TelemetrySession`, `Telemetry`) : sections `runs_detail` (run, seed, issue, `duration_seconds`, `wake`, `below_lucid_seconds/share`, `startup_ms`, `load_ms`) et `boss_attempts` (boss, issue `victory`/`death`/`abandoned`, PV restants, phase la plus profonde, durée) ; `summary.below_lucid_seconds/share`. Une tentative commence à `boss_engaged`, se clôt à `boss_defeated` (victoire), `run_ended` (issue de la run) ou au `run_started` / `end` suivant (abandon). Aucune clé existante ne change de sens. `Telemetry.session()` donne la session en mémoire.
- `Run.startup_msec()` et `Main` : `Events.floor_ready` ; le journal dit « floor ready in N ms » (`run`) et « … since the request » (`Main`).
- Soak : `game/debug/soak_runner.tscn/.gd` + `tools/soak.sh` (rapport dans `tools/soak-result.txt`, ignoré par git). 20 nuits en une dizaine de secondes ; code de sortie 1 sur toute erreur du moteur ou du jeu, fuite, délai dépassé, jeton `ResourceLoader` ouvert, pool de projectiles qui refuse un tir, télémétrie incohérente.
- Tests GUT : `unit/telemetry/test_session_summary` (11), `integration/telemetry/test_boss_attempts` (4), `integration/generation/test_seed_determinism` (10 seeds, plan, offres trésor/boutique, ennemis des salles traversées), `integration/run/test_floor_load_time` (2). Suite : 848 réussis. `run_all.sh` en mode normal : toutes les scènes PASS ; `--quit-after 120` propre (zéro SCRIPT ERROR, zéro Parse Error).
- **Résultat du soak (une exécution, `bash tools/soak.sh`, 20 nuits, 10 victoires / 10 morts, 16 combats contre Le Professeur dont 7 Interros)** : PASSED, zéro erreur, zéro fuite ; nœuds constants à 187, orphelins 0, objets 2 501 à 2 586 (cache de salles), mémoire statique 58 à 59 Mo, chargement 95 à 109 ms depuis le lit au premier passage, 6 à 15 ms ensuite.

| nuit | départ | seed | issue | temps de jeu (s) | réveil | objets |
|---|---|---|---|---|---|---|
| 1 | lit | ZHXBPB2K | victoire | 12,0 | 00:18 | 2511 |
| 2 | relance | 46K5JDTN | mort en salle | 1,1 | 23:06 | 2521 |
| 3 | seed (chambre) | 00000D8B | victoire | 11,2 | 00:18 | 2530 |
| 4 | seed (réveil) | 000031MZ | mort au combat | 8,1 | 23:45 | 2529 |
| 5 | lit | 0ZN55CKS | victoire | 11,6 | 00:18 | 2532 |
| 6 | relance | BNVXVJ4V | mort à l'annonce | 3,5 | 23:32 | 2533 |
| 7 | seed (chambre) | 00088QZD | victoire | 11,7 | 00:18 | 2548 |
| 8 | seed (réveil) | 00041EZR | mort en salle | 1,1 | 23:06 | 2541 |
| 9 | lit | ZKQ85A49 | victoire | 11,3 | 00:18 | 2565 |
| 10 | relance | A8EG4YAB | victoire | 11,7 | 00:18 | 2562 |
| 11 | seed (chambre) | 00003RJ0 | mort au combat | 6,8 | 23:26 | 2565 |
| 12 | seed (réveil) | 0000KYZH | victoire | 11,6 | 00:18 | 2563 |
| 13 | lit | 8F58WS0X | mort en salle | 0,7 | 23:00 | 2571 |
| 14 | relance | HCXAW1EX | victoire | 11,6 | 00:18 | 2580 |
| 15 | seed (chambre) | 0000RN2H | mort à l'annonce | 2,6 | 23:19 | 2552 |
| 16 | seed (réveil) | 00000YK9 | victoire | 11,2 | 00:18 | 2552 |
| 17 | lit | GGKXZCRW | mort au combat | 7,2 | 23:32 | 2581 |
| 18 | relance | SHJAFE2W | mort en salle | 1,5 | 23:13 | 2567 |
| 19 | seed (chambre) | 0001HC3H | mort à l'annonce | 2,5 | 23:19 | 2562 |
| 20 | seed (réveil) | 0002JYJ9 | victoire | 11,7 | 00:18 | 2586 |

- **NON VÉRIFIÉ (humain)** : les 20 nuits jouées à la main sur la machine de référence ; chargement < 2 s et relance < 3 s sur cette machine (disque, GPU) ; durée médiane 12 à 18 min, ≥ 25 % de la run sous Lucide, 30 à 50 % de victoires contre Le Professeur dès la 5e tentative (aucune mesure automatique n'a de sens : le soak simule des coups) ; le temps de jeu des nuits du soak (≈ 11 s) vient des coups simulés, pas du jeu réel.

### Liste des fichiers

- `game/telemetry/telemetry_session.gd`, `game/telemetry/telemetry.gd`, `game/autoloads/events.gd` (`floor_ready`), `game/run/run.gd`, `game/main/main.gd`
- `game/debug/soak_runner.tscn`, `game/debug/soak_runner.gd`, `tools/soak.sh`, `.gitignore`
- `game/tests/unit/telemetry/test_session_summary.gd`, `game/tests/integration/telemetry/test_boss_attempts.gd`, `game/tests/integration/generation/test_seed_determinism.gd`, `game/tests/integration/run/test_floor_load_time.gd`

### Review Findings

Revue de `c124053..e1b2bf0` (lignes de `a56c20c` pour `run.gd`). Preuves : `SOAK_RUNS=60 bash tools/soak.sh` sur une copie propre de `e1b2bf0` : PASSED, 4 s, nœuds constants à 187 sur les 60 nuits, orphelins 0, objets 2 515 → 2 655 (+2,3 par nuit, dont 2 sont les `Night` et `Sample` du soak lui-même), mémoire statique 58,0 → 59,7 Mo ; `run_all.sh` en mode normal sur une copie propre de `e1b2bf0` (voir le rapport).

- [ ] [Review][Patch] La reprise d'une nuit reste invisible et ses objets sont recomptés dans la télémétrie (report de la revue 6.8, attribué à 6.9, non traité) : `runs_detail` et `run_start` d'une nuit reprise ressemblent à une nuit neuve, `items` de la session recompte chaque objet restauré [game/run/run.gd:99-100 ; game/telemetry/telemetry.gd:168 ; game/telemetry/telemetry_session.gd:62, 96, 182] — nouveau signal `Events.run_resumed` émis par `Run._ready()` juste avant `_announce_restored_items()` ; `Telemetry` → `_session.run_resumed()` : `"resumed": true` sur le dernier `run_start` et dans l'entrée `runs_detail` de la run (`_run_resumed`, remis à `false` dans `run_started`), et `_restoring = true` ; `item_taken` ajoute à `_run_items` mais pas à `items` tant que `_restoring` ; `room_entered` (émis par `_announce_room()` juste après) remet `_restoring = false` ; test unitaire : reprise avec 2 objets ⇒ `items` inchangé, `resumed` vrai.
- [ ] [Review][Patch] Marges de fuite du soak trop larges pour attraper une fuite lente (CA 3 « pas de croissance monotone ») : un nœud perdu par nuit passe 20 nuits avec ± 20 (les nœuds sont constants à 187), une fuite de 1 Mo par nuit passe avec 1,5× (≈ + 29 Mo tolérés), et les objets du soak lui-même (+ 2 par nuit) consomment la marge des objets [game/debug/soak_runner.gd:45-49, 116-121, 141] — `NODE_MARGIN = 2`, `MEMORY_GROWTH_LIMIT = 1.1` ; prendre l'échantillon sans compter les objets du soak (`night.sample.objects -= 2 * night.index`, ou créer les 20 `Night` avant la première nuit) puis `OBJECT_MARGIN = 100`.
- [ ] [Review][Patch] Le soak lancé hors de `tools/soak.sh` (éditeur, F6) écrit dans les vraies données du joueur : seul `SaveService` est redirigé, la session `Telemetry` (créée et élaguée dans son `_ready`, avant le soak) écrit 20 nuits factices de 11 s dans `user://telemetry/` [game/debug/soak_runner.gd:98-104 ; tools/soak.sh:13] — `tools/soak.sh` exporte `SOAK_ISOLATED=1` ; au début de `_run_soak`, si `OS.get_environment("SOAK_ISOLATED") != "1"` : `push_error("soak: run it with tools/soak.sh (user data must be isolated)")`, `get_tree().quit(1)`, `return`.
- [ ] [Review][Patch] Les nuits « seed saisie » ne passent pas par la fenêtre de saisie : `Events.run_requested` est émis directement, donc le bureau de la chambre (`_freeze(true)` puis la fenêtre) et « Nouvelle seed » de l'écran de réveil ne sont jamais joués (décision 11) [game/debug/soak_runner.gd:312-317, 332-334] — TYPED_BEDROOM : `bedroom.seed_entry_requested.emit()` ; TYPED_WAKE : `_wake().new_seed_requested.emit()` ; puis, dans les deux cas, `(_main.find_children("*", "SeedEntry", true, false)[0] as SeedEntry).seed_submitted.emit(SEEDS[night.index % SEEDS.size()])`.

Points vérifiés sans suite : `floor_ready` mesuré correctement (lit, boutons du réveil, fenêtre de saisie et reprise appellent `_start_run` de façon synchrone ; `run_started` part de `Run._ready()` pendant `add_child`) ; tentative contre le boss : ouverture à `boss_engaged` (avant l'annonce), victoire à `boss_defeated`, mort à `run_ended`, abandon à la relance ou à la fin de session ; part sous Lucide divisée par les secondes de paliers (décision 7) ; durée en images hors `GameClock.paused` (pause, réveil) ; clés existantes intactes (ajouts seulement : `runs_detail`, `boss_attempts`, `summary.below_lucid_*`, `run_start.startup_ms/load_ms`) ; durée bornée (`_until` à ticks bornés, `SOAK_MAX_SECONDS` entre deux nuits, `timeout` de `soak.sh`) ; erreurs moteur détectées par `soak.sh` (`SCRIPT ERROR`, `Parse Error`, `^ERROR:`, `physics`) ; `tools/soak-result.txt` ignoré par git ; une mort « en salle » au 3e combat est toujours possible (nightmare à ≥ 4 liaisons, cellules intermédiaires toutes de combat).

### Journal des modifications

- 2026-11-24 : télémétrie des indicateurs du jalon B, mesure du chargement d'étage, soak de 20 nuits, tests de déterminisme sur 10 seeds. Statut : review.
- 2026-11-24 : revue de code : 4 patchs, 3 reports. Statut : in-progress.
