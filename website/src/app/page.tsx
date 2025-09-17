import fs from 'node:fs';
import path from 'node:path';

import Image from 'next/image';
import Link from 'next/link';

import { ThemeToggle } from '../components/theme-toggle';

export const dynamic = 'force-static';

const galleryItems = [
  {
    fileName: 'hero.png',
    title: 'Dashboard-Übersicht',
    description: 'Visualisiere Check-ins und Geräte-Auslastung auf einen Blick.',
  },
  {
    fileName: 'screenshot-1.png',
    title: 'Trainingshistorie',
    description: 'Verfolge persönliche Fortschritte mit detaillierten Analysen.',
  },
  {
    fileName: 'screenshot-2.png',
    title: 'Ranglisten & Challenges',
    description: 'Motiviere Mitglieder durch transparente Wettbewerbe.',
  },
  {
    fileName: 'screenshot-3.png',
    title: 'Studio-Konfiguration',
    description: 'Passe Branding, Geräte und Regeln pro Studio an.',
  },
];

const featureItems = [
  {
    title: 'NFC-Check-in in Sekunden',
    description:
      'Mitglieder melden sich per Tap am Terminal an – inklusive Gerätefreigabe und Sicherheit.',
  },
  {
    title: 'Multi-Tenant Branding',
    description:
      'Individuelle Farben, Logos und Tarife pro Studio – zentral administriert.',
  },
  {
    title: 'Trainingshistorie & Charts',
    description:
      'Automatisierte Trainingsprotokolle mit Diagrammen und Fortschrittsberichten.',
  },
  {
    title: 'Ranglisten & Challenges',
    description:
      'Gamification-Features motivieren Mitglieder mit saisonalen Wettbewerben.',
  },
  {
    title: 'Geräte-Auslastung in Echtzeit',
    description:
      'Erkenne Stoßzeiten und plane Wartung vorausschauend mit Smart-Analytics.',
  },
  {
    title: 'Studio-übergreifendes Reporting',
    description:
      'Vergleiche KPIs zwischen Standorten und exportiere Reports für Stakeholder.',
  },
];

const steps = [
  {
    title: 'Tap & Sync',
    description:
      'Mitglieder checken per NFC ein; Trainingsdaten werden automatisch erfasst.',
    icon: (
      <svg
        aria-hidden="true"
        className="h-10 w-10 text-primary"
        fill="none"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.5"
        viewBox="0 0 24 24"
      >
        <path d="M12 5v14" />
        <path d="m18 9-6-6-6 6" />
        <path d="M6 15h12" />
      </svg>
    ),
  },
  {
    title: 'Analyse & Visualisiere',
    description:
      'Dashboards zeigen Auslastung, Performance und Retention auf einen Blick.',
    icon: (
      <svg
        aria-hidden="true"
        className="h-10 w-10 text-primary"
        fill="none"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.5"
        viewBox="0 0 24 24"
      >
        <path d="M4 19h16" />
        <path d="M8 19V7" />
        <path d="M12 19V4" />
        <path d="M16 19v-6" />
      </svg>
    ),
  },
  {
    title: 'Optimieren & Motivieren',
    description:
      'Automatisierte Challenges und Benachrichtigungen halten Mitglieder aktiv.',
    icon: (
      <svg
        aria-hidden="true"
        className="h-10 w-10 text-primary"
        fill="none"
        stroke="currentColor"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="1.5"
        viewBox="0 0 24 24"
      >
        <path d="m12 5 6 6-6 6" />
        <path d="M6 12h12" />
      </svg>
    ),
  },
];

const faqItems = [
  {
    question: 'Ist Tap\'em für bestehende Studio-Systeme kompatibel?',
    answer:
      'Ja, Tap\'em setzt auf modulare APIs und kann mit gängigen Mitgliederverwaltungen integriert werden.',
  },
  {
    question: 'Wie schnell kann ein Studio live gehen?',
    answer:
      'Der Rollout dauert typischerweise weniger als zwei Wochen – inklusive Hardware-Konfiguration.',
  },
  {
    question: 'Werden persönliche Daten DSGVO-konform verarbeitet?',
    answer:
      'Tap\'em speichert Daten verschlüsselt in der EU und erfüllt aktuelle Datenschutzstandards.',
  },
  {
    question: 'Gibt es White-Label-Optionen?',
    answer: 'Ja, komplette White-Labeling-Optionen sind über das Admin-Portal verfügbar.',
  },
  {
    question: 'Welche Hardware wird benötigt?',
    answer:
      'Neben NFC-fähigen Endgeräten benötigt das Studio lediglich ein Tap\'em Hub-Terminal pro Zone.',
  },
  {
    question: 'Kann ich Tap\'em unverbindlich testen?',
    answer: 'Fordere eine Demo über das Kontaktformular an und teste Tap\'em in deinem Studio.',
  },
];

