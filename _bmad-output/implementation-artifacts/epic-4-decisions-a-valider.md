# Epic 4 : décisions prises sans toi, à valider

> **En attente : Kroustille validera toutes les décisions en une fois, à la fin. Les choix par défaut s'appliquent d'ici là.**

Pendant l'epic 4 (stories 4.1 à 4.11 : tests, salles prédessinées, trous, meubles, chemins, grandes salles, génération d'étage, changement de salle, carte, pool de l'Endormissement, seed), des décisions ont été prises sans toi. Elles sont toutes notées dans les sections « Décisions prises sans Kroustille » de chaque story. Ce document les trie pour que tu puisses valider vite, en même temps que celles des autres epics.

**Comment répondre :** réponds avec les numéros à changer et ce que tu veux à la place ; tout le reste est validé. Exemple : « D4.7-2 : 64 bits ; D4.9-1 : icônes après visite seulement ».

Lecture d'un numéro : `D4.3-7` = story 4.3, décision 7. `D4.3-R1` = décision de la revue de code (label R1 de la story). Les « Revue » des stories sans label R gardent leur numéro (par exemple `D4.9-10`). Quand une décision se subdivise en lettres (a, b, c…), le numéro porte la lettre (`D4.7-10c`, `D4.8-9g`). La 4.5 n'a pas de décision 7.

Colonne « GDD ? » : **conforme** (le GDD ou l'epic dit déjà la même chose), **comble un manque** (rien n'est dit, on a choisi), **s'en écarte** (le GDD, l'epic ou l'architecture dit autre chose).

