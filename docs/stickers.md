# How to Add Stickers to Your App

## Method 1: Using Firebase Console (Recommended)

1. **Open Firebase Console**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project (`tap-em-dev`)

2. **Navigate to Firestore**
   - Click on "Firestore Database" in the left sidebar
   - Click on "Start collection" or navigate to existing collections

3. **Create the `stickers` Collection**
   - Collection ID: `stickers`

4. **Add a Sticker Document**
   - Click "Add document"
   - **Document ID**: Use a unique ID (e.g., `sticker_7`, `custom_sticker_1`)
   - **Fields**:
     - `name` (string): Display name (e.g., "Rocket")
     - `imageUrl` (string): URL to the image (see below for options)
     - `isPremium` (boolean): `false` for free, `true` for premium
     - `sortOrder` (number): Order in picker (e.g., 7, 8, 9...)
     - `createdAt` (timestamp): Click the clock icon and select "Server timestamp"

5. **Save** the document

## Image URL Options

### Option 1: Use Emoji URLs (Quick & Easy)
Use Google's Noto Emoji CDN:
```
https://fonts.gstatic.com/s/e/notoemoji/latest/[EMOJI_CODE]/512.gif
```

Examples:
- Rocket: `https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif`
- Star: `https://fonts.gstatic.com/s/e/notoemoji/latest/2b50/512.gif`
- Trophy: `https://fonts.gstatic.com/s/e/notoemoji/latest/1f3c6/512.gif`

Find emoji codes at: https://unicode.org/emoji/charts/full-emoji-list.html

### Option 2: Upload to Firebase Storage
1. Go to Firebase Console → Storage
2. Upload your image file
3. Click on the uploaded file
4. Copy the "Download URL"
5. Use this URL in the `imageUrl` field

### Option 3: Use External URLs
Any publicly accessible image URL will work.

## Default Stickers to Add

Here are the 6 default stickers you can add manually:

| Document ID | name | imageUrl | isPremium | sortOrder |
|------------|------|----------|-----------|-----------|
| sticker_1 | Thumbs Up | https://fonts.gstatic.com/s/e/notoemoji/latest/1f44d/512.gif | false | 1 |
| sticker_2 | Heart | https://fonts.gstatic.com/s/e/notoemoji/latest/2764_fe0f/512.gif | false | 2 |
| sticker_3 | Fire | https://fonts.gstatic.com/s/e/notoemoji/latest/1f525/512.gif | false | 3 |
| sticker_4 | Muscle | https://fonts.gstatic.com/s/e/notoemoji/latest/1f4aa/512.gif | false | 4 |
| sticker_5 | 100 | https://fonts.gstatic.com/s/e/notoemoji/latest/1f4af/512.gif | false | 5 |
| sticker_6 | Party | https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif | false | 6 |

## Testing

After adding stickers:
1. Restart your app
2. Open a chat
3. Tap the sticker icon
4. Your new stickers should appear in the picker

## Future: Premium Stickers

To implement "earned" stickers later:
- Set `isPremium: true` for premium stickers
- Add logic in the app to check if user has unlocked them
- Filter the sticker list based on user's unlocked stickers
