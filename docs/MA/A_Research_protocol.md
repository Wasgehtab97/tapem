Rechercheprotokoll

Dieses Rechercheprotokoll skizziert das methodische Vorgehen für die Literaturrecherche der Masterarbeit „Prompt-Driven Development in Practice: Productivity, Quality, and Maintainability in a Vibecoded Flutter App“. Die Arbeit untersucht in einer Single-Case Design-Science-Studie am Beispiel des Projekts “Tap’em” den Einsatz von Large Language Models (LLMs) beim prompt-basierten Programmieren. Im Folgenden werden die Forschungsziele und -fragen, die Suchstrategie, konkrete Suchanfragen, Auswahlkriterien, Qualitätsbewertung sowie eine Literaturmatrix dargelegt.

A1. Forschungsziele und Forschungsfragen

Forschungsziele: Ziel der Arbeit ist es, empirisch und systematisch zu analysieren, wie sich LLM-basiertes Prompt Engineering auf die Softwareentwicklung auswirkt – insbesondere in Bezug auf Produktivität, Softwarequalität (gemäß ISO/IEC 25010), Wartbarkeit sowie weitere Aspekte wie Sicherheit, User Experience (UX) bzw. Gamification-Elemente, Risiken (z.B. Halluzinationen, Bias, Lizenzprobleme) und die Interaktion zwischen Mensch und KI im Entwicklungsprozess. Frühere Untersuchungen zeigen etwa, dass ein KI-Pair Programmer wie GitHub Copilot Entwicklungsaufgaben erheblich beschleunigen kann (eine Studie fand ~55,8 % Zeitersparnis bei einer Programmieraufgabe)
arxiv.org
. Unklar ist jedoch, wie sich solche Produktivitätsgewinne auf die resultierende Code-Qualität und Wartbarkeit auswirken. Erste Befunde deuten darauf hin, dass LLM-generierter Code teils weniger initiale Bugs enthält und mit geringerem Aufwand zu beheben ist
arxiv.org
, gleichzeitig aber in komplexen Fällen neue strukturelle Probleme auftreten können
arxiv.org
. Auch bestehen Bedenken, dass AI-basierte Entwicklung Sicherheitslücken einführt (eine Untersuchung fand z.B. in ~40 % der von Copilot erzeugten Lösungen Verwundbarkeiten)
fossa.com
 oder dass Bias und Lizenzverletzungen auftreten können
credo.ai
. Vor diesem Hintergrund wurden die folgenden forschungsleitenden Fragen (RQs) formuliert, um die Auswirkungen von Prompt-Driven Development ganzheitlich zu untersuchen:

RQ1: Produktivität – Wie beeinflusst LLM-basiertes Prompt-Programming die Produktivität der Softwareentwicklung? (etwa hinsichtlich Entwicklungszeit, Implementierungstempo und Entwickleraufwand im Vergleich zu traditioneller Entwicklung)

RQ2: Softwarequalität und UX – Welche Auswirkungen hat Prompt-Driven Development auf die Softwarequalität des entstandenen Produkts gemäß ISO/IEC 25010? Insbesondere: wie schneiden Aspekte wie funktionale Korrektheit, Zuverlässigkeit, Sicherheit und Usability/UX (z.B. Benutzerfreundlichkeit und Gamification-Elemente der App) unter KI-gestützter Entwicklung ab, im Vergleich zu erwartbaren Standards?

RQ3: Wartbarkeit – Inwiefern beeinflusst die Verwendung von LLMs als Programmierassistenz die Wartbarkeit des Quellcodes? (Betrachtet werden interne Qualitätsmerkmale wie Codeverständlichkeit, Modularität, Dokumentation sowie technische Schuld und der Aufwand für zukünftige Anpassungen oder Fehlerbehebungen.)

RQ4: Mensch-Maschine-Interaktion im Entwicklungsprozess – Wie gestaltet sich die Interaktion zwischen Entwickler und LLM beim prompt-basierten Coden in der Praxis? (Etwa: Welche Strategien der Prompt-Formulierung und Ergebnisüberprüfung werden eingesetzt? Wie verteilt sich die Aufgaben- und Verantwortungsbalance zwischen Mensch und KI im “Pair Programming”? Wie beeinflusst das die Entwicklererfahrung und -zufriedenheit?)

