# Anleitung: Default Stickers hinzufügen

Da die automatischen Scripts nicht funktionieren, füge die Sticker bitte manuell über die Firebase Console hinzu:

## Schritt 1: Firebase Console öffnen
1. Gehe zu: https://console.firebase.google.com/
2. Wähle das Projekt **tap-em-dev**
3. Klicke links auf **Firestore Database**

## Schritt 2: Stickers Collection erstellen
1. Klicke auf **Start collection** (falls noch keine Collections existieren)
   ODER klicke auf **+ Start collection** oben
2. Collection ID: **stickers**
3. Klicke **Next**

## Schritt 3: Sticker 1 - Thumbs Up 👍
- **Document ID**: `sticker_1`
- Felder hinzufügen:
  - `name` (string): `Thumbs Up`
  - `imageUrl` (string): `https://fonts.gstatic.com/s/e/notoemoji/latest/1f44d/512.gif`
  - `isPremium` (boolean): `false`
  - `sortOrder` (number): `1`
- **Save** klicken

## Schritt 4: Sticker 2 - Heart ❤️
- Klicke auf **Add document** in der stickers Collection
- **Document ID**: `sticker_2`
- Felder:
  - `name` (string): `Heart`
  - `imageUrl` (string): `https://fonts.gstatic.com/s/e/notoemoji/latest/2764_fe0f/512.gif`
  - `isPremium` (boolean): `false`
  - `sortOrder` (number): `2`
- **Save**

## Schritt 5: Sticker 3 - Fire 🔥
- **Add document**
- **Document ID**: `sticker_3`
- Felder:
  - `name` (string): `Fire`
  - `imageUrl` (string): `https://fonts.gstatic.com/s/e/notoemoji/latest/1f525/512.gif`
  - `isPremium` (boolean): `false`
  - `sortOrder` (number): `3`
- **Save**

## Schritt 6: Sticker 4 - Muscle 💪
- **Add document**
- **Document ID**: `sticker_4`
- Felder:
  - `name` (string): `Muscle`
  - `imageUrl` (string): `https://fonts.gstatic.com/s/e/notoemoji/latest/1f4aa/512.gif`
  - `isPremium` (boolean): `false`
  - `sortOrder` (number): `4`
- **Save**

## Schritt 7: Sticker 5 - 100 💯
- **Add document**
- **Document ID**: `sticker_5`
- Felder:
  - `name` (string): `100`
  - `imageUrl` (string): `https://fonts.gstatic.com/s/e/notoemoji/latest/1f4af/512.gif`
  - `isPremium` (boolean): `false`
  - `sortOrder` (number): `5`
- **Save**

## Schritt 8: Sticker 6 - Party 🎉
- **Add document**
- **Document ID**: `sticker_6`
- Felder:
  - `name` (string): `Party`
  - `imageUrl` (string): `https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif`
  - `isPremium` (boolean): `false`
  - `sortOrder` (number): `6`
- **Save**

## Fertig! ✅
Nach dem Hinzufügen aller 6 Sticker:
1. Starte die App neu
2. Öffne einen Chat
3. Tippe auf das Sticker-Icon
4. Alle 6 Default-Stickers sollten erscheinen!

---

**Tipp**: Du kannst auch Copy-Paste verwenden:
- Klicke auf einen Sticker → **Duplicate** → Ändere nur die ID, name, imageUrl und sortOrder
