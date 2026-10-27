// Firestore security rules tests, run against the local emulator:
//   npm --prefix test_rules test
// Covers post privacy (I-2), the queries the feeds rely on, @usernames (U-4),
// private emails (U-5) and Smart Wardrobe items (I-1).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-banigoba',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

const as = (uid) => env.authenticatedContext(uid).firestore();

// tariro posts. rudo is her friend (mutual follow); farai follows her one
// way; zoe is a stranger.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const post = (id, visibility) =>
      setDoc(doc(db, 'posts', id), {
        authorId: 'tariro',
        authorID: 'tariro',
        visibility,
        isPublic: visibility === 'public',
        caption: id,
      });
    await post('private', 'private');
    await post('friends', 'friends');
    await post('followers', 'followers');
    await post('public', 'public');
    await setDoc(doc(db, 'posts/legacy'), { authorId: 'tariro', isPublic: true });
    await setDoc(doc(db, 'posts/friends/comments/c1'), { userId: 'rudo', text: 'Yes!' });
    // rudo <-> tariro follow each other; farai follows tariro.
    await setDoc(doc(db, 'users/tariro/followers/rudo'), {});
    await setDoc(doc(db, 'users/tariro/following/rudo'), {});
    await setDoc(doc(db, 'users/rudo/followers/tariro'), {});
    await setDoc(doc(db, 'users/rudo/following/tariro'), {});
    await setDoc(doc(db, 'users/tariro/followers/farai'), {});
    await setDoc(doc(db, 'users/farai/following/tariro'), {});
  });
});

describe('reading a post', () => {
  test('the author reads every one of her posts', async () => {
    for (const id of ['private', 'friends', 'followers', 'public']) {
      await assertSucceeds(getDoc(doc(as('tariro'), 'posts', id)));
    }
  });

  test('a stranger reads only public posts', async () => {
    const db = as('zoe');
    await assertSucceeds(getDoc(doc(db, 'posts/public')));
    await assertSucceeds(getDoc(doc(db, 'posts/legacy')));
    await assertFails(getDoc(doc(db, 'posts/followers')));
    await assertFails(getDoc(doc(db, 'posts/friends')));
    await assertFails(getDoc(doc(db, 'posts/private')));
  });

  test('a one-way follower reads followers posts but not friends ones', async () => {
    const db = as('farai');
    await assertSucceeds(getDoc(doc(db, 'posts/followers')));
    await assertFails(getDoc(doc(db, 'posts/friends')));
    await assertFails(getDoc(doc(db, 'posts/private')));
  });

  test('a friend reads friends and followers posts, never private ones', async () => {
    const db = as('rudo');
    await assertSucceeds(getDoc(doc(db, 'posts/friends')));
    await assertSucceeds(getDoc(doc(db, 'posts/followers')));
    await assertFails(getDoc(doc(db, 'posts/private')));
  });

  test('signed-out visitors read nothing', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'posts/public')));
  });

  test('comments are as private as their post', async () => {
    await assertSucceeds(getDocs(collection(as('rudo'), 'posts/friends/comments')));
    await assertFails(getDocs(collection(as('zoe'), 'posts/friends/comments')));
  });
});

describe('the queries the feeds make', () => {
  const posts = (db) => collection(db, 'posts');

  test('listing the whole collection is refused', async () => {
    await assertFails(getDocs(posts(as('zoe'))));
  });

  test('my own posts, by authorId', async () => {
    const db = as('tariro');
    await assertSucceeds(getDocs(query(posts(db), where('authorId', '==', 'tariro'))));
  });

  test('someone else\'s posts by authorId alone are refused', async () => {
    const db = as('zoe');
    await assertFails(getDocs(query(posts(db), where('authorId', '==', 'tariro'))));
  });

  test('public posts, by visibility', async () => {
    const db = as('zoe');
    const snap = await assertSucceeds(
      getDocs(query(posts(db), where('visibility', '==', 'public'))),
    );
    if (snap.size !== 1) throw new Error(`expected 1 public post, got ${snap.size}`);
    await assertSucceeds(getDocs(query(posts(db), where('isPublic', '==', true))));
  });

  test('followers posts of someone I follow', async () => {
    const q = (db) =>
      query(posts(db), where('authorId', '==', 'tariro'), where('visibility', '==', 'followers'));
    await assertSucceeds(getDocs(q(as('farai'))));
    await assertFails(getDocs(q(as('zoe'))));
  });

  test('friends posts of a friend', async () => {
    const q = (db) =>
      query(posts(db), where('authorId', '==', 'tariro'), where('visibility', '==', 'friends'));
    await assertSucceeds(getDocs(q(as('rudo'))));
    await assertFails(getDocs(q(as('farai'))));
  });
});

