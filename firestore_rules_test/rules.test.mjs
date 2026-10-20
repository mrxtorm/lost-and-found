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
  deleteField,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
  increment,
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
    await accept('adam', VERSION);
    await setDoc(doc(db, 'admins', 'adam'), { note: 'test admin' });

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
    await setDoc(doc(db, 'conversations', 'c1', 'messages', 'm0'), {
      senderId: 'alice', senderName: 'Alice', text: 'rude words', isRead: false,
      timestamp: Timestamp.now(),
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

const itemReport = (uid, over = {}) => ({
  targetType: 'item', targetId: 'item1', conversationId: '', reporterId: uid,
  reportedUserId: 'alice', reportedUserName: 'Unknown', contentPreview: 'Phone',
  reason: 'fake', details: '', status: 'pending', createdAt: serverTimestamp(),
  ...over,
});
const messageReport = (uid, over = {}) => ({
  targetType: 'message', targetId: 'm0', conversationId: 'c1', reporterId: uid,
  reportedUserId: 'alice', reportedUserName: 'Alice', contentPreview: 'rude words',
  reason: 'harassment', details: 'x', status: 'pending', createdAt: serverTimestamp(),
  ...over,
});
const review = (uid, status, resolution) => ({
  status, resolution, reviewedBy: uid, reviewedAt: serverTimestamp(),
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

    await assertFails(setDoc(doc(as('dave', false), 'reports', 'item_item1_dave'), itemReport('dave')));
    await assertSucceeds(setDoc(doc(as('bob'), 'reports', 'item_item1_bob'), itemReport('bob')));
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

describe('user reports', () => {
  it('a user can report a post once, with verified content', async () => {
    const bob = as('bob');
    await assertSucceeds(setDoc(doc(bob, 'reports', 'item_item1_bob'), itemReport('bob')));
    // same id again = update -> denied (no duplicate reports)
    await assertFails(setDoc(doc(bob, 'reports', 'item_item1_bob'), itemReport('bob')));
    await assertSucceeds(getDoc(doc(bob, 'reports', 'item_item1_bob')));
  });

  it('rejects forged or invalid post reports', async () => {
    const bob = as('bob');
    await assertFails(setDoc(doc(bob, 'reports', 'item_item1_bob'), itemReport('bob', { contentPreview: 'Fake title' })));
    await assertFails(setDoc(doc(bob, 'reports', 'item_item1_bob'), itemReport('bob', { reportedUserId: 'frank' })));
    await assertFails(setDoc(doc(bob, 'reports', 'item_item1_x'), itemReport('bob')));            // id mismatch
    await assertFails(setDoc(doc(bob, 'reports', 'item_item1_bob'), itemReport('bob', { status: 'actioned' })));
    await assertFails(setDoc(doc(bob, 'reports', 'item_item1_bob'), itemReport('bob', { reason: 'nope' })));
    await assertFails(setDoc(doc(bob, 'reports', 'item_item1_bob'), itemReport('bob', { details: 'x'.repeat(301) })));
    // own post
    await assertFails(setDoc(doc(as('alice'), 'reports', 'item_item1_alice'), itemReport('alice')));
  });

  it('a participant can report a message they received; outsiders cannot', async () => {
    await assertSucceeds(setDoc(doc(as('bob'), 'reports', 'message_m0_bob'), messageReport('bob')));
    await assertFails(setDoc(doc(as('frank'), 'reports', 'message_m0_frank'), messageReport('frank')));
    await assertFails(setDoc(doc(as('alice'), 'reports', 'message_m0_alice'), messageReport('alice')));
  });

  it('message reports must quote the real text', async () => {
    await assertFails(setDoc(doc(as('bob'), 'reports', 'message_m0_bob'),
      messageReport('bob', { contentPreview: 'something worse' })));
  });

  it('users cannot read others reports, list all, or review', async () => {
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'reports', 'item_item1_frank'), { ...itemReport('frank'), createdAt: Timestamp.now() }));
    await assertFails(getDoc(doc(as('bob'), 'reports', 'item_item1_frank')));
    await assertFails(getDocs(query(collection(as('bob'), 'reports'), where('status', '==', 'pending'))));
    await assertFails(updateDoc(doc(as('frank'), 'reports', 'item_item1_frank'), review('frank', 'dismissed', 'dismiss')));
  });
});

describe('admin role and moderation', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'reports', 'item_item1_bob'), { ...itemReport('bob'), createdAt: Timestamp.now() }));
  });

  it('users cannot make themselves admins', async () => {
    await assertFails(setDoc(doc(as('bob'), 'admins', 'bob'), { x: 1 }));
    await assertFails(deleteDoc(doc(as('adam'), 'admins', 'adam')));
    await assertSucceeds(getDoc(doc(as('bob'), 'admins', 'bob')));   // "am I admin?" check
    await assertFails(getDoc(doc(as('bob'), 'admins', 'adam')));
    await assertFails(getDocs(collection(as('adam'), 'admins')));
  });

  it('admin can list and review pending reports exactly once', async () => {
    const adam = as('adam');
    await assertSucceeds(getDocs(query(collection(adam, 'reports'), where('status', '==', 'pending'))));
    await assertFails(updateDoc(doc(adam, 'reports', 'item_item1_bob'), review('bob', 'dismissed', 'dismiss')));       // reviewedBy spoof
    await assertFails(updateDoc(doc(adam, 'reports', 'item_item1_bob'), review('adam', 'dismissed', 'remove')));       // inconsistent
    await assertSucceeds(updateDoc(doc(adam, 'reports', 'item_item1_bob'), review('adam', 'dismissed', 'dismiss')));
    await assertFails(updateDoc(doc(adam, 'reports', 'item_item1_bob'), review('adam', 'actioned', 'remove')));        // already reviewed
    await assertFails(deleteDoc(doc(adam, 'reports', 'item_item1_bob')));
  });

  it('admin powers require the access gate too', async () => {
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), 'admins', 'dave'), {}));
    await assertFails(getDocs(query(collection(as('dave', false), 'reports'), where('status', '==', 'pending'))));
  });

  it('admin can delete any post; regular users still cannot', async () => {
    await assertFails(deleteDoc(doc(as('bob'), 'items', 'item1')));
    await assertSucceeds(deleteDoc(doc(as('adam'), 'items', 'item1')));
  });

  it('admin can blank a reported message but cannot read messages', async () => {
    const adam = as('adam');
    const msg = doc(adam, 'conversations', 'c1', 'messages', 'm0');
    const removed = 'This message was removed by an admin.';
    await assertFails(getDoc(msg));
    await assertFails(getDoc(doc(adam, 'conversations', 'c1')));
    await assertFails(updateDoc(msg, { text: 'anything else', removedByAdmin: true }));
    await assertFails(updateDoc(msg, { text: removed, removedByAdmin: true, senderId: 'adam' }));
    await assertSucceeds(updateDoc(msg, { text: removed, removedByAdmin: true }));
    // a non-admin cannot do the same
    await assertFails(updateDoc(doc(as('bob'), 'conversations', 'c1', 'messages', 'm0'),
      { text: removed, removedByAdmin: true }));
  });

  it('admin can suspend another user from posting; users cannot', async () => {
    const until = Timestamp.fromMillis(Date.now() + 7 * 86_400_000);
    await assertSucceeds(setDoc(doc(as('adam'), 'users', 'bob'), { offenseCount: 1, bannedUntil: until }, { merge: true }));
    await assertFails(setDoc(doc(as('adam'), 'users', 'bob'),
      { offenseCount: 1, bannedUntil: Timestamp.fromMillis(Date.now() + 365 * 86_400_000) }, { merge: true }));
    await assertFails(setDoc(doc(as('adam'), 'users', 'bob'), { role: 'admin' }, { merge: true }));
    await assertFails(setDoc(doc(as('alice'), 'users', 'bob'), { offenseCount: 1, bannedUntil: until }, { merge: true }));
    // the suspension is enforced by the existing posting-ban rule
    await assertFails(setDoc(doc(as('bob'), 'items', 'b1'), newItem('bob')));
  });

  it('only admins can send moderation notices', async () => {
    const notice = { recipientId: 'alice', type: 'moderation_removed', title: '', message: '', isRead: false };
    await assertFails(setDoc(doc(as('bob'), 'notifications', 'x1'), notice));
    await assertSucceeds(setDoc(doc(as('adam'), 'notifications', 'x2'), notice));
  });

  it('moderation log: admin append-only, invisible to users', async () => {
    const entry = {
      adminId: 'adam', adminEmail: 'adam@school.edu', action: 'remove', targetType: 'item',
      targetId: 'item1', reportedUserId: 'alice', reportedUserName: 'Unknown',
      contentPreview: 'Phone', reasons: ['fake'], reportCount: 1, reportIds: ['item_item1_bob'],
      note: '', createdAt: serverTimestamp(),
    };
    await assertSucceeds(setDoc(doc(as('adam'), 'moderationLog', 'l1'), entry));
    await assertSucceeds(getDoc(doc(as('adam'), 'moderationLog', 'l1')));
    await assertFails(setDoc(doc(as('adam'), 'moderationLog', 'l2'), { ...entry, adminId: 'bob' }));
    await assertFails(updateDoc(doc(as('adam'), 'moderationLog', 'l1'), { note: 'edited' }));
    await assertFails(deleteDoc(doc(as('adam'), 'moderationLog', 'l1')));
    await assertFails(getDoc(doc(as('bob'), 'moderationLog', 'l1')));
    await assertFails(setDoc(doc(as('bob'), 'moderationLog', 'l3'), { ...entry, adminId: 'bob' }));
  });
});

