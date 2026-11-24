# Story 3.6 : Subir le danger du palier le plus bas

Status: in-progress

## Story

En tant que joueur,
je veux que plonger rende la salle plus dangereuse jusqu'à sa fin, même si je remonte,
afin que dépenser soit un vrai risque.

Exigences : FR19 (vitesse des projectiles, télégraphes, signalement), AR10, P1 (epics.md, Story 3.6). Architecture : D5, ADR-002 (deux lectures de la lucidité), P1 (`DangerProfile`).

**Dépend de : 3.1** (paliers), **3.2** (`Lucidity.begin_room()` et `Arena.begin_room()` déjà appelés à chaque vague) et **3.3** (`ring_pulse`, dépenses : ce qui fait plonger). **Prépare 3.7** (renfort : lit `danger.reinforcement`, écoute `room_danger_raised`) et 3.8 (effets de palier en direct, pas de room).

Hors périmètre : renfort (3.7), pattern supplémentaire des cauchemars (`boss_extra_pattern` : champ calculé et testé, aucun consommateur avant epic 6), loot x1,25/1,5/2 (epic 5 ; `room_cleared` porte déjà `room_tier`), distorsions (3.8).

## Critères d'acceptation

1. **Début de vague** : `Lucidity.begin_room()` (étendu) fixe `room_tier = live_tier` ; `Arena.begin_room()` recalcule le `DangerProfile` de la salle depuis `room_tier`.
2. **Aggravation** : une dépense (ou `set_value`) qui amène `live_tier` plus profond que `room_tier` fait suivre `room_tier`, émet `Lucidity.room_danger_raised(tier)` (relayé par `Events.room_danger_raised(tier, previous)`) ; la salle recalcule son `DangerProfile` ; un son et un effet visuel signalent l'aggravation.
3. **Remontée** : `live_tier` qui remonte ne change ni `room_tier` ni le danger ; ils changent à la vague suivante (`begin_room()`).
4. **Projectiles** : avec `room_tier` en Dérive ou plus bas, un ennemi qui tire envoie son projectile 10 % plus vite (`enemy_bullet_speed_mult = 1,1`). Les projectiles déjà en vol gardent leur vitesse.
5. **Télégraphes** : avec `room_tier` en Abandon ou plus bas, la durée d'un télégraphe est multipliée par 0,85, sans jamais passer sous 0,4 s (`CombatTuning.min_telegraph`). Un télégraphe déjà lancé garde sa durée. Tous les ennemis (4) sont concernés.
6. **Seul `room_tier`** : aucun système de danger ne lit `live_tier`. F3 affiche `room_tier` (en plus de la ligne du palier en direct).
7. **`DangerProfile`** (`combat/danger_profile.gd`, `RefCounted`) : `enemy_bullet_speed_mult`, `telegraph_mult`, `reinforcement: bool`, `boss_extra_pattern: bool` ; `apply_tier(tier, tuning)` ; valeurs par palier dans `LucidityTuning`.
8. **`room_cleared`** reçoit `room_tier` : `Events.room_cleared(room: Node, lowest_tier: int)` ; tous les écouteurs sont mis à jour dans le même commit (joueur 3.2, télémétrie, scènes de test).

## Tâches

