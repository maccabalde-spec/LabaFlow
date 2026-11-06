import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore, type Transaction} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

initializeApp();
const db = getFirestore();

async function allocateUserId(transaction: Transaction): Promise<number> {
  const counterRef = db.collection("metadata").doc("counters");
  const counter = await transaction.get(counterRef);
  const latest = await transaction.get(db.collection("users").orderBy("id", "desc").limit(1));
  const previous = Math.max(
    Number(counter.get("userId") ?? 0),
    Number(latest.docs[0]?.get("id") ?? 0),
  );
  const id = previous + 1;
  transaction.set(counterRef, {userId: id}, {merge: true});
  return id;
}

async function requireStaff(uid: string): Promise<"ADMIN" | "SELLER"> {
  const profile = await db.collection("users").doc(uid).get();
  const role = profile.get("role");
  if (role !== "ADMIN" && role !== "SELLER") {
    throw new HttpsError("permission-denied", "Staff access is required.");
  }
  return role;
}

export const ensureUserProfile = onCall({region: "us-central1"}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const uid = request.auth.uid;
  const ref = db.collection("users").doc(uid);
  const existing = await ref.get();
  if (existing.exists) return {uid, id: existing.get("id")};

  const name = String(request.data?.name ?? request.auth.token.name ?? "Customer").trim().slice(0, 100);
  const phone = String(request.data?.phone ?? "").trim().slice(0, 24);
  if (name.length < 2) throw new HttpsError("invalid-argument", "Enter your name.");
  let id = 0;
  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(ref);
    if (current.exists) {
      id = current.get("id") as number;
      return;
    }
    id = await allocateUserId(transaction);
    transaction.create(ref, {
      id,
      name,
      email: String(request.auth!.token.email ?? "").toLowerCase(),
      phone,
      role: "CUSTOMER",
      points: 0,
      photoUrl: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return {uid, id};
});

export const inviteUser = onCall({region: "us-central1"}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  if (await requireStaff(request.auth.uid) !== "ADMIN") {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }
  const name = String(request.data?.name ?? "").trim().slice(0, 100);
  const email = String(request.data?.email ?? "").trim().toLowerCase();
  const phone = String(request.data?.phone ?? "").trim().slice(0, 24);
  const role = String(request.data?.role ?? "CUSTOMER").toUpperCase();
  const password = String(request.data?.password ?? "");
  if (name.length < 2 || !email.includes("@") || password.length < 12) {
    throw new HttpsError("invalid-argument", "Check the name, email, and 12-character temporary password.");
  }
  if (role !== "SELLER" && role !== "CUSTOMER" && role !== "ADMIN") {
    throw new HttpsError("invalid-argument", "Choose a valid account role.");
  }

  const created = await getAuth().createUser({email, password, displayName: name});
  const ref = db.collection("users").doc(created.uid);
  let id = 0;
  try {
    await db.runTransaction(async (transaction) => {
      id = await allocateUserId(transaction);
      transaction.create(ref, {
        id, name, email, phone, role, points: 0, photoUrl: null,
        createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
      });
    });
  } catch (error) {
    await getAuth().deleteUser(created.uid);
    throw error;
  }
  return {uid: created.uid, id};
});

export const updateUserAccount = onCall({region: "us-central1"}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  if (await requireStaff(request.auth.uid) !== "ADMIN") {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }
  const uid = String(request.data?.uid ?? "");
  const name = String(request.data?.name ?? "").trim().slice(0, 100);
  const email = String(request.data?.email ?? "").trim().toLowerCase();
  const phone = String(request.data?.phone ?? "").trim().slice(0, 24);
  const role = String(request.data?.role ?? "CUSTOMER").toUpperCase();
  const password = request.data?.password == null ? undefined : String(request.data.password);
  const photoUrl = request.data?.photoUrl == null ? null : String(request.data.photoUrl).slice(0, 750000);
  if (!uid || name.length < 2 || !email.includes("@") || !["ADMIN", "SELLER", "CUSTOMER"].includes(role)) {
    throw new HttpsError("invalid-argument", "Check the user details.");
  }
  if (uid === request.auth.uid && role !== "ADMIN") {
    throw new HttpsError("failed-precondition", "You cannot remove your own administrator access.");
  }
  if (password !== undefined && password.length < 12) {
    throw new HttpsError("invalid-argument", "Use a password with at least 12 characters.");
  }
  const target = db.collection("users").doc(uid);
  const profile = await target.get();
  if (!profile.exists) throw new HttpsError("not-found", "User profile not found.");
  await getAuth().updateUser(uid, {
    email,
    displayName: name,
    ...(password === undefined ? {} : {password}),
  });
  await target.update({name, email, phone, role, photoUrl, updatedAt: FieldValue.serverTimestamp()});
  return {updated: true};
});

