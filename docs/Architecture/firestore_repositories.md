## Firestore‑Zugriffe & Repositories

Ziel: Firestore‑Zugriffe konsolidieren, damit zentrale Datenflüsse testbar, erweiterbar und offline‑fähig bleiben.

### 1. Status Quo (Dezember 2025)

- Für die meisten Kernbereiche existieren bereits dedizierte **Data Sources / Repositories**, z.B.:
  - Geräte & Übungen:  
    - `FirestoreDeviceSource`, `FirestoreExerciseSource`, `FirestoreMachineAttemptSource`
  - Workouts & Sessions:  
    - `FirestoreSessionSource`, `SessionRepositoryImpl`, `SessionMetaSource`
  - Training‑Pläne & Schedule:  
    - `FirestoreTrainingPlanSource`, `FirestoreTrainingScheduleSource`, `TrainingPlanRepository`
  - XP & Leaderboards:  
    - `FirestoreXpSource`, `RankSource`, `LeaderboardScreen` (teils direkt, s.u.)
  - Community & Challenges:  
    - `FirestoreCommunityStatsSource`, `CommunityStatsWriter`, `FirestoreChallengeSource`
  - Coaching & Friends:  
    - `FirestoreCoachingSource`, `FirestoreCoachingAuditSource`, `FirestoreCoachInviteSource`, `FriendsApi`
  - Gym & Membership:  
    - `FirestoreGymSource`, `MembershipService`, `GymCodeService`
  - Rest‑Stats, Feedback, Surveys, Avatare:  
    - `RestStatsService`, `FeedbackProvider`, `SurveyProvider`, `AvatarRepository`, `AvatarEquipService`.

- Es gibt noch **einige direkte Firestore‑Zugriffe in UI‑Layern**, insbesondere in Admin‑/Reporting‑Screens (z.B. `admin_remove_users_screen.dart`, `report_members_usage_screen.dart`, `leaderboard_screen.dart`).

### 2. Grundsatz – Repositories als einziger Zugriffspunkt

1. **Domain‑/Feature‑Layer**
   - Alle produktiven Features greifen über klar benannte Repositories oder Data Sources zu:
     - `Repository` / `Source` übernimmt Query‑Logik, Paging, Mapping.
     - UI‑Code (Screens, Widgets) arbeitet nur mit Domain‑Modellen / Streams.
2. **Kein direkter Firestore‑Zugriff im UI**
   - Neue Screens/Features verwenden **nicht** mehr `FirebaseFirestore.instance.collection(...)` direkt.
   - Für bestehende Stellen im UI gilt: nur noch Refactorings, keine neuen direkten Firestore‑Calls.

### 3. Migrationsstrategie für Alt‑Code

1. **Inventar erstellen**
   - Mittels `rg "FirebaseFirestore.instance" lib -n` wurden alle direkten Zugriffe identifiziert.
   - Die meisten davon befinden sich bereits in Services/Repos; die wenigen verbleibenden UI‑Stellen sind:
     - Admin‑Screens (`admin_remove_users_screen.dart`, `admin_symbols_screen.dart`, `user_symbols_screen.dart`, `challenge_admin_screen.dart`),
     - XP‑/Rank‑Screens (`leaderboard_screen.dart`, `device_xp_leaderboard_screen.dart`, `powerlifting_leaderboard_screen.dart`),
     - Report‑Screens (`report_members_screen.dart`, `report_members_usage_screen.dart`),
     - einige Provider, die Firestore „inline“ verwenden und bei Gelegenheit auf dedizierte Sources umgestellt werden können.
2. **Schrittweise Extraktion**
   - Pro Modul einen kleinen `*Repository` oder `*Source` erstellen, z.B.:
     - `AdminUserRepository` für User‑Listings/Löschen,
     - `LeaderboardRepository` für XP‑/Ranking‑Queries,
     - `ReportMembersRepository` für Mitglieder‑Reports.
   - Die bestehenden Queries werden unverändert in diese Klassen verschoben, UI‑Code ruft nur noch Methoden wie `fetchMembers(...)` oder `watchLeaderboard(...)` auf.
3. **Priorisierung**
   - Zuerst Screens, die:
     - von normalen Usern häufig verwendet werden (XP‑Rankings, Reports),
     - komplexe/mehrfach duplizierte Queries enthalten.
   - Reine Admin‑Screens mit geringer Nutzung können nach Launch iterativ nachgezogen werden.

### 4. Regeln für neue Features

- Keine neuen direkten `FirebaseFirestore.instance`‑Aufrufe in Widgets / Screens.
- Neue Datenflüsse immer zuerst als Repository/Source modellieren und dann via Provider/Riverpod in die UI bringen.
- Wenn ein bestehender Screen funktional angepasst wird, möglichst gleich die Query‑Logik in ein Repository auslagern.

Mit diesem Dokument ist Phase 8.18 in `technisch_launchready.md` abgedeckt:  
- Repositories sind als Architekturprinzip festgelegt.  
- Die noch bestehenden direkten UI‑Zugriffe sind inventarisiert und klar als Migrationskandidaten markiert.  
- Neue Features werden gemäß dieser Leitlinien ausschließlich über Repositories an Firestore angebunden.