describe('@usernames', () => {
  const claim = (uid, name) => {
    const db = as(uid);
    const batch = writeBatch(db);
    batch.set(doc(db, 'usernames', name), { uid });
    batch.set(doc(db, 'users', uid), { username: name }, { merge: true });
    return batch.commit();
  };

  test('a user claims a free name with their user record', async () => {
    await assertSucceeds(claim('tariro', 'tariro.m'));
  });

  test('a taken name cannot be claimed by someone else', async () => {
    await claim('tariro', 'tariro.m');
    await assertFails(claim('zoe', 'tariro.m'));
  });

  test('a name cannot be set on the user record without holding it', async () => {
    await assertFails(setDoc(doc(as('zoe'), 'users/zoe'), { username: 'tariro.m' }));
  });

  test('a lookup cannot be created for another user', async () => {
    await assertFails(setDoc(doc(as('zoe'), 'usernames/x.y'), { uid: 'tariro' }));
  });
});

describe('private account details', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled((context) =>
      setDoc(doc(context.firestore(), 'users/tariro/private/account'), {
        email: 'tariro@example.com',
      }),
    );
  });

  test('only the owner reads her email', async () => {
    await assertSucceeds(getDoc(doc(as('tariro'), 'users/tariro/private/account')));
    await assertFails(getDoc(doc(as('zoe'), 'users/tariro/private/account')));
  });

  test('an email lookup can be read by exact key but not listed', async () => {
    await env.withSecurityRulesDisabled((context) =>
      setDoc(doc(context.firestore(), 'emailLookup/somehash'), { uid: 'tariro' }),
    );
    await assertSucceeds(getDoc(doc(as('zoe'), 'emailLookup/somehash')));
    await assertFails(getDocs(collection(as('zoe'), 'emailLookup')));
    await assertFails(setDoc(doc(as('zoe'), 'emailLookup/other'), { uid: 'tariro' }));
    await assertSucceeds(setDoc(doc(as('zoe'), 'emailLookup/mine'), { uid: 'zoe' }));
  });
});

describe('Smart Wardrobe items', () => {
  test('owners list their own items; others cannot write them', async () => {
    await assertSucceeds(
      setDoc(doc(as('tariro'), 'user_products/p1'), { userId: 'tariro', visibility: 'private' }),
    );
    await assertSucceeds(
      getDocs(query(collection(as('tariro'), 'user_products'), where('userId', '==', 'tariro'))),
    );
    await assertFails(getDoc(doc(as('zoe'), 'user_products/p1')));
    await assertFails(deleteDoc(doc(as('zoe'), 'user_products/p1')));
  });
});

describe('user records cannot grant privileges', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/curator'), { role: 'admin', isAdmin: true });
      await setDoc(doc(db, 'users/zoe'), {
        displayName: 'Zoe',
        role: 'user',
        shop: { name: 'Zoe Boutique', verified: false },
      });
    });
  });

  test('a user edits her own profile', async () => {
    await assertSucceeds(
      setDoc(doc(as('zoe'), 'users/zoe'), { displayName: 'Zoe M' }, { merge: true }),
    );
  });

  test('a user cannot make herself an admin', async () => {
    const db = as('zoe');
    await assertFails(setDoc(doc(db, 'users/zoe'), { isAdmin: true }, { merge: true }));
    await assertFails(setDoc(doc(db, 'users/zoe'), { role: 'admin' }, { merge: true }));
  });

  test('a new user cannot start as an admin', async () => {
    await assertFails(setDoc(doc(as('newbie'), 'users/newbie'), { role: 'admin' }));
    await assertSucceeds(setDoc(doc(as('newbie'), 'users/newbie'), { role: 'user' }));
  });

  test('a user cannot verify her own shop', async () => {
    await assertFails(
      setDoc(doc(as('zoe'), 'users/zoe'), { shop: { name: 'Zoe Boutique', verified: true } }, { merge: true }),
    );
  });

  test('a curator verifies a shop, and only that', async () => {
    const db = as('curator');
    await assertSucceeds(
      setDoc(doc(db, 'users/zoe'), { shop: { name: 'Zoe Boutique', verified: true } }, { merge: true }),
    );
    await assertFails(setDoc(doc(db, 'users/zoe'), { displayName: 'Hacked' }, { merge: true }));
  });

  test('a user\'s private subcollections stay theirs', async () => {
    await assertSucceeds(setDoc(doc(as('zoe'), 'users/zoe/cart/item1'), { qty: 1 }));
    await assertFails(getDoc(doc(as('tariro'), 'users/zoe/cart/item1')));
  });
});

describe('moving the email off the public profile (sign-in)', () => {
  test('the owner moves her email in one batch', async () => {
    await env.withSecurityRulesDisabled((context) =>
      setDoc(doc(context.firestore(), 'users/tariro'), {
        displayName: 'Tariro',
        email: 'tariro@example.com',
      }),
    );
    const db = as('tariro');
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/tariro/private/account'), { email: 'tariro@example.com' }, { merge: true });
    batch.set(doc(db, 'emailLookup/hash-of-tariro'), { uid: 'tariro' });
    batch.set(doc(db, 'users/tariro'), { displayName: 'Tariro', email: null }, { merge: true });
    await assertSucceeds(batch.commit());
  });
});
