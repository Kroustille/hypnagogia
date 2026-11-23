# Story 3.2 : Regagner sa lucidité par le skill

Status: ready-for-dev

## Story

En tant que joueur,
je veux regagner de la lucidité en frôlant les projectiles et en dashant au bon moment,
afin que mon skill nourrisse mes pouvoirs.

Exigences : FR22, AR10, AR11, FR68 (sons du graze et du dash parfait, provisoires) (epics.md, Story 3.2). Architecture : D5, pattern P2 (graze et dash parfait), ADR-002.

**Dépend de : 3.1** (`Lucidity`, `LucidityTuning`, `Events.lucidity_*`, F1 `L`, F3). Les stories 3.3 (dépense), 3.6 (`room_tier`) et 3.7 (renfort) étendent `Lucidity.begin_room()` et `Arena.begin_room()` créés ici.

Hors périmètre : `try_spend` (3.3), bonus de palier (3.5), `room_tier` et danger (3.6). Le consommable « Se pincer » (+25, epic 5) réutilisera `gain(25, Source.CONSUMABLE)` : la source existe dès maintenant, sans plafond.

## Critères d'acceptation

1. **Graze** : un projectile ennemi dont le centre passe à moins de `graze_radius` (1 tuile) du rectangle de la hurtbox du joueur sans la toucher, alors que le joueur n'est pas invulnérable (ni dash, ni après un coup), donne +2 (`Lucidity.gain`, source `GRAZE`), émet `Events.player_grazed(position, gained)`, joue un son discret et pose `FLAG_COUNTED` sur le projectile. Le même projectile ne rapporte plus de graze. Un projectile qui frôle pendant une invulnérabilité n'est pas marqué ni compté.
2. **Dash parfait** : quand l'invulnérabilité du **dash** évite un projectile qui aurait touché (le projectile recouvre la hurtbox pendant `is_dash_invulnerable()`), le joueur gagne +5 (source `PERFECT_DASH`), `Events.perfect_dash(position, gained)` est émis, un son plus marqué se joue, le projectile continue sa course et ne peut plus rapporter de graze. Compté **par projectile**, jamais par dash (`FLAG_DODGED`). L'invulnérabilité après un coup ne donne rien.
3. **Plafond** : les grazes rapportent au plus +20 depuis `begin_room()`, tenu par `Lucidity.gain()` (le `BulletManager` ne compte rien). Au-delà, `gain()` renvoie 0 ; le projectile reste marqué et l'événement est quand même émis (avec `gained = 0`). Le dash parfait et la salle vidée ne sont pas plafonnés par ce compteur.
4. **Début de vague** : `Lucidity.begin_room()` remet le compteur de graze à 0 ; `Arena.begin_room()` l'appelle, et `WaveRunner` appelle `Arena.begin_room()` au début de **chaque** vague, avant les apparitions (y compris `force_next_wave`).
5. **Salle vidée** : à `Events.room_cleared`, le joueur vivant gagne +5 (source `ROOM_CLEARED`).
6. **Debug** : F2 affiche aussi la zone de graze (hurtbox élargie du rayon de graze).
7. Valeurs (rayon, gains, plafond) dans `LucidityTuning`, aucune en dur. Sons dans `audio/sfx/` (`sfx_graze.wav`, `sfx_perfect_dash.wav`, générés par script, provisoires, remplacés en 7.7).

## Tâches

- [ ] `LucidityTuning` : `graze_radius` (1.0, tuiles), `graze_gain` (2), `perfect_dash_gain` (5), `room_cleared_gain` (5), `graze_cap_per_room` (20).
- [ ] `Lucidity` : `enum Source { OTHER, GRAZE, PERFECT_DASH, ROOM_CLEARED, CONSUMABLE }` ; `gain(amount: int, source: Source = Source.OTHER) -> int` (renvoie le gain réel ; `GRAZE` borné par `graze_cap_per_room - _room_graze_gained`) ; `begin_room()`. Le défaut garde les appels de 3.1.
- [ ] `Hurtbox` : `set_evade_filter(Callable)` et `is_evading() -> bool` (faux sans filtre) ; le joueur y branche `is_dash_invulnerable`.
- [ ] `BulletManager` : `FLAG_DODGED = 4` ; `enable_graze(hurtbox, radius_tiles)` ; signaux locaux `grazed(position: Vector2)` et `dodged(position: Vector2)` ; test de graze et d'esquive dans la boucle (voir État du code) ; livraison des signaux après la boucle.
- [ ] `Arena` : `begin_room()`, branche `bullets.enable_graze(...)` et connecte les signaux au joueur ; `WaveRunner._start_next_wave()` appelle `_room.begin_room()`.
- [ ] `Player` : `on_bullet_grazed(position)` / `on_bullet_dodged(position)` (gain, `Events`, son, `Log.debug`) ; écoute de `Events.room_cleared` ; filtre d'esquive.
- [ ] `Events.player_grazed`, `Events.perfect_dash` ; `CollisionDrawer` (F2) dessine la zone de graze.
- [ ] Sons et vérifications headless (`t_graze`), `run_all.sh` une fois à la fin, `--quit-after 120` propre.

