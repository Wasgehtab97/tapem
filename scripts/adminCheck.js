// adminCheck.js
const admin = require('firebase-admin');
const serviceAccount = require('./23_05.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // optional, falls nötig:
  // projectId: 'dein-firebase-projekt-id',
});

const uid = '80l73ay9uiW82pckh1f6EwWwIcO2';
admin.auth().getUser(uid)
  .then(userRec => {
    console.log('Custom Claims:', userRec.customClaims);
  })
  .catch(console.error);