export const deleteUser = onCall({region: "us-central1"}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  if (await requireStaff(request.auth.uid) !== "ADMIN") {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }
  const uid = String(request.data?.uid ?? "");
  if (!uid || uid === request.auth.uid) throw new HttpsError("invalid-argument", "Choose another account.");
  const profileRef = db.collection("users").doc(uid);
  const profile = await profileRef.get();
  if (!profile.exists || profile.get("role") === "ADMIN") {
    throw new HttpsError("failed-precondition", "This account cannot be deleted here.");
  }
  for (const subcollection of ["devices", "notifications"]) {
    const items = await profileRef.collection(subcollection).get();
    for (let start = 0; start < items.docs.length; start += 450) {
      const batch = db.batch();
      for (const item of items.docs.slice(start, start + 450)) batch.delete(item.ref);
      await batch.commit();
    }
  }
  await getAuth().deleteUser(uid);
  await profileRef.delete();
  return {deleted: true};
});

export const sendUserNotification = onCall({region: "us-central1"}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const uid = String(request.data?.recipientUid ?? "");
  const type = String(request.data?.type ?? "GENERAL").slice(0, 40);
  const title = String(request.data?.title ?? "").trim().slice(0, 100);
  const body = String(request.data?.body ?? "").trim().slice(0, 500);
  const icon = String(request.data?.icon ?? "🔔").slice(0, 8);
  if (!uid || !title || !body) throw new HttpsError("invalid-argument", "A recipient, title, and message are required.");
  let callerRole = "CUSTOMER";
  if (uid !== request.auth.uid || type !== "ORDER_PLACED") {
    callerRole = await requireStaff(request.auth.uid);
  }
  const recipient = await db.collection("users").doc(uid).get();
  if (!recipient.exists) throw new HttpsError("not-found", "Notification recipient not found.");
  await db.collection("users").doc(uid).collection("notifications").add({
    type, title, body, icon, read: false,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: request.auth.uid,
    senderRole: callerRole,
  });
  return {queued: true};
});

export const grantLoyaltyPoints = onCall({region: "us-central1"}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  await requireStaff(request.auth.uid);
  const uid = String(request.data?.recipientUid ?? "");
  const amount = Number(request.data?.amount ?? 0);
  if (!uid || !Number.isFinite(amount) || amount <= 0 || amount > 100000) {
    throw new HttpsError("invalid-argument", "A valid points amount is required.");
  }
  const profile = db.collection("users").doc(uid);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(profile);
    if (!snapshot.exists) throw new HttpsError("not-found", "Customer profile not found.");
    transaction.update(profile, {points: FieldValue.increment(Math.floor(amount))});
  });
  return {points: Math.floor(amount)};
});

export const deliverUserNotification = onDocumentCreated(
  {document: "users/{uid}/notifications/{notificationId}", region: "us-central1"},
  async (event) => {
    const notification = event.data?.data();
    if (!notification) return;
    const uid = event.params.uid;
    const devices = await db.collection("users").doc(uid).collection("devices").get();
    const tokens = devices.docs.map((doc) => ({id: doc.id, token: String(doc.get("token") ?? "")}))
      .filter((device) => device.token.length > 0);
    for (let start = 0; start < tokens.length; start += 500) {
      const chunk = tokens.slice(start, start + 500);
      const result = await getMessaging().sendEachForMulticast({
        tokens: chunk.map((device) => device.token),
        notification: {title: String(notification.title), body: String(notification.body)},
        data: {
          notificationId: event.params.notificationId,
          type: String(notification.type ?? "GENERAL"),
        },
        android: {priority: "high", notification: {channelId: "labaflow_updates"}},
        apns: {payload: {aps: {sound: "default", badge: 1}}},
      });
      const batch = db.batch();
      let shouldCommit = false;
      result.responses.forEach((response, index) => {
        if (!response.success && ["messaging/registration-token-not-registered", "messaging/invalid-registration-token"]
          .includes(response.error?.code ?? "")) {
          batch.delete(db.collection("users").doc(uid).collection("devices").doc(chunk[index].id));
          shouldCommit = true;
        }
      });
      if (shouldCommit) await batch.commit();
    }
  },
);
