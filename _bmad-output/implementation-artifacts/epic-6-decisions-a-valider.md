# Epic 6 : décisions prises sans toi, à valider

> **En attente : Kroustille validera toutes les décisions en une fois, à la fin. Les choix par défaut s'appliquent d'ici là.**

Pendant l'epic 6 (stories 6.1 à 6.9 : Le Professeur en trois phases, l'Interro surprise, la victoire, la chambre, l'heure du réveil, le profil et les succès, sauvegarder / quitter / reprendre, le soak de vingt nuits), des décisions ont été prises sans toi. Elles sont toutes notées dans les sections « Décisions prises sans Kroustille » de chaque story (125 au total, revues de code comprises). Ce document les trie pour que tu puisses valider vite, en même temps que celles des autres epics.

**Comment répondre :** réponds avec les numéros à changer et ce que tu veux à la place ; tout le reste est validé. Exemple : « D6.6-1 : la mort peut afficher 00:18 ; D6.2-1 : barre de 1 tuile à 8 t/s ».

Lecture d'un numéro : `D6.5-9` = story 6.5, décision 9. Les décisions de revue de code gardent leur numéro dans la liste de la story (la mention « Revue » ou « Dev » est rappelée quand elle aide). Dans la story 6.2, les décisions 8 à 14 sont des « décisions complémentaires » du dev et la liste saute de 7 à 15 pour la revue ; dans la 6.8, les décisions 10 à 20 forment une suite de la liste.

Colonne « GDD ? » : **conforme** (le GDD ou l'epic dit déjà la même chose), **comble un manque** (rien n'est dit, on a choisi), **s'en écarte** (le GDD, l'epic ou l'architecture dit autre chose).

