# The Mercy Left Behind — رحمتی که جا ماند

A noir interrogation mystery, rebuilt in Godot 4.7 from *The Murder of the Great Beggar* (v0.5.1).
Medjugorje, 1189 — a beloved beggar is found on the chapel steps with a dagger in his heart.
Washington, D.C., today — six medieval suspects wake in Room B, and Detective Richard Hale has five nights.

## Play

- Double-click **`Play The Mercy Left Behind.bat`** (one folder up), or open the project in Godot and press F5.
- First launch asks for the language (فارسی / English). Everything — UI, story, AI answers — follows it.

### Two ways to interrogate

| Mode | How it works | Needs |
|---|---|---|
| **AI** (default) | Type any question; each suspect answers in character, streamed live. | A local [Ollama](https://ollama.com) (`gemma3n:latest` by default) or any OpenAI-compatible API (URL + key + model in Settings → AI). |
| **Classic** | Click topics and show evidence; every answer is hand-written. | Nothing — fully offline. |

If the AI server does not answer, the game silently falls back to the written answer for that question, so a case can never get stuck.

## What changed from 0.5.1

- **One coherent truth.** The lore was rewritten so every clue, lie and red herring fits a single hidden story (the Offering of 1176, the swapped infant, the counterfeit blade). See `data/story.json` and `data/suspects.json`.
- **Real detective work instead of a 1-in-6 guess.** 11 pieces of evidence, 21 unlockable testimonies, and a final accusation of *who*, *how* and *why*. Seven endings (true, half-truth, five wrong ones).
- **Tone, trust and composure.** Gentle questioning builds trust, pressing breaks composure; some secrets need one, some the other. Press the boy too hard and he will "confess" — falsely.
- **AI that can't spoil the case.** Each suspect only knows their own life. Secrets are released by the game's clue engine (evidence + trust/composure), which tells the model *what* to reveal and *when*; testimony is then written to the case file automatically.
- **User-friendly.** Topic buttons, an Instinct hint button, auto-recorded case file, autosave, scalable window, full Persian right-to-left layout.
- **New art.** 24 suspect portraits (4 moods each), 13 scenes and 11 evidence illustrations, all in one ink-and-gouache noir style. The original score is kept.

## Project layout

```
data/            story.json (intro, nights, evidence, endings, hints) · suspects.json (profiles, prompts, topics, secrets)
scripts/autoload Settings · Story (data + UI strings) · Game (rules, clue engine, saves) · AI (streaming client, prompts) · Audio
scripts/screens  MainMenu · Intro · Hub (corridor) · Interrogation · CaseFile · NightEnd · Accusation · Ending · Settings · HowTo
scripts/ui       UI (theme + widget builders) · Vignette
assets/          art/portraits · art/scenes · art/evidence · music · fonts
tools/           process_art.py (resize new art) · check.sh (compile check) · grab_download.py / take.py (art pipeline)
```

## Developer checks

```bash
# Compile-check every script
tools/check.sh
# Play the intended solution through the real rules; prints unlocked secrets and the ending
../Godot_v4.7.2/Godot_v4.7.2-stable_mono_win64_console.exe --headless --path . -- --selftest
# Render screens to %APPDATA%/Godot/app_userdata/The Mercy Left Behind/shots
../Godot_v4.7.2/Godot_v4.7.2-stable_mono_win64_console.exe --path . -- --shot=menu,hub,room:sara,casefile:2 --lang=fa
```

To add art, drop images named `<suspect>_<mood>.jpg`, `ev_<id>.jpg` or `<scene>.jpg` into `assets/art/_incoming/` and run `python tools/process_art.py`.