RQ5: Risiken und Herausforderungen – Welche Risiken und Herausforderungen treten bei LLM-basiertem Coden auf und wie lassen sie sich handhaben? (Untersucht werden z.B. Halluzinationen – d.h. syntaktisch korrekt, aber fachlich falscher oder nicht existierender Code –, Bias in generierten Code-Texten, Lizenz- und Urheberrechtsprobleme durch die Verwendung von Trainingsdaten, sowie potenzielle Sicherheitsrisiken durch ungeprüften KI-Code. Zudem: Welche Gegenmaßnahmen oder Prüfschritte sind notwendig, um diese Risiken zu mitigieren?)

Diese Forschungsfragen decken die wichtigsten Dimensionen ab – von Produktivität und Qualität über Wartbarkeit und Security/UX bis hin zu Risiken und der Interaktion Mensch-KI. Sie ermöglichen eine ganzheitliche Untersuchung, wie sich Prompt-Driven Development im Fallstudienprojekt auf das Softwareprodukt und den Entwicklungsprozess auswirkt.

A2. Suchräume und Datenbanken

Für die systematische Literaturrecherche werden mehrere relevante Datenbanken und Suchräume genutzt, die speziell für Themen an der Schnittstelle von LLMs, Software Engineering und empirischen Studien geeignet sind. Die folgenden Quellen werden durchsucht:

ACM Digital Library – Zur Abdeckung von Konferenzbeiträgen und Journalen im Bereich Software Engineering, HCI und KI (z.B. ICSE, ESEM, CHI, Transactions on Software Engineering etc.), in denen Arbeiten zu AI-unterstützter Programmierung veröffentlicht wurden.

IEEE Xplore – Für IEEE-Konferenzen und -Journale (etwa IEEE Software, IEEE Transactions on AI, Konferenzen wie ASE oder ICSME), um weitere Studien über LLMs im Softwareentwicklungsprozess und verwandte technische Papers zu finden.

arXiv – Als Preprint-Server, insbesondere im Bereich Computer Science (cs.AI, cs.SE), um top-aktuelle Forschung zu LLM-basiertem Codieren abzudecken, die ggf. noch im Publikationsprozess ist (viele neuere Studien zu GitHub Copilot & Codex sind zunächst auf arXiv erschienen).

SpringerLink – Für die Suche in Springer-Fachzeitschriften und Tagungsbänden (z.B. Empirical Software Engineering, Software Quality Journal, LNCS-Bände etc.), um sowohl empirische Studien als auch Überblicksarbeiten zu Softwarequalität, Wartbarkeit und evtl. Gamification in Apps zu finden.

Google Scholar – Als übergreifende akademische Suchmaschine, um Publikationen verschiedener Verlage gleichzeitig abzudecken und Zitationen zu verfolgen. Scholar hilft, relevante Literatur über unterschiedliche Plattformen (ACM, IEEE, arXiv, etc.) hinweg zu identifizieren und sortiert nach Zitationseinfluss.

Scopus / Web of Science – Für eine ergänzende systematische Suche nach wissenschaftlichen Artikeln und zur Zitationsrecherche. Diese Datenbanken stellen sicher, dass keine wichtigen Studien übersehen werden, und erlauben Filter etwa nach Publikationsjahr, Fachgebiet und Peer-Review-Status.

Durch die Kombination dieser Suchräume wird eine möglichst umfassende Abdeckung gewährleistet. Insbesondere ACM und IEEE liefern Kernliteratur im Software Engineering, während arXiv und Scholar sicherstellen, dass auch neueste oder interdisziplinäre Arbeiten (z.B. an der Grenze von KI-Forschung und Softwaretechnik) berücksichtigt werden.

A3. Suchstrings und Suchphrasen

