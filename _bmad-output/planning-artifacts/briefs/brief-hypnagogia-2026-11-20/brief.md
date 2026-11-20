---
title: 'Game Brief — Hypnagogia'
status: final
created: '2026-11-20'
updated: '2026-11-20'
sources:
  - '_bmad-output/planning-artifacts/hypnagogia-brainstorm.md'
  - '_bmad-output/planning-artifacts/brainstorm-stress-test.md'
---

# Game Brief : Hypnagogia

## Résumé

Hypnagogia est un roguelike twin-stick en 2D pour PC, développé seul sous Godot comme projet personnel. Un homme fait des rêves lucides sans savoir pourquoi. Chaque run est une nuit, chaque mort un réveil, et le réveil lui-même finit par se fissurer.

Le cœur du jeu est **la lucidité à deux pôles**. Le joueur dépense sa lucidité pour plier le rêve, ce qui le fait glisser vers l'abandon, où le danger et les récompenses augmentent. Il la regagne par le skill. Autour de ce système s'organisent :

- des objets tirés des rêves universels, qui ont chacun un coût et dont les synergies se devinent ;
- des pactes ;
- des cauchemars qui se débloquent l'un après l'autre ;
- un mystère qui se lit dans la chambre (le hub), une couche par victoire.

Le jeu vise les vétérans d'Isaac, à commencer par le développeur et ses amis. Premier objectif : une vraie run de 15 minutes, jouable dans deux mois.

## Vision

> **Lutter avec frénésie dans un rêve où la frontière avec la réalité devient si fine qu'on ne sait plus ce qui est vrai.**

**Ce que vit le joueur** :

- **L'adrénaline.** Il dépense sa lucidité pour plier le rêve, et chaque pouvoir le fait glisser vers l'abandon. Le jeu se déforme autour de lui, mais il continue à lutter, plus exposé mais mieux récompensé.
- **L'intrigue.** La chambre où il se réveille change, des détails clochent, et ce qu'il croyait réel se fissure. Il ne s'y attendait pas du tout.
- **La montée en puissance.** Il se sent plus fort au fil de la run, au prix de choix durs : sacrifier un objet pour un autre, plus puissant, accepter un pacte, dépenser sa lucidité.
- **La réaction visée.** Il pose la manette en se disant « c'est quoi ce truc de fou », puis il relance.

**Ce que « ne plus savoir ce qui est vrai » ne veut jamais dire** : le doute porte sur ce qui est réel et ce qui ne l'est pas, jamais sur le combat. Projectiles et hitbox restent toujours lisibles.

## Joueurs visés

**Public principal : les vétérans d'Isaac**, avec 300 à 500 heures de jeu et plus. Ils connaissent les codes du genre (item pools, synergies, pactes, déblocages), lisent les patterns et veulent que leur précision paie. Ils ont tout vu dans Isaac et cherchent un nouveau mystère à creuser, enfoui sous une vraie couche de skill.

**Premier cercle : le développeur et ses amis**, eux-mêmes vétérans d'Isaac. Le premier cercle *est* le public principal : le jeu n'a pas besoin d'être pensé pour des débutants.

**Sessions** : une run dure environ 15 minutes au début, et jusqu'à 45 minutes une fois les cauchemars les plus profonds débloqués.

## Fondamentaux

**Genre** : roguelike twin-stick en 2D, vu de dessus, avec des salles prédessinées assemblées aléatoirement. Méta-progression par le contenu uniquement.

### Boucle de jeu

Une run, c'est une nuit :

1. On s'endort depuis la chambre.
2. On descend étage par étage, en suivant les phases du sommeil.
3. Chaque étage se termine par un cauchemar à affronter.
4. Entre deux étages, on choisit un pacte.
5. La mort réveille le joueur : retour à la chambre avec de nouveaux déblocages, jamais plus de puissance.

En combat, on vise, on tire et on dash.

### Piliers