Plan :
1. Écarts au GDD, aux epics ou à l'architecture.
2. À regarder en priorité (ce que le joueur ressent), par thème.
3. À survoler (technique, une ligne par sujet).
4. À juger en jouant (ce qui n'a jamais été vu ni tenu en main par un humain).
5. Actions qui te reviennent.

---

## 1. Écarts au GDD, aux epics ou à l'architecture

Quatorze points s'écartent d'un texte de référence, le lisent de façon ambiguë ou fixent une valeur que rien ne donnait. Chacun reprend aussi son contexte dans la section 2 ou 3.

**Boss, victoire, heure du réveil**

- **D6.6-1 (confirmé en revue par D6.6-9) : l'heure de la mort est plafonnée à 00:17** (phase moins 1 min). Le GDD donne l'heure au prorata des salles de combat vidées et 00:18 pour la victoire ; sans plafond, mourir face au boss après avoir vidé toutes les salles afficherait 00:18. Seul le cas 12 salles sur 12 change. Donnée dans `WakeTuning`, supprimable en mettant la marge à 0.
- **D6.2-1 (réglé par la revue : D6.2-15, D6.2-14, D6.2-16) : la règle est une barre verticale qui balaie la salle, 0,75 tuile à 12 tuiles/s, toutes les 7 s ; la fuir est impossible.** Le GDD dit « balaie la salle, annoncée par une ligne » sans forme ni vitesse. La parade est le dash (fenêtre de 5 ticks sur place, 19 vers la barre) ; marcher ou dasher dans le sens de la barre ne sauve jamais (D6.2-16, assumé).
- **D6.1-9 (gardé en revue par D6.1-15) : la salle du cauchemar garde ses quatre portes déclarées**, trois scellées par l'étage en jeu, donc une seule ouverte. Le générateur exige les portes du côté d'où l'impasse est atteinte ; l'AC dit « une porte », tenue en jeu.
- **D6.1-1 : le boss est un `Enemy` piloté par des données, pas un chemin dédié ; `professor.gd` est une marionnette et la logique est dans `boss.gd`.** Écart léger à l'architecture.
- **D6.4-1 : délai de victoire de 2 s avec invulnérabilité forcée avant `run_ended`.** L'epic enchaîne mort du boss et réveil sans durée ; la valeur est choisie, sans écart de texte.

**Chambre, touches**

- **D6.5-1 : le personnage de la chambre est un marcheur minimal (`BedroomWalker`), pas le `Player`.** Écart à l'esprit d'AR20 sans le contredire : le `Player` est couplé à une salle (tir, lucidité).
- **D6.5-9 (remplace D6.5-3, dont le texte dit E) : `interact` sur X au clavier et A / Croix à la manette**, pas E ni X / Carré : E et le bouton X de la manette portent déjà `use_active`, F est pris par le panneau F1. Remappage avec la story 1.7 (reportée). À lire avec D6.5-14 (textes « E / X-Carré » de la spec remplacés, spec non réécrite).

**Sauvegarde, profil, télémétrie**

- **D6.8-1 : les stocks des salles visitées sont dans `run.json`** (ligne ajoutée à l'architecture D12, qui ne les listait pas). Sans eux, un objet laissé au sol ou une boutique à moitié achetée reviendraient différents.
- **D6.8-6 (avec D6.4-5) : un seul étage pour sauvegarder et reprendre.** `Run.stocks` et la carte restent indexés par cellule seule ; `floor_index` est sauvé pour qu'une migration de format suffise à l'acte 1. Les entrées différées sur l'enchaînement d'étages ne sont pas traitées par l'epic 6.
- **D6.8-16 (avec D6.8-17) : « Sauvegarder et quitter » perd le progrès de la salle en cours** (ennemis tués, achats, dégâts subis depuis l'entrée) et les états de pouvoir (café, ralentis). Voulu par le GDD d'après la story, le save-scum étant une limite acceptée.
- **D6.7-11 (avec D6.7-4) : une run avec seed saisie ignore les déblocages du profil et n'écrit rien dans le profil** (statistiques comprises). L'AC ne parle que de victoire et de succès. Conséquence différée : une seed affichée en fin de run normale ne rejoue plus la même nuit une fois des déblocages acquis.
- **D6.6-7 : `Log.info` et non `Log.warn` quand il n'y a pas de plan d'étage** (arène, salle seule). Écart à l'AC 6, qui se lit « 23:00, journalisé ». Un warning à chaque mort en arène serait du bruit.

**Qualité**

- **D6.9-1 : soak automatisé (20 runs et 10 seeds, mesures de télémétrie) à la place de 20 parties jouées.** L'epic parle de parties « jouées sur la machine de référence » : les 20 nuits jouées à la main restent à ta charge (NON VÉRIFIÉ).
- **D6.9-13 : le soak garde 3 000 ms de chargement pour les relances et seeds saisies**, au lieu des 2 s du CA 1 ; le seuil de 2 s est tenu par `test_floor_load_time` sur le chemin « Se rendormir ». Les deux mesures sont faites en headless.

---

## 2. À regarder en priorité

### Le Professeur : Dictée, Calcul mental, Examen final (6.1, 6.2)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D6.1-2 | Dictée : trou de 5 tuiles, craies espacées de 0,75 tuile (diamètre 0,5), trou déplacé de 10 tuiles au plus, signe 0,5 s, annonce 1,5 s. | Le GDD ne donne que 2 s, 5 tuiles/s et un télégraphe d'au moins 0,4 s. À régler au playtest. | comble un manque |
| D6.1-16 | Espacement 0,75 gardé : la fente de 4 px égale la hurtbox Lucide de 4 px et reste fermée parce que le test de touche est `<=`. Marge nulle reportée. | Une hurtbox plus petite passerait entre les craies. | comble un manque |
| D6.1-4 | Salle sans obstacle haut, boss au centre et immobile. | Le GDD ne dit rien du déplacement ; une salle ouverte rend les rangées lisibles. | comble un manque |
| D6.1-6 | Le boss refuse l'éblouissement et le recul. | Lampe et meubles n'existent pas dans cette salle ; pas d'annonce annulée au milieu de l'épreuve. | comble un manque |
| D6.1-5 | Barre de vie en bas de l'écran, titre en haut de la salle. | Placement au jugé. NON ÉVALUÉ. | comble un manque |
| D6.1-11 | Une phase lance tous les attacks de tous ses groupes en même temps. | Les groupes servent à l'alternance de 6.2. | comble un manque |
| D6.1-17 | Renfort et reflet exclus de la salle du cauchemar. | Le GDD (« jamais en salle de cauchemar »). | conforme |
| D6.2-3 | Spirale : une craie par bras toutes les 0,2 s ; éventail visé de 3 à 20° ; Examen final : 8 s par ensemble, en commençant par la Dictée. | Le GDD donne bras, rotation, 3 craies, 3 s, rien de plus. | comble un manque |
| D6.2-8, D6.2-10 | `spread_deg` = angle entre les deux craies extrêmes (-10°, 0°, +10°) ; craies visées à 6 t/s, spirale à 5 t/s. | Le GDD ne donne pas la vitesse. | comble un manque |
| D6.2-9 | Première règle 7 s après le début de l'Examen final (signe à 6,2 s). | Pas de règle pendant l'annonce ni juste après le départ de la Dictée. À confirmer au jeu. | comble un manque |
| D6.2-2 | Attaque lourde = 2 demi-cœurs (« retire 1 cœur »), source `RULER` dédiée. | Cause de mort lisible en télémétrie. | conforme |
| D6.2-4 | Annonce de phase = pause de 1,5 s des nouvelles attaques, craies en vol conservées. | Lisibilité ; allonge le combat d'environ 4,5 s dans la cible de 75 s. | comble un manque |
| D6.2-5, D6.2-12 | Un coup multi-seuils saute à la phase atteinte sans annoncer celles qu'il enjambe ; une annonce en cours se relance si un second seuil tombe. | Pas d'empilement d'annonces. | comble un manque |
| D6.2-6 | Pas d'invulnérabilité du boss pendant l'annonce. | Le joueur n'a pas à attendre. | comble un manque |
| D6.2-7 | Durée de 75 s vérifiée par le calcul (≈ 73 s), pas mesurée. | Le tir réel dépend du joueur. | conforme |
| D6.2-11 | Une règle lancée va au bout même pendant une annonce ; `fire_hold` la fige. | Elle avance seule. | comble un manque |
| **D6.2-1**, D6.2-14, D6.2-15, D6.2-16 | **Règle : barre de 0,75 tuile à 12 tuiles/s ; fuir impossible.** | Voir section 1. NON ÉVALUÉ. | **s'en écarte** |

### Interro surprise (6.3)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D6.3-1 | Le verrou « Interro active jusqu'à la fin du combat, même si la jauge remonte » vit dans `Boss` (`_extra_active`). | L'AC le demande ; `DangerProfile` reste un calcul pur. | conforme |
| D6.3-2 | Cercles décalés d'un demi-pas (15°) à chaque tir, sans tirage. | Lisible, déterministe : pas de consommation du flux `boss`. | comble un manque |
| D6.3-3 | Annonce de l'Interro sans pause des attaques. | Une pause serait un répit en récompense d'un abandon total. | conforme |
| D6.3-4, D6.3-8 | `ChalkTitle` affiche une seule ligne à la fois ; l'Interro remplace le titre de phase encore affiché. | Détail visuel NON ÉVALUÉ. | comble un manque |
| D6.3-6 | L'Interro est gelée pendant une annonce de phase : un signe en anneau reste figé jusqu'à 1,5 s puis le cercle part. | Une annonce retient toutes les attaques. Lisibilité NON ÉVALUÉE. | comble un manque |

### Victoire (6.4)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D6.4-1** | **Délai de 2 s avec invulnérabilité forcée avant `run_ended`.** | Laisser voir la craie s'effacer et les Éclats arriver. Valeur dans `RoomTuning`, NON ÉVALUÉ. | comble un manque |
| D6.4-4 | Écran de réveil de victoire sans question de justesse. | La question vise la mort méritée ; une victoire n'a rien à juger. | conforme |
| D6.4-7 | `run_end.outcome = "abandoned"` pour une run coupée par une relance ou la fin de session. | Sans lui ces `run_end` n'auraient pas de champ `outcome`. Une relance pendant les 2 s de victoire compte abandonnée. | comble un manque |
| D6.4-8 | Un `boss_defeated` reçu après la fin de la run paie quand même ses Éclats ; `Run` l'ignore. | `Main` gèle la scène au `run_ended`, le boss ne peut plus mourir ensuite. | comble un manque |
| D6.4-5 | Les entrées différées sur l'enchaînement d'étages ne sont pas traitées. | Un seul étage au MVP. | comble un manque |

### Chambre (6.5)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D6.5-1** | **Marcheur minimal (`BedroomWalker`), pas le `Player`.** | Voir section 1. | **s'en écarte** |
| D6.5-2 | L'écran de réveil garde « Se rendormir » par défaut et ajoute « Retourner dans la chambre ». | L'AC veut à la fois la chambre et la relance directe. Si la chambre doit être un passage obligé, c'est un changement de focus et de bouton. | comble un manque |
| **D6.5-9**, D6.5-3, D6.5-14 | **`interact` sur X / bouton A (Croix), pas E.** | Voir section 1. | **s'en écarte** |
| D6.5-4, D6.5-13 | Bureau = saisie de seed, lit = dormir ; bureau en haut à droite (≈ 430 px du lit), « près du lit » lu comme « dans la chambre ». | Un second objet évite un menu dans le lit. Placement repris avec les vrais décors (epic 7). | comble un manque |
| D6.5-5 | HUD masqué dans la chambre. | Valeurs d'une run finie sans sens. | comble un manque |
| D6.5-7 | Pas de fondu entre la chambre et la run. | Même échange que la relance ; `Transition` possible plus tard. | comble un manque |
| D6.5-8 | La seed saisie est une run unique ; « Se rendormir » après tire une nouvelle seed. | Comportement de 4.11 conservé. | conforme |

### Heure du réveil (6.6)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D6.6-1**, D6.6-9 | **Mort plafonnée à 00:17.** | Voir section 1. | **s'en écarte** |
| D6.6-2 | `floori` pour le prorata : l'heure n'avance qu'à la salle vidée. | Pas d'heure intermédiaire. | conforme |
| D6.6-4 | Dénominateur = cellules `COMBAT` du plan réel, pas la constante de `onset.tres`. | Le plan réel fait foi. | conforme |
| D6.6-5 | Avant toute run, le réveil marque 23:00. | Le GDD ne dit rien du premier lancement. | comble un manque |
| **D6.6-7** | **`Log.info` sans plan d'étage.** | Voir section 1. | **s'en écarte** |
| D6.6-8 | Victoire sans plan d'étage (salle du boss seule via F1) : 23:00. | Chemin de débogage, l'heure n'y mesure rien. | conforme |

### Profil et succès (6.7)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| D6.7-3 | Succès du MVP : `professor` (première victoire), `total_abandon_room`, `synergy_three`. Liste ouverte pour l'acte 1. | Les deux derniers sont les exemples de l'epic et du GDD. | comble un manque |
| **D6.7-4**, **D6.7-11** | **Une run seedée n'écrit rien dans le profil et ignore les déblocages.** | Voir section 1. | **s'en écarte** |
| D6.7-5 | Écriture à chaque obtention et à chaque fin de run, pas seulement à la fermeture. | GDD et architecture. | conforme |
| D6.7-7 | `Events.synergy_activated(id, threshold)` ; « synergie à 3 objets » lu comme seuil ≥ 3 (`fall_3`). | L'AC parle de 3 objets. | comble un manque |
| D6.7-8 | Message de corruption = `Notice` de quelques secondes, pas une fenêtre modale. | Le jeu ne s'arrête jamais sur une erreur (architecture). | conforme |
| D6.7-6, D6.7-12, D6.7-16 | Fichier verrouillé n'est pas corrompu : ni quarantaine ni écrasement ; un seul niveau de quarantaine (un `.corrupt` plus ancien est remplacé, contrairement à `Settings`). | Ne pas perdre un profil qu'un antivirus a seulement verrouillé. | comble un manque |
| D6.7-10, D6.7-15 | Première victoire enregistrée à `run_ended(VICTORY)`, pas à `boss_defeated` comme le dit l'AC 5 ; quitter pendant les ≈ 2 s de délai de victoire la perd. | Un boss moins profond ne gagne pas la nuit ; rare, accepté. | comble un manque |
| D6.7-14 | Une run abandonnée (nouvelle seed, Quitter) ne change ni `runs` ni `last_wake_minute` ; les succès déjà obtenus restent. | Seule une nuit finie compte ; revu pour la sauvegarde en 6.8. | comble un manque |

### Sauvegarder, quitter, reprendre (6.8)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D6.8-1** | **Stocks des salles visitées sérialisés (architecture D12 complétée).** | Voir section 1. | **s'en écarte** |
| D6.8-3 | « Sauvegarder et quitter » ne réécrit rien ; il ne diffère de « Quitter » que par le libellé et l'intention. | Le dernier instantané suffit, comme après un crash. | comble un manque |
| D6.8-4 | Invite de reprise avant la chambre ; refuser efface la sauvegarde. | Le GDD ne propose qu'une nuit en cours. | conforme |
| **D6.8-6** | **Un seul étage.** | Voir section 1. | **s'en écarte** |
| D6.8-5, D6.8-17 | Les états de pouvoir en cours (café, ralentis, minuteries, bonus de Chute libre, Ailes suspendues) ne sont pas sauvés : la salle rejouée repart de zéro. | Simple ; confirmé en revue. | comble un manque |
| **D6.8-16** | **Progrès de la salle perdu à « Sauvegarder et quitter ».** | Voir section 1. | **s'en écarte** |
| D6.8-8 | Une run seedée se sauvegarde et se reprend comme une autre (`seeded` conservé, elle n'écrira toujours rien dans le profil). | Cohérent avec D6.7-4. | comble un manque |
| D6.8-9 | Un `run.json` d'une version de format plus récente est mis en quarantaine, jamais lu à moitié. | Sûreté. | comble un manque |
| D6.8-12 | L'invite s'ouvre sur la chambre gelée ; les checks qui démarrent une run effacent `run.json`. | La chambre est le décor. | comble un manque |
| D6.8-18 | Quitter pendant le délai de victoire rejoue le boss. | Même limite que D6.7-15 (≈ 2 s). | comble un manque |
| D6.8-19 | Changement du pool de salles entre deux versions : empreinte du plan en patch. | Intention de l'AC 4. | conforme |

### Soak et télémétrie (6.9)

| N° | Décision | Pourquoi | GDD ? |
|---|---|---|---|
| **D6.9-1** | **Soak automatisé à la place de 20 parties jouées.** | Voir section 1. | **s'en écarte** |
| D6.9-2, D6.9-7 | « Temps passé sous Lucide » lu comme le temps dans les paliers sous Lucide (Flottant à Abandon total), en secondes et en part de la run (temps sous Lucide divisé par la somme des secondes de paliers). L'autre lecture se déduit de `tier_seconds[0]`. | Le GDD : « au moins 25 % de la run sous le palier Lucide ». Les deux horloges (murale et de jeu) ne sont pas mélangées. | comble un manque |
| D6.9-3 | Une tentative contre Le Professeur commence à `boss_engaged` (le boss apparaît). | Mourir avant qu'il apparaisse n'en est pas une. | comble un manque |
| D6.9-4, **D6.9-13** | Seuils de chargement (2 s) et de relance (3 s) mesurés en headless ; le soak garde 3 s pour les relances et seeds saisies. | Voir section 1. NON VÉRIFIÉ sur la machine de référence. | **s'en écarte** |
| D6.9-8 | Durée de run = temps de jeu compté en images (pause et écran de réveil exclus). | `duration_seconds` ne dépend plus de l'horloge murale. | comble un manque |
| D6.9-11 | Les 20 nuits mêlent quatre départs (lit, « Se rendormir », seed depuis la chambre, seed depuis l'écran de réveil) ; fins : 10 victoires, 4 morts en salle, 3 pendant l'annonce, 3 au combat ; Interro forcée une nuit de boss sur deux. | Couvrir tous les chemins de lancement. | comble un manque |
| D6.9-14 | Le contrôle de l'Interro dans le soak reste « au moins une » (21 pour 24 nuits forcées). | Une mort pendant l'annonce peut précéder le déclenchement ; le soak cherche des plantages. | comble un manque |

---

## 3. À survoler

**Boss (6.1)**
- Flux RNG dédié `boss` plutôt que `combat` (règle « un usage, un flux ») : D6.1-3. `Kind` d'attaque en champs plats dans une seule Resource : D6.1-7.
- `AttackRunner.tick(clock_step, pace)` à deux arguments (télégraphe à l'horloge seule, cadence à horloge × rythme de salle) : D6.1-8. Boss lié à la salle par `Room.spawn_enemy()` (`Boss.bind_room`), signes ajoutés comme enfants de la salle : D6.1-10.
- Test d'espacement relâché à ≤ diamètre + 0,25 : D6.1-12. `boss_health_changed(0, max)` émis en quittant l'arbre (cache la barre) : D6.1-13. Tirage du trou par `Boss.draw_unit()`, `ChalkPatterns.next_gap` reste pure : D6.1-14.
- Quatre portes gardées en revue : D6.1-15.

**Boss (6.2)**
- Validation : les genres `SPIRAL` (ignore `interval`) et `RULER` (ignore `bullet_speed`) n'exigent plus ces champs : D6.2-13.
- Écartés en revue (cas impossible hors debug, pas de garde sur le joueur) : D6.2-17.

**Interro (6.3)**
- Pas d'événement de télémétrie dédié (journal INFO seulement) : D6.3-5. Phase refusée par `BossPhase.validate()` : tous ses ensembles tournent à la fois, donnée fautive signalée une fois : D6.3-7.

**Victoire (6.4)**
- `Run.deepest_floor_index()` renvoie 0 au MVP ; un boss d'un étage moins profond ne finit pas la run : D6.4-2. Éclats du boss par `shards_collected` : D6.4-3. `run_end` reçoit `outcome` sans `reason` : D6.4-6.

**Chambre (6.5)**
- `Main.start_in_bedroom` statique : D6.5-6. Énum `Main.SeedOrigin { PAUSE, WAKE, BEDROOM }` : D6.5-11. Chambre construite à la main, hors générateur : D6.5-12.
- Tests : crochet `pre_run.gd` (`start_in_bedroom = false`) gardé comme filet, les trois tests existants posent aussi le drapeau : D6.5-10, D6.5-15. Écartés en revue (lit toujours `FLOOR`, intégration sous pause, Échap pendant la saisie, caméra, F5 depuis la chambre, « second » bouton) : D6.5-16.

**Heure du réveil (6.6)**
- Heure calculée par `Run` et publiée par `Events.wake_time_set` avant `run_ended` : D6.6-3. Heure gardée en mémoire par `Main`, persistée par 6.7 : D6.6-6.

**Profil (6.7)**
- `SaveService` créé en 6.7 (écriture atomique commune) : D6.7-1. `Settings` pas refactoré, deux écrivains atomiques : D6.7-2.
- `Achievements` gère statistiques et première victoire, une seule écriture à `run_ended` : D6.7-9. `last_read_status` (MISSING, UNREADABLE, CORRUPT, OK) : D6.7-12 (voir aussi D6.7-6). Tests isolés par `SaveDir` : D6.7-13.

**Sauvegarde (6.8)**
- Instantané pris en tête de `_enter_cell`, avant tout tirage : D6.8-2. États RNG et grands entiers en chaînes décimales : D6.8-7. Cellule `current` non validée : D6.8-10. Plan régénéré deux fois au lancement avec reprise : D6.8-11.
- Durée de la nuit = `play_seconds` : D6.8-13. Objets restaurés réémis sur `item_acquired` sans bannière : D6.8-14. Échec de `store_string` sans test : D6.8-15. Reproduction exacte vérifiée sur 3 seeds, 0 écart : D6.8-20.

**Soak (6.9)**
- Marge de fuite fixe : D6.9-5 (resserrée par la revue : D6.9-12). Soak hors suite GUT et hors `tools/run_tests.sh`, `tools/soak.sh` à part, `SOAK_RUNS` / `SOAK_MAX_SECONDS` : D6.9-6, D6.9-10. Signal `Events.floor_ready(startup_ms, load_ms)` écrit dans `run_start` et `runs_detail` : D6.9-9.

---

## 4. À juger en jouant

Tout ceci n'a été vérifié que par tests automatiques et par le soak ; aucun humain ne l'a vu ni tenu en main.

**Touches utiles**
- Chambre : `X` (ou bouton A / Croix) pour dormir au lit ou saisir une seed au bureau ; navigation à la manette entre « Se rendormir », « Nouvelle partie avec une seed » et « Retourner dans la chambre ».
- Panneau `F1` : `H` règle les PV du boss pour tester vite ; F1 permet aussi d'ouvrir la salle du boss seule (sans plan d'étage, heure 23:00).
- Menu pause : « Sauvegarder et quitter ». Relancer le jeu : l'invite de reprise s'ouvre sur la chambre gelée.

**Chambre (D6.5-1, D6.5-4, D6.5-9)**
- Ressenti du marcheur (même vitesse que le joueur, pas d'accélération), lisibilité du lit, du bureau et des invites « Dormir (X) » / « Saisir une seed (X) », bouton A réel à la manette. Limite connue : l'invite lit la première touche clavier, donc « Dormir (X) » s'affiche aussi à la manette.

**Professeur : Dictée (F1 `H` puis combat dans la salle du cauchemar ; D6.1-2, D6.1-5)**
- Atteindre la salle du cauchemar : lisibilité et difficulté de la Dictée (trou de 5 tuiles, 5 t/s, espacement 0,75, rangée toutes les 2 s, signe 0,5 s, annonce 1,5 s), barre de vie en bas, titre à la craie en haut (12 lettres/s). Sons provisoires réutilisés (Veilleuse et Berceuse).

**Professeur : Calcul mental et Examen final (D6.2-1, D6.2-3, D6.2-9)**
- Lisibilité de la spirale (4 bras, 60°/s, 5 t/s) et de l'éventail visé (6 t/s) ; enchaînement 8 s / 8 s ; signe de la règle (rectangle et 3 flèches, 0,8 s) ; première règle à 7 s.
- Parade de la règle après réglage : dash sur place = 5 ticks (0,08 s), dash vers la barre ≈ 19 ticks, fuite impossible. Si trop dur : 0,5 tuile à 10 t/s (6 ticks) ; si trop facile : revenir vers 1 tuile. Durée réelle du combat (théorie ≈ 73 s, cible 75 s).

**Interro surprise (jauge à 0 ; D6.3-4, D6.3-6, D6.3-8)**
- Cercle de 12 craies à 5 t/s × 1,1 toutes les 6 s superposé à l'Examen final, signe en anneau de 0,6 s (0,51 s en Abandon total), annonce qui remplace le titre de phase, anneau figé pendant une annonce de phase.

**Victoire (battre le Professeur ; D6.4-1)**
- Délai de 2 s : trop long ? La craie qui s'efface et les Éclats sont-ils lisibles ? Écran de réveil de victoire sans question.

**Heure du réveil (D6.6-1)**
- Ligne « Réveil : HH:MM » de l'écran de réveil et `Label` du réveil de la chambre (sprite d'horloge en epic 7) ; ressenti du plafond de la mort à 00:17.

**Sauvegarde et reprise (menu pause, puis relancer le jeu ; D6.8-3, D6.8-4, D6.8-16)**
- Texte et lisibilité de l'invite de reprise ; ressenti du retour au début de salle (progrès de la salle et états de pouvoir perdus).

---

## 5. Actions qui te reviennent

1. **Jalon A, prérequis toujours ouverts :** stories 1.7 (réassignation des touches, invites par périphérique) et 1.8 (export, latence, relance en moins de 3 s), reportées, à faire avant le playtest. La 1.7 compte davantage depuis que `interact` est sur X / A (D6.5-9) et que l'invite de la chambre lit la première touche clavier. 7.1 (cohérence des graphismes IA) aussi, avant que des amis jouent. La 1.8 devra exclure `debug/soak_runner.*` et `bullet_load_test.*` du preset de release et importer deux fois un dépôt neuf.
2. **Mesure de 10 minutes à 400 projectiles** (story 1.2) : toujours pas faite. `F5` lance le test de charge, `F3` affiche la perf ; cible 60 FPS soutenus, 1 % low d'au moins 55.
3. **Télémétrie chez tes amis : ni avertissement ni option pour la couper.** À prévoir pour le build du jalon A : une ligne dans le README livré et, si tu veux, un réglage de désactivation. Elle écrit maintenant aussi les tentatives contre le boss, les temps de chargement et les paliers de lucidité (D6.9-2, D6.9-3, D6.9-9).
4. **Epic 7 (art et audio) demande un travail humain ou d'IA** : les craies, le titre, la barre de vie, les sons du boss (provisoires, réutilisés), le sprite d'horloge, les décors de la chambre (D6.1-5, D6.5-13, D6.6-1) ne seront pas faits sans toi.
5. **Les 20 nuits jouées à la main sur la machine de référence (NON VÉRIFIÉ)** : aucun plantage, chargement d'étage < 2 s et relance < 3 s mesurés à la main, durée médiane 12 à 18 min, au moins 25 % de la run sous Lucide, Le Professeur battu 30 à 50 % du temps dès la 5e tentative (lire `runs_detail` et `boss_attempts` dans `telemetry/*.json`). Le soak (`tools/soak.sh`, une dizaine de secondes) prouve la stabilité, pas l'équilibre ni la lisibilité (D6.9-1, D6.9-4, D6.9-13).
6. **Quatre synthèses de décisions en attente de ta validation :** epics 3, 4, 5 et 6 (celle-ci). À trancher avec la rétro d'epic : la liste des écarts de la section 1, en particulier D6.6-1 (plafond 00:17), D6.2-1 (règle sans fuite possible) et D6.8-16 (progrès de la salle perdu). Durcissements de sauvegarde reportés (`run.json` modifié à la main, fichier verrouillé, `.bak`) et tests de reprise plus faibles que la spec : à décider avant ou après le jalon A.
