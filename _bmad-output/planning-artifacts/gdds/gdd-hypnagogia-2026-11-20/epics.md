---
title: 'Epics — Hypnagogia'
status: final
created: '2026-11-20'
updated: '2026-11-20'
gdd: 'gdd.md'
---

# Hypnagogia : epics de développement

Chaque epic se termine sur quelque chose de jouable. Les stories ci-dessous restent de haut niveau ; leur découpage détaillé revient à `gds-create-epics-and-stories`, après l'architecture.

## Jalon A : le combat (≈ 3 à 4 semaines)

Le jalon A se joue dans une seule arène, avec relance instantanée. Le jalon B ne démarre qu'une fois le jalon A validé.

### E1. Contrôles et sensations

**Livre** : un personnage qui se déplace, dashe et tire dans une arène vide, avec des sensations de jeu nerveuses.

- Déplacement à 6 tuiles/s, avec accélération et décélération (GDD : Déplacement et dash).
- Dash : 3 tuiles, 0,18 s, invulnérabilité de 0,15 s, recharge de 0,6 s, tampon de 0,1 s.
- Tir libre à la souris et au stick, cadence de 4 tirs/s, projectiles sans gravité ni portée limitée, sans dispersion.
- Caméra fixe pour une salle d'un écran ; rendu en 640×360 mis à l'échelle par un facteur entier.
- Bascule automatique entre clavier-souris et manette ; touches réassignables.
- Retours de tir et d'impact (recul visuel, flash, son placeholder).

### E2. Lucidité à deux pôles

**Livre** : la jauge, ses paliers et les deux pouvoirs, jouables dans l'arène.