| Pilier | Ce qu'il exige | Ce qu'il interdit |
|---|---|---|
| **1. Action nerveuse, mort méritée** | Chaque attaque se lit : animation, télégraphe, origine visible. Parfois de justesse, mais toujours esquivable avec du skill et des réflexes. | Les attaques qu'on ne peut pas voir venir. Le hasard qui tue. |
| **2. Le thème explique les mécaniques** | Chaque mécanique a un sens onirique. Mourir, c'est se réveiller ; la profondeur, c'est la difficulté ; perdre sa lucidité, c'est perdre le contrôle de son rêve. Le rêve peut être abstrait et vaste, mais jamais arbitraire. | Les mécaniques sans justification dans le rêve (un « +10 % de dégâts » générique, par exemple). |
| **3. Des synergies qu'on devine** | On peut presque deviner ce que deux objets font ensemble. Les combinaisons peuvent surprendre, mais toujours dans le bon sens. | La mauvaise surprise cachée : regretter un objet parce qu'on ne pouvait pas imaginer son interaction. Regretter un coût connu et accepté reste permis : c'est même le sel du jeu. |
| **4. Un mystère dévoilé une couche à la fois** | Chaque victoire (un boss battu, un succès…) révèle **une seule** information ; une même run peut donc en révéler plusieurs. | Les révélations groupées, les pavés d'exposition. |

### Mécaniques principales

- **Contrôles twin-stick** : visée libre (stick ou souris), un dash avec une invulnérabilité courte, un bouton pour l'objet actif, un pour le consommable. Les tirs n'ont pas de gravité.
- **La lucidité à deux pôles** : c'est le différenciateur du jeu.
  - En haut, **lucide** : contrôle, précision, accès aux pouvoirs qui plient le rêve.
  - Chaque pouvoir **dépense** de la lucidité et fait glisser vers l'**abandon** : le rêve se déforme, le danger augmente, les récompenses aussi.
  - On **regagne** de la lucidité surtout par le skill (frôler un projectile, esquiver au dernier moment), un peu en vidant les salles, et rarement par des consommables.
  - Les coups reçus ne retirent que des cœurs : faire baisser la jauge est toujours un choix.
- **Objets** : chacun a un bonus et un coût, avec une description claire en jeu. Les synergies sont mécaniques et émergentes (piste : des tags thématiques comme chute, temps ou regard), et les runs « cassées » sont permises. Objets répartis en item pools.
- **Pactes** entre les étages : une malédiction contre un pouvoir, dans l'esprit des pactes diable et ange d'Isaac.
- **Consommables** : à double tranchant, inspirés des vraies techniques de rêve lucide.
- **Santé** : les mêmes types de cœurs qu'Isaac.
- **Cauchemars** (les boss) : en battre un débloque le suivant, plus profond, ce qui allonge la run.
- **Lisibilité** : même dans une run cassée, les projectiles ennemis passent toujours au premier plan, quelle que soit la phase ou la lucidité (règle détaillée dans `addendum.md`).

## Références et différenciation