- [x] `LucidityTuning` : `danger_bullet_speed_mult` (par palier : 1, 1, 1.1, 1.1, 1.1), `danger_telegraph_mult` (1, 1, 1, 0.85, 0.85), `reinforcement_from_tier` (`Tier.ABANDON`), `boss_extra_pattern_from_tier` (`Tier.TOTAL_ABANDON`).
- [x] `Lucidity` : `room_tier`, `begin_room()` étendu, `is_deeper(a, b)`, signal `room_danger_raised(tier)` ; `room_tier` suit dans `set_value`/`try_spend` (après la mise à jour de `live_tier`).
- [x] `combat/danger_profile.gd` ; `Arena.danger` (un seul objet, **muté sur place** par `apply_tier`), `Arena.begin_room()` et `_on_room_danger_raised()` ; `Enemy.setup(def, target, hurtbox, bullets, danger)` (dernier paramètre facultatif, défaut : profil neutre) donné par `Arena.spawn_enemy`.
- [x] Ennemis : `Enemy._start_telegraph_of(base, sound)` (décision 10) appelle `telegraph.start(base, sound, danger.telegraph_mult)` ; remplacer les 5 appels directs (Somnambule, Mouton, Veilleuse/Berceuse via `ShooterEnemy._start_telegraph`) ; `ShooterEnemy._fire_volley()` règle `_bullet_params.speed = base * danger.enemy_bullet_speed_mult` avant `fire()`.
- [x] Signalement : son `sfx_danger_raised.wav` (grave, provisoire) et `ring_pulse` rouge sur le joueur (pas de flash plein écran), joués par `Arena._on_room_danger_raised`.
- [x] `Events.room_danger_raised` (relais par le joueur), `Events.room_cleared(room, lowest_tier)` ; F3 : `room_tier` et profil (`x1.1`, `x0.85`).
- [x] `t_danger` ; mise à jour des scènes existantes qui écoutent `room_cleared` ; `run_all.sh` une fois à la fin.

## État du code concerné

