class TimestampMock {
  constructor(date = new Date()) {
    this._date = date instanceof Date ? new Date(date.getTime()) : new Date(date);
  }

  static now() {
    return new TimestampMock(new Date());
  }

  static fromDate(date) {
    return new TimestampMock(date);
  }

  static fromMillis(ms) {
    return new TimestampMock(new Date(ms));
  }

  toDate() {
    return new Date(this._date.getTime());
  }

  toMillis() {
    return this._date.getTime();
  }

  isEqual(other) {
    return other instanceof TimestampMock && other.toMillis() === this.toMillis();
  }
}

class DeleteSentinel {}

function isPlainObject(value) {
  return Object.prototype.toString.call(value) === '[object Object]';
}

function deepClone(value) {
  if (value instanceof TimestampMock) {
    return TimestampMock.fromMillis(value.toMillis());
  }
  if (value instanceof DeleteSentinel) {
    return value;
  }
  if (Array.isArray(value)) {
    return value.map(deepClone);
  }
  if (isPlainObject(value)) {
    const result = {};
    for (const [key, val] of Object.entries(value)) {
      result[key] = deepClone(val);
    }
    return result;
  }
  return value;
}

function applyMerge(target, source) {
  const result = isPlainObject(target) ? deepClone(target) : {};
  for (const [key, value] of Object.entries(source)) {
    if (value instanceof DeleteSentinel) {
      delete result[key];
      continue;
    }
    if (isPlainObject(value)) {
      result[key] = applyMerge(result[key], value);
    } else {
      result[key] = deepClone(value);
    }
  }
  return result;
}

class DocumentSnapshotMock {
  constructor(ref, data) {
    this.ref = ref;
    this.id = ref.id;
    this._data = data === undefined ? undefined : deepClone(data);
    this.exists = data !== undefined;
  }

  data() {
    if (!this.exists) return undefined;
    return deepClone(this._data);
  }
}

class QuerySnapshotMock {
  constructor(docs) {
    this.docs = docs;
    this.size = docs.length;
    this.empty = docs.length === 0;
  }
}

class DocumentReferenceMock {
  constructor(db, pathSegments) {
    this._db = db;
    this._pathSegments = [...pathSegments];
    this.path = this._pathSegments.join('/');
    this.id = this._pathSegments[this._pathSegments.length - 1];
  }

  collection(collectionId) {
    return new CollectionReferenceMock(this._db, [...this._pathSegments, collectionId]);
  }

  async get() {
    const data = this._db._get(this._pathSegments);
    return new DocumentSnapshotMock(this, data);
  }

  async set(data, options = {}) {
    if (options && options.merge) {
      const existing = this._db._get(this._pathSegments) || {};
      this._db._set(this._pathSegments, applyMerge(existing, data));
    } else {
      this._db._set(this._pathSegments, data);
    }
  }

  async update(data) {
    const existing = this._db._get(this._pathSegments);
    if (!existing) {
      throw new Error(`Document ${this.path} does not exist`);
    }
    this._db._set(this._pathSegments, applyMerge(existing, data));
  }

  async delete() {
    this._db._delete(this._pathSegments);
  }

  async listCollections() {
    const prefix = `${this.path}/`;
    const names = new Set();
    for (const key of this._db._store.keys()) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      const remainder = key.slice(prefix.length);
      const segments = remainder.split('/');
      if (segments.length >= 2) {
        names.add(segments[0]);
      }
    }
    return Array.from(names).map(
      (id) => new CollectionReferenceMock(this._db, [...this._pathSegments, id])
    );
  }
}

class CollectionReferenceMock {
  constructor(db, pathSegments) {
    this._db = db;
    this._pathSegments = [...pathSegments];
    this.id = this._pathSegments[this._pathSegments.length - 1];
    this.path = this._pathSegments.join('/');
  }

  doc(id) {
    const segments = [...this._pathSegments, id];
    return new DocumentReferenceMock(this._db, segments);
  }

  async add(data) {
    const id = this._db._autoId();
    const docRef = this.doc(id);
    await docRef.set(data);
    return docRef;
  }

  async get() {
    const docs = this._db._getCollectionDocs(this._pathSegments).map(
      ([segments, data]) => new DocumentSnapshotMock(new DocumentReferenceMock(this._db, segments), data)
    );
    return new QuerySnapshotMock(docs);
  }

  limit(count) {
    const self = this;
    return {
      async get() {
        const snap = await self.get();
        return new QuerySnapshotMock(snap.docs.slice(0, count));
      },
    };
  }
}

class TransactionMock {
  constructor(db) {
    this._db = db;
  }

  async get(ref) {
    return ref.get();
  }

  async set(ref, data, options) {
    return ref.set(data, options);
  }

  async update(ref, data) {
    return ref.update(data);
  }

  async delete(ref) {
    return ref.delete();
  }
}

class FirestoreMock {
  constructor(store) {
    this._store = store;
  }

  collection(collectionId) {
    return new CollectionReferenceMock(this, [collectionId]);
  }

  doc(path) {
    return new DocumentReferenceMock(this, path.split('/'));
  }

  async runTransaction(fn) {
    const tx = new TransactionMock(this);
    return fn(tx);
  }

  _autoId() {
    return Math.random().toString(36).slice(2, 10);
  }

  _key(segments) {
    return segments.join('/');
  }

  _get(segments) {
    const key = this._key(segments);
    const raw = this._store.get(key);
    return raw === undefined ? undefined : deepClone(raw);
  }

  _set(segments, data) {
    const key = this._key(segments);
    const value = deepClone(data);
    this._store.set(key, value);
  }

  _delete(segments) {
    const key = this._key(segments);
    this._store.delete(key);
  }

  _getCollectionDocs(collectionSegments) {
    const results = [];
    const expectedLength = collectionSegments.length + 1;
    for (const [key, value] of this._store.entries()) {
      const segments = key.split('/');
      if (segments.length === expectedLength) {
        let match = true;
        for (let i = 0; i < collectionSegments.length; i += 1) {
          if (segments[i] !== collectionSegments[i]) {
            match = false;
            break;
          }
        }
        if (match) {
          results.push([segments, deepClone(value)]);
        }
      }
    }
    return results;
  }
}

const store = new Map();

const firestoreInstance = new FirestoreMock(store);

function firestore() {
  return firestoreInstance;
}

firestore.FieldValue = {
  serverTimestamp() {
    return TimestampMock.now();
  },
  delete() {
    return new DeleteSentinel();
  },
};

firestore.Timestamp = TimestampMock;

let appInstance = {
  delete: () => Promise.resolve(),
};

function initializeApp() {
  return appInstance;
}

function app() {
  return appInstance;
}

function messaging() {
  return {
    async sendEachForMulticast() {
      return { successCount: 0, failureCount: 0 };
    },
  };
}

function __resetFirestore() {
  store.clear();
}

module.exports = {
  initializeApp,
  app,
  firestore,
  messaging,
  __resetFirestore,
  __setApp(instance) {
    appInstance = instance;
  },
  __TimestampMock: TimestampMock,
  __DeleteSentinel: DeleteSentinel,
};
