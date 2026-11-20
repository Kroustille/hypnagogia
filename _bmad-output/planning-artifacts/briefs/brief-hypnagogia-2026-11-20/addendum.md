---
title: 'Addendum — Game Brief Hypnagogia'
created: '2026-11-20'
updated: '2026-11-20'
---

# Addendum : Game Brief Hypnagogia

Ce document garde le détail utile au GDD qui alourdirait le brief : les matrices de références, le contenu détaillé du MVP, la règle de lisibilité des projectiles et le détail de la direction artistique et sonore.

## Matrice Isaac : ce qu'on prend, ce qu'on laisse

| # | Élément d'Isaac | Décision | Note |
|---|---|---|---|
| 1 | Tir sur 4 directions | Refusé | Visée libre twin-stick (souris ou stick) |
| 2 | Pas de dash | Refusé | Dash avec invulnérabilité courte |
| 3 | Tirs avec gravité et portée | Refusé | Pas de gravité des tirs |
| 4 | Les objets modifient l'apparence des tirs | Repris | |
| 5 | Dégâts au contact | Repris | |
| 6 | Objets sans description | Refusé | Description claire en jeu |
| 7 | Synergies mécaniques émergentes | Repris | Remplace les paires écrites à la main ; piste des tags thématiques (stress test, constat 11) |
| 8 | Objets presque tous positifs | Refusé | Chaque objet a un bonus et un coût |
| 9 | Objets actifs à charges | Reporté | Le bouton d'objet actif existe, la règle de charge reste à définir |
| 10 | Pilules et cartes à effet inconnu | Reporté | Pilule mystère écartée pour l'instant |
| 11 | Item pools par type de salle | Repris | |
| 12 | Gros volume d'objets, runs cassées | Pris autrement | Peu d'objets, mais des runs cassées autorisées |
| 13 | Étages faits de salles prédessinées | Repris | |
| 14 | Économie pièces / bombes / clés | Non tranché | Pas encore étudié |
| 15 | Salles spéciales variées | Repris | Types à définir dans le GDD |
| 16 | Pactes façon diable / ange | Repris | Ce sont les pactes |
| 17 | Choix de route | Pris autrement | Descente linéaire, puis choix de porte dans les derniers étages (voir S3) |
| 18 | Cœurs de plusieurs types | Repris | Mêmes types de cœurs qu'Isaac |
| 19 | Déblocages par succès, pas de stats | Repris | |
| 20 | Battre un boss débloque le suivant | Repris | |
| 21 | Plusieurs personnages jouables | Pris autrement | Un seul au départ ; d'autres possibles, avec la même histoire |
| 22 | Mode « tainted » et défis | Reporté | Pas dans un premier temps, mais un jour |
| 23 | Récit quasi muet | Refusé | Mieux raconté : chambre, journal, dossiers |
| 24 | Plus de 20 fins | Pris autrement | 4 fins au départ, d'autres ajoutées ensuite |
| 25 | Secrets découverts par la communauté | Reporté | |
| 26 | Humour scatologique | Refusé | |
| 27 | Thèmes religieux | Refusé | Remplacés par le rêve et la psychiatrie |
| 28 | Difficulté opaque, RNG injouable | Refusé | Pilier : une mort toujours méritée |

## Autres références : ce qu'on prend, ce qu'on laisse

### Enter the Gungeon

Ce que le développeur aimait : le côté très nerveux.

