\chapter{Ist-Analyse der Applikation Tap'em}
\label{chap:ist-analyse}

\section{Zielsetzung und Vorgehen}

Ziel dieses Kapitels ist es, den aktuellen Entwicklungsstand der Applikation \emph{Tap'em} systematisch zu bewerten und daraus den technischen sowie organisatorischen Reifegrad für einen Markteintritt abzuleiten. Die Analyse dient als Grundlage für die spätere Planung von Maßnahmen (Roadmap) und wird im Kontext der Masterarbeit insbesondere genutzt, um das Potenzial von \emph{Prompt-Driven Development} für eine strukturierte Ist-Aufnahme zu untersuchen.

Die Ist-Analyse basiert auf einer statischen Auswertung des bestehenden Git-Repositories von Tap'em. Als Technologie-Stack kommen insbesondere Flutter (Multi-Plattform-UI), Firebase (Authentication, Firestore, Cloud Functions, Storage, Messaging) sowie Provider- und Riverpod-basiertes State-Management zum Einsatz. Die Auswertung erfolgte automatisiert durch ein Large Language Model (LLM), das in der Rolle eines Senior-Engineers den Quellcode, die Projektstruktur und vorhandene Konfigurations- und Dokumentationsdateien analysiert hat. Es wurden keine manuellen Tests, keine Produktiv-Builds und keine Nutzerdaten einbezogen; alle Aussagen beziehen sich auf den im Repository vorliegenden Stand.

\section{Architektur- und Systemüberblick}

Aus Sicht der Repository-Struktur präsentiert sich Tap'em als umfangreiche, modular aufgebaute Fitness-Applikation mit Fokus auf den Einsatz in Fitnessstudios (Multi-Tenant-Szenario):

\begin{itemize}
  \item Der Ordner \texttt{lib/} enthält die Haupt-App mit einem Kernbereich (\texttt{core/}) für Provider, Theme, Services und Drafts, feature-spezifische Module unter \texttt{features/} (u.\,a.\ Authentifizierung, NFC, Training, Gamification/XP, Community), generische Services (\texttt{services/}) sowie UI-Komponenten (\texttt{ui/}). Einstiegspunkte bilden \texttt{main.dart} und \texttt{app\_router.dart}.
  \item Unter \texttt{functions/} liegen Node.js-Cloud-Functions (z.\,B.\ XP-Logik, Aktivitäts-Feed, Avatar-Verwaltung) inklusive Jest-Tests, die serverseitige Gamification und Backend-Aufgaben übernehmen.
  \item Die Firebase-Konfiguration umfasst Sicherheitsregeln für Firestore (\texttt{firestore.rules}, \texttt{firestore-dev.rules}), Indexdefinitionen, Storage-Regeln und Emulator-Setups sowie globale Konfigurationsdateien (\texttt{firebase.json}, \texttt{.env}-Assets).
  \item Plattformverzeichnisse für Android, iOS, Web und Desktop sind angelegt, zusätzlich existieren Ressourcen- und Dokumentationsordner (\texttt{assets/}, \texttt{docs/}, \texttt{thesis/}).
\end{itemize}

Architektonisch folgt das Projekt weitgehend einer Aufteilung in \emph{data}, \emph{domain} und \emph{presentation}-Schichten je Feature. Gleichzeitig zeigt die Analyse, dass im State-Management zwei Paradigmen parallel genutzt werden: klassische Provider (\texttt{package:provider}) und \texttt{flutter\_riverpod}. Eine große Anzahl von Providern wird zentral in \texttt{main.dart} initialisiert, darunter Auth-, Gym-, Challenge-, Trainingsplan- und Branding-Provider. Community-Streams und weitere Teile nutzen hingegen Riverpod-Strukturen. Diese Mischung erhöht die Komplexität des Bootstrappings und erschwert langfristig Refactoring und Testbarkeit.

Auf Feature-Ebene deckt Tap'em bereits ein breites Spektrum ab:

\begin{itemize}
  \item \textbf{Auth \& Onboarding:} Gym-Codes, Benutzerprofile, Avatare und Rollenverwaltung.
  \item \textbf{NFC:} Lesen und Schreiben von NFC-Tags, globaler NFC-Listener und Gerätesuche über Tag-Codes.
  \item \textbf{Training:} Geräte- und Übungskataloge, Trainingspläne, Sessions und Timerfunktionalität.
  \item \textbf{Gamification:} XP-System, Challenges, Ränge, Avatare, Community-Feed, Freundesfunktionen und Rest-Statistiken.
  \item \textbf{Branding \& Multi-Tenant:} Gym-spezifische Themes und Konfigurationen über einen Branding-Provider und Membership-Services.
  \item \textbf{Offline-Fähigkeit:} Lokale Zwischenspeicherung von Session-Entwürfen über SharedPreferences.
\end{itemize}

Insgesamt zeichnet die LLM-Analyse ein Bild einer technisch ambitionierten und in viele Richtungen ausgebauten Codebasis, die allerdings in weiten Teilen noch den Charakter eines umfangreichen Alpha-Builds trägt.

\section{Technischer Reifegrad}

\subsection{Stabilität und Zuverlässigkeit}

Die Initialisierung der Applikation ist stark zentralisiert und komplex. In \texttt{main.dart} werden eine große Zahl von Providern, Services und Use-Cases manuell registriert. Globale Listener (z.\,B.\ für NFC oder Challenges) bauen auf Streams und Log-Ausgaben (\texttt{debugPrint}, \texttt{print}), verfügen jedoch kaum über robuste Fehlerbehandlung, Rücksetzlogik oder Retry-Strategien.

Zwar existieren Unit- und Komponenten-Tests für ausgewählte Bereiche (u.\,a.\ Authentifizierung, Community, NFC, Geräte), jedoch fehlen weitgehend durchgängige UI-, Navigations- und Integrations-Tests. Dies erhöht die Gefahr, dass Regressionen erst spät erkannt werden. Zusätzlich sind in \texttt{analysis\_options.yaml} mehrere sicherheitsrelevante Lints deaktiviert, was die Fehleranfälligkeit zur Laufzeit weiter steigert.

\subsection{Funktionalität und Umfang}

Die Funktionsbreite der App ist hoch: Von Authentifizierung über NFC-Workflows, Trainingsplaner und Gamification bis hin zu Community-Features sind viele Bausteine implementiert oder zumindest angelegt. Die Analyse zeigt jedoch, dass zahlreiche Module noch nicht produktionsreif ausgehärtet sind. Typische Indikatoren sind fehlende Lade- und Fehlerzustände in Widgets, Debug-Ausgaben anstelle strukturierter Fehlerbehandlung sowie nur teilweise integrierte Funktionen (z.\,B.\ vorbereitete, aber deaktivierte Push-Benachrichtigungen und Dynamic Links).

Offline-Funktionalität wird im Wesentlichen über Session-Drafts abgebildet; ein konsistentes Konzept zur Konfliktlösung und Synchronisation zwischen lokaler und serverseitiger Datenhaltung ist nicht erkennbar.

\subsection{Sicherheit und Datenschutz (aus Codesicht)}

Die Firestore-Regeln sind detailliert und bilden komplexe Zugriffskonzepte für Gyms, Rollen, Freundschaften und Chats ab. Gleichzeitig ist die Client-Logik stark davon abhängig, dass Zustände wie die aktive Gym-ID (\texttt{activeGymId}) und Rollen-Claims korrekt gepflegt und synchron gehalten werden. App Check, Token-Registrierung und weitere Sicherheitsmechanismen sind im Code vorbereitet, aber (Stand der Analyse) noch nicht durchgehend produktionsreif aktiviert und getestet.

Die Trennung von Entwicklungs- und Produktionskonfigurationen ist angelegt, muss für einen realen Launch jedoch in klaren Prozessen für Secrets-Handling und Deployment verankert werden.

\subsection{Wartbarkeit und Codequalität}

Aus Wartungssicht fällt insbesondere die parallele Nutzung von Provider und Riverpod ins Gewicht. Ohne klare Abgrenzung oder Migrationsstrategie entsteht eine doppelte State-Management-Landschaft mit erhöhter Komplexität. Die zentrale Bündelung von Abhängigkeiten in \texttt{main.dart} erschwert zusätzlich das Verständnis des Bootstrappings und erhöht das Risiko zyklischer Abhängigkeiten.

Mehrere Features greifen direkt aus Widgets oder Providern auf Firestore zu, statt konsistente Repository-Schichten zu nutzen. Dies reduziert Wiederverwendbarkeit und erschwert sowohl Tests als auch zukünftige Erweiterungen, zum Beispiel im Bereich Offline-Synchronisation.

\subsection{UX, UI und Gamification}

Die Applikation ist lokalisiert und verfügt über zahlreiche UI-Komponenten. Dennoch zeigt die Ist-Analyse, dass Lade- und Fehlerzustände in vielen Bereichen nicht konsistent umgesetzt sind. Dies betrifft insbesondere Stream-basierte Listen wie Challenges oder Community-Feeds. Ein einheitlicher Design- oder Komponenten-Guide ist im Repository nicht ersichtlich.

Die Gamification-Elemente (XP, Badges, Leaderboards, Avatare) sind technisch angelegt, die dazugehörigen Nutzerflüsse (z.\,B.\ Belohnungsmomente, Einstiegspunkte in Leaderboards, Sichtbarkeit von Fortschritt) wirken jedoch noch nicht vollständig durchdesignt und getestet. Gerade für eine motivationsgetriebene Fitness-App stellt dies einen zentralen Hebel für spätere Engagement-Optimierungen dar.

\subsection{Zwischenfazit technischer Reifegrad}

Zusammenfassend bewertet die LLM-Analyse Tap'em als umfangreiche, aber in vielen Bereichen noch nicht produktionsreif gehärtete Codebasis. Für einen realistischen Markteintritt müssen insbesondere Authentifizierungs- und Gym-Wechsel-Flows, State-Management, Offline- und Synchronisationskonzept, Sicherheits- und Observability-Themen sowie grundlegende UX-Standards gezielt stabilisiert werden. Der geschätzte Netto-Aufwand für die identifizierten \enquote{MUST-HAVE}-Maßnahmen liegt im Bereich mehrerer Wochen Vollzeitentwicklung durch ein erfahrenes Flutter/Firebase-Team.

\section{Nicht-technischer Reifegrad}

Ergänzend zur technischen Betrachtung wurden durch das LLM auch nicht-technische Faktoren identifiziert, die für einen erfolgreichen Launch wesentlich sind. Dazu zählen insbesondere:

\begin{itemize}
  \item \textbf{Gründung und Recht:} Wahl einer geeigneten Rechtsform (z.\,B.\ GmbH/UG), Erstellung und Prüfung von B2B-Verträgen mit Fitnessstudios, rechtssichere Anbieterkennzeichnung (Impressum).
  \item \textbf{Finanzen und Steuern:} Einrichtung von Buchhaltung, steuerlicher Registrierung, Geschäftskonto und Zahlungsinfrastruktur.
  \item \textbf{Datenschutz und Rechtstexte:} Erstellung DSGVO-konformer Datenschutzerklärungen, Allgemeiner Geschäftsbedingungen (AGB), Auftragsverarbeitungsverträge sowie Prozesse für Einwilligungen (z.\,B.\ Analytics, Push, Bildnutzung).
  \item \textbf{App-Store-Setup:} Einrichtung von Apple- und Google-Developer-Accounts, Erstellung von Store-Listings und Assets, Aufbau von Beta-Testprozessen (TestFlight, Closed Testing).
  \item \textbf{Produkt, Pricing und Go-to-Market:} Klärung der Value Proposition gegenüber Studios, Preismodell, Pilotkunden-Programm sowie grundlegende Marketing- und Vertriebsmaßnahmen.
  \item \textbf{Betrieb, Support und Analytics:} Definition von Supportkanälen und Reaktionszeiten, Incident-Response-Plänen sowie Einrichtung von Dashboards und Metriken zur datengetriebenen Weiterentwicklung.
\end{itemize}

Die Analyse verdeutlicht, dass die reine Fertigstellung der App-Funktionalität nicht ausreicht, um das Produkt erfolgreich in den Markt zu bringen. Vielmehr ist ein paralleler Aufbau von rechtlichen, organisatorischen und vertrieblichen Strukturen notwendig.

\section{Zusammenfassung}

Die Ist-Analyse zeigt, dass Tap'em bereits über eine breite und tief integrierte technische Basis verfügt, die viele zentrale Funktionalitäten für eine moderne, gamifizierte Fitness-App abdeckt. Gleichzeitig weist der aktuelle Stand in zentralen Bereichen (Stabilität, Sicherheit, Offline-Fähigkeit, UX-Polish, Observability) noch deutliche Lücken zur Produktionsreife auf. 

Auf der nicht-technischen Ebene bestehen zudem substanzielle Anforderungen in den Bereichen Gründung, Recht, Datenschutz, App-Store-Setup und Go-to-Market-Strategie. 

Für die Masterarbeit ist diese Analyse in zweifacher Hinsicht relevant: Erstens liefert sie eine fachliche Grundlage für die Ableitung einer Roadmap hin zur Market-Readiness der Applikation. Zweitens illustriert sie, wie ein LLM im Rahmen von Prompt-Driven Development genutzt werden kann, um aus einer bestehenden Codebasis systematisch den Ist-Zustand und zentrale Handlungsfelder für ein reales Softwareprodukt zu identifizieren.