Um die Literatur systematisch zu finden, werden konkrete Suchstrings verwendet, die verschiedene Begriffe und Synonyme abdecken. Die Suchanfragen werden iterativ verfeinert; dabei kommen Boolsche Operatoren (AND, OR) und Platzhalter zum Einsatz, um relevante Publikationen aufzufinden. Im Folgenden sind mindestens sechs zentrale Suchphrasen beispielhaft aufgeführt:

Suchstring 1: “AI-assisted programming” OR “AI pair programming” OR “AI-augmented coding” – fokussiert auf allgemein AI-unterstütztes Programmieren und pair programming mit KI.

Suchstring 2: “Large Language Models” OR LLM AND “software engineering” OR “code generation” – zielt auf Arbeiten über LLMs im Kontext Softwareentwicklung bzw. automatischer Code-Generierung ab (schließt Begriffe wie Codegenerierung, automatisches Programmieren ein).

Suchstring 3: “Prompt engineering” AND “code generation” OR “software development” – deckt Literatur zum Einsatz von Prompt-Engineering für Codeerzeugung ab; inkludiert evtl. auch Synonyme wie “natural language programming”.

Suchstring 4: “GitHub Copilot” OR “OpenAI Codex” AND (productivity OR study OR evaluation) – speziell für Studien und empirische Auswertungen zu Copilot bzw. Codex, mit Fokus auf Produktivitätsmessungen, Entwicklerstudien oder qualitativen Auswertungen.

Suchstring 5: “code maintainability” AND (“AI-generated code” OR “machine-generated code” OR “automated code”) AND (“technical debt” OR “code quality”) – um Arbeiten zu interner Codequalität, Wartbarkeit und technischer Schuld in von KI erzeugtem Code zu finden.

Suchstring 6: “software quality” AND “AI code” OR “LLM” AND “ISO 25010” – verbindet den Qualitätsbegriff (ISO/IEC 25010 Merkmale wie Sicherheit, Zuverlässigkeit, Usability) mit KI-generiertem Code; hier werden auch Begriffe wie “code quality metrics LLM” berücksichtigt.

Suchstring 7: “gamification” AND “mobile app” OR “user experience” OR “UX design” – zielt auf Literatur zu Gamification und UX in Apps ab, um eventuelle Grundlagen hierfür abzudecken. (Dieser String ist nicht direkt LLM-bezogen, wird aber aufgenommen, da die Fallstudien-App ein Fitness-App mit Gamification-Aspekten ist und untersucht werden soll, ob und wie KI-Unterstützung solche Features beeinflusst.)

Jeder dieser Strings wird an die jeweilige Datenbank angepasst (z.B. Nutzung von Feld-Begrenzungen in Scopus/Web of Science oder der ACM DL). Zudem werden Synonyme auf Deutsch mit berücksichtigt, falls relevant (die meisten einschlägigen Publikationen sind jedoch Englisch). Durch die Kombination aus spezifischen Begriffen (GitHub Copilot, prompt engineering) und breiteren Konzepten (AI-assisted programming, code generation) wird sowohl gezielt bekannte Literatur gefunden als auch nach verwandten Studien gesucht, die auf den ersten Blick nicht offensichtlich sind.

A4. Einschluss-/Ausschlusskriterien und Screening-Vorgehen

Um aus den gefundenen Treffern die tatsächlich relevanten Quellen zu selektieren, werden klare Einschluss- und Ausschlusskriterien definiert. Diese Kriterien sichern, dass die ausgewählte Literatur für die Forschungsfragen passend und qualitativ hochwertig ist. Anschließend wird in einem Screening-Prozess schrittweise gefiltert.

Einschlusskriterien:

Inhaltliche Relevanz: Die Studie adressiert LLM-basierte Softwareentwicklung oder eng verwandte Themen (AI-Unterstützung beim Programmieren, automatische Codegenerierung, Entwicklerproduktivität mit KI, Codequalität/Wartbarkeit von AI-Code, Risiken von generativem Code etc.). Auch berücksichtigt werden Schlüsselwerke zu grundlegenden Konzepten (z.B. allgemeine Arbeiten zu Softwarequalität ISO 25010 oder Gamification), sofern sie zum Verständnis beitragen.