| Référence | On prend | On laisse |
|---|---|---|
| **The Binding of Isaac** | Structure en étages et salles, item pools, pactes, types de cœurs, déblocages de contenu, boss qui débloquent le suivant, choix de porte | Tir sur 4 directions, tirs avec gravité, objets sans description, humour scatologique, thèmes religieux, difficulté opaque |
| **Enter the Gungeon** | Esquive avec invulnérabilité, au cœur du skill ; effaceur de projectiles, synergies signalées en jeu, patterns lisibles, interaction avec la salle | Lore enfoui que seule la communauté découvre |
| **Neon Abyss** | Cumul d'objets sans limite (runs cassées), règles qui modifient le donjon, ton néon pour la phase REM | Vue de côté, familiers évolutifs |
| **Slay the Spire** | Information totalement lisible, intentions ennemies annoncées (ici par l'animation, comme dans Cuphead), reliques aux interactions prévisibles, niveaux d'Ascension | Deckbuilding, carte de route |

Les matrices complètes et les références secondaires (Hellblade, Yume Nikki, Omori, Little Nightmares) sont dans `addendum.md`.

### Ce qui différencie Hypnagogia

1. **La lucidité à deux pôles**, absente de toutes ces références.
2. **Un mystère qui se lit dans la chambre**, plus explicite que dans Isaac ou Gungeon, sans jamais trancher entre rêve et réalité.
3. **Des objets qui ont du sens** : tirés des rêves universels, avec un coût et des synergies qui se devinent.
4. **Une bande-son signée**, composée par le développeur.

**L'avantage est l'identité et les sensations, pas le volume.** Hypnagogia ne rivalisera pas avec les 700 objets d'Isaac.

## Périmètre et MVP

**Cadre** : projet personnel, sans sortie publique prévue pour l'instant. Le critère de réussite, c'est que le développeur et ses amis prennent plaisir à y jouer.

- **Équipe** : un développeur seul et expérimenté, qui compose aussi la musique. Les graphismes sont générés par IA.
- **Moteur et plateforme** : Godot, sur PC uniquement. C'est le premier projet du développeur avec Godot.
- **Rythme** : plusieurs dizaines d'heures par semaine.

### Jalons

| Jalon | Contenu | Ce qu'il valide | Horizon |
|---|---|---|---|
| **A. Le combat** | Une arène, les contrôles, 3 ou 4 ennemis, la lucidité à deux pôles, mort et relance instantanée | Le combat est nerveux et la lucidité donne envie de jouer avec | Environ 3 à 4 semaines |
| **B. MVP : une vraie run** | La lucidité complète, 1 étage Endormissement, 3 ou 4 ennemis, 1 cauchemar (Le Professeur), environ 8 objets et 2 consommables, une chambre minimale. Sans pactes, sans chambre qui change, sans histoire. | Une run de 15 minutes donne envie de relancer | 2 mois |
| **C. L'acte 1** | Les 4 phases et l'étage secret, les 5 cauchemars, les pactes, la chambre qui change, le premier mystère avec sa propre fin | Le jeu tient seul | Non fixé |
| **D. Les actes 2 et 3** | Le réveil, puis l'asile | L'histoire complète | Plus tard |

Le contenu détaillé du MVP (dedans et dehors) est dans `addendum.md`.

## Contenu et direction

- **Monde** :
  - **Acte 1** : les phases réelles du sommeil, de l'Endormissement au sommeil paradoxal (REM), puis un étage secret (le rêve dans le rêve).
  - **Acte 2** : les mêmes phases, envahies par le réel de l'hôpital.
  - **Acte 3** : l'asile devient jouable.
- **Récit** : chaque réveil se révèle être une couche de rêve de plus. Le jeu ne tranche jamais trop vite : le personnage est-il malade, ou lui ment-on ? L'histoire se lit dans la chambre, le journal de rêves et les dossiers. L'heure 4:12 sert de motif récurrent. Quatre fins au départ, d'autres ensuite.
- **Volume de l'acte 1, en ordre de grandeur** : 5 étages (4 phases et le secret), 5 cauchemars, quelques dizaines d'objets plutôt que des centaines. La rejouabilité vient des synergies, des pactes et de l'Ascension.
- **Direction artistique** : pixel art avec une palette par phase. L'abandon déforme le décor, jamais les projectiles. La résolution et la taille des sprites restent à définir.
- **Audio** : une musique composée par le développeur, qui se densifie avec la profondeur du sommeil.
- **Accessibilité** : des options pour réduire les distorsions et les tremblements d'écran, et un mode photosensibilité pour les néons de la phase REM.

Le détail des palettes et de la musique par phase est dans `addendum.md`.

## Risques et questions ouvertes

### Risques

| Risque | Parade |
|---|---|
| **La lucidité à deux pôles est un système non éprouvé** | Le jalon A la teste avant d'investir dans le contenu |
| **Cumul sans limite et équilibrage des synergies** | Peu d'objets au départ, règle de lisibilité des projectiles, synergies par tags plutôt que par paires |
| **Graphismes générés : cohérence des animations et lisibilité** | Les tester dès le jalon A, avec des contraintes de style strictes |
| **Thème psychiatrique : trouver des pouvoirs dans l'abandon et dans l'arrêt du traitement peut se lire comme un message contre les médicaments** | Donner un coût clair à la lucidité de l'acte 3, et faire relire par des personnes concernées le moment venu (comme pour Hellblade) |
| **L'acte 1 finit sur un cliffhanger** | Lui écrire une vraie fin (la révélation du faux réveil) avant d'aborder l'acte 2 |

### Questions ouvertes pour le GDD

- **Structure d'une run** : nombre d'étages, condition de victoire, lien entre étages et cauchemars, place du choix de porte.
- **Économie et salles** : monnaie, clés, boutiques, types de salles spéciales, contenu des item pools.
- **Lucidité** : les pouvoirs concrets, les chiffres de la jauge, la récompense exacte en abandon.
- **Objets** : charges de l'objet actif, mécanisme de sacrifice ou d'échange d'objets, tags de synergie.
- **Récit** : le passé du personnage et le sens de 4:12, les déclencheurs des actes et des fins, la priorité entre les fins.
- **Technique et confort** : sauvegarde quand on quitte en pleine run, résolution du pixel art.
- **Les constats encore ouverts** du stress test (`_bmad-output/planning-artifacts/brainstorm-stress-test.md`).
