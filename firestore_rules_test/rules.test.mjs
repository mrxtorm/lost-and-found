import { readFileSync } from 'node:fs';
import { before, after, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const VERSION = '1.0';
const EMAIL = (uid) => `${uid}@school.edu`;

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lost-found',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => env.cleanup());

// Seed: alice/bob = full access. carol = verified, never accepted.
// dave = accepted but UNVERIFIED. erin = verified, accepted an OLD version.
// frank = full access but currently banned from posting.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const accept = (uid, version) =>
      setDoc(doc(db, 'termsAcceptances', `${uid}_${version}`), {
        userId: uid, email: EMAIL(uid), version, acceptedAt: Timestamp.now(),
      });
    await accept('alice', VERSION);
    await accept('bob', VERSION);
    await accept('dave', VERSION);
    await accept('frank', VERSION);
    await accept('erin', '0.9');

    await setDoc(doc(db, 'users', 'frank'), {
      offenseCount: 3,
      bannedUntil: Timestamp.fromMillis(Date.now() + 86_400_000),
    });
    await setDoc(doc(db, 'items', 'item1'), {
      title: 'Phone', ownerId: 'alice', status: 'Found',
    });
    await setDoc(doc(db, 'claims', 'item1_bob'), {
      itemId: 'item1', itemTitle: 'Phone', itemImageUrl: '', claimantId: 'bob',
      claimantName: 'Bob', ownerId: 'alice', answer: 'blue',
      additionalDetails: '', status: 'Pending', createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'conversations', 'c1'), {
      participantIds: ['alice', 'bob'], postId: 'item1', itemName: 'Phone',
      itemImageUrl: '', itemType: 'Found', lastMessage: '',
      lastMessageTime: Timestamp.now(), unreadCounts: {},
    });
    await setDoc(doc(db, 'notifications', 'n1'), {
      recipientId: 'alice', type: 'message', title: 't', message: 'm',
      isRead: false,
    });
  });
});

const as = (uid, verified = true) =>
  env.authenticatedContext(uid, { email: EMAIL(uid), email_verified: verified })
    .firestore();

const newItem = (ownerId) => ({
  title: 'Wallet', ownerId, status: 'Lost', createdAt: serverTimestamp(),
});
const newMessage = (senderId) => ({
  senderId, senderName: senderId, text: 'hi', isRead: false,
  timestamp: serverTimestamp(),
});

// Users that must be BLOCKED from all protected data, and why.
const blocked = {
  'unauthenticated': () => env.unauthenticatedContext().firestore(),
  'verified but never accepted Terms': () => as('carol'),
  'accepted Terms but email NOT verified': () => as('dave', false),
  'verified, accepted only an OLD Terms version': () => as('erin'),
};

describe('access gate blocks protected data', () => {
  for (const [label, db] of Object.entries(blocked)) {
    describe(label, () => {
      it('cannot read items', async () =>
        assertFails(getDoc(doc(db(), 'items', 'item1'))));
      it('cannot create an item', async () =>
        assertFails(setDoc(doc(db(), 'items', 'x'), newItem(label === 'unauthenticated' ? 'x' : 'carol'))));
      it('cannot read a notification addressed to them', async () => {
        await env.withSecurityRulesDisabled((c) =>
          setDoc(doc(c.firestore(), 'notifications', 'n2'),
            { recipientId: 'carol', type: 'message', title: '', message: '', isRead: false }));
        await assertFails(getDoc(doc(db(), 'notifications', 'n2')));
      });
    });
  }

  it('unverified dave (accepted) cannot read his own claim/conversation', async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      const d = c.firestore();
      await setDoc(doc(d, 'claims', 'item1_dave'), {
        itemId: 'item1', itemTitle: 'Phone', itemImageUrl: '', claimantId: 'dave',
        claimantName: 'D', ownerId: 'alice', answer: '', additionalDetails: '',
        status: 'Pending', createdAt: Timestamp.now(),
      });
      await setDoc(doc(d, 'conversations', 'c2'), {
        participantIds: ['alice', 'dave'], postId: 'item1', itemName: 'Phone',
        itemImageUrl: '', itemType: 'Found',
      });
    });
    await assertFails(getDoc(doc(as('dave', false), 'claims', 'item1_dave')));
    await assertFails(getDoc(doc(as('dave', false), 'conversations', 'c2')));
    await assertFails(setDoc(doc(as('dave', false), 'conversations', 'c2', 'messages', 'm'), newMessage('dave')));
  });

  it('cannot submit a claim or report without access', async () => {
    const claim = (uid) => ({
      itemId: 'item1', itemTitle: 'Phone', itemImageUrl: '', claimantId: uid,
      claimantName: uid, ownerId: 'alice', answer: 'x', additionalDetails: '',
      status: 'Pending', createdAt: serverTimestamp(),
    });
    await assertFails(setDoc(doc(as('carol'), 'claims', 'item1_carol'), claim('carol')));
    await assertFails(setDoc(doc(as('dave', false), 'claims', 'item1_dave'), claim('dave')));
    await assertFails(setDoc(doc(as('erin'), 'claims', 'item1_erin'), claim('erin')));

    const report = (uid) => ({
      itemId: 'item1', reporterId: uid, reason: 'spam', details: '',
      status: 'pending', createdAt: serverTimestamp(),
    });
    await assertFails(setDoc(doc(as('dave', false), 'reports', 'item1_dave'), report('dave')));
    await assertSucceeds(setDoc(doc(as('bob'), 'reports', 'item1_bob'), report('bob')));
  });
});

