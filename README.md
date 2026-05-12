# Jadwal — AI-Powered Quran Memorisation App

A cross-platform mobile application that helps Muslims on their Hifdh (Quran memorisation) journey through intelligent scheduling, AI-assisted assessment, and progress analytics. Built as a University of Birmingham final year project (2024–25).

---

## The Problem

Memorising the Quran — 114 chapters, 600+ pages, 6,200+ verses — takes years of consistent effort. Most people who attempt it struggle with the same set of problems: no clear structure, inconsistent review schedules, forgetting previously memorised content, and losing motivation without a way to visualise progress. Existing apps address parts of this problem but none integrate modern learning science with a fully adaptive system.

Jadwal solves this by combining a custom spaced repetition algorithm, AI speech recognition, and a structured daily scheduling engine into a single, coherent experience.

---

## Key Features

### Intelligent Scheduling Engine
- Users set their memorisation goals, available days, and daily capacity
- The engine automatically generates daily new memorisation and review tasks
- Handles missed days and failed reviews without overwhelming the user — sessions are intelligently rescheduled rather than piling up

### Spaced Repetition Algorithm (Modified SM-2)
- Based on the SuperMemo-2 algorithm, adapted specifically for Quranic memorisation
- Users are rated 0–5 after each review quiz; intervals grow with successful recall and reset on failure
- Key adaptations from standard SM-2:
  - First review interval set to 3 days (not 6) — more appropriate for Arabic memorisation
  - Maximum of 5 review sessions per item; requires 3 consecutive successes to mark as mastered
  - If a user fails 3 times or exhausts reviews without mastery, the content is flagged for re-memorisation
  - Easiness factor starts at 2.0 (not 2.5) and adjusts more gradually (×0.75) to prevent intervals growing too quickly

### AI-Powered Quiz System — 4 Question Types
1. **Fill in the Blank** — removes words from the start and end of verses (where people most commonly forget) with AI-generated distractor options. Distractors are generated via GPT with grammatical plausibility requirements, making it genuinely difficult for Arabic speakers
2. **What Comes Next** — displays a verse, user recites the next verse aloud; speech is transcribed via OpenAI Whisper and assessed with a custom Arabic text comparison algorithm
3. **Verse Pairing** — given a central verse, select the correct verse before and after from multiple options; tests sequential memory
4. **Build the Verse** — given only the first word, drag and rearrange the remaining words to reconstruct the full verse

### Custom Arabic Text Comparison
Arabic NLP is significantly harder than Latin-script comparison due to diacritical marks (tashkeel), multiple alif forms, hamza variants, and Quranic-specific notation. Jadwal implements a custom pipeline:
- Normalises both transcribed and reference text (removes diacritics, standardises alif/hamza variants, removes tatweel)
- Applies a modified Levenshtein distance algorithm at the character level
- Maps differences back to the original text with diacritics preserved, so errors are highlighted clearly without penalising acceptable transcription variation
- All unit tested against edge cases including alif omission, single character substitution, and completely different input

### Progress Tracking & Analytics
- Surah-by-surah completion tracking with percentage indicators
- Session history for both memorisation and reviews
- Streak counter to encourage daily consistency
- Estimated completion date — updates dynamically based on pace

### Light & Dark Mode, Offline Support
- Full theme support with persistent user preference
- Firestore offline persistence for core functionality without a connection

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile (iOS & Android) | Flutter / Dart |
| State management | GetX, Provider |
| Backend / Auth | Firebase Authentication, Cloud Firestore, Cloud Functions |
| Local storage | SQLite (sqflite), SharedPreferences |
| AI — Speech recognition | OpenAI Whisper API |
| AI — Quiz distractor generation | OpenAI GPT API |
| Arabic typography | 604 custom page fonts (one per Mushaf page) |
| CI/CD | Codemagic |
| Design | Figma |
| Notifications | flutter_local_notifications |

---

## Architecture

Jadwal follows a layered architecture with clear separation of concerns:

```
Presentation Layer     →  Flutter UI (screens, widgets, themes)
Business Logic Layer   →  Scheduling engine, SM-2 algorithm, quiz generation, text comparison
Data Access Layer      →  Firestore operations, SQLite, SharedPreferences
External Services      →  Firebase Auth, OpenAI Whisper, OpenAI GPT
```

Firestore collections are structured around a user-centric model: each user has sub-collections for `plans`, `hifdhs`, `reviews`, `weeks`, and `surahsProgress`. Shared Quranic content (`surahs`, `verses`) lives in global collections with read-only security rules.

---

## Testing

**Unit tests** cover the three most critical algorithmic components:
- SM-2 algorithm — correct interval calculation, EF adjustment, mastery/failure logic, minimum EF enforcement
- Quiz generation — correct question construction per type, answer validation
- Arabic text comparison — diacritic handling, alif omission, character substitution, completely divergent input

**Integration tests** (Flutter integration testing framework, run on both iOS and Android):
- Full authentication flow — registration, login, profile display, logout
- Plan creation — prior memorisation entry, surah/verse selection, schedule configuration, confirmation
- Plan editing — amount modification, unit toggling, day selection, persistence verification

**User Acceptance Testing:**
- Alpha: 4 participants; led to a full UI redesign and improved mistake detection accuracy
- Beta: 14 participants; intuitiveness rated 4.2/5, visual design 4.6/5, spaced repetition effectiveness 4.3/5, adaptive scheduling 4.4/5, likelihood of continued use 7.9/10

---

## Getting Started

**Prerequisites:** Flutter SDK — see [flutter.dev](https://flutter.dev/docs/get-started/install), and a Firebase project with Firestore and Authentication enabled.

```bash
git clone https://github.com/suheybhersi/Jadwal.git
cd Jadwal
flutter pub get
```

You'll need to add your own `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase project, and configure your OpenAI API key via a `.env` file:

```
OPENAI_API_KEY=your_key_here
```

Then run:

```bash
flutter run
```

---

## Project Background

Developed as a final year Computer Science project at the **University of Birmingham** (2024–25). The project involved original research into traditional Hifdh methodologies across different cultures (Mauritanian, Ottoman, Indian-Pakistani, Somali), cognitive science literature on spaced repetition and the Ebbinghaus forgetting curve, and a review of existing Quran apps to identify the gap Jadwal fills.

The development followed a hybrid Agile approach (Scrum + Kanban) across 6 two-week sprints over 30 weeks, from requirements gathering through to user testing.

---

## Limitations & Future Work

- Mistake detection does not yet account for Tajweed rules (proper pronunciation rules)
- No social or gamification features yet (leaderboards, teacher-student connections were the most requested additions from beta testers)
- Not yet published to the App Store or Play Store
- Future plans include in-app Quran reader, free-practice recitation mode, and collaborative teacher/student features
