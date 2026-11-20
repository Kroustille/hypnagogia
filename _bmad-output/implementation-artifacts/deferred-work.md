## Deferred from: code review of story 1-1 (2026-11-20)

- `GameClock.paused` est indépendant de `SceneTree.paused` : deux sources de vérité possibles, à trancher à la story 1.6 (pause).
- CA 9 et CA 11 : plein écran à ×2/×3/×4, HiDPI et build release non couverts par les mesures, à traiter à la story 1.8 (export et mesures).
- `GameClock` n'expose aucune API pour modifier les échelles (hitstop, ralenti) : à créer quand une story en aura besoin.

## Deferred from: story 1-2 (2026-11-20)

- **Mesure de 10 minutes à 400 projectiles sur la machine de référence (CA 7 et 8, NFR1, AR31 point 1) : NON FAITE.** Protocole dans la story 1.2 (« Mesure sur la machine de référence ») : F5, F3 visible, 10 minutes, FPS ≥ 60 et 1 % low ≥ 55, `refused` à 0. À faire avant de bâtir le combat ennemi (epic 2) et au plus tard avec l'export de la story 1.8. En cas d'échec : repli GDExtension ou Forward+, à décider et consigner dans la story et dans `game-architecture.md`. Décision de Kroustille du 2026-11-20 : « plus tard ».
- **Fluidité à 144 Hz (CA 9, AR31 point 3) : NON VÉRIFIÉE.** Aucune interpolation des positions de rendu n'est codée ; à ajouter dans `BulletManager` seulement si les projectiles saccadent sur un écran 144 Hz.

## Deferred from: code review of story 1-2 (2026-11-20)

- Traversée de mur si l'échelle de temps d'un groupe dépasse 1 : un seul échantillon de cellule par tick. À traiter (sous-pas ou plafond de pas) à la story 1.4, quand `GameClock` aura une API d'écriture.
- Projectile qui sort de la zone tuilée (ouverture dans `Walls`) ou qui apparaît dans une cellule solide : il vit jusqu'à la fin de sa durée de vie. Dépend de l'arène réelle (story 1.3) et des motifs ennemis (epic 2).
- Couches solides libérées ou remplacées pendant la vie du manager (changement de salle), et F5 qui vide tous les enfants d'`ActiveScene` : à reprendre quand l'arène existe (story 1.3).

## Deferred from: story 1-3 (2026-11-20)

- **Stick de manette réel : NON VÉRIFIÉ.** Pas de manette sous WSL. Vérifié seulement par `InputEventJoypadMotion` simulés (zone morte à 0,1, déplacement à 1,0, stick incliné de 10° contre les quatre murs sans accrochage). À valider sous Windows avec une vraie manette, au plus tard avec la story 1.7.
- **Ressenti du déplacement et latence : NON ÉVALUÉS** (étapes humaines). Valeurs de départ à juger au jeu : demi-tour = 2× le temps d'accélération (il passe par `accel_px`), `wall_min_slide_angle` laissé au défaut de 15° (aucun accrochage mesuré, voir story 1.3). Latence mesurée : story 1.8.
- **F2 : le contour suit la position physique, pas la position interpolée.** `get_global_transform_interpolated()` n'existe pas en Godot 4.7.2. Le cadre peut devancer le sprite de moins d'un tick (≈1,6 px à pleine vitesse). Acceptable pour du debug ; à reprendre seulement si cela gêne le réglage des hitbox.
- **Mire de netteté (`scale_test_pattern`) conservée mais plus instanciée** : à supprimer ou à rebrancher (touche de debug) selon le besoin de la story 1.8.
