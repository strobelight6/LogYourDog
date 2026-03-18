# Production Checklist

Items to complete before launching to production.

---

## Firebase

- [ ] Update `.firebaserc` default project alias from `log-your-dog-local` to the real Firebase project ID
- [ ] Deploy Firestore security rules: `firebase deploy --only firestore:rules`
