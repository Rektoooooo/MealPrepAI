/**
 * Minimal firebase-admin mock for test scripts.
 * Prevents any real Firebase connections.
 */

const noopFirestore = {
  collection: () => noopFirestore,
  doc: () => noopFirestore,
  get: async () => ({ exists: false, data: () => null }),
  set: async () => {},
  update: async () => {},
  delete: async () => {},
  where: () => noopFirestore,
  orderBy: () => noopFirestore,
  limit: () => noopFirestore,
  batch: () => ({
    set: () => {},
    update: () => {},
    delete: () => {},
    commit: async () => {},
  }),
  runTransaction: async (fn: any) =>
    fn({
      get: async () => ({ exists: false, data: () => null }),
      set: () => {},
      update: () => {},
    }),
};

const firestoreFn = () => noopFirestore;

firestoreFn.Timestamp = {
  now: () => ({ toDate: () => new Date() }),
  fromDate: (d: Date) => ({ toDate: () => d }),
};
firestoreFn.FieldValue = {
  increment: (n: number) => n,
  serverTimestamp: () => new Date(),
  arrayUnion: (...args: any[]) => args,
  arrayRemove: (...args: any[]) => args,
};

const admin = {
  initializeApp: () => {},
  firestore: firestoreFn,
  appCheck: () => ({
    verifyToken: async () => ({ appId: 'test' }),
  }),
  auth: () => ({
    verifyIdToken: async () => ({ uid: 'test-user' }),
  }),
};

export = admin;