describe('profile rename propagates to old activity', () => {
  it('owner can rename themselves on their post, even while banned', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'items', 'item1'), { username: 'Alice B' }));
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'items', 'fitem'), { title: 'Bag', ownerId: 'frank', status: 'Lost', username: 'Frank' }));
    await assertSucceeds(updateDoc(doc(as('frank'), 'items', 'fitem'), { username: 'Frankie' }));
    await assertFails(updateDoc(doc(as('frank'), 'items', 'fitem'), { username: 'F', title: 'Changed' }));
    await assertFails(updateDoc(doc(as('frank'), 'items', 'fitem'), { username: '' }));
    await assertSucceeds(updateDoc(doc(as('frank'), 'items', 'fitem'), { username: 'Frankie', ownerPhotoUrl: 'https://res.cloudinary.com/x.jpg' }));
    await assertSucceeds(updateDoc(doc(as('frank'), 'items', 'fitem'), { ownerPhotoUrl: '' }));
    await assertFails(updateDoc(doc(as('frank'), 'items', 'fitem'), { ownerPhotoUrl: 'x'.repeat(1001) }));
    await assertFails(updateDoc(doc(as('bob'), 'items', 'item1'), { username: 'Bob' }));
  });

  it('claimant can rename themselves on their claim only', async () => {
    await assertSucceeds(updateDoc(doc(as('bob'), 'claims', 'item1_bob'), { claimantName: 'Robert' }));
    await assertFails(updateDoc(doc(as('bob'), 'claims', 'item1_bob'), { claimantName: 'Robert', status: 'Approved' }));
    await assertFails(updateDoc(doc(as('alice'), 'claims', 'item1_bob'), { claimantName: 'Fake' }));
  });

  it('participant can change only their own participantNames entry', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'conversations', 'c1'), { 'participantNames.alice': 'Alice B' }));
    await assertFails(updateDoc(doc(as('alice'), 'conversations', 'c1'), { 'participantNames.bob': 'Not Bob' }));
    await assertFails(updateDoc(doc(as('alice'), 'conversations', 'c1'), { 'participantNames.alice': 'A', itemName: 'X' }));
    await assertFails(updateDoc(doc(as('carol'), 'conversations', 'c1'), { 'participantNames.carol': 'Carol' }));
  });

  it('sender can rename themselves on their own messages only', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'conversations', 'c1', 'messages', 'm0'), { senderName: 'Alice B' }));
    await assertFails(updateDoc(doc(as('alice'), 'conversations', 'c1', 'messages', 'm0'), { senderName: 'A', text: 'edited' }));
    await assertFails(updateDoc(doc(as('bob'), 'conversations', 'c1', 'messages', 'm0'), { senderName: 'Bob' }));
  });

  it('the rename queries the app runs are allowed', async () => {
    await assertSucceeds(getDocs(query(collection(as('bob'), 'claims'), where('claimantId', '==', 'bob'))));
    await assertSucceeds(getDocs(query(collection(as('alice'), 'conversations', 'c1', 'messages'), where('senderId', '==', 'alice'))));
  });
});