Empirische oder methodische Belastbarkeit: Bevorzugt werden empirische Studien (Experimente, Fallstudien, Surveys, Mixed-Methods-Untersuchungen) mit nachvollziehbarer Methodik und realweltlichem Kontext. Auch qualitative Studien oder fundierte Design-Science Arbeiten werden eingeschlossen, sofern sie einen wissenschaftlich begründeten Erkenntnisbeitrag liefern.

Publikationsart: Peer-Review ist ein wichtiges Kriterium – vorrangig werden begutachtete Konferenzbeiträge, Journalartikel oder anerkannte Preprints (arXiv) ausgewählt. Ausnahmen sind möglich für besonders aktuelle oder einflussreiche nicht-begutachtete Quellen (z.B. ein Whitepaper zu Lizenzrisiken oder offizielle Dokumentationen), aber nur unterstützend.

Zeitfenster: Hauptsächlich Publikationen von 2018 bis heute (Stand: 2025), da LLMs in der Programmierung erst ab ca. 2018 (und insbesondere seit 2021 mit Codex/Copilot) relevant wurden. Ältere Werke werden nur bei grundsätzlicher Relevanz (z.B. klassische Grundlagen der Softwarequalität oder Gamification) herangezogen.

Sprache: Literatur in englischer Sprache (da dies die Fachsprache ist). Deutschsprachige Quellen werden nur berücksichtigt, wenn sie empirisch relevant und nicht in englischer Fassung verfügbar sind.

Ausschlusskriterien:

Arbeiten, die zwar LLMs behandeln, aber nicht im Kontext Softwareentwicklung (z.B. rein NLP-Anwendungen, ohne Bezug zu Programmierung) – solche werden ausgeschlossen.

Quellen mit fehlender wissenschaftlicher Fundierung, etwa Blogposts oder Meinungsartikel, sofern sie nicht durch Daten gestützt sind (mit Ausnahme oben genannter Fälle zu aktuellen Risiken, falls notwendig).

Redundante Publikationen (Mehrfache Publikationen desselben Inhalts) – hier wird die aktuellste oder umfassendste Version genutzt (z.B. Journal-Extension statt vorangegangenem Workshop-Paper).

Veröffentlichungen vor 2018 (außer es handelt sich um seminal works, die z.B. ISO-Standards erklären oder Grundkonzepte definieren).

Thematisch unpassende Studien, auch wenn sie “Prompt” oder “AI” im Titel tragen, werden ausgeschlossen, sobald aus Titel/Abstract erkennbar ist, dass kein Bezug zu Softwareentwicklung oder unseren RQs besteht.

Screening-Vorgehen: Die Auswahl der Literatur erfolgt mehrstufig. (1) Zunächst wird ein Titel-/Abstract-Screening durchgeführt: Alle Suchergebnisse werden anhand ihres Titels und Abstracts überflogen und mit den obigen Kriterien abgeglichen. Studien, die offensichtlich nicht passen (Themenferne, keine empirische Grundlage, etc.), werden in dieser Phase ausgesiebt. (2) Die verbleibenden Kandidaten werden im Volltext untersucht. Dabei wird geprüft, ob die Studie tatsächlich die Erwartungen erfüllt (manchmal zeigt erst der Volltext z.B., dass doch kein LLM verwendet wurde o.ä.) und ob ausreichend Informationen zur Beantwortung der RQs vorliegen. (3) Zusätzlich findet ein Schneeballverfahren (Snowballing) statt: Relevante Quellen in den Literaturlisten bereits inkludierter Arbeiten werden nachträglich überprüft (Backward Snowballing). Ebenso werden Zitationen dieser Arbeiten mittels Google Scholar/Scopus analysiert (Forward Snowballing), um neuere relevante Studien zu entdecken, die den originalen Arbeiten folgen.

