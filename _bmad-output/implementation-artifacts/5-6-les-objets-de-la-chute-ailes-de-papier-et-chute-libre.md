# Story 5.6 : Les objets de la Chute : Ailes de papier et Chute libre

Status: ready-for-dev

## Story

En tant que joueur,
je veux des objets qui jouent avec la chute,
afin de construire un build autour des trous et de l'esquive.

Exigences : FR48, FR49, AR15 (`ItemEffect`) (epics.md, Story 5.6). Architecture : D9, P5 (exemple `FreeFallEffect`).

**Dépend de : 5.1** (`BuildCarrier`, `ItemEffect`, `hit_incoming` / `hit_taken`, `OwnedItem`), 4.3 (chute dans les trous, `CAN_FLY_OVER_PITS`). Prépare 5.7 (ces deux objets portent le tag Chute) et 5.10 (les effets sont refusés sur un porteur qui n'est pas le joueur).

Hors périmètre : onde de choc et synergies (5.7).

## Critères d'acceptation

1. **Ailes de papier** (`data/items/paper_wings.tres`, tag Chute, `effect_script = PaperWingsEffect`) : tant que l'objet est porté et qu'il n'a pas été interrompu, `CAN_FLY_OVER_PITS` est à 1 (modificateur `ADD_FLAT 1` dont la source est l'`OwnedItem`). Le joueur survole les trous : `Player.can_fly_over_pits()` ne change pas.
2. **Coup reçu** : sur `hit_taken`, le survol est retiré (`clear_modifier`) pendant 3 s (`params.suspend_seconds`, en ticks du groupe `PLAYER`), puis rendu (`set_modifier` à nouveau). Un nouveau coup pendant la suspension relance les 3 s.
3. **Coup reçu au-dessus d'un trou** : le survol disparaît, le joueur tombe sur le champ : retour à `_pit_guard.last_safe`, **sans dégât de chute** (`PIT_DAMAGE` non appliqué : il ne perd que le coup). `Player` expose `fall_if_over_pit()` (le test de `_is_over_pit()` puis `_fall(deal_damage = false)`), appelé par l'effet après avoir retiré le survol. Le coup lui-même a déjà été appliqué par le chemin normal du `Hurtbox`.
4. **Chute libre** (`data/items/free_fall.tres`, tag Chute, `effect_script = FreeFallEffect`) : tant que le joueur n'est pas touché, un modificateur `ADD_PERCENT` de la source `DAMAGE` monte de +5 % par seconde pleine jusqu'à +50 % (`params.rate`, `params.max_bonus`, `params.step_seconds` = 1). Le compteur progresse avec `GameClock.scale(PLAYER)` (le pause, le ralenti de 5.8 ne le font pas avancer à tort : seul le joueur compte).
5. **Coup reçu avec bonus actif** : sur `hit_incoming(info)`, si le bonus est > 0, `info.amount += 1` (½ cœur de plus, l'armure absorbe d'abord comme pour tout coup) et le bonus retombe à zéro (modificateur retiré). Sans bonus, aucun supplément. Le bonus repart de zéro à chaque coup, avec ou sans supplément. Un coup refusé (invulnérabilité) n'est pas un coup : `hit_incoming` n'est émis qu'après les filtres de la hurtbox (il l'est dans `_on_hurtbox_damage_received`, donc déjà filtré).
6. **`detach()`** : retiré, chaque effet se déconnecte de tous les signaux qu'il écoutait et laisse la stat comme s'il n'avait jamais été posé ; `Loadout.remove` appelle aussi `clear_source` (5.1). Deux Chute libre : une seule `ItemDef` non `stackable`, jamais en double.
7. **Chute libre et le coup de chute** : tomber dans un trou sans survol est un coup de la source `PIT` : il compte comme un coup (bonus perdu, supplément ½ cœur inclus), documenté et testé.
8. **Pools** : les deux objets sont ajoutés aux pools trésor et boutique (`data/pools/*.tres`, 5.2).
9. Textes `strings.csv` : noms, bonus, coûts des deux objets (le coût de Chute libre : « le bonus retombe à zéro au premier coup, et ce coup retire ½ cœur de plus »).

## Tâches

- [ ] `items/effects/paper_wings_effect.gd`, `items/effects/free_fall_effect.gd` (sans valeur littérale : tout dans `ItemDef.params`), `data/items/paper_wings.tres`, `free_fall.tres`.
- [ ] `BuildCarrier` : appelle `effect.tick(delta × GameClock.scale(PLAYER))` pour les effets qui le demandent (`wants_tick`), ne le fait pas quand le joueur est mort.
- [ ] `BuildCarrier.hit_incoming` émis par `Player._on_hurtbox_damage_received` **avant** `health.apply_damage(info)` (5.1 pose le signal ; câblage vérifié ici).
- [ ] `Player.fall_if_over_pit()` + paramètre de dégâts de `_fall`.
- [ ] Pools, `strings.csv`, tests.

