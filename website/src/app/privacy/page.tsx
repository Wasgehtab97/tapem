import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Datenschutzerklärung | Tap'em",
  description:
    "Platzhalter-Datenschutzerklärung für Tap'em. Bitte finale Inhalte und Rechtsgrundlagen ergänzen.",
};

export default function PrivacyPage() {
  return (
    <main className="bg-white text-slate-900 dark:bg-slate-950 dark:text-slate-100">
      <article className="mx-auto flex min-h-screen max-w-3xl flex-col gap-10 px-6 py-16 lg:px-8">
        <header className="space-y-4" aria-labelledby="privacy-heading">
          <p
            role="note"
            className="rounded-lg border border-amber-400 bg-amber-50 px-4 py-3 text-sm font-medium text-amber-800 dark:border-amber-500/60 dark:bg-amber-500/10 dark:text-amber-200"
          >
            Platzhaltertext – bitte final prüfen/ersetzen.
          </p>
          <h1 id="privacy-heading" className="text-3xl font-bold tracking-tight sm:text-4xl">
            Datenschutzerklärung
          </h1>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Dieser Text dient als Vorlage. Ergänze konkrete Datenverarbeitungen, Dienstleister und Rechtsgrundlagen, um eine
            vollständige Datenschutzinformation nach Art. 13/14 DSGVO bereitzustellen.
          </p>
        </header>

        <section aria-labelledby="controller-heading" className="space-y-3">
          <h2 id="controller-heading" className="text-2xl font-semibold">
            Verantwortlicher
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Tap&apos;em GmbH (Platzhalter), Musterstraße 1, 12345 Berlin, Deutschland
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Trage hier die finale Anschrift, Telefon- und E-Mail-Kontaktdaten des Verantwortlichen ein.
          </p>
        </section>

        <section aria-labelledby="purpose-heading" className="space-y-3">
          <h2 id="purpose-heading" className="text-2xl font-semibold">
            Zwecke und Rechtsgrundlagen der Verarbeitung
          </h2>
          <div className="space-y-3 text-base leading-relaxed text-slate-600 dark:text-slate-300">
            <p>
              Wir verarbeiten personenbezogene Daten, um unsere Website bereitzustellen, Anfragen zu beantworten und das
              Nutzungsverhalten zu analysieren (Platzhalter).
            </p>
            <p>
              Die Rechtsgrundlagen ergeben sich insbesondere aus Art. 6 Abs. 1 lit. a, b und f DSGVO (Platzhalter).
            </p>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Ergänze konkrete Prozesse, Datenkategorien sowie Rechtsgrundlagen.
          </p>
        </section>

        <section aria-labelledby="hosting-heading" className="space-y-3">
          <h2 id="hosting-heading" className="text-2xl font-semibold">
            Hosting &amp; Content Delivery Networks (CDN)
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Diese Website wird bei Vercel Inc. (Platzhalter) gehostet. Der Dienstleister verarbeitet IP-Adressen und weitere
            technische Daten, um den Webseitenzugriff zu ermöglichen.
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Ergänze den tatsächlichen Hoster, Standorte der Server und ggf. Vereinbarungen zur Auftragsverarbeitung.
          </p>
        </section>

        <section aria-labelledby="logfiles-heading" className="space-y-3">
          <h2 id="logfiles-heading" className="text-2xl font-semibold">
            Server-Logfiles
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Bei jedem Zugriff werden Server-Logfiles (z.&nbsp;B. IP-Adresse, Zeitpunkt, User Agent) gespeichert, um die
            Systemsicherheit sicherzustellen (Platzhalter). Die Daten werden nach kurzer Zeit gelöscht.
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Gib konkrete Speicherfristen und Log-Umfänge an.
          </p>
        </section>

        <section aria-labelledby="cookies-heading" className="space-y-3">
          <h2 id="cookies-heading" className="text-2xl font-semibold">
            Cookies &amp; Consent-Management (TODO)
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Beschreibe hier verwendete Cookies, Speicherdauer und das eingesetzte Consent-Tool. Dieser Abschnitt muss vor dem
            Produktivgang finalisiert werden (Platzhalter).
          </p>
        </section>

        <section aria-labelledby="analytics-heading" className="space-y-3">
          <h2 id="analytics-heading" className="text-2xl font-semibold">
            Analytik &amp; Tracking (TODO)
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Trage hier genutzte Analyse-Dienste (z.&nbsp;B. Vercel Analytics, Plausible, Matomo) mit Rechtsgrundlagen, Speicherdauer
            und Opt-out-Möglichkeiten ein (Platzhalter).
          </p>
        </section>

        <section aria-labelledby="rights-heading" className="space-y-3">
          <h2 id="rights-heading" className="text-2xl font-semibold">
            Rechte der betroffenen Personen
          </h2>
          <div className="space-y-3 text-base leading-relaxed text-slate-600 dark:text-slate-300">
            <p>
              Betroffene haben das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit
              sowie Widerspruch gegen bestimmte Verarbeitungen (Platzhalter).
            </p>
            <p>
              Zudem besteht ein Beschwerderecht bei einer Aufsichtsbehörde, etwa bei der Berliner Beauftragten für Datenschutz und
              Informationsfreiheit (Platzhalter).
            </p>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Ergänze Kontaktdaten der zuständigen Aufsichtsbehörde.
          </p>
        </section>

        <section aria-labelledby="contact-section-heading" className="space-y-3">
          <h2 id="contact-section-heading" className="text-2xl font-semibold">
            Kontakt für Datenschutzanfragen
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Bitte richte Datenschutzanfragen an datenschutz@tapem.app oder schriftlich an die oben genannte Adresse (Platzhalter).
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Benenne hier die verbindliche Kontaktadresse und ggf. den Datenschutzbeauftragten.
          </p>
        </section>
      </article>
    </main>
  );
}
