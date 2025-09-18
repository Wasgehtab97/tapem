import { ImageResponse } from 'next/og';

export const size = {
  width: 1200,
  height: 630,
};

export const contentType = 'image/png';

const baseFont = '"Segoe UI", "Helvetica Neue", Arial, "Noto Sans", sans-serif';

export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          width: '100%',
          height: '100%',
          padding: '80px',
          background: 'radial-gradient(circle at 20% 20%, #1e293b 0%, #0f172a 45%, #020617 100%)',
          color: '#f8fafc',
        }}
      >
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 24,
            maxWidth: '760px',
          }}
        >
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              padding: '8px 16px',
              borderRadius: '9999px',
              background: 'rgba(148, 163, 184, 0.15)',
              color: '#cbd5f5',
              fontSize: 24,
              fontWeight: 600,
              letterSpacing: 2,
              textTransform: 'uppercase',
              fontFamily: baseFont,
            }}
          >
            NFC-Ready Platform
          </div>

          <h1
            style={{
              fontFamily: baseFont,
              fontSize: 96,
              fontWeight: 700,
              lineHeight: 1.05,
              letterSpacing: -1.5,
            }}
          >
            Tap&apos;em
          </h1>

          <p
            style={{
              fontFamily: baseFont,
              fontSize: 42,
              fontWeight: 500,
              color: '#e2e8f0',
              lineHeight: 1.3,
            }}
          >
            NFC-basiertes Gym-Tracking &amp; -Management
          </p>
        </div>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            fontFamily: baseFont,
            fontSize: 28,
            color: '#cbd5f5',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 16,
            }}
          >
            <div
              style={{
                width: 16,
                height: 16,
                borderRadius: '50%',
                background: '#38bdf8',
                boxShadow: '0 0 40px rgba(56, 189, 248, 0.65)',
              }}
            />
            <span>tapem.app</span>
          </div>
          <div
            style={{
              width: 240,
              height: 2,
              background: 'linear-gradient(90deg, rgba(56,189,248,0) 0%, rgba(56,189,248,0.8) 50%, rgba(56,189,248,0) 100%)',
            }}
          />
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
