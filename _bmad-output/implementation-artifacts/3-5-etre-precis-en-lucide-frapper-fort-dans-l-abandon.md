# Story 3.5 : Être précis en Lucide, frapper fort dans l'abandon

Status: done

## Story

En tant que joueur,
je veux que chaque palier change ma façon de combattre,
afin de choisir entre la précision et la puissance.

Exigences : FR18, AR15 (`StatBlock`) (epics.md, Story 3.5). Architecture : D9 (`StatBlock`, modificateurs), P1 point 7 (les bonus suivent `live_tier`, jamais `room_tier`).

**Dépend de : 3.1** (`tier_changed`, `live_tier`) ; fonctionne sans 3.2 à 3.4 mais se joue avec (la jauge doit descendre pour voir les bonus ; F1 `L` suffit pour tester). Indépendante de 3.6 : ne lit jamais `room_tier`.

Hors périmètre : loot ×1,25 / ×1,5 / ×2 (epic 5, à lire sur `room_tier`), objets et bonus d'objets (epic 5 ajoutera ses modificateurs au même `StatBlock`), pattern supplémentaire des cauchemars (epic 6).

## Critères d'acceptation

1. **`StatBlock`** (`core/stat_block.gd`, `RefCounted`, sans scène) : stats de base données par les Resources ; modificateurs `ADD_PERCENT` **additionnés entre eux** puis appliqués à la base. Formule : `(base + somme(ADD_FLAT)) * (1 + somme(ADD_PERCENT)) * produit(MULTIPLY)`. Les modificateurs sont identifiés par leur **source** (un objet) : `set_modifier(source, stat, kind, value)` remplace celui de la même source et de la même stat ; `clear_source(source)` les retire tous. Signal `changed(stat)` quand une valeur calculée change.
2. **Stats portées par le joueur** : `DAMAGE` (base `ShotTuning.damage` = 10), `SHOT_SPEED` (`ShotTuning.bullet_speed` = 14 tuiles/s), `HURTBOX_SIZE` (`PlayerTuning.hitbox_size` = 0,375 tuile = 6 px).
3. **Lucide en direct** : projectiles du joueur 30 % plus rapides (`+0,30` sur `SHOT_SPEED`, soit 18,2 tuiles/s) et hurtbox de 4x4 px (`0,25` tuile) au lieu de 6x6.
4. **Dégâts par palier** (en direct) : Lucide 10, Flottant 11 (+10 %), Dérive 12 (+20 %), Abandon et Abandon total 13,5 (+35 %). La précision de Lucide disparaît dès qu'on quitte ce palier (vitesse et hurtbox reviennent à la base) ; elle revient en remontant.
5. **Mise à jour** : sur `tier_changed` (et une fois à la création du joueur), les modificateurs du palier remplacent ceux du précédent ; la remontée en pleine vague agit aussitôt. Les projectiles déjà en vol gardent vitesse et dégâts ; seuls les tirs suivants changent.
6. **Données** : bonus de dégâts par palier, bonus de vitesse et taille de la hurtbox de Lucide dans `LucidityTuning` ; aucune valeur de GDD dans le code.
7. **Lecture en direct** : rien ici ne lit `room_tier` (n'existe pas encore) ; le HUD / F3 peuvent afficher dégâts et vitesse courants (ligne F3).

## Tâches

- [ ] `core/stat_block.gd` : `enum Stat { DAMAGE, SHOT_SPEED, HURTBOX_SIZE }`, `enum Kind { ADD_FLAT, ADD_PERCENT, MULTIPLY }`, `value_of(stat)`, `base_of`, `set_base`, `set_modifier`, `clear_source`, signal `changed(stat: int)`.
- [ ] `LucidityTuning` : `tier_damage_bonus: PackedFloat32Array` (0, 0.10, 0.20, 0.35, 0.35 dans l'ordre de `Lucidity.Tier`), `lucid_shot_speed_bonus` (0.30), `lucid_hurtbox_size` (0.25).
- [ ] `Player` : `stats: StatBlock` créé dans `_ready()` depuis `Tuning.SHOT` et `Tuning.PLAYER` ; `_apply_tier_modifiers(tier)` appelé à la création et sur `tier_changed` ; branchement de `stats.changed` sur `_shot_params` (vitesse, dégâts) et sur la forme de la hurtbox.
- [ ] `Player.equip_bullets()` lit les valeurs courantes de `stats` (et non plus directement `Tuning.SHOT`) ; la hurtbox change de taille sans nouvelle instance de forme.
- [ ] Ligne F3 (dégâts, vitesse) ; `CollisionDrawer` suit la forme (elle est déjà dans le groupe de debug).
- [ ] Vérifications `t_stat_block` (pur) et `t_tier_bonus` (jeu) ; `run_all.sh` une fois à la fin.

## État du code concerné

- `Player.equip_bullets()` construit `_shot_params` (un `BulletParams` propre) une fois : `speed = tuning.bullet_speed`, `damage = tuning.damage`, etc. `BulletManager.fire()` copie `speed`, `damage` et `radius` du `BulletParams` **dans les tableaux du projectile** : changer `_shot_params.speed` ne touche que les tirs suivants (c'est exactement le comportement voulu).
- La hitbox du joueur : `_hitbox` (`CollisionShape2D`, corps de mouvement, 6x6 px, forme propre au joueur) et `hurtbox` (nœud `Hurtbox` dont `Shape` est un `RectangleShape2D` propre, 6x6 px) ; tous deux issus de `PlayerTuning.hitbox_size`. **Seule la hurtbox rétrécit** : le corps garde 6x6 (voir décision 3).
- `BulletManager` lit `hurtbox.world_rect()` à chaque tick : un changement de taille agit au tick suivant, sans rien déclarer. Le graze (3.2) lit le même rectangle : sa zone suit la précision.
- 3.1 : `Player._on_lucidity_tier_changed` relaie sur le bus et joue le son ; on y ajoute l'appel des modificateurs **avant** le relais (les écouteurs du bus voient les stats à jour).
- `Telemetry` ne change pas. Les dégâts du joueur apparaissent en chiffres flottants (`roundi`) : 13,5 s'affiche 14 (décision 4).
- 3.6/3.7 ne touchent pas à `StatBlock`. L'epic 5 y ajoutera `ItemEffect` et des sources d'objets (`set_modifier(item, …)`) : la clé de modificateur est un `Object` quelconque, d'où le nom `source`.

## Pièges

- **Un seul `RefCounted` source par palier** : la source des modificateurs de palier est l'objet `Lucidity` du joueur ; `set_modifier(lucidity, Stat.DAMAGE, ADD_PERCENT, bonus)` remplace le précédent. Ne jamais empiler une entrée par changement de palier.
- **`ADD_PERCENT` entre eux** : `+0,1` (palier) et `+0,3` (objet futur) donnent `base * 1,4`, pas `1,1 * 1,3`. Test pur dédié.
- **Flottants** : `10 * 1,35 = 13,5` exactement ; `0,375 + (-0,125)` n'est pas exact : la hurtbox de Lucide est un **remplacement** (`ADD_FLAT = lucid_hurtbox_size - base`) ; comparer avec `is_equal_approx`. Ne pas passer par `MULTIPLY` (2/3 n'est pas représentable).
- `StatBlock.changed` ne doit partir que si la valeur calculée change (sinon `Player` réécrit la forme à chaque appel) ; ne pas émettre dans `set_modifier` si le modificateur est identique.
- **Forme partagée** : changer `shape.size` d'une `RectangleShape2D` change la ressource, jamais celle d'une scène : la hurtbox a sa propre forme créée en code (3.1 / 2.1), vérifier avant d'écrire.
- La précision ne doit pas dépasser la limite de vitesse de `BulletManager._is_shot_valid` (< 60 tuiles/s = 1 tuile par tick) : 18,2 est sûr ; `StatBlock` ne borne rien (le manager valide).
- Une hurtbox plus petite change la zone de graze mais pas l'AC de 3.2 (distance au rectangle) : pas de cas à traiter, un test de non-régression suffit.
- Appliquer au démarrage : `tier_changed` n'est pas émis pour l'état initial (3.1) ; sans appel initial le joueur Lucide n'aurait pas la précision.

## Vérifications prévues

- `t_stat_block` (pur) : base seule ; `ADD_PERCENT` additionnés (0,1 + 0,2 -> ×1,3) ; `ADD_FLAT` puis pourcentage puis `MULTIPLY` dans l'ordre ; deux sources, l'une retirée ; remplacement de la même source ; `changed` émis une fois par vraie variation, pas sur un set identique ; entiers et flottants (13,5 exact).
- `t_tier_bonus` (jeu, `main.tscn`, F1 `L` ou `lucidity.set_value`) : à 100 -> vitesse de tir 18,2 et hurtbox 4x4 (`world_rect().size`), dégâts 10 ; à 75 -> 14 et 6x6, dégâts 11 ; à 50 -> 12 ; à 25 et 0 -> 13,5 ; remontée à 80 -> précision revenue.
- Tir réel : un projectile tiré à 100 garde 18,2 après passage à 50 ; le tir suivant part à 14 (lecture du manager ou distance parcourue sur N ticks) ; les dégâts reçus par un ennemi factice sont 10, 11, 12, 13,5 aux paliers.
- Non-régression : graze à 12 px du rectangle réduit ; corps de mouvement `_hitbox` toujours 6x6.

## Fichiers prévus

`game/core/stat_block.gd`, `game/core/lucidity_tuning.gd`, `game/data/tuning/lucidity_tuning.tres`, `game/player/player.gd`, `game/debug/perf_overlay.gd`, `game/.scratch/t_stat_block.*`, `game/.scratch/t_tier_bonus.*`.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **« Projectiles 30 % plus rapides » = vitesse de balle ×1,3, pas la cadence** — Raison : l'AC de l'epic dit « vont 30 % plus vite » ; le GDD écrit « tirs 30 % plus rapides » (ambigu). À valider en jouant.
2. **Hurtbox de Lucide par remplacement (`ADD_FLAT`)** — Raison : 4 px est une valeur absolue du GDD, pas un pourcentage.
3. **Seule la hurtbox rétrécit, pas le corps de mouvement** — Raison : le GDD parle de « hitbox » au sens des tirs ennemis ; changer le corps de collision pourrait coincer le joueur dans un mur quand le palier change.
4. **Dégâts de 13,5 gardés en flottant** (chiffres affichés arrondis à 14) — Raison : l'AC donne 13,5 ; les PV des ennemis sont flottants.
5. **Un palier = une source de modificateurs (l'objet `Lucidity`)** — Raison : garantit « la précision disparaît en quittant Lucide » sans comptabilité.
6. **`HURTBOX_SIZE` est une `Stat` du `StatBlock`** — Raison : Éveil, objets (Jambes de plomb, etc.) et le reflet pourront la modifier sans nouvelle API.
7. **Pas d'affichage des bonus dans le HUD** — Raison : la jauge et le nom du palier suffisent au jalon A ; à juger.

8. **Les contacts ennemis passent de 0,75 à 0,875 tuile (`contact_size` des quatre ennemis)** — Raison : le corps du joueur reste 6x6 px, donc un ennemi (corps 10 px) s'arrête à 8 px de centre ; avec une hurtbox de 4 px et une zone de contact de 12 px, les rectangles ne font que se toucher et le contact n'infligerait plus jamais de dégâts à un joueur Lucide. À 14 px, le recouvrement de 1 px d'avant est conservé. Test `t_sleepwalker` ajusté (valeur du `.tres`, zone témoin 14x14).
9. **Valeur de 13,5 comparée à la tolérance** — Raison : `1 + 0,35` n'est pas exact en flottant ; `StatBlock` calcule en double précision (classe `Modifier`, pas de `Vector2` qui tronque en float32), les tests comparent à 1e-12.

10. **Revue : décision 8 maintenue (zones de contact à 0,875 tuile plutôt qu'un changement du test de contact)** — Raison : correctif de données, réversible ; tester le contact contre le corps de mouvement changerait l'architecture `Hitbox` → `Hurtbox`. Effet sur l'équilibrage de l'epic 2 : en Lucide la portée latérale reste celle validée en 2.5 (joueur touché à moins de 9 px de la ligne) ; dans les autres paliers elle passe à 10 px (+1 px), négligeable et cohérent avec un abandon plus dangereux. Les scènes de l'epic 2 tournent avec un joueur Lucide (jauge pleine) et passent.
11. **Revue : hurtbox de Lucide = écart `ADD_FLAT` calculé depuis la base au moment du changement de palier** — acceptée pour 3.5 (la base ne change jamais) ; combinaison avec des objets reportée à l'epic 5 (`deferred-work.md`).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5.5

### Completion Notes

- `StatBlock` (`core/stat_block.gd`) : base + modificateurs par source (`set_modifier`, `clear_source`, `clear_modifier`), `changed(stat)` seulement sur variation réelle.
- `Player.stats` créé après la jauge ; `_apply_tier_modifiers` à la création et avant le relais du bus sur `tier_changed` ; la forme de la hurtbox est redimensionnée en place, `_shot_params` mis à jour (les balles en vol gardent leurs valeurs).
- `LucidityTuning` : `tier_damage_bonus`, `lucid_shot_speed_bonus`, `lucid_hurtbox_size`. Ligne F3 : dégâts, vitesse de tir, taille de hurtbox.
- Vérifs : `t_stat_block` (14), `t_tier_bonus` (49) ; suite complète voir rapport. NON ÉVALUÉ : ressenti de la précision (+30 % de vitesse de balle, hurtbox 4 px) et des dégâts, à juger en jouant.

### File List

- game/core/stat_block.gd (nouveau)
- game/core/lucidity_tuning.gd, game/data/tuning/lucidity_tuning.tres
- game/player/player.gd, game/debug/perf_overlay.gd
- game/data/enemies/{sleepwalker,sheep,night_light,lullaby}.tres (contact_size)
- game/.scratch/t_stat_block.*, t_tier_bonus.*, t_sleepwalker.gd, run_all.sh (non versionnés)

### Change Log

- 2026-11-24 : implémentation de la story 3.5 (StatBlock, bonus de palier, hurtbox de Lucide).

### Review Findings

Revue de code (2026-11-24, Claude Opus 5.5, mode complet : Blind Hunter, Edge Case Hunter, Acceptance Auditor) sur `f9ad888..26daad9`.

- Critères d'acceptation 1 à 7 : satisfaits. `BulletManager.fire()` copie vitesse et dégâts dans les tableaux du projectile (les balles en vol gardent les leurs) ; `Hurtbox.world_rect()` relit la forme à chaque appel et le manager rafraîchit les rectangles à chaque tick (graze, esquive parfaite, dessin F2 et contact suivent la hurtbox réduite) ; modificateurs appliqués à la création et avant le relais du bus.
- Preuves (arbre au commit `26daad9`, `--fixed-fps 60`) : `t_stat_block` 14/0, `t_tier_bonus` 49/0, `t_sleepwalker` 123/0, `t_graze` 37/0 ; `--quit-after 120` propre.
- Patch : aucun. Écartés : appel d'`equip_bullets()` ou de `tier_changed` avant `stats` (le joueur est prêt avant l'arène, rien n'émet pendant `_setup_lucidity`), cache `_values` à l'epsilon près (cohérent avec ce que reçoivent les consommateurs), typage (aucun avertissement).
- Reportés (`deferred-work.md`) : `StatBlock` face aux objets de l'epic 5 (base, durée de vie des sources, bornes, nommage de l'architecture) ; règle de taille des zones de contact pour les nouveaux ennemis.