describe('fully authorized users keep existing behavior', () => {
  it('can read items and create their own item', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'items', 'item1')));
    await assertSucceeds(setDoc(doc(as('bob'), 'items', 'new'), newItem('bob')));
  });

  it('cannot create an item for someone else or edit another owner\'s item', async () => {
    await assertFails(setDoc(doc(as('bob'), 'items', 'new'), newItem('alice')));
    await assertFails(updateDoc(doc(as('bob'), 'items', 'item1'), { title: 'Hacked' }));
    await assertFails(deleteDoc(doc(as('bob'), 'items', 'item1')));
    await assertSucceeds(updateDoc(doc(as('alice'), 'items', 'item1'), { title: 'Edited' }));
  });

  it('claims: claimant creates, finder decides, outsiders blocked', async () => {
    const claim = {
      itemId: 'item1', itemTitle: 'Phone', itemImageUrl: '', claimantId: 'alice',
      claimantName: 'A', ownerId: 'alice', answer: 'x', additionalDetails: '',
      status: 'Pending', createdAt: serverTimestamp(),
    };
    await assertFails(setDoc(doc(as('alice'), 'claims', 'item1_alice'), claim)); // own item

    await assertSucceeds(getDoc(doc(as('bob'), 'claims', 'item1_bob')));
    await assertSucceeds(getDoc(doc(as('alice'), 'claims', 'item1_bob')));
    await assertFails(updateDoc(doc(as('bob'), 'claims', 'item1_bob'), { status: 'Approved' }));
    await assertSucceeds(updateDoc(doc(as('alice'), 'claims', 'item1_bob'), { status: 'Approved' }));

    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'claims', 'item1_carol'), {
        itemId: 'item1', claimantId: 'carol', ownerId: 'alice', status: 'Pending',
      }));
    await assertFails(getDoc(doc(as('bob'), 'claims', 'item1_carol'))); // third party
  });

  it('conversations: only participants read/write messages', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'conversations', 'c1')));
    await assertSucceeds(getDocs(query(collection(as('bob'), 'conversations'),
      where('participantIds', 'array-contains', 'bob'))));
    await assertSucceeds(setDoc(doc(as('bob'), 'conversations', 'c1', 'messages', 'm1'), newMessage('bob')));
    await assertSucceeds(getDoc(doc(as('alice'), 'conversations', 'c1', 'messages', 'm1')));
    // participant 'frank' is not in c1
    await assertFails(getDoc(doc(as('frank'), 'conversations', 'c1')));
    await assertFails(getDoc(doc(as('frank'), 'conversations', 'c1', 'messages', 'm1')));
    await assertFails(setDoc(doc(as('frank'), 'conversations', 'c1', 'messages', 'm2'), newMessage('frank')));
    // sender spoofing still blocked
    await assertFails(setDoc(doc(as('bob'), 'conversations', 'c1', 'messages', 'm3'), newMessage('alice')));
  });

  it('notifications: only the recipient reads; only isRead may change', async () => {
    await assertSucceeds(getDoc(doc(as('alice'), 'notifications', 'n1')));
    await assertFails(getDoc(doc(as('bob'), 'notifications', 'n1')));
    await assertSucceeds(updateDoc(doc(as('alice'), 'notifications', 'n1'), { isRead: true }));
    await assertFails(updateDoc(doc(as('alice'), 'notifications', 'n1'), { title: 'x' }));
    // moderation notices cannot be forged by clients
    await assertFails(setDoc(doc(as('bob'), 'notifications', 'fake'), {
      recipientId: 'alice', type: 'moderation_ban', title: '', message: '', isRead: false,
    }));
  });
});

