## Deferred from: code review of story 1-1 (2026-11-20)

- `GameClock.paused` est indépendant de `SceneTree.paused` : deux sources de vérité possibles, à trancher à la story 1.6 (pause).
- CA 9 et CA 11 : plein écran à ×2/×3/×4, HiDPI et build release non couverts par les mesures, à traiter à la story 1.8 (export et mesures).
- `GameClock` n'expose aucune API pour modifier les échelles (hitstop, ralenti) : à créer quand une story en aura besoin.

## Deferred from: story 1-2 (2026-11-20)

- **Mesure de 10 minutes à 400 projectiles sur la machine de référence (CA 7 et 8, NFR1, AR31 point 1) : NON FAITE.** Protocole dans la story 1.2 (« Mesure sur la machine de référence ») : F5, F3 visible, 10 minutes, FPS ≥ 60 et 1 % low ≥ 55, `refused` à 0. À faire avant de bâtir le combat ennemi (epic 2) et au plus tard avec l'export de la story 1.8. En cas d'échec : repli GDExtension ou Forward+, à décider et consigner dans la story et dans `game-architecture.md`. Décision de Kroustille du 2026-11-20 : « plus tard ».
- **Fluidité à 144 Hz (CA 9, AR31 point 3) : NON VÉRIFIÉE.** Aucune interpolation des positions de rendu n'est codée ; à ajouter dans `BulletManager` seulement si les projectiles saccadent sur un écran 144 Hz.