## État du code concerné

- `BulletManager._physics_process` : par projectile actif, déplacement, puis `_test_targets(i)` (cercle contre rectangle des hurtboxes **hittables**, cible lue une fois par tick dans `_target_rects` / `_target_hittable`), puis durée de vie et murs. `FLAG_COUNTED = 2` est déjà réservé « pour le graze et le dash parfait ». Les touches sont livrées après la boucle (`_deliver_hits`) : les signaux de graze suivent le même principe (tableaux réutilisés, jamais d'émission pendant l'itération).
- Le joueur est enregistré comme cible du manager ennemi par `Arena._setup_enemy_bullets()` ; sa hurtbox a `one_hit_per_tick = true` et un `hit_filter` (`not is_invulnerable() and not is_dead()`). Quand le filtre dit non, `_test_targets` saute la cible : le projectile traverse sans rien dire. C'est exactement le cas à détecter pour le dash parfait.
- `Player.is_dash_invulnerable()`, `is_invulnerable()` (dash ou coup) existent. Invulnérabilité du dash : 0,15 s depuis le début ; coup : 1 s. Le joueur est dans `Run`, la salle reçoit `Player` par `setup()`.
- `WaveRunner._start_next_wave()` est le seul point de début de vague (aussi appelé par `force_next_wave`) ; `Events.room_cleared(room: Node)` est émis par `_on_room_emptied`.
- Plus tard : 3.3 ajoute `try_spend` dans `Lucidity` et le premier `power_*` ; 3.4 ajoute une invulnérabilité de Glissement dans `Player.is_invulnerable()` (elle n'est pas `is_evading()` : pas de dash parfait) ; 3.5 réduit la hurtbox en Lucide (le graze lit `world_rect()` donc suit sans changement) ; 3.6 étend `begin_room()` et `room_cleared`.

## Règles de détection (par tick, par projectile non touché)

Cible de graze = la hurtbox du joueur, lue une fois par tick : rectangle, `hittable`, `evading`, plus « invulnérable pour une autre raison » = `not hittable and not evading`.

1. Projectile qui touche (cercle contre rectangle) la hurtbox et `evading` : si pas `FLAG_DODGED` → pose `FLAG_DODGED | FLAG_COUNTED`, enregistre la position pour `dodged`. Le projectile n'est **pas** libéré.
2. Sinon, hurtbox `hittable`, pas `FLAG_COUNTED`, et distance du centre du projectile au rectangle < `graze_radius` en pixels → pose `FLAG_COUNTED`, enregistre pour `grazed`.
3. Hurtbox invulnérable pour une autre raison : rien.

Distance au carré, sans racine ; un test de boîte englobante élargie écarte vite la plupart des projectiles (pas d'allocation, pas de `Array` par tick).

## Pièges

- **Écart assumé avec P2** : P2 écrit `not _counted[i]` pour le dash parfait. Un projectile déjà frôlé avant le dash perdrait alors son +5 : or un dash réactif arrive presque toujours quand le projectile est déjà à moins d'une tuile (à 5 tuiles/s, la zone de 1 tuile précède l'impact de 0,2 s, l'invulnérabilité dure 0,15 s). On sépare donc `FLAG_DODGED` (dash parfait déjà compté) de `FLAG_COUNTED` (graze déjà compté) ; un projectile frôlé puis esquivé rapporte 2 + 5. Voir décision 1.
- Après la fin de l'invulnérabilité du dash, un projectile esquivé qui recouvre encore la hurtbox touche le joueur (il n'a pas été libéré). C'est voulu (P2 : « continue sa course »), à noter au playtest.
- `one_hit_per_tick` passe `_target_hittable[t]` à faux après la première touche du tick : les projectiles suivants de ce tick ne doivent ni frôler ni esquiver (`evading` faux, `hittable` faux, rien).
- Livrer `grazed` / `dodged` **après** la boucle : `Lucidity.gain` peut changer de palier et déclencher son, bus, télémétrie ; aucune écriture dans les tableaux du manager pendant leur parcours.
- Plafond : le compteur de salle vit dans `Lucidity` (pur, testable sans scène). Ne jamais le dupliquer dans le manager.
- `Events.room_cleared` : le joueur d'un `Run` détruit est libéré avec lui (la connexion d'un `Callable` d'objet libéré tombe seule) ; garder quand même le test `health.is_dead()` avant de gagner. Un joueur mort ne reçoit rien.
- Le signal de 3.6 ajoutera `lowest_tier` à `room_cleared(room, …)` : le gestionnaire du joueur doit déjà tolérer ce changement (3.6 met tous les écouteurs à jour dans le même commit).
- Sons : `Audio.play_sfx(stream, max_voices)` ; graze à 2 voix au plus (un mur de projectiles ne doit pas saturer), dash parfait à 1.
- Typage strict, pas de `Variant` implicite ; `_flags` est un `PackedByteArray` : `_flags[i] |= FLAG_COUNTED`.

## Vérifications prévues (`.scratch/t_graze.gd`)

- `Lucidity` pur : `gain(+2, GRAZE)` ×11 depuis 50 → +20 puis 0 ; `begin_room()` rouvre le plafond ; `gain(5, PERFECT_DASH)` et `ROOM_CLEARED` hors plafond ; renvoie le gain réel (95 + 10 → 5).
- Manager ennemi seul + hurtbox de joueur factice : projectile qui passe à 12 px (graze) ; à 20 px (rien) ; qui touche (coup, pas de graze) ; deux projectiles côte à côte (deux grazes) ; un même projectile sur plusieurs ticks (un seul graze).
- Invulnérabilité de coup : aucun graze, `FLAG_COUNTED` non posé ; invulnérabilité de dash : projectile qui recouvre = un `dodged`, libre de poursuivre, un seul `dodged` malgré plusieurs ticks de recouvrement, deux projectiles = deux ; frôlé puis esquivé = 2 + 5.
- Dans le jeu : `Events.player_grazed` / `perfect_dash` émis, jauge à jour, son joué (voix), compteur remis à 0 à la vague suivante (`WaveRunner`), +5 à la salle vidée, aucun gain après la mort.
- F2 : le tracé de la zone existe (rectangle élargi de `graze_radius`), pas de lecture de pixels.

## Fichiers prévus

`game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`, `game/player/lucidity.gd`, `game/player/player.gd`, `game/combat/hurtbox.gd`, `game/combat/bullets/bullet_manager.gd`, `game/rooms/arena/arena.gd`, `game/rooms/waves/wave_runner.gd`, `game/autoloads/events.gd`, `game/debug/collision_drawer.gd`, `game/audio/sfx/sfx_{graze,perfect_dash}.wav`, `game/.scratch/t_graze.*` et `run_all.sh` (non versionnés).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Un projectile déjà frôlé peut encore rapporter un dash parfait (2 + 5)** — Raison : sinon le dash parfait serait presque inatteignable en réaction ; s'écarte de la lettre de P2 (`not counted`) et du GDD (« remplace le graze »), pas de son esprit (récompenser l'esquive). Alternative si trop généreux : ne donner que +3 de complément.
2. **Distance mesurée du centre du projectile au rectangle de la hurtbox** (pas du bord du projectile) — Raison : « à moins d'une tuile de la hitbox » ; le rayon du projectile (4 px) reste sous 1 tuile et ne change pas la lecture.
3. **Le plafond atteint garde le projectile marqué, le son et l'événement** (`gained = 0`) — Raison : le joueur a bien frôlé ; un son qui disparaît sans raison lui semblerait un bug.
4. **`Lucidity.gain(amount, source)` renvoie le gain réel** — Raison : l'événement et la télémétrie portent ce qui a été gagné, pas ce qui était demandé.
5. **Gain de salle vidée porté par le joueur (écoute de `Events.room_cleared`)** — Raison : le joueur possède `Lucidity` ; la salle n'a pas à le connaître. `Arena.begin_room()` est lui appelé par `WaveRunner`.
6. **Un dash parfait n'est pas plafonné** — Raison : le GDD ne plafonne que le graze ; le dash parfait est le geste difficile.
7. **Zone de graze en F2 = rectangle élargi** (coins carrés, pas arrondis) — Raison : outil de debug ; l'écart de coin (0,4 tuile) est invisible en jeu.

## Dev Agent Record

### Agent Model Used

### Completion Notes

### File List
