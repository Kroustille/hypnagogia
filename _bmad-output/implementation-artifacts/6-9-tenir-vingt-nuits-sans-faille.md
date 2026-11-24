# Story 6.9 : Tenir vingt nuits sans faille

Status: ready-for-dev

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

- [ ] `telemetry/telemetry_session.gd` : `runs_detail`, `boss_attempts`, durées par run (ticks ou secondes de session, mêmes sources que `tier_seconds`), parts sous Lucide ; `telemetry.gd` écoute `Events.boss_engaged`, `boss_health_changed`, `boss_phase_changed`, `boss_defeated`, `wake_time_set`, `run_ended(outcome)` (6.4) et `Events.floor_ready` si créé ; `to_dict` : sections `runs_detail`, `boss_attempts`, `summary.below_lucid_*`.
- [ ] `run/run.gd` : mesure `startup_ms` et journalise ; `main/main.gd` : durée de la demande à `run_started`.
- [ ] `debug/soak_runner.gd` + `.tscn`, `tools/soak.sh` (lance Godot en `--fixed-fps 60` plus rapide que le temps réel, comme `FAST=1`, et affirme les critères 2 et 3, code de sortie non nul en cas d'échec) ; résultat texte dans `tools/` sorti, **non versionné**.
- [ ] Tests GUT : télémétrie, déterminisme de 10 seeds, seuil de chargement.
- [ ] Consigner dans cette story les résultats du soak (20 lignes) et ce qui reste NON VÉRIFIÉ.

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
6. **Le soak n'est pas dans la suite GUT** (trop long) : script dédié, lancé à la main et par l'orchestrateur à la fin de l'epic.

## Dev Agent Record

### Notes de complétion

### Liste des fichiers

### Journal des modifications