describe('claimed posts (archive)', () => {
  const claimLost = (finder = 'bob', over = {}) => ({
    status: 'Claimed', claimedFrom: 'Lost', claimedBy: finder,
    claimedByName: 'Bob', claimedAt: serverTimestamp(), ...over,
  });
  const lostReturn = (over = {}) => ({
    itemId: 'lost1', itemTitle: 'Wallet', ownerId: 'bob', claimantId: 'alice',
    completedAt: serverTimestamp(), ...over,
  });

  beforeEach(async () => {
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'items', 'lost1'), {
        title: 'Wallet', ownerId: 'alice', status: 'Lost',
      }));
  });

  it('the owner can mark a Lost post claimed and undo it', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'items', 'lost1'), claimLost()));
    await assertSucceeds(updateDoc(doc(as('alice'), 'items', 'lost1'), {
      status: 'Lost', claimedFrom: deleteField(), claimedBy: deleteField(),
      claimedByName: deleteField(), claimedAt: deleteField(),
    }));
  });

  it('marking claimed without naming anyone is allowed', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'items', 'lost1'),
      claimLost('', { claimedByName: '' })));
  });

  it('rejects bad claim changes', async () => {
    // someone else's post
    await assertFails(updateDoc(doc(as('bob'), 'items', 'lost1'), claimLost()));
    // wrong origin status
    await assertFails(updateDoc(doc(as('alice'), 'items', 'lost1'),
      claimLost('bob', { claimedFrom: 'Found' })));
    // crediting yourself
    await assertFails(updateDoc(doc(as('alice'), 'items', 'lost1'), claimLost('alice')));
    // claim fields without the status change
    await assertFails(updateDoc(doc(as('alice'), 'items', 'lost1'), { claimedBy: 'bob' }));

    await updateDoc(doc(as('alice'), 'items', 'lost1'), claimLost());
    // undo to a different status than it came from
    await assertFails(updateDoc(doc(as('alice'), 'items', 'lost1'), {
      status: 'Found', claimedFrom: deleteField(), claimedBy: deleteField(),
      claimedByName: deleteField(), claimedAt: deleteField(),
    }));
    // undo that leaves claim fields behind
    await assertFails(updateDoc(doc(as('alice'), 'items', 'lost1'), { status: 'Lost' }));
    // re-pointing the claim at someone else
    await assertFails(updateDoc(doc(as('alice'), 'items', 'lost1'), { claimedBy: 'frank' }));
  });

  it('the finder can archive a Found post after approving the claim', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'items', 'item1'), {
      status: 'Claimed', claimedFrom: 'Found', claimedBy: 'bob',
      claimedByName: 'Bob', claimedAt: serverTimestamp(),
    }));
  });

  it('a banned owner can still close and reopen a claim', async () => {
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'items', 'frank1'), {
        title: 'Keys', ownerId: 'frank', status: 'Lost',
      }));
    await assertSucceeds(updateDoc(doc(as('frank'), 'items', 'frank1'), claimLost()));
    await assertFails(updateDoc(doc(as('frank'), 'items', 'frank1'), { title: 'x' }));
  });

  it('a Lost post owner records the return only for the credited finder', async () => {
    // not claimed yet
    await assertFails(setDoc(doc(as('alice'), 'completedReturns', 'lost1_bob'), lostReturn()));

    await updateDoc(doc(as('alice'), 'items', 'lost1'), claimLost());
    // wrong finder
    await assertFails(setDoc(doc(as('alice'), 'completedReturns', 'lost1_frank'),
      lostReturn({ ownerId: 'frank' })));
    // someone other than the post owner
    await assertFails(setDoc(doc(as('bob'), 'completedReturns', 'lost1_bob'),
      lostReturn({ claimantId: 'bob' })));
    await assertSucceeds(setDoc(doc(as('alice'), 'completedReturns', 'lost1_bob'), lostReturn()));

    // both sides can then leave feedback with the usual roles
    const feedback = (uid, role, other) => ({
      returnId: 'lost1_bob', itemTitle: 'Wallet', authorId: uid, role,
      otherUserId: other, rating: 5, recommendation: '', createdAt: serverTimestamp(),
    });
    await assertSucceeds(setDoc(doc(as('bob'), 'feedback', 'lost1_bob_bob'),
      feedback('bob', 'finder', 'alice')));
    await assertSucceeds(setDoc(doc(as('alice'), 'feedback', 'lost1_bob_alice'),
      feedback('alice', 'claimant', 'bob')));
  });
});

