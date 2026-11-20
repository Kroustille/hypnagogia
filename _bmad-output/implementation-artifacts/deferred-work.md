## Deferred from: code review of story 1-1 (2026-11-20)

- `GameClock.paused` est indépendant de `SceneTree.paused` : deux sources de vérité possibles, à trancher à la story 1.6 (pause).
- CA 9 et CA 11 : plein écran à ×2/×3/×4, HiDPI et build release non couverts par les mesures, à traiter à la story 1.8 (export et mesures).
- `GameClock` n'expose aucune API pour modifier les échelles (hitstop, ralenti) : à créer quand une story en aura besoin.
