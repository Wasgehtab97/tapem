// adminCheck.js
const admin = require('firebase-admin');
const serviceAccount = require('./admin.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // optional, falls nötig:
  // projectId: 'dein-firebase-projekt-id',
});

const uid = 'BdEMGJkrE6MjGC9i3uH909MKCim1';
admin.auth().getUser(uid)
  .then(userRec => {
    console.log('Custom Claims:', userRec.customClaims);
  })
  .catch(console.error);