describe('feedback visibility', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'feedback', 'item1_bob_bob'), {
        returnId: 'item1_bob', itemTitle: 'Phone', authorId: 'bob', role: 'claimant',
        otherUserId: 'alice', rating: 5, recommendation: 'great', createdAt: Timestamp.now(),
      }));
  });

  it('admins can list and read all feedback', async () => {
    await assertSucceeds(getDocs(collection(as('adam'), 'feedback')));
    await assertSucceeds(getDoc(doc(as('adam'), 'feedback', 'item1_bob_bob')));
  });

  it('users only see their own feedback and cannot list', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'feedback', 'item1_bob_bob')));
    await assertFails(getDoc(doc(as('alice'), 'feedback', 'item1_bob_bob')));
    await assertFails(getDocs(collection(as('bob'), 'feedback')));
  });

  it('admins still cannot edit or delete feedback', async () => {
    await assertFails(updateDoc(doc(as('adam'), 'feedback', 'item1_bob_bob'), { rating: 1 }));
    await assertFails(deleteDoc(doc(as('adam'), 'feedback', 'item1_bob_bob')));
  });
});

describe('undo of admin decisions', () => {
  const REMOVED = 'This message was removed by an admin.';
  const ITEM = { title: 'Phone', ownerId: 'alice', status: 'Found' };
  const logEntry = (over = {}) => ({
    adminId: 'adam', adminEmail: 'adam@school.edu', action: 'remove', targetType: 'item',
    targetId: 'item1', reportedUserId: 'alice', reportedUserName: 'Unknown',
    contentPreview: 'Phone', reasons: ['fake'], reportCount: 1, reportIds: ['item_item1_bob'],
    note: '', createdAt: serverTimestamp(), ...over,
  });
  const backupBase = (type, id, cid = '') => ({
    targetType: type, targetId: id, conversationId: cid,
    removedBy: 'adam', removedAt: serverTimestamp(),
  });

  beforeEach(async () => {
    await env.withSecurityRulesDisabled((c) =>
      setDoc(doc(c.firestore(), 'reports', 'item_item1_bob'), { ...itemReport('bob'), createdAt: Timestamp.now() }));
  });

  // Same writes AdminService.resolve() sends for "remove post".
  const removeItem = (db, backupItem = ITEM) => {
    const b = writeBatch(db);
    b.set(doc(db, 'removedContent', 'item_item1'), { ...backupBase('item', 'item1'), item: backupItem });
    b.delete(doc(db, 'items', 'item1'));
    b.update(doc(db, 'reports', 'item_item1_bob'),
      { status: 'actioned', resolution: 'remove', reviewedBy: 'adam', reviewedAt: serverTimestamp() });
    b.set(doc(db, 'moderationLog', 'l1'), logEntry());
    return b.commit();
  };

  // Same writes AdminService.undo() sends for that decision.
  const undoItem = (db, restored = ITEM) => {
    const b = writeBatch(db);
    b.set(doc(db, 'items', 'item1'), restored);
    b.delete(doc(db, 'removedContent', 'item_item1'));
    b.update(doc(db, 'reports', 'item_item1_bob'),
      { status: 'pending', resolution: 'undone', reviewedBy: 'adam', reviewedAt: serverTimestamp() });
    b.set(doc(db, 'moderationLog', 'undo_l1'), logEntry({ action: 'undo', undoOf: 'l1' }));
    return b.commit();
  };

  it('removing a post saves a verified copy; a forged copy is rejected', async () => {
    await assertFails(removeItem(as('adam'), { ...ITEM, title: 'Something else' }));
    await assertSucceeds(removeItem(as('adam')));
    await assertFails(getDoc(doc(as('bob'), 'removedContent', 'item_item1')));
  });

  it('undo restores the exact post, re-queues reports, and only once', async () => {
    const adam = as('adam');
    await assertSucceeds(removeItem(adam));
    await assertFails(undoItem(adam, { ...ITEM, title: 'Tampered' }));   // must match the copy
    await assertSucceeds(undoItem(adam));
    const restored = await getDoc(doc(adam, 'items', 'item1'));
    if (restored.data().title !== 'Phone') throw new Error('item not restored');
    const report = await getDoc(doc(adam, 'reports', 'item_item1_bob'));
    if (report.data().status !== 'pending') throw new Error('report not re-queued');
    // second undo of the same decision is impossible (log is create-only)
    await assertFails(setDoc(doc(adam, 'moderationLog', 'undo_l1'), logEntry({ action: 'undo', undoOf: 'l1' })));
  });

  it('undo entries must point at a real, non-undo decision with the right id', async () => {
    const adam = as('adam');
    await assertSucceeds(removeItem(adam));
    await assertFails(setDoc(doc(adam, 'moderationLog', 'undo_x'), logEntry({ action: 'undo', undoOf: 'l1' })));
    await assertFails(setDoc(doc(adam, 'moderationLog', 'undo_nope'), logEntry({ action: 'undo', undoOf: 'nope' })));
    await assertSucceeds(undoItem(adam));
    await assertFails(setDoc(doc(adam, 'moderationLog', 'undo_undo_l1'), logEntry({ action: 'undo', undoOf: 'undo_l1' })));
    await assertFails(setDoc(doc(adam, 'moderationLog', 'l9'), logEntry({ undoOf: 'l1' })));   // undoOf only on undo
  });

  it('non-admins cannot restore posts or re-queue reports', async () => {
    await assertSucceeds(removeItem(as('adam')));
    await assertFails(setDoc(doc(as('bob'), 'items', 'item1'), ITEM));
    await assertFails(updateDoc(doc(as('bob'), 'reports', 'item_item1_bob'),
      { status: 'pending', resolution: 'undone', reviewedBy: 'bob', reviewedAt: serverTimestamp() }));
  });

  it('message removal and undo bring back the original text only', async () => {
    const adam = as('adam');
    const msg = doc(adam, 'conversations', 'c1', 'messages', 'm0');
    const backup = doc(adam, 'removedContent', 'message_m0');

    // forged backup text rejected
    let b = writeBatch(adam);
    b.set(backup, { ...backupBase('message', 'm0', 'c1'), text: 'made up' });
    b.update(msg, { text: REMOVED, removedByAdmin: true });
    await assertFails(b.commit());

    b = writeBatch(adam);
    b.set(backup, { ...backupBase('message', 'm0', 'c1'), text: 'rude words' });
    b.update(msg, { text: REMOVED, removedByAdmin: true });
    await assertSucceeds(b.commit());

    // restoring different text is rejected; the saved original works
    await assertFails(updateDoc(msg, { text: 'nicer words', removedByAdmin: false }));
    b = writeBatch(adam);
    b.update(msg, { text: 'rude words', removedByAdmin: false });
    b.delete(backup);
    await assertSucceeds(b.commit());

    // participants can read it again
    const back = await getDoc(doc(as('bob'), 'conversations', 'c1', 'messages', 'm0'));
    if (back.data().text !== 'rude words') throw new Error('message not restored');
  });

  it('undo can lift a suspension', async () => {
    const adam = as('adam');
    await assertSucceeds(setDoc(doc(adam, 'users', 'bob'),
      { offenseCount: 1, bannedUntil: Timestamp.fromMillis(Date.now() + 7 * 86_400_000) }, { merge: true }));
    await assertFails(setDoc(doc(as('bob'), 'items', 'b1'), newItem('bob')));
    await assertSucceeds(setDoc(doc(adam, 'users', 'bob'),
      { offenseCount: increment(-1), bannedUntil: serverTimestamp() }, { merge: true }));
    await assertSucceeds(setDoc(doc(as('bob'), 'items', 'b1'), newItem('bob')));
  });

  it('only admins can send "restored" notices', async () => {
    const notice = { recipientId: 'alice', type: 'moderation_restored', title: '', message: '', isRead: false };
    await assertFails(setDoc(doc(as('bob'), 'notifications', 'r1'), notice));
    await assertSucceeds(setDoc(doc(as('adam'), 'notifications', 'r2'), notice));
  });
});

