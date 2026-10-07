# Game hooks

The game calls your mod at these moments. Subscribe: `hook("name", func(d): …)` in your mod code (or `Pax.hook`). The handler gets a Dictionary `d` and may change it in place; for hooks marked **[cancel]** `d.cancel = true` stops the action. Game records inside (law, faction, research) use Russian keys, the same as in `data/*.json`.

_Generated from `Pax.HOOKS` by `tools/modding/страж.py` — do not edit by hand._

| Hook | When and what is in `d` | Called from |
|---|---|---|
| `order_parsed` | **[cancel]** The AI understood a player's order; the game has not carried it out yet. order: String — the player's words; request: Dictionary — the parsed request (edit it: stages, days, needs, building, army…). | ai/OrderEvaluation.gd |
| `report_ready` | The AI wrote the report for a stretch of time (reactions, events, newspaper). report: Dictionary — edit or add to it before the player sees it. | sim/RewindSystem.gd |
| `event_card` | An event card is about to be shown. card: Dictionary (заголовок, текст, варианты…); body: String — where. | ui/Cards.gd |
| `war_declared` | **[cancel]** The player declares war. target: String — country name; faction: Dictionary — its record. | ui/DiplomacyPanel.gd |
| `peace_made` | A war ended in peace. faction: Dictionary — the other side (its terms are already set). | sim/factions/FactionPeace.gd |
| `province_captured` | The player's side took a province. province: int — id; from: String — former owner; name: String. | core/GameRoot.gd |
| `law_parsed` | The AI read a new law: who backs it, how the chamber votes. law: Dictionary; answer: Dictionary — the AI's reply (edit it). | politics/LawMaking.gd |
| `law_passed` | A law came into force. law: Dictionary. | politics/LawMaking.gd |
| `law_removed` | A law left force. law: Dictionary; how: String — отменён, переписан, отозван… | politics/LawMaking.gd |
| `research_priced` | The AI classified and priced a research project. research: Dictionary; answer: Dictionary (edit cost, years, chance). | science/Research.gd |
| `research_done` | A research project was completed and applied. research: Dictionary; body: String. | science/ScienceStep.gd |
| `leader_died` | The player's head of state died. leader: Dictionary. | politics/Leadership.gd |
| `election_held` | An election was counted. record: Dictionary — results by province and totals; state: Dictionary — the country's government. | politics/Elections.gd |
| `system_generated` | A star's system is about to be built (first entry from the galaxy). star: Dictionary — galaxy star; system: Dictionary — bodies.json «системы» record; bodies: Array — bodies.json «тела» records (edit, add or remove before they are created). | ui/GalaxyView.gd |
| `secret_reveal` | **[cancel]** A galaxy secret is about to open: something of ours (ship, satellite, station, colony) reached its star. secret: Dictionary; star: Dictionary — galaxy star. Cancel to hold it back (your own timeline); it is tried again later. | ui/GalaxyView.gd |
| `secret_found` | A galaxy secret was found. secret: Dictionary — its record from data/galaxy_secrets.json; body: String — where its guests appeared. | ui/GalaxyView.gd |
| `ai_request` | **[cancel]** Any request is about to go to the AI. channel: String (interpreter, report, faction, talk…); system: String; user: String — edit them to add rules or context. | ai/provider/RequestBuilder.gd |