| # | Élément | Décision | Note |
|---|---|---|---|
| G1 | Roulade d'esquive avec invulnérabilité, cœur du skill | Repris | Le dash |
| G2 | Blanks (effacent les projectiles à l'écran) | Repris | Piste : un pouvoir de lucidité |
| G3 | Synergies signalées en jeu | Repris | Sert le pilier 3 |
| G4 | Patterns lisibles, ennemis avec une personnalité | Repris | Sert le pilier 1 |
| G5 | Lore très enfoui, découvert par la communauté | Refusé | Mystère raconté explicitement, une couche à la fois |
| G6 | Tables à renverser | Pris autrement | Jouer avec la salle, pas forcément avec des tables |

### Neon Abyss

| # | Élément | Décision | Note |
|---|---|---|---|
| N1 | Objets cumulables sans limite | Repris | Runs cassées sans plafond (attention à la lisibilité, pilier 1) |
| N2 | Œufs et familiers évolutifs | Refusé | |
| N3 | Faiths qui modifient le donjon | Repris | Proche des pactes |
| N4 | Vue de côté avec plateformes | Refusé | Vue de dessus |
| N5 | Ton néon, saturé, rapide | Repris | Pour la phase REM |

### Slay the Spire

Ce que le développeur aimait : la progression, se sentir de plus en plus fort, parfois en sacrifiant des objets pour en obtenir de plus puissants. Des choix durs.

| # | Élément | Décision | Note |
|---|---|---|---|
| S1 | Intentions ennemies annoncées | Pris autrement | Traduit par les animations des ennemis (référence citée : Cuphead) |
| S2 | Tout est lisible, aucune information cachée | Repris | |
| S3 | Carte avec choix de route | Pris autrement | Dans les derniers étages seulement, sans carte : choix de porte comme dans Isaac |
| S4 | Reliques aux interactions prévisibles | Repris | |
| S5 | Niveaux d'Ascension | Repris | Rejouabilité après la fin |
| S6 | Deckbuilding | Refusé | |

Piste pour le GDD : un mécanisme de **sacrifice ou d'échange d'objet** (perdre un objet contre un autre, plus puissant), qui n'existe pas dans le brainstorm. Il pourrait passer par les pactes ou par un type de salle dédié.

### Références secondaires

- **Cuphead** : des boss dont les attaques se lisent dans l'animation (anticipation, télégraphe).
- **Hellblade** : traiter la santé mentale sans cliché ni jugement. Modèle pour la relecture par des personnes concernées.
- **Yume Nikki, Omori, Little Nightmares** : la preuve que le thème du rêve a déjà été exploré. Ce sont des repères à éviter plutôt que des modèles : la différence se fera sur l'histoire et la direction artistique.

## MVP détaillé (jalon B)

**Dedans** :

- **Contrôles** : déplacement, visée libre, tir, dash avec invulnérabilité.
- **Lucidité complète** : la jauge, 2 pouvoirs pour plier le rêve, l'état d'abandon (déformation, danger et loot accrus), la remontée par le frôlement de projectiles et les salles vidées.
- **1 étage** de la phase Endormissement, généré à partir d'une dizaine de salles prédessinées.
- **3 ou 4 types d'ennemis** télégraphiés par l'animation.
- **1 cauchemar** à patterns : Le Professeur. Le stress test déconseille La Silhouette pour ce jalon, car son immobilisation au début du combat est trop particulière pour juger les sensations.
- **Environ 8 objets** avec un coût et une description, et une famille de synergies.
- **2 consommables.**
- **Boucle** : mort, chambre minimale, relance.
- **Placeholders** : graphismes générés et une piste de musique.

**Dehors** : les pactes, les autres phases et les autres cauchemars, le choix de porte, la chambre qui change, l'histoire et le journal, l'Ascension, les cœurs variés.

## Lisibilité des projectiles

- Les tirs du joueur restent discrets : plus transparents, plus petits, d'une couleur réservée.
- Les projectiles ennemis passent toujours au premier plan, avec une couleur et un contour que rien d'autre n'utilise.
- Cette palette reste identique dans toutes les phases et à tous les niveaux de lucidité. Les distorsions de l'abandon ne touchent jamais les projectiles.

## Direction artistique et audio (détail)

| Phase | Palette | Musique |
|---|---|---|
| Endormissement | Pastels délavés | Ambient, tempo lent |
| Sommeil léger | Tons neutres, répétitifs | Downtempo, boucles hypnotiques |
| Sommeil profond | Gris bleuté à noir profond | Drones lourds, basses |
| Paradoxal (REM) | Néons saturés | Psytech / psytrance, tempo rapide |
| Asile (actes 2 et 3) | Blanc clinique, néons froids | Sons concrets mêlés à la musique : bips, pas, portes |

- **Abandon à l'image** : aberration chromatique, décors qui ondulent.
- **Abandon au son** : un filtre passe-bas étouffe la musique.
