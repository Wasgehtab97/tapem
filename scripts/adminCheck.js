// adminCheck.js
const admin = require('firebase-admin');
const serviceAccount = require('./24_05_gym02.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // optional, falls nötig:
  // projectId: 'dein-firebase-projekt-id',
});

const uid = '3IK8kmaZfpX7ec1fng744H2px5y1';
admin.auth().getUser(uid)
  .then(userRec => {
    console.log('Custom Claims:', userRec.customClaims);
  })
  .catch(console.error);
