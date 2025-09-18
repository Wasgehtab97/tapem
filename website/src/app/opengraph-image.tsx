// website/src/app/opengraph-image.tsx
import { ImageResponse } from 'next/og';

export const runtime = 'edge'; // optional, gut für @vercel/og
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',                 // <— KEIN inline-flex
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          background: '#0b0b0b',
          color: '#ffffff',
          padding: 64,
          fontSize: 72,
          lineHeight: 1.2,
          // nur System-Fonts verwenden (keine externen Fonts laden)
          fontFamily:
            'ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial',
        }}
      >
        <div style={{ fontWeight: 700 }}>Tap’em</div>
        <div style={{ fontSize: 36, opacity: 0.95, marginTop: 16, textAlign: 'center' }}>
          NFC-basiertes Gym-Tracking &amp; -Management
        </div>
        <div style={{ fontSize: 28, opacity: 0.7, marginTop: 36 }}>tapem.app</div>
      </div>
    ),
    { width: size.width, height: size.height }
  );
}
