# Story 6.3 : Subir l'Interro surprise en Abandon total

Status: ready-for-dev

## Story

En tant que joueur,
je veux qu'un pattern de plus s'ajoute si j'affronte Le Professeur à 0 de lucidité,
afin que l'abandon total se paie aussi contre le boss.

Exigences : FR19 (pattern supplémentaire), FR60 (Interro surprise) (epics.md, Story 6.3). Architecture : P1 (`DangerProfile.boss_extra_pattern`, calculé depuis `room_tier` et `LucidityTuning`).

**Dépend de : 6.1** (cadre `Boss`/runners/`BossAttack`) **et 6.2** (phases : l'Interro s'ajoute à l'épreuve en cours, il faut donc des phases à superposer ; `Kind`, `AttackSign` formes).

Hors périmètre : mort du boss (6.4) ; sprites et audio réels.

## Critères d'acceptation

1. **Activation** : quand `DangerProfile.boss_extra_pattern` devient vrai dans la salle du cauchemar (`room_tier` = Abandon total, `LucidityTuning.boss_extra_pattern_from_tier` = 4), le boss ajoute l'**Interro surprise** : un cercle de **12 craies** autour de lui, toutes les **6 s**, à 5 tuiles/s, annoncé par un signe en anneau d'au moins 0,4 s (donnée 0,6 s). Elle s'ajoute à l'attaque en cours (Dictée, Calcul mental, Examen final) sans l'arrêter.
2. **Annonce** : au moment de l'activation, la craie écrit « Interro surprise » (`Events.boss_announced`, clé `BOSS_PROFESSOR_EXTRA`), **sans suspendre** les autres attaques (contrairement à une annonce de phase).
3. **Définitive pour le combat** : une fois active, l'Interro surprise reste jusqu'à la fin du combat, même si la jauge remonte et que `live_tier` quitte Abandon total ; elle ne se déclenche pas deux fois. Elle suit les changements de phase (elle ne redémarre pas, ne se superpose pas deux fois).
4. **Activation en cours de combat** : si le joueur tombe à 0 de lucidité après le début, l'Interro démarre à ce moment (elle n'attend pas la phase suivante) ; s'il est déjà à 0 à l'entrée, elle démarre dès la fin de la première annonce.
5. **Pas avant** : à Abandon ou au-dessus, `boss_extra_pattern` reste faux, aucun cercle ne part. Les joueurs qui ne descendent jamais à 0 ne la voient jamais.
6. **Motif en Resource** : `BossDef.extra_attack: BossAttack` (`kind = RING`, `bullet_count` 12, `interval` 6, `telegraph` 0,6, `bullet_speed` 5, `ring_offset_deg`), validé par `validate()`. Chaque cercle est décalé de `ring_offset_deg` (15° = demi-pas, donnée) par rapport au précédent : deux cercles successifs ne se superposent pas, les trous suivent un schéma fixe, **sans tirage**.
7. **Danger** : mêmes règles que 6.1 (vitesse × `enemy_bullet_speed_mult`, signe ≥ 0,4 s, `pace_mult`, `fire_hold`).
8. **Capacité** : 60 s d'Examen final + Interro surprise en Abandon total : `refused_count == 0`.

## Tâches

