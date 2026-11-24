# Epic 5 : décisions prises sans toi, à valider

> **En attente : Kroustille validera toutes les décisions en une fois, à la fin. Les choix par défaut s'appliquent d'ici là.**

Pendant l'epic 5 (stories 5.1 à 5.10 : objets et prix, salle trésor, consommables, Éclats et drops, boutique, objets de la chute, synergies, objet actif, Copie d'examen et Être nu en public, Miroir), des décisions ont été prises sans toi. Elles sont toutes notées dans les sections « Décisions prises sans Kroustille » de chaque story. Ce document les trie pour que tu puisses valider vite, en même temps que celles des autres epics.

**Comment répondre :** réponds avec les numéros à changer et ce que tu veux à la place ; tout le reste est validé. Exemple : « D5.8-1 : le joueur ET ses tirs ralentis ; D5.5-2 : un cœur acheté = 1 demi-cœur ».

Lecture d'un numéro : `D5.5-2` = story 5.5, décision 2. Les décisions de revue de code gardent leur numéro dans la liste de la story (la mention « Revue » ou « Dev » est rappelée quand elle aide). Dans les stories 5.6 et 5.7, les décisions 6 à 9 (5.6) et 12 à 15 (5.7) viennent après un saut de la liste.

Colonne « GDD ? » : **conforme** (le GDD ou l'epic dit déjà la même chose), **comble un manque** (rien n'est dit, on a choisi), **s'en écarte** (le GDD, l'epic ou l'architecture dit autre chose).