Plan :
1. Écarts au GDD, aux epics ou à l'architecture.
2. À regarder en priorité (ce que le joueur ressent), par thème.
3. À survoler (technique, une ligne par sujet).
4. À juger en jouant (ce qui n'a jamais été vu ni tenu en main par un humain).
5. Actions qui te reviennent.

---

## 1. Écarts au GDD, aux epics ou à l'architecture

Dix-neuf points s'écartent d'un texte de référence ou le lisent de façon ambiguë. Chacun reprend aussi son contexte dans la section 2 ou 3.

**Cadre de test et outillage**

- **D4.1-1 : GUT plutôt que GdUnit4.** Noté pour mémoire : l'epic et l'architecture disent « GUT ou GdUnit4 », donc conforme. Choix réversible tant que les tests sont peu nombreux.
- **D4.2-1 : salles produites par un outil ASCII puis converties en `.tscn`, pas peintes dans l'éditeur.** Le GDD et l'architecture (D10) parlent de salles « dessinées » dans Godot. Raison : les agents ne peuvent pas peindre. Les `.tscn` restent la vérité et sont éditables à la main (une retouche à la main doit être reportée dans le texte source, voir D4.2-20).
- **D4.3-3 : `PitGuard` à la place de `PlayerMotor` pour la position sûre.** L'architecture range le mouvement dans `PlayerMotor`. Raison : testabilité, `PlayerMotor` reste de la vitesse pure.

**Comportements validés à l'epic 2 modifiés**

- **D4.3-7 : le Somnambule ne pousse plus le joueur immobile** (reprise de la décision 33 de la 2.3). Ressenti NON ÉVALUÉ.
- **Mouton arrêté par les obstacles hauts : étourdi comme contre un mur** (point 6 du descriptif de la story 4.5, sans numéro de décision ; D4.5-3 en est le pendant pour les obstacles bas et les meubles, qui arrêtent sans étourdir). Change la charge validée à l'epic 2.
- **D4.3-6 puis D4.6-9 : limite de charge du Mouton, 45 tuiles puis environ 65 tuiles (1,5 diagonale) en salle d'un écran.** Filet de sécurité ajouté à une charge sans limite jusque-là.
- **Patch de revue 4.6 (sans numéro) : durée de vie des balles ennemies de 10 s à 18 s** (`enemy_bullet_lifetime`, tuning et valeur par défaut). Raison : 10 s ne couvre pas la diagonale d'une salle large (72 tuiles) avec les balles les plus lentes. Effet : les balles ennemies vivent plus longtemps dans toutes les salles.

**Génération, carte, seed**

- **D4.7-2 : seed de 40 bits** (l'epic 4.7 et l'architecture disent « 64 bits » ; le GDD dit « 8 caractères », ce que 40 bits en Crockford base32 donne). Même question qu'en D3.7-1.
- **D4.9-1 : icônes des salles spéciales visibles dès qu'elles sont adjacentes et reliées à une salle visitée (façon Isaac).** Le GDD dit « la carte se révèle au fil de l'exploration » et l'epic « une fois découverts ». Lecture : adjacent relié = découvert (revue D4.9-9 : confirmé).
- **D4.9-10 : la carte se cale sur la grille fixe du générateur (9×7, départ au centre), pas sur l'emprise réelle de l'étage.** Raison : l'emprise révélerait la forme de l'étage, contre « se révèle au fil de l'exploration ». Coût : la carte est petite et excentrée quand l'étage est compact.
- **D4.11-1 (avec D4.11-11) : pas de saisie de seed à la manette.** Le GDD dit « saisissable avant une run » sans exclure un périphérique. Reporté aux menus manette de l'epic 7 ; NON VÉRIFIÉ.

**Pool de salles (4.10)**

- **D4.10-1 : quotas chiffrés fixés par les agents** (70 % de salles de combat à trous, 4 types d'ennemis chacun dans au moins 10 salles, 3 grandes salles dont 2 hautes, 6 salles à meubles, 3 à lampe). L'epic dit « la plupart », « quelques ». Servent de seuils de test.
- **D4.10-8 (avec D4.10-12) : « beaucoup de trous » = au moins 40 cases de trou** (6 % d'un écran). Seuil de test, pas règle de level design.
- **D4.10-13 : « obstacles hauts et bas dans au moins 15 salles » lu « hauts ou bas »** (20 salles ; 16 avec des hauts, 11 avec des bas, 5 avec les deux ; le test exige aussi 4 salles avec les deux).

**Caméra et HUD**

- **D4.6-5 : la vue d'une grande salle peut montrer jusqu'à 24 px hors du mur du haut**, sous la bande de HUD. L'epic dit « sans jamais montrer l'extérieur ».
- **D4.4-3 : la lampe ne réagit qu'aux tirs du joueur** ; les tirs ennemis la traversent. Le GDD dit « un tir ».

**Flux de partie**

- **D4.8-1 : le mode par défaut de `Main` est maintenant l'étage (FLOOR), plus l'arène du jalon A.** L'arène reste accessible par F1 (touche B, voir D4.8-10a). Tout lancement du jeu démarre donc sur un étage généré.
- **D4.11-8 (avec D4.8-10d et D4.11-12) : « Se rendormir » après une run avec seed saisie tire une nouvelle seed.** Le GDD et l'epic attachent la seed saisie à une seule run. Pour rejouer : bouton « Nouvelle partie avec une seed » ou F1 `C`.
- **D4.11-9 (avec D4.11-14) : la seed est écrite sur l'événement `run_start` de la télémétrie** (`seed`, `seeded`), pas dans un bloc de run ni un événement à part. L'epic 4.11 (AC 5) évoque un bloc de run que `TelemetrySession` n'a pas.

---

## 2. À regarder en priorité

### Salles et portes (4.2, 4.8)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D4.2-3 | Portes à des positions canoniques : milieu de chaque côté, 2 tuiles de large. | Le générateur n'a qu'un côté à connaître, la porte d'arrivée se calcule sans lire la scène. | comble un manque |
| D4.2-4 | Une porte fermée ou scellée est une tuile de `Walls` retirée à l'ouverture. | Tirs, Glissement et ennemis la respectent sans code propre. | conforme |
| D4.2-9 | Portes ouvertes au chargement, fermées dès l'entrée dans une salle qui a des `EnemySpawn`, sans attendre `start_delay`. `Door.seal()` seule voie vers SCELLÉE (générateur). | Une salle de combat est fermée dès que le joueur y est. | conforme |
| D4.2-10 | Cadre complet peint par l'outil ; les portes percent leur trou à l'exécution. | La salle ouverte dans Godot montre un cadre plein. | comble un manque |
| D4.2-11 | Rythme des salles dans `RoomTuning` : 1 s avant la première vague, 2 s entre vagues, comme l'arène. Une salle ne peut pas le surcharger. | Valeurs de l'arène déjà jouées. | comble un manque |
| D4.2-5 | `room_cleared` émis une seule fois par salle prédessinée (une fois par vague pour l'arène). | Récompense et changement de salle n'ont besoin que de la fin de salle. | conforme |
| D4.2-12 | Vague sautée (aucun ennemi n'a pu paraître) : le renfort annoncé est annulé, arène comprise. | Évite un renfort sans vague. | comble un manque |
| D4.2-19 | Ordre de fin de salle : `end_room()` ouvre les portes, puis `room_cleared` (inverse du CA 6). | Un écouteur voit une salle déjà gagnée. | comble un manque |
| D4.2-18 | Distance porte-apparition mesurée au centre de la porte, 4 tuiles ou plus. | Règle documentée et testée ; la 4.8 la revisite. | comble un manque |
| D4.8-2 | Fondu au noir 2 × 0,12 s, entrée à 2,5 tuiles de la porte, pas de glissement de caméra. | Simple et lisible ; durées dans `Tuning.ROOM`. | comble un manque |
| D4.8-3 | Les tirs en vol disparaissent avec la salle quittée ; joueur désactivé pendant la transition. | Aucun coup possible dans le noir (la revue D4.8-10f a corrigé le cas où il restait possible). | comble un manque |
| D4.8-4 | Salle vidée = définitive pour la run, l'état vit dans `FloorMap`. | Pas de farm ni de réapparition. | conforme |
| D4.8-9g | Un joueur dans l'embrasure quand les portes se ferment est replacé au point d'entrée de cette porte. | Évite d'être coincé dans un mur de porte. | comble un manque |
| D4.8-9h | En mode ROOM (F1 R) et arène, les portes restent telles que peintes : ouvertes sur le vide une fois la salle vidée. | Outils de debug, pas de voisin à rejoindre. | comble un manque |

### Trous (4.3)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D4.3-1 | Position testée = centre du corps. | Lecture simple de la chute ; un bord de trou est un peu indulgent. | comble un manque |
| D4.3-2 | Chute sans dégât si invulnérable, mais retour quand même. | Évite de camper dans un trou pendant l'invulnérabilité. | comble un manque |
| D4.3-4 | Les ennemis ne tombent pas ; le Mouton qui charge traverse un trou. | Le GDD ne parle que du joueur. | comble un manque |
| D4.3-5 | Chute au Glissement : pas d'invulnérabilité d'arrivée de 0,1 s. | Sinon le coup de chute serait refusé. | comble un manque |
| **D4.3-7** | **Plus de poussée du Somnambule sur le joueur immobile.** | Voir section 1. NON ÉVALUÉ. | **s'en écarte** |
| D4.3-R1 | En vol (dash), la position sûre reste une cellule sans trou : toute case sûre traversée compte. | Sinon la fin d'un vol au-dessus d'un trou enferme le joueur dans des chutes. | comble un manque |
| D4.3-R2 | Couloir de `onset_combat_004` décalé du centre (deux tuiles de marge). | Le joueur paraît au centre jusqu'à la 4.8. | comble un manque |
| D4.3-13 | Un coup de chute réduit à moins d'un demi-cœur (stat à 0) repositionne sans coup. | `Health` refuse sous 0,5. | comble un manque |

### Meubles et lampe (4.4)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D4.4-1 | Un coup ennemi vaut 1 PV sur un meuble. | Le GDD ne chiffre que les 30 PV. | comble un manque |
| D4.4-2 | Le meuble bloque les corps comme un obstacle haut et arrête la charge du Mouton sans l'étourdir. | Cohérent avec D4.5-3. | comble un manque |
| **D4.4-3** | **La lampe ne réagit qu'aux tirs du joueur.** | Voir section 1. | **s'en écarte** |
| D4.4-4 | Le contact reste actif pendant l'éblouissement. | Règle de télégraphe du GDD : le contact n'est pas une attaque. | conforme |
| D4.4-5 | Reprise à l'état de départ après l'éblouissement. | Plus simple que l'état interrompu. | comble un manque |
| D4.4-6 | La lampe n'est pas détruite et ne coupe pas les tirs au-delà de leur consommation. | « Jouer avec la salle », pas détruire la salle. | comble un manque |
| D4.4-7 | Le validateur interdit les meubles à détruire obligatoirement. | Une salle ne peut pas exiger de les casser. | comble un manque |
| D4.4-8 | Portée de la lampe inclusive : un ennemi à exactement 3 tuiles est ébloui. | Le GDD dit « moins de 3 tuiles » sans borne. | comble un manque |
| D4.4-9 | Pose des meubles : marqueur au centre de la tuile en haut à gauche ; lit 3×2, chaise 1×1, pupitre 2×1 (provisoire). | Le GDD ne donne pas les tailles. | comble un manque |
| D4.4-10 | Éblouissement : teinte jaune provisoire, minuteur de tir gelé, Mouton étourdi ramené au repos ; la lampe n'a ni corps ni PV et refuse le coup sans chiffre ; les meubles montrent un chiffre de dégâts. | Feedback minimal avant l'epic 7. | comble un manque |
| D4.4-13 (R1) | Tirs en vol du même tick : les PV ne baissent plus, ceux des ticks suivants passent ; quelques balles du même tick sont consommées. La lampe passe en `one_hit_per_tick`. | Un budget de coups par hurtbox coûterait plus qu'il ne rapporte. | comble un manque |

### Ennemis et chemins (4.5)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D4.5-2 | L'accélération du Somnambule reste directe ; seule la poursuite est pathée. | Elle dure 0,6 s (3 tuiles environ) ; la contourner changerait sa lecture. | comble un manque |
| D4.5-3 | Un obstacle bas ou un meuble arrête le Mouton sans l'étourdir. | L'epic ne parle que des hauts. | comble un manque |
| D4.5-4 | Les trous sont des cellules bloquées pour les ennemis (ils les évitent) alors qu'ils n'y tombent pas. | Évite des ennemis qui s'arrêtent au bord. | comble un manque |
| D4.5-6 | Pas de ligne de vue pour les tireuses : elles tirent à travers les obstacles. | Hors périmètre ; NON ÉVALUÉ au jeu. | comble un manque |
| D4.5-12 | Le Somnambule ne télégraphie qu'avec une ligne libre vers le joueur. | Sinon il boucle télégraphe/ruée contre un mur d'une tuile. | comble un manque |
| D4.5-9 | Le test de ligne directe est planifié comme le chemin (toutes les 0,4 s) : frottement d'au plus 0,4 s contre un coin si la cible bouge. | Coût borné. | comble un manque |

### Grandes salles et caméra (4.6)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D4.6-1 | Dimensions jouables 72×19 et 36×38, soit deux écrans. | L'epic dit « à ajuster selon la grille ». | conforme |
| D4.6-2 | Caméra posée par calcul pur, sans `limit_*` ni lissage. | Lisible, testable. | conforme |
| D4.6-3 | Caméra sur la position du tick, sans avance sur la visée. | NON ÉVALUÉ. | comble un manque |
| D4.6-4 | Une porte par côté, au milieu, même en grande salle. | Cohérent avec D4.2-3. | comble un manque |
| **D4.6-5** | **La vue peut montrer 24 px hors du mur du haut.** | Voir section 1. | **s'en écarte** |
| D4.6-6 | Ennemis hors vue en grande salle (télégraphes, tirs, apparitions) : reporté au playtest ; seul le renfort est corrigé. | Les balles et la charge restent lisibles en entrant dans la vue. | comble un manque |
| D4.6-7 | Toute la salle passe en priorité de physique 10 (pas seulement la caméra). | Cohérence ; effets décalés d'un tick sans conséquence. | comble un manque |
| D4.6-8 | En salle haute (TALL) le joueur est 12 px au-dessus du centre de la zone visible. | Négligeable. | conforme |
| **D4.6-9** | **Limite de charge du Mouton de 45 à environ 65 tuiles en salle d'un écran.** | Voir section 1. | **s'en écarte** |

### Génération d'étage (4.7)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D4.7-1 | Une salle = une cellule de grille, y compris les grandes. | La génération ignore la taille. | comble un manque |
| **D4.7-2** | **Seed de 40 bits.** | Voir section 1. | **s'en écarte** |
| D4.7-3 | Étage = arbre étendu puis boucles facultatives entre salles non spéciales. | Chemin garanti, impasses pour trésor, boutique, cauchemar. | conforme |
| D4.7-4 | Distance = nombre de connexions. | Le GDD dit « 4 salles ou plus ». | conforme |
| D4.7-5 | Salles tirées dans `rooms`, forme dans `layout` : changer le pool ne change pas la forme pour une seed donnée. | La disposition ne dépend que de la seed. | conforme |
| D4.7-8 | Cauchemar provisoire = combat renforcé, sans renfort. | Comme l'epic ; contenu à l'epic 6. | conforme |
| D4.7-10c | Les impasses spéciales se greffent sur un départ ou un combat, dans l'ordre cauchemar, trésor, boutique. | Détermisme ; structurel. | comble un manque |
| D4.7-10d | Départ au centre de la grille. | Structurel. | comble un manque |
| D4.7-10i | `onset_combat_009` à `012` ont les quatre portes pour que le pool réel remplisse toujours un étage. | Le pool réel compte 12 combats. | comble un manque |
| D4.7-R1 | `seed_value` n'est lu que si `seeded` est vrai ; la 4.11 dira si une run à seed fixe compte pour la progression. | Le panneau F1 en dépend. | comble un manque |
| D4.7-R2 | Les connexions d'un étage sont exactement `FloorLayout.edges()` : une porte hors `door_sides(cell)` reste scellée. | Sinon `loop_chance` ne voudrait rien dire. | comble un manque |

### Changement de salle et tutoriel (4.8)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D4.8-1** | **Défaut de `Main` = étage** ; l'arène par F1 `B`. | Voir section 1. | **s'en écarte** |
| D4.8-5 | Repli sur l'arène si l'étage ne se génère pas ou si une salle manque (AR28). | Jamais d'écran mort. | conforme |
| D4.8-6 | Tutoriel affiché dans la salle de départ, tant que le joueur y est : une aide par action, texte court, périphérique selon la dernière entrée. | Plutôt qu'au seul début de la run. | comble un manque |
| D4.8-10a | La commande « arène » du panneau F1 quitte la touche A (celle de `move_left`) pour la touche B. | Marcher à gauche panneau ouvert relançait l'arène. Remplace D4.8-9j pour l'arène. | comble un manque |
| D4.8-10b | Le tutoriel affiche l'étiquette de la disposition active (AZERTY : Z/Q/S/D), repli sur le nom physique en headless. | Le joueur visé est francophone ; remplace l'API prescrite par la tâche. | comble un manque |
| D4.8-10d | La relance après la mort tire une nouvelle seed (mode FLOOR gardé). | La même seed est la 4.11. | conforme |
| D4.8-9k | Mi-run, une salle qui ne se charge pas : `Log.error` et repli sur l'arène, la run continue. | AR28. | conforme |

### Carte de l'étage (4.9)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D4.9-1** | **Salles spéciales visibles dès l'adjacence reliée (façon Isaac).** | Voir section 1. Confirmé en revue par D4.9-9. | **s'en écarte** |
| D4.9-2 | Les voisins non reliés par une porte restent invisibles. | Pas « adjacents » pour le joueur. | comble un manque |
| D4.9-3 | Select = bouton Back de la manette ; Tab au clavier, maintenu ; pas de réassignation avant l'epic 7. | Le GDD dit « maintenu ». | conforme |
| D4.9-4 | Carte masquée en pause, sur l'écran de réveil et hors mode étage. | Un dessin par-dessus un menu n'aurait pas de sens. | comble un manque |
| D4.9-5 | Pas de légende des salles courantes (combat, départ), seulement des trois icônes spéciales. | Garde la carte lisible. | comble un manque |
| D4.9-6 | Marque « vidée » ajoutée (non demandée). | Aide à choisir où aller. | comble un manque |
| **D4.9-10** | **La carte se cale sur la grille fixe 9×7, pas sur l'emprise de l'étage.** (Remplace D4.9-7.) | Voir section 1. | **s'en écarte** |
| D4.9-11 | Le fond de la carte laisse la bande de HUD visible. | Le jeu continue, les cœurs doivent rester lisibles. | comble un manque |

### Contenu du pool (4.10)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D4.10-1** | **Quotas chiffrés (70 % de trous, etc.).** | Voir section 1. | **s'en écarte** |
| D4.10-3 | Au moins 2 renforts par salle, dont un loin des portes. | Le GDD exige un renfort prévu ; le tirage `combat` a besoin de choix. | conforme |
| D4.10-4 | Pas de duplication par retournement sans vagues différentes. | Variété réelle plutôt que quantité. | comble un manque |
| D4.10-5 | Plan de difficulté provisoire, réglé au jalon B. | Rien de mesuré. | comble un manque |
| D4.10-6 | Une seule salle de départ, de trésor, de boutique et de cauchemar. | Contenu définitif aux epics 5 et 6. | comble un manque |
| D4.10-7 | Deux salles à trois portes (018, 025), les 28 autres à quatre (93 %). | Le générateur a besoin de portes partielles. | comble un manque |
| **D4.10-8**, D4.10-12 | **« Beaucoup de trous » = 40 cases au moins.** Gardé en revue : 6 salles dépassent 100 cases. | Voir section 1. | **s'en écarte** |
| D4.10-9 | Le Mouton passe en vague 2 dans 005 et 010. | « Première vague douce ». | conforme |
| **D4.10-13** | **« Hauts et bas » lu « hauts ou bas ».** | Voir section 1. | **s'en écarte** |
| D4.10-14 | Écarts au plan de difficulté acceptés (014 à 018 à trois types, premières vagues de 021 à 027 à 2 ennemis). | L'AC (2 à 6 ennemis) tient ; équilibrage au jalon B. | conforme |
| D4.10-15 | 17 salles ouvrent sur 2 Somnambules seuls (5 aux mêmes marqueurs) : reporté au jalon B. | Contenu, pas un défaut d'AC. | comble un manque |

### Seed : affichage et saisie (4.11)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D4.11-1** (D4.11-11) | **Saisie au clavier seulement** (champ de texte, collage possible). | Voir section 1. | **s'en écarte** |
| D4.11-2 | Pas de séparateur à l'affichage (« XXXXXXXX ») ; tirets et espaces tolérés en saisie. | Simple. | comble un manque |
| D4.11-5 | « Nouvelle partie avec une seed » aussi à l'écran de réveil ; pas d'écran-titre. | Le GDD : « saisissable avant une run », « affichée à la mort ». | conforme |
| D4.11-6 | `seeded` ne bloque que les déblocages (indicateur pour l'epic 8) ; une seed saisie reste rejouable à l'identique à déblocages égaux. | GDD. | conforme |
| **D4.11-8** (D4.11-12) | **Une relance tire une nouvelle seed ; le raccourci « fenêtre pré-remplie avec la seed courante » est reporté.** | Voir section 1. | **s'en écarte** |
| D4.11-13 | Une seed saisie depuis l'arène ou une salle F1 démarre toujours un étage. | AC 7 et la tâche nomment FLOOR. | conforme |

---

## 3. À survoler

**Tests (4.1)**
- GUT 9.7.1 épinglé, dépôt `bitwes/Gut` ; pas de `runner.tscn`, plugin non activé dans `project.godot` : D4.1-4, D4.1-5, D4.1-6.
- Contrat de test de l'epic (tests versionnés par story, anciennes scènes `.scratch` non portées) ; test de `RunRng` ajouté : D4.1-2, D4.1-3.
- Un test « pending » ou « risky » fait échouer `run_tests.sh` ; `user://` isolé par `XDG_DATA_HOME` (Linux/WSL seulement) ; tests de `Lucidity` sur les valeurs par défaut du script, pas sur le `.tres` : D4.1-7, D4.1-8, D4.1-9.

**Salles prédessinées (4.2)**
- `Arena` sous-classe de `Room` ; `RunOptions` et `Events.run_requested` comme seule entrée de relance, mémorisées par `Main` ; F1 `R` salle suivante du pool ; pas de `Pits` dans `Arena` : D4.2-2, D4.2-6, D4.2-13, D4.2-14.
- Salles sans renfort acceptées (départ, trésor, boutique, cauchemar) : D4.2-7.
- `Door.Side` déclaré tel quel dans les annotations (énumération globale `Side` de Godot) : D4.2-8.
- Fixtures et validateur (salle COMBAT sans `EnemySpawn` refusée), `run_tests.sh` à `--fixed-fps 60`, harnais sans `add_child_autofree` : D4.2-15, D4.2-16, D4.2-17.
- Salles du pool aplaties (copie de `room_base.tscn`, source ASCII dans `art_source/rooms/*.txt`) : D4.2-20.

**Trous (4.3)**
- `CAN_FLY_OVER_PITS` en stat flottante (`StatBlock` ne connaît que des flottants) : D4.3-8.
- Accessibilité des salles vérifiée par le validateur, flood fill avec obstacles bas bloquants, voisinage à 4 : D4.3-9, D4.3-10.
- `PitGuard.observe` reçoit le centre de la cellule ; test de chute après `finish_tick()` ; `max_charge_distance = 0` = sans limite ; Somnambule `test_move()` avant d'avancer ; fixtures `pit_band`, `pits_cut_door`, `enemy_cut_off`, `reinforcement_on_pit` : D4.3-11, D4.3-12, D4.3-14, D4.3-15, D4.3-16.

**Meubles (4.4)**
- Salles de test `onset_combat_005` et fixtures `furniture_*` / `trigger_no_kind` : D4.4-12.
- Arrêt de la charge du Mouton sans changer `STUNNING_LAYERS` : D4.4-11.

**Chemins (4.5)**
- Grille d'une tuile par cellule, cadre complet ; cellules de portes toujours bloquées : D4.5-1, D4.5-8.
- Budget de 4 calculs par tick, intervalle 0,4 s (réglables, aucune mesure de performance) : D4.5-5.
- La garde « ne pas avancer dans la cible » devient la règle de `_move_toward` : D4.5-10.
- Retour de chute d'un ennemi non traité (reste dans `deferred-work.md`) : D4.5-11.

**Génération (4.7)**
- Pool factice pour les tests ; `Room.setup` reçoit l'indice d'étage ; la seed dans `run_started` laissée à la 4.11 : D4.7-6, D4.7-7, D4.7-9.
- `FloorGenerator` sans journal (`FloorLayout.failure` + `Log.error` dans `Run.ensure_floor()`) ; croissance de l'arbre à 1 ou 2 voisines ; `is_nightmare` dérivé de `room_type` ; `RoomBuilder` valide les salles de pool sans sortie explicite ; F1 `G` et `Run.ensure_floor()` ; `seed_value` à -1 par défaut : D4.7-10a, D4.7-10b, D4.7-10e, D4.7-10f, D4.7-10g, D4.7-10h.
- `MAX_GROWTH_NEIGHBORS`, départ au centre et ordre des impasses structurels, pas des réglages : D4.7-R3.

**Changement de salle (4.8)**
- `Events.room_entered` ajouté ; aucune sauvegarde d'entrée de salle (epic 8) : D4.8-7, D4.8-8.
- `RoomOptions` porte cellule, côtés, `already_cleared`, côté d'entrée ; `Tuning.ROOM.player_entry_distance` ; `transition_duration` ; `Main.default_mode` typé `RunOptions.Mode`, ligne de repli posée dans `th.gd` : D4.8-9a, D4.8-9b, D4.8-9c, D4.8-9d.
- Le validateur vérifie les points d'entrée (`onset_combat_001` retouchée) ; salle sans ennemi ni scène n'arme pas de vagues ; départ chargé en synchrone avant les requêtes d'arrière-plan (interblocage de `load()`) ; F1 `F` étage : D4.8-9e, D4.8-9f, D4.8-9i, D4.8-9j.
- Libellés de manette en dur (LB, RB, LT, RT) ; `begin_room()` de la jauge dans chaque salle, y compris vidée ; la décision 3 « aucun coup pendant le fondu » corrigée par un patch : D4.8-10c, D4.8-10e, D4.8-10f.

**Carte (4.9)**
- `FloorMap.entries()` sans argument, `Run` pose `FloorMap.layout` : D4.9-8.

**Pool (4.10)**
- Salles composées par un script jetable puis passées par l'outil ASCII ; fixtures `catalog_dupes` : D4.10-2, D4.10-10, D4.10-11.

**Seed (4.11)**
- Un seul journal `run started seed=… seeded=…` ; `Events.run_seeded` séparé de `run_started` ; commandes F1 seed courante et presse-papiers ; salle injouable (`room_path` invalide) : repli sur l'arène avec journal d'erreur : D4.11-3, D4.11-4, D4.11-7, D4.11-10.
- Bloc de run de la télémétrie tenu par l'événement `run_start` : D4.11-14.

---

## 4. À juger en jouant

Tout ceci n'a été vérifié que par tests automatiques ; aucune capture fenêtrée WSLg n'a été examinée. Le jeu démarre maintenant sur un étage (D4.8-1).

**Touches utiles**
- `Tab` (clavier) ou `Back` (manette) maintenu : carte de l'étage.
- Panneau `F1`, quand il est visible : `1` invulnérable, `2` armure, `3` coup au joueur, `4` salve, `5` tir auto, `6` à `9` ennemis, `0` tue tout, `L` lucidité, `-` vague suivante, `R` salle suivante du pool (nouvelle run), `G` carte de l'étage de la seed dans le journal, `B` nouvelle run dans l'arène du jalon A, `F` nouvelle run sur un étage, `C` nouvel étage sur la seed courante, `V` nouvel étage sur la seed du presse-papiers, `I` pose le prochain objet du catalogue (epic 5).
- `F2` collisions, `F3` perf, `F4` ralenti, `F5` test de charge de balles.
- Pause puis « Nouvelle partie avec une seed » (aussi sur l'écran de réveil) : saisie de seed.

**Trous et chute (`R` pour jouer `onset_combat_004`, ou un étage)**
- Demi-cœur perdu, retour au centre de la dernière cellule sûre, invulnérabilité de 1 s, lisibilité des trous sans art, tolérance du bord au centre du corps (D4.3-1, D4.3-R1). Chute au Glissement (D4.3-5).
- Somnambule qui ne pousse plus : bon ou trop mou ? (D4.3-7)

**Meubles et lampe (`onset_combat_005`)**
- Lisibilité de l'éblouissement (teinte jaune, disque provisoire, aucun son), couvert des meubles (30 PV), tailles provisoires (D4.4-9, D4.4-10).

**Ennemis et obstacles (salles à obstacles ou meubles)**
- Contournement : fluide ? Frottement contre les coins, Somnambule qui ne télégraphie pas sans ligne libre, tireuses qui tirent à travers les obstacles (D4.5-6, D4.5-9, D4.5-12).
- Mouton : étourdi par un mur ou un obstacle haut, pas par un obstacle bas ni un meuble ; limite de charge (D4.3-6, D4.6-9). Coût de pathing d'une vague de 7 ennemis : mesurer avec `F5`/`F3`.

**Grandes salles (WIDE 72×19, TALL 36×38)**
- Caméra sur la position du tick, sans avance de visée ni lissage ; bande de HUD sur 24 px ; ennemis qui tirent ou télégraphient hors vue (D4.6-3, D4.6-5, D4.6-6). Balles de 18 s de vie.

**Étage et transitions (`F` ou lancement normal)**
- Fondu de 2 × 0,12 s, joueur gelé dans le noir, arrivée à 2,5 tuiles de la porte, pas de glissement de caméra (D4.8-2).
- Tutoriel de la salle de départ, étiquettes AZERTY (D4.8-6, D4.8-10b), libellés LB/RB/LT/RT sur une vraie manette.
- Portes qui se ferment avec le joueur dans l'embrasure (D4.8-9g).

**Carte (`Tab` / `Back`)**
- Lisibilité à 640×360, icônes provisoires (losange, disque, croix), marque « vidée », icônes spéciales dès l'adjacence, carte petite et excentrée sur la grille 9×7 (D4.9-1, D4.9-10). `Back` sur une vraie manette (indice 4 non vérifié).

**Pool et jalon B**
- Lisibilité et plaisir des salles 013 à 030 (005 et 009 à 012 enrichies) : tireuses derrière un obstacle haut, grandes salles de trous (D4.10-1, D4.10-8).
- Monotonie des premières vagues (D4.10-15) et plan de difficulté (D4.10-5, D4.10-14).

**Seed (menu pause, écran de réveil, `F1` `C` et `V`)**
- Aspect de la fenêtre de saisie (taille du champ, message d'erreur, fond assombri) ; pas de saisie à la manette (D4.11-1) ; « Se rendormir » tire une nouvelle seed (D4.11-8) : est-ce voulu pour rejouer ?

---

## 5. Actions qui te reviennent

1. **Stories 1.7 (réassignation des touches, invites par périphérique) et 1.8 (export, latence, relance en moins de 3 s)** : toujours à faire avant le playtest du jalon A. 7.1 (cohérence des graphismes IA) aussi, avant que des amis jouent.
2. **Mesure de 10 minutes à 400 projectiles** (story 1.2) : toujours pas faite. `F5` lance le test de charge, `F3` affiche la perf ; cible 60 FPS soutenus, 1 % low d'au moins 55.
3. **Télémétrie chez tes amis : ni avertissement ni option pour la couper.** À prévoir pour le build du jalon A : une ligne dans le README livré et, si tu veux, un réglage de désactivation. La seed est maintenant écrite dans les événements `run_start` (D4.11-9).
4. **Jalon B :** équilibrage du pool (premières vagues trop semblables, plan de difficulté provisoire, D4.10-5, D4.10-14, D4.10-15) et jugement humain des 30 salles.
5. **À trancher avec la rétro d'epic :** seed à 64 bits ou architecture corrigée (D4.7-2, D3.7-1) ; saisie de seed à la manette avec les menus de l'epic 7 (D4.11-1).