## État du code concerné

- `Player._on_hurtbox_damage_received(info)` : `health.apply_damage(info)` → `Events.player_hit` → `_die` si mort ; `hurtbox.refuse_hit()` si rien n'est perdu. `info.amount` est un float de demi-cœurs.
- `Player._fall()` : replace au dernier point sûr, remet le moteur à zéro, puis un `DamageInfo(PIT)` par `hurtbox.receive(info)` si `PIT_DAMAGE ≥ 1` ; un joueur invulnérable est replacé sans dégât (c'est le cas juste après un coup : invulnérabilité de 1 s).
- `_is_over_pit()` ne tombe pas quand `can_fly_over_pits()` ; `_check_pits()` ne teste que hors dash.
- `Glide` : atterrir dans un trou tombe sans invulnérabilité d'arrivée (4.3) ; avec Ailes de papier, le test `_is_over_pit()` renvoie faux : rien à faire.
- `StatBlock.set_modifier` remplace le modificateur de la source sur la stat ; `clear_modifier(source, stat)` le retire.

## Pièges

- **Ordre** : l'effet des Ailes réagit à `hit_taken` (après `apply_damage`), pas à `hit_incoming`. Au moment où il retire le survol, le joueur est invulnérable (1 s) : `_fall` n'applique donc pas de coup supplémentaire, mais on passe `deal_damage = false` quand même (ne pas dépendre de l'invulnérabilité : une invulnérabilité réglée à 0 s dans `CombatTuning` doit donner le même résultat).
- **Mort au coup** : si le coup tue, ne rien faire (pas de chute, pas de signal de plus) ; `hit_taken` est émis avant `_die` mais l'effet vérifie `health.is_dead()`.
- **Suspension et `Run.travel`** : le joueur est `PROCESS_MODE_DISABLED` pendant le fondu (4.8) : le carrier est son enfant, ses timers se figent avec lui (voulu).
- Chute libre ajoute 1 à `info.amount` : le coup « ½ cœur de plus » sur armure retire de l'armure d'abord, comme tout coup. À écrire tel quel dans le test.
- `ItemEffect.tick` ne doit pas allouer à chaque tick (pas de nouvelle `Callable` par tick) ; le bonus n'est réécrit dans le `StatBlock` qu'à chaque palier d'une seconde (évite `changed` 60 fois par seconde).
- Le survol est une stat à 0/1 : pas de `MULTIPLY` (0 × tout = 0).

## Tests

- `unit/items/test_paper_wings_effect.gd` : stat à 1 à l'attachement, 0 après `hit_taken`, 1 de nouveau après 180 ticks, relance sur un second coup, `detach` rend la stat à 0 et déconnecte (compte de connexions du carrier).
- `unit/items/test_free_fall_effect.gd` : +5 % / s plafonné à +50 % à 10 s, aucun supplément sans bonus, `info.amount += 1` avec bonus, retombée à 0, pas de tick avec `GameClock.paused`.
- `integration/items/test_fall_items.gd` : joueur au-dessus d'un trou avec Ailes de papier, coup reçu : replacé au point sûr, un seul coup perdu ; survol qui revient après 3 s ; Chute libre : bonus de dégâts lu sur `_shot_params`, supplément de ½ cœur sur un vrai coup.

## Sources

epics.md (Story 5.6) ; GDD « Objets du MVP » (lignes Ailes de papier, Chute libre) et notes de design ; architecture P5 (exemple de `FreeFallEffect`).

### Décisions prises sans Kroustille (à valider en fin d'epic)

1. **Bonus de Chute libre par paliers d'une seconde** (+5 %, +10 %…) plutôt que continu : lisible, et peu de `changed`.
2. **Le coup de chute (`PIT`) compte comme un coup** pour Chute libre ; il retire le bonus et le ½ cœur de plus.
3. **Chute sans dégât au retrait du survol** passe par un paramètre de `_fall`, pas par une modification de `PIT_DAMAGE`.
4. **Chute libre n'est pas cumulable** (`stackable` faux, sans doublon dans la run), comme les autres objets hors Dent.
5. **Le bonus est dans le temps du groupe `PLAYER`** (pas affecté par le Réveil cassé qui épargne le joueur).