- [ ] `boss_attack.gd` : `Kind.RING` (à la fin), champs `ring_offset_deg` ; `boss_def.gd` : `extra_attack` ; `chalk_patterns.gd` : `ring_directions(count, offset_deg)`.
- [ ] `runners/ring_runner.gd` ; `attack_runner.gd` : `make()` branche `RING`.
- [ ] `boss.gd` : lecture de `danger.boss_extra_pattern` chaque tick (`_check_extra()`), **verrou** `_extra_active` (jamais remis à faux), démarrage du runner de l'Interro, annonce sans pause ; le runner survit aux changements d'ensemble et de phase (il n'appartient à aucun ensemble) ; arrêt avec les autres à la mort/fin de run.
- [ ] `professor.tres` : `extra_attack` ; `strings.csv` : `BOSS_PROFESSOR_EXTRA` (« Interro surprise »).
- [ ] Télémétrie : `Log.info("combat", "boss extra pattern started")` ; pas de nouveau champ (6.9 lit l'issue de la tentative, pas le pattern).
- [ ] Tests.

## État du code concerné

- `DangerProfile.apply_tier()` calcule `boss_extra_pattern = index >= tuning.boss_extra_pattern_from_tier` ; la salle l'appelle à `begin_room()` (tier = tier vivant à cet instant, `Lucidity.begin_room()` ramène `room_tier` au tier vivant) puis à chaque `room_danger_raised` (la jauge est passée sous le tier de salle). `room_tier` ne remonte pas pendant un combat, mais **`begin_room()` peut le faire** (nouvelle vague, nouveau combat) : le boss ne doit donc pas lire l'état brut comme un état à suivre, il le verrouille. Dans la salle du cauchemar il n'y a qu'une vague, un seul `begin_room()`.
- `Room.is_nightmare()` : pas de renfort, pas de reflet. Aucun test de 3.7/5.10 ne change.
- `LucidityTuning.boss_extra_pattern_from_tier = 4`, table de danger : à 4, vitesse ×1,1, télégraphe ×0,85 ; plancher 0,4 s via `Telegraph.duration_for` (6.1).
- Le boss tourne via `_physics_process` d'`Enemy` (6.1) : l'ordre est annonce → runners d'ensemble → extras de phase → Interro.

## Pièges

- Ne pas lire `Lucidity.live_tier` : seule `room_tier` (donc `DangerProfile`) alimente le danger (règle de la 3.6) ; le boss lit `danger.boss_extra_pattern`, jamais la jauge.
- Le verrou est dans le **boss**, pas dans `DangerProfile` : `apply_tier()` doit continuer à pouvoir redescendre (autres salles, autres tests).
- Un boss tué avant l'activation ne démarre rien ; une salle rechargée (reprise, 6.8) repart sans verrou (le combat reprend du début de la salle, donc l'Interro se redéclenche selon le palier de l'entrée).
- Cercle de 12 depuis le centre du boss : à l'apparition de la craie, l'origine est dans le corps du boss, pas dans un mur (centre de salle) : `fire()` ne la refuse pas.
- Une annonce qui n'arrête pas les attaques ne doit pas rouvrir la pause d'une annonce de phase : `Boss` distingue `boss_announced` « avec pause » (phase) et « sans pause » (Interro) par un paramètre interne, pas par la clé.
- Interro + règle : la règle (lourde) et un cercle peuvent coïncider ; c'est voulu, à juger au playtest.

## Tests (GUT)

- `unit/bosses/test_chalk_patterns` : `ring_directions(12, 0)` équidistantes (30°) ; avec 15° de décalage les directions successives alternent sans coïncider.
- `unit/combat/test_danger_profile` (existant, relire) : inchangé ; ajouter un cas « `boss_extra_pattern` faux sous Abandon ».
- `integration/bosses/test_surprise_quiz` : à 100 de lucidité aucun cercle en 20 s ; salle commencée à 0 : premier cercle après l'annonce de phase 1 et le signe ; descente à 0 en cours de phase 2 : annonce « Interro surprise » sans pause des spirales, cercle ensuite toutes les 6 s ± 1 tick ; remontée de la jauge à 100 : les cercles continuent ; changement de phase : une seule cadence de cercles ; signe ≥ 0,4 s ; mort du boss/fin de run : plus de cercle.

## Sources

epics.md (Story 6.3) ; GDD, Le Professeur, « En Abandon total : Interro surprise, un cercle de 12 craies toutes les 6 s » ; GDD, tableau de la lucidité (boss : pattern supplémentaire à 0) ; architecture P1.

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Verrou dans `Boss`** (`_extra_active`) plutôt que dans `DangerProfile`. Raison : l'AC dit « reste active jusqu'à la fin du combat, même si la jauge remonte » ; `DangerProfile` reste un calcul pur du tier de salle.
2. **Cercles décalés d'un demi-pas (15°) à chaque tir, sans tirage.** Raison : lisible, déterministe, pas de consommation du flux `boss` par une attaque d'abandon (un joueur à 0 et un autre à 100 gardent les mêmes trous de rangée).
3. **Annonce de l'Interro sans pause des attaques.** Le GDD dit qu'elle « s'ajoute » ; suspendre ferait un répit en récompense d'un abandon total.
4. **`ChalkTitle` affiche une seule ligne à la fois** : le titre de phase s'efface après 3 s, l'Interro s'écrit ensuite seule (ou remplace le titre s'il est encore là). Détail visuel NON ÉVALUÉ.
5. **Pas d'événement de télémétrie dédié** (journal INFO seulement).

## Dev Agent Record

### Notes de complétion

### Liste des fichiers

### Journal des modifications
