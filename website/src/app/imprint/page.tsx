import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Impressum | Tap'em",
  description:
    "Platzhalter-Impressum für Tap'em. Bitte finale rechtliche Angaben ergänzen und prüfen.",
};

export default function ImprintPage() {
  return (
    <article className="mx-auto flex w-full max-w-3xl flex-col gap-10 px-6 py-16 lg:px-8">
        <header className="space-y-4" aria-labelledby="imprint-heading">
          <p
            role="note"
            className="rounded-lg border border-amber-400 bg-amber-50 px-4 py-3 text-sm font-medium text-amber-800 dark:border-amber-500/60 dark:bg-amber-500/10 dark:text-amber-200"
          >
            Platzhaltertext – keine Rechtsberatung; bitte final prüfen/ersetzen.
          </p>
          <h1 id="imprint-heading" className="text-3xl font-bold tracking-tight sm:text-4xl">
            Impressum
          </h1>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Dieses Impressum stellt eine Platzhalter-Vorlage dar. Ergänze hier die verbindlichen Angaben
            gemäß § 5 TMG und § 55 RStV.
          </p>
        </header>

        <section aria-labelledby="provider-heading" className="space-y-3">
          <h2 id="provider-heading" className="text-2xl font-semibold">
            Anbieter
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Tap&apos;em GmbH (Platzhalter)<br />
            Musterstraße 1<br />
            12345 Berlin<br />
            Deutschland
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Ersetze Firmierung, Anschrift und Rechtsform mit den tatsächlichen Angaben.
          </p>
        </section>

        <section aria-labelledby="contact-heading" className="space-y-3">
          <h2 id="contact-heading" className="text-2xl font-semibold">
            Kontakt
          </h2>
          <div className="space-y-1 text-base leading-relaxed text-slate-600 dark:text-slate-300">
            <p>Telefon: +49 (0)30 000000 (Platzhalter)</p>
            <p>E-Mail: team@tapem.app (Platzhalter)</p>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Gib hier die verbindlichen Kontaktwege an, z.&nbsp;B. Telefon und eine funktionsfähige E-Mail-Adresse.
          </p>
        </section>

        <section aria-labelledby="representation-heading" className="space-y-3">
          <h2 id="representation-heading" className="text-2xl font-semibold">
            Vertretungsberechtigt
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Geschäftsführer: Max Mustermann (Platzhalter)
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Trage die vertretungsberechtigten Personen laut Handelsregister ein.
          </p>
        </section>

        <section aria-labelledby="vat-heading" className="space-y-3">
          <h2 id="vat-heading" className="text-2xl font-semibold">
            USt-ID
          </h2>
          <p className="text-base leading-relaxed text-slate-600 dark:text-slate-300">
            Umsatzsteuer-Identifikationsnummer gemäß § 27 a UStG: DE000000000 (Platzhalter)
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Ergänze die gültige USt-ID. Falls keine vorhanden ist, kennzeichne dies entsprechend.
          </p>
        </section>

        <section aria-labelledby="liability-heading" className="space-y-3">
          <h2 id="liability-heading" className="text-2xl font-semibold">
            Haftungshinweise
          </h2>
          <div className="space-y-3 text-base leading-relaxed text-slate-600 dark:text-slate-300">
            <p>
              Die Inhalte dieser Website wurden mit größtmöglicher Sorgfalt erstellt. Dennoch kann für die Richtigkeit,
              Vollständigkeit und Aktualität der Inhalte keine Gewähr übernommen werden (Platzhalter).
            </p>
            <p>
              Für Inhalte externer Links übernehmen wir keine Haftung. Für den Inhalt verlinkter Seiten sind ausschließlich
              deren Betreiber verantwortlich (Platzhalter).
            </p>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Ergänze hier individuelle Haftungs- und Urheberrechtshinweise entsprechend deiner finalen Fassung.
          </p>
        </section>
    </article>
  );
}