describe('suspended users (admin view + unban)', () => {
  const until = () => Timestamp.fromMillis(Date.now() + 7 * 86_400_000);
  const unbanLog = (over = {}) => ({
    adminId: 'adam', adminEmail: 'adam@school.edu', action: 'unban', targetType: 'user',
    targetId: 'frank', reportedUserId: 'frank', reportedUserName: 'Frank',
    contentPreview: 'Posting suspension lifted early', reasons: [], reportCount: 0,
    reportIds: [], note: '', createdAt: serverTimestamp(), ...over,
  });

  it('admins can list suspended users; regular users cannot', async () => {
    const q = (db) => query(collection(db, 'users'), where('bannedUntil', '>', Timestamp.now()));
    await assertSucceeds(getDocs(q(as('adam'))));
    await assertSucceeds(getDoc(doc(as('adam'), 'users', 'frank')));
    await assertFails(getDocs(q(as('bob'))));
    await assertFails(getDoc(doc(as('bob'), 'users', 'frank')));
  });

  it('suspending can record name/admin/time, but not someone else as suspender', async () => {
    const adam = as('adam');
    await assertSucceeds(setDoc(doc(adam, 'users', 'bob'), {
      offenseCount: 1, bannedUntil: until(), displayName: 'Bob',
      suspendedBy: 'adam', suspendedAt: serverTimestamp(),
    }, { merge: true }));
    await assertFails(setDoc(doc(adam, 'users', 'alice'), {
      offenseCount: 1, bannedUntil: until(), displayName: 'Alice', suspendedBy: 'bob',
    }, { merge: true }));
    await assertFails(setDoc(doc(adam, 'users', 'alice'), {
      offenseCount: 1, bannedUntil: until(), displayName: 'x'.repeat(101),
    }, { merge: true }));
  });

  it('an admin can lift a suspension; the user can post again', async () => {
    await assertFails(setDoc(doc(as('frank'), 'items', 'f9'), newItem('frank')));
    const adam = as('adam');
    const b = writeBatch(adam);
    b.update(doc(adam, 'users', 'frank'), { bannedUntil: Timestamp.fromMillis(0) });   // as AdminService does
    b.set(doc(adam, 'moderationLog', 'u1'), unbanLog());
    await assertSucceeds(b.commit());
    await assertSucceeds(setDoc(doc(as('frank'), 'items', 'f9'), newItem('frank')));
  });

  it('users cannot lift their own or others\' suspensions', async () => {
    await assertFails(updateDoc(doc(as('frank'), 'users', 'frank'), { bannedUntil: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('bob'), 'users', 'frank'), { bannedUntil: serverTimestamp() }));
  });

  it('unban log entries are validated and cannot be undone', async () => {
    const adam = as('adam');
    await assertFails(setDoc(doc(adam, 'moderationLog', 'u2'), unbanLog({ targetId: 'bob' })));
    await assertFails(setDoc(doc(adam, 'moderationLog', 'u3'), unbanLog({ targetType: 'item' })));
    await assertSucceeds(setDoc(doc(adam, 'moderationLog', 'u4'), unbanLog()));
    await assertFails(setDoc(doc(adam, 'moderationLog', 'undo_u4'), unbanLog({
      action: 'undo', undoOf: 'u4', targetType: 'item',
    })));
  });
});