describe('moderation protections are preserved', () => {
  it('a banned user cannot post or edit, but can still delete their own post', async () => {
    await assertFails(setDoc(doc(as('frank'), 'items', 'f1'), newItem('frank')));
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'items', 'f2'), { title: 'x', ownerId: 'frank', status: 'Lost' }));
    await assertFails(updateDoc(doc(as('frank'), 'items', 'f2'), { title: 'y' }));
    await assertSucceeds(deleteDoc(doc(as('frank'), 'items', 'f2')));
  });

  it('users documents: own read only, nobody can write', async () => {
    await assertSucceeds(getDoc(doc(as('frank'), 'users', 'frank')));
    await assertFails(getDoc(doc(as('bob'), 'users', 'frank')));
    await assertFails(setDoc(doc(as('bob'), 'users', 'bob'), { bannedUntil: null }));
    await assertFails(updateDoc(doc(as('frank'), 'users', 'frank'), { bannedUntil: null }));
    // own read must still work before Terms/verification so ban status shows
    await assertSucceeds(getDoc(doc(as('carol'), 'users', 'carol')));
  });

  it('server-only collections stay closed', async () => {
    await assertFails(getDoc(doc(as('alice'), 'moderationLog', 'x')));
    await assertFails(setDoc(doc(as('alice'), 'moderationLog', 'x'), { a: 1 }));
  });
});

describe('termsAcceptances', () => {
  const accept = (uid, over = {}) => ({
    userId: uid, email: EMAIL(uid), version: VERSION,
    acceptedAt: serverTimestamp(), ...over,
  });

  it('a brand-new UNVERIFIED user can record their own acceptance (registration order)', async () => {
    await assertSucceeds(setDoc(doc(as('carol', false), 'termsAcceptances', `carol_${VERSION}`), accept('carol')));
    await assertSucceeds(getDoc(doc(as('carol', false), 'termsAcceptances', `carol_${VERSION}`)));
  });

  it('rejects forged or malformed acceptances', async () => {
    const d = as('carol', false);
    await assertFails(setDoc(doc(d, 'termsAcceptances', `alice_${VERSION}`), accept('alice')));      // for someone else
    await assertFails(setDoc(doc(d, 'termsAcceptances', `carol_${VERSION}`), accept('alice')));      // wrong userId
    await assertFails(setDoc(doc(d, 'termsAcceptances', 'carol_0.9'), accept('carol', { version: '0.9' }))); // old version
    await assertFails(setDoc(doc(d, 'termsAcceptances', `carol_${VERSION}`), accept('carol', { version: '2.0' })));
    await assertFails(setDoc(doc(d, 'termsAcceptances', 'carol_wrongid'), accept('carol')));          // id mismatch
    await assertFails(setDoc(doc(d, 'termsAcceptances', `carol_${VERSION}`), accept('carol', { email: 'x@y.com' })));
    await assertFails(setDoc(doc(d, 'termsAcceptances', `carol_${VERSION}`), accept('carol', { acceptedAt: Timestamp.fromMillis(1) })));
    await assertFails(setDoc(doc(d, 'termsAcceptances', `carol_${VERSION}`), accept('carol', { extra: true })));
  });

  it('records are immutable and private', async () => {
    const a = as('alice');
    await assertSucceeds(getDoc(doc(a, 'termsAcceptances', `alice_${VERSION}`)));
    await assertFails(getDoc(doc(a, 'termsAcceptances', `bob_${VERSION}`)));
    await assertFails(getDocs(collection(a, 'termsAcceptances')));
    await assertFails(updateDoc(doc(a, 'termsAcceptances', `alice_${VERSION}`), { version: '2.0' }));
    await assertFails(deleteDoc(doc(a, 'termsAcceptances', `alice_${VERSION}`)));
  });

  it('an acceptance record does not unlock access without a verified email', async () => {
    await assertFails(getDoc(doc(as('dave', false), 'items', 'item1')));
  });
});