- Jauge de 100 points, jamais sous 0 ; 5 paliers, dont le danger est figé à l'entrée de la salle (en arène : à chaque vague). Le danger suit la descente (palier le plus bas atteint dans la salle) ; renfort en pleine salle annoncé 0,6 s avant.
- Détection du graze (+2, une seule fois par projectile, plafond de +20 par salle, pas pendant l'invulnérabilité), du dash parfait (+5) et de la salle vidée (+5).
- Éveil (coût 30) et Glissement (coût 20), avec 1 s de recharge ; une dépense que la jauge ne couvre pas est refusée.
- Règles de destination de Glissement (murs, obstacles hauts, ennemis, trous ; distance au stick).
- Précision au palier Lucide (tirs 30 % plus rapides, hitbox de 4×4 px) ; bonus de dégâts (cumul additif) et de loot sous Lucide ; danger par palier (vitesse des projectiles, renfort, télégraphes, pattern supplémentaire).
- Signes à l'écran : HUD de la jauge, aberration chromatique, ondulation, filtre passe-bas, son de changement de palier.
- Réglages d'accessibilité qui réduisent les effets visuels.

### E3. Combat et ennemis

**Livre** : les 4 ennemis de l'Endormissement, la santé, le HUD, la mort et la relance.

- Le Somnambule, La Veilleuse, Le Mouton et La Berceuse, avec leurs télégraphes d'au moins 0,4 s et les vitesses de projectiles du GDD.
- Projectiles ennemis avec une couleur et un contour exclusifs.
- Santé : 3 cœurs, coups à ½ cœur, 1 s d'invulnérabilité après un coup, armure.
- Dégâts au contact.
- HUD : cœurs, armure, jauge de lucidité, Éclats, objet actif, consommable.
- Mort, puis nouvelle partie en moins de 3 s.
- Vagues d'ennemis dans l'arène pour tester les paliers.
- Question « cette mort était-elle juste ? » après chaque mort (outil de playtest).

## Jalon B : le MVP, une vraie run (2 mois)

### E4. Étage et génération

**Livre** : un étage Endormissement de 16 salles, généré à partir d'une seed.

- Format des salles prédessinées (36×19 tuiles jouables, grandes salles de deux écrans) : obstacles bas et hauts, emplacements d'ennemis et de renfort, trous.
- Assemblage de l'étage sur une grille : départ, 12 salles de combat, trésor, boutique, cauchemar ; chemin principal garanti, cauchemar à au moins 4 salles du départ.
- Toute la génération découle de la seed. La disposition ne dépend pas des choix du joueur, et les tirages d'objets, de drops et de combat sont indépendants.
- Portes qui se ferment tant que la salle n'est pas vidée ; carte de l'étage révélée au fil de l'exploration.
- Trous : une chute compte comme un coup, puis retour au dernier bord sûr.
- Meubles du rêve destructibles et éléments déclenchables d'un tir (jouer avec la salle).
- Pool d'au moins 30 salles de combat pour l'Endormissement.

### E5. Objets et économie

**Livre** : les 8 objets du MVP, la synergie Chute, les 2 consommables et l'économie en Éclats.

- Modèle d'objet : bonus, coût, tags, description en jeu ; pas de doublon dans une run, sauf la Dent qui tombe ; cumul additif des bonus de dégâts.
- Les 8 objets du GDD avec leurs précisions, dont Réveil cassé comme objet actif (recharge en 3 salles vidées, charge conservée au sol).
- Seuils de tag (objets distincts) et annonce des synergies ; famille Chute à 2 et 3 objets.
- Se pincer et Café ; un seul consommable porté.
- Éclats (1 à 3 par salle de combat) et drops (30 % par salle de combat), multipliés par le loot du palier.
- Boutique (2 objets à 15, consommable 5, cœur 4, armure 5) et salle trésor gratuite.

### E6. Le Professeur et la boucle de run

**Livre** : une nuit complète, de la chambre au réveil.

- Le Professeur : 2 500 PV, 3 épreuves (Dictée, Calcul mental, Examen final) et Interro surprise en Abandon total, annonce à la craie.
- Victoire : battre le cauchemar le plus profond débloqué ; au MVP, la run se termine toujours après Le Professeur.
- Chambre minimale : le lit pour lancer une run, le réveil qui affiche l'heure (de 23:00 à 00:18 au MVP, au prorata des salles de combat vidées).
- Seed affichée à la mort et dans le menu pause, et saisissable ; une run avec seed saisie ne débloque rien.
- Sauvegarder et quitter : reprise au début de la salle, sauvegarde effacée à la reprise ; reprise après un crash.
- Enregistrement des victoires et des succès, pour que les déblocages de l'acte 1 puissent s'y brancher (au MVP, rien n'est débloqué).

### E7. Direction artistique et audio du MVP *(transversal, jalons A et B)*

**Livre** : un MVP cohérent visuellement et une piste de musique.

- Pipeline de graphismes IA sous contraintes de style ; test de cohérence des animations dès le jalon A.
- Palette Endormissement (au plus 32 couleurs) et couleurs réservées aux projectiles.
- Sprites : joueur, 4 ennemis, Le Professeur, tuiles, meubles du rêve, objets. Ceux du jalon B ne sont produits qu'une fois le jalon A validé.
- Une piste de musique Endormissement ; ≈ 40 effets sonores (tir, impact, télégraphes, graze, dash parfait, paliers).
- Mode photosensibilité ; réduction des distorsions et des tremblements d'écran.

## Jalon C : l'acte 1 (esquisse)

| Epic | Contenu |
|---|---|
| E8. Pactes | Salle de pacte entre les étages ; les 4 pactes (Sans voix, On te regarde, Visage oublié, Portes mouvantes), une fois corrigés |
| E9. Phases 2 à 4 | Sommeil léger (duplication), Sommeil profond (salles sombres, coups à 1 cœur), REM (bullet-hell) : ennemis, salles, palettes, musiques |
| E10. Cauchemars de l'acte 1 | La Poursuite, La Vague, La Silhouette au pied du lit, Toi (le double qui utilise le build du joueur) |
| E11. Choix de porte et étage secret | Porte de l'étage 3, salles spéciales, étage secret optionnel (« le rêve dans le rêve ») et sa porte après La Silhouette |
| E12. Contenu de run | Objets jusqu'à 4 par tag avec leurs synergies, pool cauchemar, consommables restants du brainstorm, cœurs variés, salle d'oubli (sacrifice d'un objet contre un choix entre 2) |
| E13. Chambre et mystère | Chambre qui change, journal de rêves, une couche par première victoire, la fin de l'acte 1 (le faux réveil). Dépend de `gds-create-narrative`. |
| E14. Méta-progression | Déblocages par succès, Ascension |