Plan :
1. Écarts au GDD, aux epics ou à l'architecture.
2. À regarder en priorité (ce que le joueur ressent), par thème.
3. À survoler (technique, une ligne par sujet).
4. À juger en jouant (ce qui n'a jamais été vu ni tenu en main par un humain).
5. Actions qui te reviennent.

---

## 1. Écarts au GDD, aux epics ou à l'architecture

Seize points s'écartent d'un texte de référence ou le lisent de façon ambiguë. Chacun reprend aussi son contexte dans la section 2 ou 3.

**Objets, boutique, flux**

- **D5.5-2 : « 1 cœur » du GDD lu comme 2 demi-cœurs en boutique** (cœur acheté = 2 demi-cœurs, armure = 2 demi-cœurs d'armure). Le GDD parle de « cœur » sans dire que la boutique compte en demi-cœurs ; les soins des drops valent 1 demi-cœur (D5.4-8). Voir aussi D5.5-12 (soin partiel au prix plein).
- **D5.5-1 : achat au contact (style Isaac), pas de touche d'interaction.** Le GDD et l'epic parlent d'« acheter » sans fixer le geste.
- **D5.1-19 (revue) : les meubles arrêtent les tirs traversants du joueur** ; seuls les ennemis sont traversés. L'epic 5.1 dit « ses tirs traversent les ennemis », FR41 « les meubles arrêtent les projectiles des deux camps », le brainstorm « traversent tout » : choix entre les deux.
- **D5.9-8 et D5.9-15 : le flux `drops` passe à 6 tirages fixes par salle, ce qui change la séquence de drops de toutes les graines existantes une fois.** Pas de sauvegarde concernée. Le GDD dit seulement que les flux sont indépendants (c'est le but). Voir aussi D5.4-14 (3 ou 4 tirages avant 5.9).
- **D5.3-3 : `use_consumable` sur la touche physique Q (qui s'affiche A sur un clavier AZERTY) et `use_active` sur E** (réservé en 5.3, pris en D5.8-5). Le GDD dit « touche A » : c'est la touche de l'AZERTY, mais la touche physique A (`move_left`) est déjà prise. Manette : Y (consommable), X (actif).
- **D5.1-1 : l'architecture est alignée sur le code (`StatBlock`, `StatBlock.Kind`, `Player.stats`), pas l'inverse** : `StatModifier` n'existe pas ; `BuildCarrier` est un nœud composant, déjà corrigé dans l'architecture. À valider avec D5.1-6 (`hit_incoming` absent de l'architecture au départ) et D5.4-16 (`Drops.spawn(room, kind, position, consumable_roll)` au lieu de `(kind, position, rng)`, doc d'architecture à aligner en fin d'epic).

**Chute et synergies**

- **D5.6-1 : Chute libre par paliers d'une seconde** (+5 %, +10 %…) plutôt qu'un bonus continu. Le GDD dit « +5 % par seconde ».
- **D5.6-2 : le coup de chute dans un trou (`PIT`) compte comme un coup** pour Chute libre (bonus perdu, ½ cœur de plus).
- **D5.7-1 : le niveau de synergie le plus haut remplace le plus bas** (30 dégâts, pas 15 + 30). Lecture du GDD (« l'onde double »), à confirmer.

**Objet actif, Copie d'examen, Miroir**

- **D5.8-1 (maintenu en revue par D5.8-13) : le Réveil cassé ralentit ENEMIES, ENEMY_BULLETS et WORLD, mais pas PLAYER ni PLAYER_BULLETS ni FX.** FR51 et l'epic disent « tous les groupes sauf `PLAYER` » : les tirs du joueur et les effets visuels sont aussi exemptés. Une constante à changer (`BrokenAlarmEffect.SLOWED_GROUPS`). À trancher à la main.
- **D5.8-14 : le ralenti traverse les portes et se décompte pendant le fondu**, une partie des 4 s peut s'y perdre. Voulu par la spec ; ressenti NON ÉVALUÉ.
- **D5.9-1 : « 1,5 premières secondes de chaque salle » (Être nu en public) compté depuis `fight_started`**, pas depuis l'entrée du joueur. Lecture du GDD ; sinon la première vague (1 s après l'entrée) n'aurait que 0,5 s de gêne.
- **D5.10-1 : le facteur d'étage du reflet est un champ inventé, `FloorDef.hp_factor`** (1,0 pour l'Endormissement). Le GDD et l'epic disent « facteur d'étage » sans que rien le définisse. À régler avec l'équilibrage des étages.
- **D5.10-2 : « motif des tirs » lu comme nombre et directions (`ShotPattern`), sans la traversée (pierce) ni la vitesse.** Le reflet ne traverse donc rien même si le joueur le fait. Le GDD et l'epic disent « reprennent le motif ».
- **D5.10-4 : le reflet doit être tué pour vider la salle, sans drop propre** (voir D5.10-10 : la vague suivante l'attend). L'epic ne le dit pas ; c'est une lecture de l'AC 7.
- **Apparence du reflet (sans numéro de décision, déferré par la revue 5.10) :** le GDD (ligne « couleur et contour exclusifs ») et l'architecture (`game-architecture.md:820`) demandent une apparence de balle propre au reflet ; l'epic 5.10 et son AC 4 demandent l'apparence ennemie existante, que le code suit. Documents à aligner.

---

## 2. À regarder en priorité

### Objets et coûts (5.1)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D5.1-9 | `SHOT_SPEED` borné à [0,5 ; 59] (le minimum n'était pas dans la story). | Une vitesse ≤ 0 ferait refuser chaque tir par `BulletManager`. | comble un manque |
| D5.1-10 | `Health.restore_max(n)` : retirer une Dent rend 2 demi-cœurs, borné à ce que `lose_max` a pris. | Retirer un objet doit rendre son prix. | comble un manque |
| D5.1-20 | (revue) Un objet ne rend que le max qu'il a pris (`OwnedItem.max_half_hearts_paid`), pas un pot commun. | « Retirer un objet retire exactement son cœur. » | comble un manque |
| D5.1-15 | Un objet non empilable déjà possédé est refusé (pickup grisé), comme la Dent à un cœur. | Seules les Jambes de plomb sont concernées en pratique. | comble un manque |
| D5.1-14 | Le catalogue refuse un objet qui porte deux modificateurs sur la même stat. | Le second écraserait le premier en silence. | comble un manque |
| **D5.1-19** | **Les meubles arrêtent les tirs traversants, pas les ennemis ; la lampe reste traversée.** | Voir section 1. | **s'en écarte** |
| D5.1-3 | Description d'un objet = deux clés (`bonus_key`, `cost_key`). | La bannière montre bonus et coût séparément. | comble un manque |
| D5.1-12 | Pas de clés `UI_BANNER_*` : la bannière affiche titre, bonus, coût tels quels, sans libellé. La 5.7 réutilise la forme. | Simple. | comble un manque |
| D5.1-5, D5.1-17 | Tout ramassable passe par `Offer` / `RoomStock` par cellule ; une offre prise reste dans le stock (`taken`). | Un objet laissé survit à la sortie de la salle. | comble un manque |

### Salle trésor (5.2)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D5.2-1 | Un pool par type de salle (trésor, boutique), listes identiques au MVP. | Elles se sépareront à l'acte 1. | conforme |
| D5.2-2 | Tirage à la première entrée, résultat figé dans le stock de la salle. | « Même objet à la même seed » vaut à objets déjà pris égaux. | conforme |
| D5.2-6 | Les pools ne contiennent que les objets existants (2 en 5.2, un de plus par story d'objet), pas 8. | Un test échoue si un objet manque à l'un des pools. | comble un manque |
| D5.2-5 | Pool filtré vide : salle sans objet, pas d'erreur bloquante. | AR28. | comble un manque |
| D5.2-12 | (revue) Pool filtré vide : un tirage est quand même consommé. | Le flux ne dépend que du nombre de salles trésor ouvertes. | conforme |
| D5.2-4 | Un seul `randi_range` sur la liste filtrée : un objet exclu change l'objet tiré, jamais le nombre de tirages. | Même raison. | conforme |

### Consommables (5.3)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D5.3-1 | Un consommable est consommé d'un coup ; Café repris pendant son effet relance la phase 1. | Pas de charges. | comble un manque |
| D5.3-2 | Se pincer ne passe pas par le `Hurtbox` : ni invulnérabilité, ni `player_hit`, ni télémétrie de mort. | Un prix, pas un coup. | comble un manque |
| **D5.3-3** | **Touche physique Q (A en AZERTY) et manette Y ; E / X réservés pour l'actif.** | Voir section 1. | **s'en écarte** |
| D5.3-5, D5.3-6 | Café : le malus de vitesse remplace le bonus (même source) ; pendant la chute, seule la vitesse baisse de 20 % 5 s, cadence normale. | Lecture du GDD. | conforme |
| D5.3-7 | Réglages : Se pincer +25 de lucidité pour 1 demi-cœur ; Café +0,3 pendant 10 s puis −0,2 pendant 5 s. | Tuning au jugé. | conforme |
| D5.3-10 | Se pincer est refusé si la vie tombe sous 1 demi-cœur ; `Shooter.set_fire_rate` raccourcit au besoin la recharge en cours. | Jamais de salve gratuite ni d'attente plus longue. | comble un manque |
| D5.3-13 | (revue) Se pincer à 100 de lucidité reste permis. | Le joueur choisit. | comble un manque |
| D5.3-4, D5.3-8, D5.3-9 | Consommable déposé = offre du stock de la salle, posée sur la plus proche cellule libre ; armée à la sortie de la zone ou 3 ticks après la création si le joueur ne la recouvre pas. | Évite de reprendre aussitôt et un consommable mort. | comble un manque |
| D5.3-14, D5.3-15 | (revue) Un consommable non armé est grisé ; ramasser le même id que celui porté reste un échange (corrigé ensuite en D5.4 : refus). | « Inerte = grisé ». | comble un manque |

### Éclats et drops par palier (5.4)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D5.4-1 | Pas de flux `loot` : Éclats, chance et type partagent `drops`, séquence fixe. | Le GDD parle d'un flux `drops`. | conforme |
| D5.4-3 | Le drop apparaît à la position de la dernière mort, recalé sur une cellule libre. | L'epic ne dit pas où. | comble un manque |
| D5.4-4 | Dans l'arène, chaque vague vidée rapporte. | La salle y boucle. | comble un manque |
| D5.4-5 | Chance bornée à 100 %. | Aucun palier ne la dépasse. | comble un manque |
| D5.4-8 | « ½ cœur » soigne 1 demi-cœur, « ½ armure » donne 1 demi-cœur d'armure. | Valeurs dans `EconomyTuning`. | comble un manque |
| D5.4-6 | Un soin refusé ne joue pas le son de refus ; seul l'achat le joue. | Éviter un bruit à chaque passage. | comble un manque |
| D5.4-14 | (revue) 3 tirages par salle, 4 si le type est un consommable ; indépendant du palier, de la chance et de l'inventaire. Pas fixe reporté à 5.9. | AC3. | conforme |
| D5.4-15 | (revue) Télémétrie `shards` = solde en fin de run ; les gains se déduisent du solde + somme des prix d'achat (D5.5-9). | Lecture littérale d'AC8. | conforme |

### Boutique et prix (5.5)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D5.5-1** | **Achat au contact avec armement ; la bannière s'ouvre à moins de 2 tuiles.** | Voir section 1. | **s'en écarte** |
| **D5.5-2** | **Cœur acheté = 2 demi-cœurs, armure = 2 demi-cœurs d'armure.** | Voir section 1. | **s'en écarte** |
| D5.5-3 | Pas de revente ni de réapprovisionnement ; étal tiré une fois par boutique. | MVP. | comble un manque |
| D5.5-4 | Les objets déjà proposés au trésor et non pris ne sont pas exclus ; seul le doublon avec le `Loadout` l'est. | Comme 5.2. | comble un manque |
| D5.5-5 | Consommable porté : l'achat reste permis, l'ancien est déposé. | Cohérent avec 5.3. | conforme |
| D5.5-11 | (revue) Un étal de consommable identique à celui porté est grisé et refuse ; le tirage ne l'exclut pas. Le joueur peut utiliser le sien puis acheter. | Payer pour un échange à l'identique ne donnerait rien. | comble un manque |
| D5.5-12 | (revue) Soin ou armure partiels au prix plein : le cœur à PV max − 1 demi-cœur soigne 1 et coûte 4 ; refus seulement quand rien n'est gagné. | Comme Isaac. | conforme |
| D5.5-13 | (revue) Objet de l'étal pris ailleurs entre-temps : l'étal reste, grisé, refusant. | Cohérent avec D5.5-4. | comble un manque |
| D5.5-10 | Disposition provisoire de `onset_shop_001` : 5 étals hors des axes porte à porte. | On ne marche pas dessus en traversant. | comble un manque |

### Objets de la chute et synergies (5.6, 5.7)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D5.6-1** | **Chute libre par paliers d'une seconde.** | Voir section 1. | **s'en écarte** |
| **D5.6-2** | **Le coup de chute compte comme un coup pour Chute libre.** | Voir section 1. | **s'en écarte** |
| D5.6-3, D5.6-6 | Ailes de papier : la chute sans dégât au retrait du survol passe par un paramètre de `_fall` ; l'objet retiré en plein trou donne une chute normale avec dégâts. | Pas de chute gratuite. | comble un manque |
| D5.6-4 | Chute libre n'est pas cumulable. | Comme les autres objets hors Dent. | comble un manque |
| D5.6-5 | Le bonus se compte dans le temps du groupe `PLAYER` (non affecté par le Réveil cassé). | Cohérence avec D5.8-1. | comble un manque |
| **D5.7-1** | **Le niveau de synergie le plus haut remplace le précédent.** | Voir section 1. | **s'en écarte** |
| D5.7-4 | Chute sans fin n'annule pas la chute (retour au point sûr) ; seul le coût en cœur disparaît. | Le GDD ne parle que du coût. | comble un manque |
| D5.7-7, D5.7-8, D5.7-12 | Annonce de synergie une seule fois par synergie et par porteur ; la bannière de synergie suit celle de l'objet, mise en file (objet 3 s, puis synergie 3 s) ; le son part au seuil. | Sinon l'objet n'était jamais lu. | comble un manque |
| D5.7-13 | Un dash qui finit au-dessus d'un trou lance l'onde, puis le joueur tombe (« piqué »). | Pas de cas particulier. | comble un manque |
| D5.7-14 | L'onde ne touche ni les lampes ni les cibles d'entraînement (ennemis et meubles seulement). | AC 4 ; à revoir si la lampe doit s'allumer. | conforme |
| D5.7-5 | Son et anneau de l'onde provisoires (epic 7). | Hors périmètre. | comble un manque |

### Objet actif : Réveil cassé (5.8)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D5.8-1** (D5.8-13) | **Ralenti de ENEMIES, ENEMY_BULLETS, WORLD ; pas PLAYER_BULLETS ni FX.** | Voir section 1. | **s'en écarte** |
| D5.8-2 | La durée du ralenti est comptée en temps réel (delta × `global_multiplier`). | Ne pas la ralentir elle-même. | comble un manque |
| D5.8-4 | Objet actif neuf = chargé à la prise ; déposé il garde sa charge, repris il la retrouve. | Pas de recharge gratuite. | comble un manque |
| D5.8-5 | Touches E / X (`use_active`) ; F1 `U` recharge. | Voir D5.3-3. | comble un manque |
| D5.8-6, D5.8-11 | Barre de charge à segments dans l'emplacement ; son généré par script ; anneau de 6 tuiles dans le groupe FX. | Provisoire, epic 7. | comble un manque |
| D5.8-9 | Un objet lâché pendant le ralenti ne l'annule pas. | Il s'éteint seul. | comble un manque |
| D5.8-12 | (revue) Ligne d'aide des touches ajoutée pour l'objet actif (inverse de D5.8-10). | Sinon E / X ne se découvre pas. | comble un manque |
| **D5.8-14** | **Le ralenti traverse les portes et se décompte pendant le fondu.** | Voir section 1. NON ÉVALUÉ. | **s'en écarte** |

### Copie d'examen vierge et Être nu en public (5.9)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D5.9-1** | **Gêne de 1,5 s comptée depuis `fight_started`.** | Voir section 1. | **s'en écarte** |
| D5.9-2 | Les ennemis ne tirent pas = leur cycle de tir ne progresse pas : premier tir 1,5 s plus tard, pas de tir avorté. | Pas de télégraphe vide. | comble un manque |
| D5.9-3 | « Plus vite » = vitesse de déplacement et du cycle de tir × 1,3 ; télégraphes et balles en vol inchangés. | Lisibilité. | comble un manque |
| D5.9-4 | Chrono sur `PLAYER`, gêne sur `ENEMIES` (le Réveil cassé ralentit la gêne). | Voulu. | comble un manque |
| D5.9-5 | Armure vidée à la prise sans événement de coup ; armure au sol ou en boutique refusée. | Pas un coup. | comble un manque |
| D5.9-6, D5.9-11 | Boutique : seul l'étal d'armure est remplacé par un cœur qui coûte le prix d'un cœur (4). | Le GDD ne chiffre pas. | comble un manque |
| D5.9-10, D5.9-14 | Le Mouton et le Somnambule ne gagnent que la vitesse de déplacement : la distance de ruée augmente de 30 % ; maintenu en revue (l'esquive latérale marche toujours). | Pénalité voulue. | comble un manque |
| D5.9-12 | Pas de signal sonore ni visuel au passage à zéro. | Epic 7. | comble un manque |
| D5.9-8, D5.9-15 | Flux `drops` à 6 tirages fixes ; séquence des graines existantes changée une fois. | Voir section 1. | **s'en écarte** |
| D5.9-9 | Deux drops côte à côte ne se superposent plus (`Room._free_spot`). | Aussi pour les consommables lâchés. | comble un manque |

### Miroir et reflet (5.10)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D5.10-1** | **`FloorDef.hp_factor`, 1,0 pour l'Endormissement.** | Voir section 1. | **s'en écarte** |
| **D5.10-2** | **Motif = nombre et directions, sans traversée ni vitesse ; dégâts d'un tir ennemi.** | Voir section 1. | **s'en écarte** |
| D5.10-3 | Seuls les modificateurs de stats et les effets `supports_non_player()` s'appliquent au reflet ; la Dent ne lui retire pas de cœur. | Copie sans coûts de joueur. | comble un manque |
| **D5.10-4** (D5.10-10) | **Le reflet doit être tué pour vider la salle ; la vague suivante l'attend.** | Voir section 1. | **s'en écarte** |
| D5.10-5 | Tirage 1 sur 4 à `fight_started`, un seul tirage `combat` par salle éligible. | Le GDD : « 1 salle de combat sur 4 ». | conforme |
| D5.10-6 | Comportement de déplacement par `enum` de données (`STILL`, `KEEP_DISTANCE`, `MIRROR_PLAYER`). | Réglable pour le playtest, comme l'epic. | conforme |
| D5.10-11, D5.10-14 | Apparition au point opposé au joueur par rapport au centre, ramené dans la vue de la caméra (moins la bande de HUD) dans les 8 salles larges ou hautes. | Sinon il tirait hors de vue pendant ~30 s. | comble un manque |
| D5.10-13 | Tag `gaze` ; réglages posés au jugé : `KEEP_DISTANCE`, 5 tuiles, vitesse 2, cadence 2 s, télégraphe 0,5 s. | À tester en jeu. | comble un manque |
| D5.10-15 | Touche F1 du reflet : `N` (pas `M`). | En AZERTY la touche physique M est la virgule. | comble un manque |
| D5.10-16 | (revue) Copie du build prise à l'apparition, pas suivie en direct. | L'AC 3 parle d'une copie. | conforme |
| D5.10-12 | Pas de salle « Miroir » à construire ; le tirage vit dans `ReflectionSpawner`. | L'histoire n'en demande pas. | comble un manque |

---

## 3. À survoler

**Objets (5.1)**
- Source d'un modificateur = un `OwnedItem` ; `pierce`, tir arrière et vol sont des stats booléennes ; `hit_incoming` ajouté aux signaux du carrier ; `ItemEffect.owned` en `WeakRef` ; `ItemCatalog` sans cache statique ; HeartRow inchangé : D5.1-2, D5.1-4, D5.1-6, D5.1-7, D5.1-11, D5.1-13.
- Télémétrie : objets pris dans `run_end` (`items`), compte par `item_id` dans le résumé, pas d'événement propre : D5.1-16.
- Touche F1 `I` pour poser un objet, libre : D5.1-8, D5.1-18.
- Architecture alignée sur `StatBlock` : D5.1-1.

**Salle trésor (5.2)**
- Marqueur `PickupSpot` et directive ASCII `pickup` (aussi pour la boutique) ; seul l'emplacement `ITEM` est lu par `Run` ; les autres salles du pool ne sont pas regénérées pour recevoir `PickupSpots` : D5.2-3, D5.2-9, D5.2-10.
- Catégorie de journal `economy` ; `ItemDef.can_be_taken(max_half_hearts: int)` ; aucune touche ajoutée : D5.2-7, D5.2-8, D5.2-11.

**Consommables (5.3)**
- `ConsumableCatalog` refuse un `.tres` sans clé requise : D5.3-7. Ligne d'aide des touches ajoutée ; HUD vidé à `run_started` : D5.3-11, D5.3-12.

**Éclats et drops (5.4)**
- Éclats dans `RunState`, signal `shards_collected`, `shards_changed(0)` en fin de `Run._ready` : D5.4-2, D5.4-9, D5.4-10.
- `Drops.spawn(room, kind, position, consumable_roll)` au lieu de `(kind, position, rng)`, doc d'architecture à aligner : D5.4-7, D5.4-16.
- Pickups superposés (`_must_leave`), validation du catalogue dans `Room.add_offer` et `BuildCarrier.refusal_of`, correctifs de revue 5.3 en commits à part, test instable `test_seed_flow` : D5.4-11, D5.4-12, D5.4-13, D5.4-17.

**Boutique (5.5)**
- Achat dans `Pickup.try_purchase()` depuis le tick physique, refus qui désarme l'article ; `ShopStock.draw` ; bannière de lecture une fois par approche ; signal `shop_purchased` et événement `purchase` ; 2 étals d'objets en dur dans la structure de salle : D5.5-6, D5.5-7, D5.5-8, D5.5-9, D5.5-14.

**Chute (5.6)**
- Pré-validation de `required_params` ; consommables figés à la mort du joueur ; échecs de `t_enemy_main` / `t_sheep_main` classés « harnais » : D5.6-7, D5.6-8, D5.6-9.

**Synergies (5.7)**
- `SynergyEffect` séparé d'`ItemEffect`, source `SHOCKWAVE`, `SynergyDef.effect_script`, `SynergyCatalog` dans son fichier, `Room.shockwave` crée l'anneau, modificateur de coût de chute par `pit_damage` : D5.7-2, D5.7-3, D5.7-9, D5.7-10, D5.7-11.
- Touche F1 `Y` : D5.7-6. Cycle de chargement `EnemyDef` → … → `Run` reporté (sans effet via `Main`) : D5.7-15.

**Objet actif (5.8)**
- Jeton du ralenti `apply_slow(token, …)` et jeton = l'instance de l'effet ; dépense de lucidité et charge dans `BuildCarrier.use_active()` ; objet actif aussi dans `Loadout.items()` ; objet ajouté aux deux pools : D5.8-3, D5.8-7, D5.8-8, D5.8-9, D5.8-10.

**Copie d'examen (5.9)**
- `room_entered` émis en fin de `Room._ready()` via `Player.room_ready(room)` : D5.9-7. `EXTRA_SLOTS = 1` : D5.9-8.
- Commit croisé du fixer de 5.8 (hunks de 5.9 dans `94a020a`) : D5.9-13.

**Miroir (5.10)**
- `spawn_enemy` reçoit un `prepare: Callable` ; `BuildCarrier.setup_host` ; `Loadout.add_def_for_copy` : D5.10-7, D5.10-8, D5.10-9.

---

## 4. À juger en jouant

Tout ceci n'a été vérifié que par tests automatiques ; aucune capture fenêtrée WSLg n'a été examinée.

**Touches utiles**
- `Q` (physique ; A sur AZERTY) ou manette `Y` : utiliser le consommable.
- `E` ou manette `X` : objet actif (Réveil cassé).
- Panneau `F1` : `I` pose le prochain objet du catalogue, `K` le prochain consommable, `Y` donne les objets de la chute, `U` recharge l'objet actif, `N` fait apparaître le reflet (anciennement `M`). `C` rejoue la seed courante.

**Objets, bannière, trésor (`I`)**
- Bannière de 3 lignes en 3 s, losange doré du pickup et grisé « non prenable », piédestal de la salle trésor (D5.1-3, D5.1-12, D5.2-3).
- Jambes de plomb (−20 % vitesse) et Dent (+30 % dégâts pour −1 cœur max) : lourdeur et prix acceptables ? Meubles qui arrêtent les tirs traversants (D5.1-19).

**Consommables (`K`, touche `Q`)**
- Café (+30 % vitesse et cadence 10 s, puis −20 % vitesse 5 s) et Se pincer (+25 de lucidité pour ½ cœur) ; icône provisoire, touche Q à côté des touches de déplacement, manette Y non testée (D5.3-3, D5.3-7).

**Éclats et drops**
- Disques provisoires (rouge, gris-bleu, or), 1 à 3 Éclats × palier, 30 % de chance de drop, drop à la dernière mort (D5.4-3, D5.4-8). Éclats gagnés par étage face aux prix de la boutique (cible GDD : environ 16 par étage Lucide, 32 en Abandon ; D5.4-15).

**Boutique**
- Lisibilité des étals, des prix et de la bannière de lecture ; équilibre 15 / 5 / 4 / 5 ; achat au contact sans touche (D5.5-1, D5.5-2, D5.5-12). Longer le cercle de 2 tuiles réémet la bannière.

**Chute (trou, objets `Y`)**
- Chute libre : +5 %/s par paliers, ½ cœur de plus au coup, coup de chute qui compte (D5.6-1, D5.6-2). Ailes de papier : 3 s de suspension (D5.6-3).
- Onde de Piqué (1,5 tuile, 15 dégâts) et Chute sans fin (2,5 tuiles, 30 dégâts) : anneau et sons provisoires, bannière de synergie en file, dash qui finit sur un trou, lampe non allumée par l'onde (D5.7-1, D5.7-12, D5.7-13, D5.7-14).

**Objet actif (`E`, `U`)**
- Ralenti de 50 % pendant 4 s, coût de 15 de lucidité, recharge en 3 salles, son et anneau provisoires, barre de charge du HUD, manette X non testée. Tirs du joueur et FX non ralentis (D5.8-1) ; ralenti qui perd du temps dans le fondu de porte (D5.8-14).

**Copie d'examen et Être nu en public**
- Chrono de 45 s et bande de texte du HUD (« Copie d'examen : 45 s » mesure 131 px dans 130 px et chevauche la 12e icône de cœur), +30 % de vitesse et de cadence à zéro, gêne de 1,5 s depuis `fight_started`, aucun signal au passage à zéro (D5.9-1, D5.9-3, D5.9-12). Ruée du Somnambule +30 % de distance (D5.9-10, D5.9-14).
- Drop d'armure toujours refusé sous Être nu en public : injuste ou non ? (D5.9-5).

**Miroir (`N`)**
- Ressenti du reflet : distance gardée (5 tuiles), cadence 2 s, télégraphe de 0,5 s, placeholder violet, 60 PV, fréquence 1 salle de combat sur 4 ; il recule en ligne droite et peut se coincer dans un coin ; apparition ramenée dans la vue en salle large (D5.10-1, D5.10-4, D5.10-11, D5.10-13, D5.10-14). La salle attend le reflet pour passer à la vague suivante (D5.10-10).

---

## 5. Actions qui te reviennent

1. **Stories 1.7 (réassignation des touches, invites par périphérique) et 1.8 (export, latence, relance en moins de 3 s)** : toujours reportées, à faire avant le playtest du jalon A. 7.1 (cohérence des graphismes IA) aussi, avant que des amis jouent. La 1.7 compte davantage depuis que Q / E et X / Y sont posées sans réassignation (D5.3-3, D5.8-5).
2. **Mesure de 10 minutes à 400 projectiles** (story 1.2) : toujours pas faite. `F5` lance le test de charge, `F3` affiche la perf ; cible 60 FPS soutenus, 1 % low d'au moins 55.
3. **Télémétrie chez tes amis : ni avertissement ni option pour la couper.** À prévoir pour le build du jalon A : une ligne dans le README livré et, si tu veux, un réglage de désactivation. Les objets pris et les achats sont maintenant écrits dans la télémétrie (D5.1-16, D5.5-9). Tes vraies sessions de télémétrie ont été supprimées par un agent le 2026-11-24 ; la règle a été corrigée depuis.
4. **Équilibrage de l'économie pour le playtest :** Éclats par palier et chance de drop, prix de la boutique (15 / 5 / 4 / 5), valeurs de Copie d'examen et d'Être nu en public, coût du Miroir, facteur d'étage (D5.10-1). Pools à 2 objets seulement au début : contenu et tirage réels à juger quand le catalogue sera plus fourni (D5.2-6).
5. **À trancher avec la rétro d'epic :** la liste des écarts de la section 1, en particulier D5.8-1 (ralenti du joueur, de ses tirs et des FX) et D5.5-2 (taille d'un cœur en boutique) ; documentation d'architecture à aligner (`Drops.spawn`, ligne `economy/`, lexique boutique, apparence de la balle du reflet).
