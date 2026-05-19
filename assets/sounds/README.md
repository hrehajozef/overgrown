# Sound assets

Drop `.mp3` files here with **exactly** these names — the game's
`AudioManager` autoload picks them up automatically at startup. Missing
files are silently skipped, so the game runs fine even if some sounds
aren't recorded yet.

### Core events

| File                          | Plays when …                                              |
| ----------------------------- | --------------------------------------------------------- |
| `bg_music.mp3`                | background music loop (volume = 20%)                      |
| `seed_pick.mp3`               | player picks up a seed at a seed box                      |
| `seed_place.mp3`              | player plants a seed in a pot                             |
| `flower_ready.mp3`            | a growing flower finishes blooming (state → BLOOMED)      |
| `flower_dead.mp3`             | a flower dies (dry-out or wilt after bloom)               |
| `pot_clean.mp3`               | player cleans a dead pot                                  |
| `flower_harvest.mp3`          | player cuts a bloomed flower from a pot                   |
| `flower_workbench_place.mp3`  | player drops cut flowers onto the workbench               |
| `workbench_modal_pop.mp3`     | bouquet modal opens / closes (incl. Esc)                  |
| `workbench_flower.mp3`        | any flower button or 1 / 2 / 3 key in the bouquet modal   |
| `workbench_remove.mp3`        | player removes the last flower from the bouquet           |
| `bouquet_sold.mp3`            | a bouquet on the counter is taken by a matching customer  |
| `customer_arrive.mp3`         | a customer reaches their queue spot                       |
| `customer_leave.mp3`          | a **served** customer walks away (happy)                  |
| `water.mp3`                   | held continuously while refilling can / watering a pot    |
| `day_complete.mp3`            | day ends successfully and rent gets paid                     |
| `game_over.mp3`               | day ends without enough money for rent                       |
| `customer_angry.mp3`          | a customer leaves because patience ran out (replaces `customer_leave` for angry departures) |
| `can_empty.mp3`               | player presses F over a growing pot with an empty can        |
| `pouch_full.mp3`              | player tries to pick a seed while the pouch already holds 10 |
| `time_warning.mp3`            | once per day when time_left drops below 30 s                 |

`water.mp3` is treated as a loop: the AudioManager replays it back-to-back
as long as the player keeps holding F at a tap or a growing pot, and
stops it ~150 ms after the last frame the action was active.