function imageExists(fileName: string) {
  const publicDir = path.join(process.cwd(), 'public', 'images');
  const candidate = path.join(publicDir, fileName);
  return fs.existsSync(candidate);
}

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col bg-white text-slate-900 dark:bg-slate-950 dark:text-slate-100">
      <header className="border-b border-slate-200 bg-white/80 backdrop-blur dark:border-slate-800 dark:bg-slate-950/80">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-4" aria-label="Top navigation">
          <Link href="#hero" className="text-lg font-semibold">
            Tap'em
          </Link>
          <nav className="hidden items-center gap-6 text-sm font-medium md:flex" aria-label="Hauptnavigation">
            <Link className="hover:text-primary" href="#features">
              Features
            </Link>
            <Link className="hover:text-primary" href="#how-it-works">
              So funktioniert's
            </Link>
            <Link className="hover:text-primary" href="#faq">
              FAQ
            </Link>
            <Link className="hover:text-primary" href="#contact">
              Kontakt
            </Link>
          </nav>
          <ThemeToggle />
        </div>
      </header>

      <main id="hero" className="flex-1">
        <section className="bg-gradient-to-b from-primary/10 via-white to-white py-20 dark:from-slate-900 dark:via-slate-950 dark:to-slate-950">
          <div className="mx-auto flex max-w-6xl flex-col gap-10 px-6 md:flex-row md:items-center">
            <div className="flex-1 space-y-6">
              <p className="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-sm font-medium text-primary">
                NFC-basiertes Gym-Tracking &amp; -Management
              </p>
              <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">Revolutioniere den Studio-Alltag mit Tap'em</h1>
              <p className="text-lg text-slate-600 dark:text-slate-300">
                Tap'em verknüpft Check-in, Trainingsplanung und Gamification in einer Plattform – für
                effizientere Abläufe und motivierte Mitglieder.
              </p>
              <div className="flex flex-col gap-3 sm:flex-row">
                <Link
                  href="#features"
                  className="rounded-full bg-primary px-6 py-3 text-center text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/30 transition hover:bg-primary/90"
                >
                  Mehr erfahren
                </Link>
                <Link
                  href="#contact"
                  className="rounded-full border border-slate-300 px-6 py-3 text-center text-sm font-semibold transition hover:border-primary hover:text-primary dark:border-slate-700"
                >
                  Für Studios: Demo anfragen
                </Link>
              </div>
              <dl className="grid grid-cols-1 gap-6 text-slate-600 dark:text-slate-300 sm:grid-cols-3">
                <div>
                  <dt className="text-sm">Check-ins pro Tag</dt>
                  <dd className="text-2xl font-semibold">10k+</dd>
                </div>
                <div>
                  <dt className="text-sm">Studios aktiv</dt>
                  <dd className="text-2xl font-semibold">120+</dd>
                </div>
                <div>
                  <dt className="text-sm">Zeitersparnis</dt>
                  <dd className="text-2xl font-semibold">bis zu 30%</dd>
                </div>
              </dl>
            </div>
            <div className="flex-1">
              <div className="relative aspect-[4/3] w-full overflow-hidden rounded-3xl border border-dashed border-slate-300 bg-slate-100 p-6 text-center dark:border-slate-700 dark:bg-slate-900">
                <div className="flex h-full flex-col items-center justify-center gap-2 text-slate-500 dark:text-slate-400">
                  <span className="text-sm font-semibold uppercase tracking-wide">Visual Mockup</span>
                  <p className="text-sm">Lege hero.png unter <code className="rounded bg-slate-200 px-1 py-0.5 dark:bg-slate-800">/public/images/</code> ab.</p>
                  <p className="text-xs">Der Platzhalter wird automatisch ersetzt, sobald die Datei vorhanden ist.</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="bg-white py-20 dark:bg-slate-950">
          <div className="mx-auto max-w-6xl px-6">
            <div className="mx-auto max-w-2xl text-center">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Alles, was moderne Studios brauchen</h2>
              <p className="mt-4 text-lg text-slate-600 dark:text-slate-300">
                Von der Zugangskontrolle bis zur Community – Tap'em bildet die komplette Journey ab.
              </p>
            </div>
            <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
              {featureItems.map((feature) => (
                <article
                  key={feature.title}
                  className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-1 hover:shadow-lg dark:border-slate-800 dark:bg-slate-900"
                >
                  <h3 className="text-xl font-semibold">{feature.title}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-slate-600 dark:text-slate-300">
                    {feature.description}
                  </p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="how-it-works" className="bg-slate-50 py-20 dark:bg-slate-900/60">
          <div className="mx-auto max-w-6xl px-6">
            <div className="mx-auto max-w-2xl text-center">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">So funktioniert Tap'em</h2>
              <p className="mt-4 text-lg text-slate-600 dark:text-slate-300">
                Drei einfache Schritte vom Check-in bis zur nachhaltigen Motivation.
              </p>
            </div>
            <div className="mt-12 grid gap-8 sm:grid-cols-3">
              {steps.map((step) => (
                <article
                  key={step.title}
                  className="flex flex-col items-center rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-sm dark:border-slate-800 dark:bg-slate-950"
                >
                  <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
                    {step.icon}
                  </div>
                  <h3 className="mt-4 text-xl font-semibold">{step.title}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-slate-600 dark:text-slate-300">
                    {step.description}
                  </p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="gallery" className="bg-white py-20 dark:bg-slate-950">
          <div className="mx-auto max-w-6xl px-6">
            <div className="mx-auto max-w-3xl text-center">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Screenshot-Galerie</h2>
              <p className="mt-4 text-lg text-slate-600 dark:text-slate-300">
                Platziere finale Mockups später unter <code className="rounded bg-slate-200 px-1 py-0.5 dark:bg-slate-800">/public/images/</code>.
              </p>
            </div>
            <div className="mt-12 grid gap-8 md:grid-cols-2">
              {galleryItems.map((item) => {
                const exists = imageExists(item.fileName);
                return (
                  <figure
                    key={item.fileName}
                    className="flex flex-col overflow-hidden rounded-3xl border border-dashed border-slate-300 bg-slate-100 shadow-sm dark:border-slate-700 dark:bg-slate-900"
                  >
                    {exists ? (
                      <Image
                        src={`/images/${item.fileName}`}
                        alt={item.title}
                        width={1200}
                        height={800}
                        className="h-64 w-full object-cover"
                        priority
                      />
                    ) : (
                      <div className="flex h-64 w-full flex-col items-center justify-center gap-2 text-slate-500 dark:text-slate-400">
                        <span className="text-sm font-semibold uppercase tracking-wide">Platzhalter</span>
                        <p className="text-sm">Füge {item.fileName} unter /public/images/ hinzu.</p>
                        <p className="text-xs">Hinweis: Keine Bilder im Repo – lokal ergänzen.</p>
                      </div>
                    )}
                    <figcaption className="p-6">
                      <h3 className="text-lg font-semibold">{item.title}</h3>
                      <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{item.description}</p>
                    </figcaption>
                  </figure>
                );
              })}
            </div>
          </div>
        </section>

        <section id="faq" className="bg-slate-50 py-20 dark:bg-slate-900/60">
          <div className="mx-auto max-w-4xl px-6">
            <div className="text-center">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Häufige Fragen</h2>
              <p className="mt-4 text-lg text-slate-600 dark:text-slate-300">
                Transparente Antworten für Studioleitungen und Trainer:innen.
              </p>
            </div>
            <div className="mt-12 space-y-6">
              {faqItems.map((item) => (
                <details
                  key={item.question}
                  className="group rounded-3xl border border-slate-200 bg-white p-6 shadow-sm transition dark:border-slate-800 dark:bg-slate-950"
                >
                  <summary className="flex cursor-pointer list-none items-center justify-between text-left text-lg font-semibold">
                    <span>{item.question}</span>
                    <span className="ml-4 text-primary transition-transform group-open:rotate-45" aria-hidden="true">
                      +
                    </span>
                  </summary>
                  <p className="mt-4 text-sm leading-relaxed text-slate-600 dark:text-slate-300">{item.answer}</p>
                </details>
              ))}
            </div>
          </div>
        </section>

        <section id="contact" className="bg-white py-20 dark:bg-slate-950">
          <div className="mx-auto max-w-3xl rounded-3xl border border-slate-200 bg-slate-50 p-10 text-center dark:border-slate-800 dark:bg-slate-900">
            <h2 className="text-3xl font-bold tracking-tight">Demo anfragen</h2>
            <p className="mt-4 text-lg text-slate-600 dark:text-slate-300">
              Teile uns Studio-Größe, bestehende Systeme und gewünschte Features mit. Wir melden uns mit
              einem individuellen Onboarding-Plan.
            </p>
            <Link
              href="mailto:team@tapem.app"
              className="mt-6 inline-flex items-center justify-center rounded-full bg-secondary px-6 py-3 text-sm font-semibold text-secondary-foreground shadow-lg shadow-secondary/30 transition hover:bg-secondary/90"
            >
              Kontakt aufnehmen
            </Link>
          </div>
        </section>
      </main>

      <footer className="border-t border-slate-200 bg-white py-10 text-sm text-slate-600 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-300">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 md:flex-row">
          <p>&copy; {new Date().getFullYear()} Tap&apos;em. Alle Rechte vorbehalten.</p>
          <div className="flex gap-6">
            <Link href="#" aria-label="Impressum (Platzhalter)">
              Impressum
            </Link>
            <Link href="#" aria-label="Datenschutzerklärung (Platzhalter)">
              Datenschutz
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