Während des Screenings wird die Nachvollziehbarkeit dokumentiert: Für jeden Schritt wird notiert, welche Studien ausgeschlossen wurden und aus welchem Grund (z.B. “nicht peer-reviewed”, “Thema verfehlt” etc.). Insgesamt stellt dieses Vorgehen sicher, dass am Ende eine hochwertige und fokussierte Literatursammlung entsteht, die die Forschungsfragen adressiert.

A5. Qualitätsbewertung der Studien

Für die eingeschlossenen Studien wird ein Qualitätsbewertungsschema angewandt, um ihre Aussagekraft und methodische Solidität einzuschätzen. Jede Studie wird systematisch nach festgelegten Kriterien beurteilt, was auch in die spätere Gewichtung der Erkenntnisse einfließt. Die Qualitätskriterien umfassen:

Peer-Review-Status: Wurde die Studie formell begutachtet (Journal/Conference) oder handelt es sich um einen Preprint/bericht? Peer-reviewed Publikationen genießen höheres Vertrauen.

Methodische Strenge: Wie belastbar ist das gewählte Studiendesign? Hier wird geschaut, ob die Methode passend und gründlich ist – z.B. ein kontrolliertes Experiment mit ausreichender Teilnehmerzahl, eine aussagekräftige Fallstudie über genügend lange Zeit, oder Mixed-Methods mit Triangulation. Studien mit Realweltdaten (etwa professionelle Entwickler oder reale Code-Repositorien) werden tendenziell höher bewertet als rein künstliche Laborexperimente, sofern sauber durchgeführt.

Evidenzstärke: Inwieweit stützen die präsentierten Daten die Schlussfolgerungen? Dies hängt zusammen mit dem obigen Punkt, zielt aber darauf ab, wie aussagekräftig die Ergebnisse sind. Beispielsweise liefern statistisch signifikante Unterschiede in einer Kontrollstudie oder konsistente Beobachtungen in mehreren Projekten eine höhere Evidenzstärke als nur anekdotische Beobachtungen.

Reproduzierbarkeit und Transparenz: Werden genug Details angegeben, um die Studie nachzuvollziehen oder zu replizieren? Etwa: Offenlegung von Datensätzen oder Code, Beschreibung der Prompt-Fragen und LLM-Version, verwendete Metriken etc. Hohe Reproduzierbarkeit (ggf. durch bereitgestellte Repos/Anhänge) deutet auf Qualität hin.

Berücksichtigung von Limitierungen: Reflektiert die Arbeit ihre Grenzen und mögliche Bias? Eine hochwertige Studie diskutiert z.B. potentielle Bedrohungen der Validität (interne/externe Validität, Konstruktvalidität etc.), Unsicherheiten in den Daten, und gibt an, was nicht abgedeckt wurde. Dies zeigt wissenschaftliche Sorgfalt.

Jede Studie wird anhand dieser Kriterien qualitativ bewertet (z.B. in Kategorien hoch, mittel, niedrig oder mittels Punkteschema). Beispielsweise würde eine von Experten begutachtete Studie, die einen soliden kontrollierten Versuch mit realen Entwicklern durchführt und deren Ergebnisse statistisch signifikant sind, als hohe Evidenz mit hoher methodischer Qualität eingestuft. Im Gegensatz dazu könnte ein Meinungsaufsatz ohne Daten bestenfalls als niedrige Evidenz gewertet werden. Durch diese Qualitätsbewertung wird sichergestellt, dass in der Synthese der Literatur den robustesten Erkenntnissen mehr Gewicht beigemessen wird und dass Schlussfolgerungen differenziert nach Vertrauenswürdigkeit der Quellen gezogen werden.

(Hinweis: Die Qualitätsbewertung erfolgt durch den Autor. Bei Unklarheiten kann ein zweiter Gutachter (z.B. Betreuer) konsultiert werden, um Objektivität zu erhöhen. Die Kriterien orientieren sich an gängigen SLR-Richtlinien im Software Engineering und empirischen Forschung.)

A6. Literaturmatrix (Analyse- und Syntheseschema)

