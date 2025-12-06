# Sticker als lokale Assets hinzufügen (100% kostenlos)

Diese Methode funktioniert **komplett ohne Firebase Storage** und ist **100% kostenlos**.

## Schritt 1: Bild vorbereiten

1. Speichere dein White Monster Bild als `white_monster.png` (oder `.jpg`)
2. Kopiere die Datei in diesen Ordner:
   ```
   /Users/daniel/Projekte/tapem/assets/stickers/white_monster.png
   ```

## Schritt 2: In Firestore eintragen

1. Gehe zu [Firebase Console](https://console.firebase.google.com/)
2. Wähle dein Projekt **tap-em** (Production)
3. Öffne **Firestore Database**
4. Navigiere zu `stickers` → `sticker_07` (oder erstelle ein neues Dokument)
5. Setze die Felder:

| Feld | Wert |
|------|------|
| `name` | `White Monster` |
| `imageUrl` | `asset://assets/stickers/white_monster.png` |
| `isPremium` | `false` |
| `sortOrder` | `7` |

**Wichtig**: Die URL **muss** mit `asset://` beginnen!

6. Klicke **Save** oder **Update**

## Schritt 3: App neu bauen

Da wir neue Assets hinzugefügt haben, muss die App neu gebaut werden:

```bash
flutter clean
flutter pub get
flutter run
```

## Schritt 4: Testen

1. Öffne einen Chat
2. Tippe auf das Sticker-Icon
3. Dein White Monster Sticker sollte erscheinen! 🎉

## Vorteile dieser Methode

✅ **100% kostenlos** - Keine Firebase Storage Kosten
✅ **Funktioniert offline** - Bilder sind in der App gebündelt
✅ **Schneller** - Keine Netzwerk-Anfragen nötig
✅ **Zuverlässig** - Keine externen Abhängigkeiten

## Weitere Sticker hinzufügen

Für jeden neuen Sticker:
1. Bild in `/assets/stickers/` speichern
2. Neues Dokument in Firestore `stickers` Collection erstellen
3. `imageUrl` mit `asset://assets/stickers/DEINBILD.png` setzen
4. App neu bauen mit `flutter clean && flutter pub get && flutter run`

## Hinweis

Die Bilder werden in die App eingebaut, was die App-Größe leicht erhöht. Für normale Sticker-Bilder (z.B. 50-100 KB pro Sticker) ist das aber kein Problem.