- `Lucidity` (3.1 à 3.3) : `value`, `live_tier`, `gain`, `try_spend`, `set_value`, `begin_room()` (3.2 : remet le compteur de graze à 0). **Pas encore de `room_tier`.** L'ordre de l'enum : `LUCID = 0` … `TOTAL_ABANDON = 4`, donc **« plus bas » = nombre plus grand**.
- `Arena._start_next_wave` (via `WaveRunner`) appelle `begin_room()` avant les apparitions (3.2).
- `Telegraph.start(base_seconds, sound, multiplier = 1.0)` fait déjà `max(base * multiplier, Tuning.COMBAT.min_telegraph)` (le commentaire du fichier l'annonce pour epic 3) ; les cinq sites d'appel passent le défaut aujourd'hui. `ShooterEnemy` stocke `_bullet_params` (instance propre) une fois et `_shooter_def.bullet_speed`.
- `Enemy.setup(def, target, target_hurtbox, bullets)` est appelé par `Arena.spawn_enemy` avant `add_child`. Les scènes `.scratch` qui instancient un ennemi sans salle gardent le profil neutre.
- `Events.room_cleared(room: Node)` : émis par `WaveRunner._on_room_emptied` ; écouteurs : joueur (3.2), `TelemetrySession` (2.8), scènes `.scratch` (`t_waves`…). Report de `deferred-work.md` : « le palier de lucidité s'ajoute à la signature ».
- Report à régler ici : « `fire_interval` ≤ durée du télégraphe » (2.4). Avec ×0,85 le télégraphe raccourcit, donc le cas empire moins qu'avant ; on ne change pas la Berceuse, on **vérifie** que pour chaque ennemi la durée de télégraphe effective reste inférieure à `fire_interval` à tous les paliers (test).
- 3.7 consomme `danger.reinforcement` ; 3.8 n'utilise pas le danger de salle (ses effets suivent le palier en direct).

## Pièges

- **Inversion de l'ordre** : `live_tier > room_tier` signifie « plus profond ». Écrire `is_deeper()` une fois et le tester (cas piégeux : Dérive -> Flottant, c'est une remontée).
- **Le profil est un objet partagé, muté sur place** : les ennemis déjà vivants le voient changer à leur prochain tir ou télégraphe (voulu, « les ennemis lisent `room.danger` quand ils lancent un télégraphe ou tirent ») ; ne pas en créer un nouveau (les ennemis garderaient l'ancien).
- **Vitesse du tir lue au moment du tir** : `_bullet_params.speed` est réécrit juste avant `fire()` ; un projectile déjà tiré a copié sa vitesse dans le manager. Garder la vitesse de base dans une variable (pas de multiplication cumulée à chaque salve !).
- `ADD_PERCENT` de 3.5 ne touche pas aux ennemis : le danger passe par le profil, pas par `StatBlock`.
- `room_tier` ne descend que par un geste du joueur ; `set_value` de F1 aussi : c'est un outil, il déclenche donc l'aggravation. Documenter dans l'aide F1 (`L` fait plonger la salle ; la vague suivante la relâche).
- **Signal avant relais** : `room_danger_raised` est émis après la mise à jour de `live_tier` **et** de `room_tier`, après `tier_changed` ; l'`Arena` recalcule dans son gestionnaire (pas dans le joueur).
- Rien ne lit `live_tier` pour le danger : garder `Arena`, `DangerProfile` et ennemis sans référence à `lucidity.live_tier` (relecture ciblée au code review).
- Le profil neutre par défaut (`Enemy.setup` sans danger) ne doit pas être un objet statique partagé muté par une salle de test.

## Vérifications prévues (`.scratch/t_danger.gd`)

- `Lucidity` pur : `begin_room()` à 80 -> `room_tier` Lucide ; chute à 40 -> Dérive, signal une fois ; chute à 20 -> Abandon, signal ; remontée à 90 -> `room_tier` inchangé, aucun signal ; `begin_room()` -> Lucide ; saut de plusieurs paliers = un seul signal avec le palier final ; départ en Abandon -> `room_tier` Abandon sans signal.
- `DangerProfile.apply_tier` : valeurs par palier (1 / 1 / 1,1 / 1,1 et 0,85 / même chose), `reinforcement` dès Abandon, `boss_extra_pattern` seulement en Abandon total.
- Jeu : en Dérive, une Veilleuse tire à 5,5 au lieu de 5 tuiles/s (vitesse mesurée sur le projectile) ; un projectile en vol garde la sienne ; en Abandon, le télégraphe de chaque ennemi dure `max(base × 0,85, 0,4)` (mesuré en ticks, y compris un cas où `base × 0,85 < 0,4`) ; une dépense en pleine vague fait aggraver tout de suite ; remonter ne change pas les durées, la vague suivante oui.
- Signalement : son joué, anneau créé ; `room_cleared` porte `room_tier` ; F3 contient `room_tier`.
- Cycle : pour chaque ennemi tireur, télégraphe effectif < `fire_interval` aux 5 paliers.

## Fichiers prévus

`game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`, `game/player/lucidity.gd`, `game/player/player.gd`, `game/combat/danger_profile.gd`, `game/enemies/enemy.gd`, `game/enemies/shooter_enemy.gd`, `game/enemies/{sleepwalker,sheep}/*.gd`, `game/rooms/arena/arena.gd`, `game/rooms/waves/wave_runner.gd`, `game/autoloads/events.gd`, `game/telemetry/*.gd`, `game/debug/perf_overlay.gd`, `game/audio/sfx/sfx_danger_raised.wav`, `game/.scratch/t_danger.*` et scènes existantes qui écoutent `room_cleared`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **`DangerProfile` unique par salle, mutée sur place** — Raison : les ennemis (déjà apparus) lisent la valeur courante sans abonnement ; l'alternative (signal vers chaque ennemi) alourdit sans rien changer au gameplay.
2. **Départ de vague en Abandon : danger et renfort du palier dès le début, sans son d'aggravation** — Raison : « la salle commence à ce palier » ; le signalement est réservé aux aggravations en pleine salle (GDD).
3. **Le danger de la salle s'applique aux ennemis qui tirent ou lancent un télégraphe après l'aggravation ; rien n'est rétroactif** — Raison : AC (« projectiles en vol », télégraphe lancé).
4. **Signalement : son grave et anneau rouge autour du joueur, pas de flash** — Raison : lisibilité et photosensibilité (FR67) ; l'intensité est réglable en 3.8.
5. **`Events.room_cleared(room, lowest_tier)`** — Raison : report de 2.8 ; l'epic 5 en a besoin (loot) ; le faire ici évite de revenir sur les écouteurs.
6. **`F1 L` fait aggraver la salle en cours** — Raison : mêmes méthodes que le jeu (règle F1) ; c'est ce qui permet de tester le danger.
7. **Le Mouton et le Somnambule subissent seulement ×0,85 sur les télégraphes** (pas de projectiles) — Raison : GDD ne cite que « projectiles ennemis » et « télégraphes ».
8. **Pas de modification de la Berceuse pour le report `fire_interval`** — Raison : le danger raccourcit les télégraphes ; seul un test garde l'invariant.
12. **Revue : la décision 11 est remplacée — le son et l'anneau rouge ne se jouent que si le `DangerProfile` change** (Lucide -> Flottant : aucun signal ; Flottant -> Dérive, Dérive -> Abandon, Abandon -> Abandon total : signal). `Lucidity.room_danger_raised` et `Events.room_danger_raised` restent émis à chaque palier plus profond (loot de l'epic 5, renfort de 3.7). — Raison : le tableau du GDD donne « Aucun » danger en Flottant et le pilier « le danger reste lisible » réserve le signal aux aggravations réelles ; sinon le premier Éveil depuis 100 (-> 70) de chaque vague joue quatre retours à la fois (son et anneau d'Éveil, son de palier, son et anneau de danger) sans aucun effet ; le passage de palier a déjà son propre son. Réversible en une ligne.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `DangerProfile` (un objet par `Arena`, muté sur place) ; `Lucidity.room_tier`, `begin_room()` étendu, `is_deeper()`, `room_danger_raised(tier, previous)`. `room_tier` est mis à jour avant tout signal ; `room_danger_raised` part en dernier, une fois par mouvement (saut de plusieurs paliers = un seul signal).
- `Enemy.setup(..., room_danger)` (profil neutre propre par défaut, jamais statique) ; `Enemy._start_telegraph_of(base, sound)` remplace les appels directs (Somnambule, Mouton, `ShooterEnemy._start_telegraph`). `ShooterEnemy._fire_volley` réécrit `_bullet_params.speed = _base_bullet_speed * mult` avant `fire()`.
- `Arena._on_room_danger_raised` : recalcule le profil, joue `sfx_danger_raised.wav` et un `RingPulse` rouge autour du joueur. `Arena.room_tier()` alimente `Events.room_cleared(room, lowest_tier)` (WaveRunner). F3 : `Room tier ... | bullets xN | telegraphs xN`.
- Écouteurs mis à jour : joueur, `t_graze`, `t_waves`, `t_waves_main`. `t_awakening` : 2 anneaux (Éveil + danger) quand 100 -> 70 quitte Lucide. Télémétrie n'écoutait pas `room_cleared` : rien à changer.
- `t_danger` (55 vérifications) ajouté à `run_all.sh`.

### Décisions prises pendant le développement

9. **`Lucidity.room_danger_raised(tier, previous)`** (deux arguments, la spec en donnait un) — Raison : `Events.room_danger_raised(tier, previous)` a besoin du palier précédent, que le joueur ne peut pas deviner (`begin_room()` change `room_tier` sans signal).
10. **`Enemy._start_telegraph_of(base, sound)`** au lieu de `_start_telegraph(base, sound)` — Raison : `ShooterEnemy._start_telegraph(sound)` existe déjà avec une autre signature (conflit de surcharge).
11. **Le signalement se joue à toute aggravation, y compris Lucide -> Flottant** (remplacée en revue par la décision 12) (danger inchangé à ce palier) — Raison : l'AC 2 le dit (« dépense qui amène `live_tier` plus profond que `room_tier` ») ; reporté au playtest.

### File List

`game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`, `game/player/lucidity.gd`, `game/player/player.gd`, `game/combat/danger_profile.gd`, `game/combat/telegraph.gd` (commentaire), `game/enemies/enemy.gd`, `game/enemies/shooter_enemy.gd`, `game/enemies/sleepwalker/sleepwalker.gd`, `game/enemies/sheep/sheep.gd`, `game/rooms/arena/arena.gd`, `game/rooms/waves/wave_runner.gd`, `game/autoloads/events.gd`, `game/debug/perf_overlay.gd`, `game/debug/debug_panel.gd`, `game/audio/sfx/sfx_danger_raised.wav`, `_bmad-output/implementation-artifacts/deferred-work.md`, `.scratch/t_danger.*`, `.scratch/run_all.sh`, scènes `.scratch` mises à jour (non versionnées).

### Change Log

- 2026-11-24 : implémentation de la story 3.6 (danger de salle), passée en review.
- 2026-11-24 : revue de code, 3 correctifs à faire, story repassée en in-progress.

### Review Findings

Revue de code (2026-11-24, Claude Opus 5.5, mode complet : Blind Hunter, Edge Case Hunter, Acceptance Auditor) sur `ce0fd32..62eedbd` (commits hors ordre de dépendance relus comme un tout).

- Critères 1, 3 à 8 : satisfaits. `is_deeper()` correct avec l'enum inversé ; `room_tier` mis à jour avant tout signal, un seul signal par saut ; `begin_room()` le remet au palier en direct à chaque vague (appelé depuis `WaveRunner._start_next_wave`, jamais en synchrone depuis `_wait`, donc `room_cleared` lit bien le palier de la vague nettoyée). `BulletManager.fire()` copie la vitesse : les balles en vol gardent la leur ; `_base_bullet_speed` évite tout cumul ; `Telegraph.start` garde le plancher `min_telegraph`. Les seuls appels `telegraph.start` / `fire` d'ennemis passent par le profil. Aucun système de danger ne lit `live_tier`. Seul le joueur écoute `room_cleared` (la télémétrie ne l'a jamais écouté). Relance en pleine salle : `Run` est recréé (joueur, jauge et `Arena.danger` neufs, palier Lucide).
- Preuve : `t_danger` 55/0 (`--fixed-fps 60`, arbre courant).
- [ ] [Review][Patch] Signal d'aggravation joué même quand le danger ne change pas (Lucide -> Flottant, premier Éveil de chaque vague) [`game/rooms/arena/arena.gd:197-201` au commit `62eedbd`] — décision 12 : `DangerProfile.apply_tier()` renvoie `bool` (vrai si un des quatre champs a changé) ; `_on_room_danger_raised` applique le profil puis `return` avant le son et l'anneau quand il renvoie faux (garder le `Log.debug`). Adapter `t_awakening` (1 anneau : Éveil seul, 100 -> 70) et les vérifications de signalement de `t_danger` (cas Lucide -> Flottant : aucun son ni anneau ; Flottant -> Dérive : son et anneau).
- [ ] [Review][Patch] Architecture P1 périmée, que la 3.7 risque de recopier [`_bmad-output/game-architecture.md:720` et `:728-733`] — signal `room_danger_raised(tier, previous)`, `danger.apply_tier(tier, Tuning.LUCIDITY)` muté sur place (pas `DangerProfile.from_tier`, qui ferait garder l'ancien profil aux ennemis vivants), signalement seulement si le profil change.
- [x] [Review][Patch] Deux tâches restées décochées alors qu'elles sont faites (Ennemis, Signalement), nom `_start_telegraph_of` — corrigé dans ce fichier pendant la revue.
- Reportés (`deferred-work.md`) : relais `Events.room_danger_raised` émis avant le recalcul du profil ; bornes des tables de danger et vitesse multipliée ; salles sans vagues dont le `room_tier` ne repart jamais ; signal joué pendant la pause entre deux vagues ; palier de départ de la télémétrie (report de 3.1 retagué).
- Écartés (12) : écouteurs de `room_cleared` non mis à jour (aucun autre), vitesse des balles en vol (copiée par `fire()`), `lucidity` nulle à la connexion (joueur prêt avant l'arène, comme pour `awakening_used`), ennemis hors `spawn_enemy` neutres (voulu), autres chemins d'attaque (aucun), `room_tier` lu après `_wait` (asynchrone), `previous` intermédiaire en cas de réentrance (aucun écouteur ne replonge), overlay à deux sources, arène non déconnectée (`Run` libéré en entier), ordre des commits (historique publié), couverture partielle des tests (pipeline allégé), écouteur télémétrie de l'AC 8 (n'existait pas).