Zur strukturierten Auswertung der gefundenen Literatur wird eine Literaturmatrix angelegt. In dieser tabellarischen Übersicht werden die wichtigsten Merkmale und Ergebnisse jeder Quelle festgehalten, um Vergleich, Analyse und Synthese zu erleichtern. Geplant ist, folgende Spalten in die Matrix aufzunehmen:

Referenz (Autoren, Jahr) – Kurze Angabe der Quelle, z.B. Peng et al., 2023
arxiv.org
. Dies dient der Identifikation und wird mit dem vollständigen Literaturverzeichnis verknüpft.

Thema/Fokus – Stichworte oder kurzer Satz, worum es in der Studie geht. Z.B. “Copilot vs. Mensch: Produktivitätsexperiment” oder “LLM-generierter Code vs. Human-Code in Bezug auf Bugs”. Damit wird der inhaltliche Schwerpunkt schnell ersichtlich.

Methode & Kontext – Angaben zur Forschungsmethode (Experiment, Fallstudie, Survey, etc.) samt Kontext: z.B. “Kontrolliertes Experiment, 30 Entwickler, Aufgabe: Webserver in JS”, oder “Fallstudie eines OSS-Projekts über 6 Monate”. Auch Stichprobengröße oder verwendete Datensätze werden hier notiert.

Wesentliche Ergebnisse – Zusammenfassung der wichtigsten Resultate bzw. Erkenntnisse der Studie. Beispielsweise: “AI-Gruppe erledigte Aufgabe 55% schneller (p<0.05)”
arxiv.org
, oder “LLM-Code hat im Schnitt weniger kritische Bugs als humanen Code
arxiv.org
, aber in komplexen Aufgaben traten neue Probleme auf
arxiv.org
”. Diese Spalte konzentriert die Kernaussagen, quantitativ wie qualitativ.

Relevanz für RQs – Einschätzung, welche Forschungsfrage(n) die Studie informiert. Dies kann etwa in Form von RQ-Nummern oder Symbolen erfolgen (z.B. “RQ1 ✅, RQ3 ✅” wenn eine Produktivitätsstudie natürlich RQ1 adressiert und evtl. auch Beobachtungen zu Wartbarkeit RQ3 liefert). So sieht man, wo welche Literatur einen Beitrag leistet.

Limitierungen der Studie – Notiert werden vom Autor genannte oder offensichtlich bestehende Limitationen. Z.B. “nur Uni-Studenten als Probanden (Externe Validität begrenzt)”, “kurzer Zeithorizont”, “nur eine Programmiersprache betrachtet”, etc. Diese Spalte hilft bei der Bewertung, wie vorsichtig man mit den Ergebnissen umgehen muss und ergänzt die Qualitätsbewertung.

Qualitätsbewertung (optional) – Falls gewünscht, kann hier eine kurz gefasste Qualitätsnote der Studie eingetragen werden (z.B. Hoch/Mittel/Niedrig oder ein Score), basierend auf den in A5 genannten Kriterien. Dies erleichtert die Filterung nach besonders soliden Evidenzen bei der Synthese.

Mit dieser Matrix können im Anschluss Muster erkannt werden – etwa ob mehrere Studien übereinstimmend eine bestimmte Wirkung von KI-Programmierung berichten – und es lässt sich nachvollziehbar aufzeigen, welche Literatur welche Teile der Forschungsfragen abdeckt. Die Matrix dient letztlich als Grundlage für das Kapitel “Verwandte Arbeiten” bzw. die Literaturanalyse in der Thesis, in der die Ergebnisse der verschiedenen Quellen vergleichend diskutiert und zusammengeführt werden.

Durch die obigen Schritte stellt das Rechercheprotokoll sicher, dass die Literaturrecherche systematisch, transparent und nachvollziehbar erfolgt. Es werden klar umrissene Forschungsfragen adressiert und die Suche in relevanten wissenschaftlichen Quellen durchgeführt. Auswahlkriterien und Qualitätsbewertung sorgen dafür, dass die Synthese belastbar ist. Dieses Protokoll dient somit als Leitfaden, um die Literaturarbeit zur Masterarbeit methodisch sauber umzusetzen und zu dokumentieren.