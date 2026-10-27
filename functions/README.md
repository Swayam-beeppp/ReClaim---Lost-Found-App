# Firebase Push Functions

This function sends FCM push notifications whenever a new document is created in `Notifications/{id}`.

## Deploy

1. Install deps:
   - `cd functions`
   - `npm install`
2. From project root:
   - `firebase login`
   - `firebase use re-claim`
   - `firebase deploy --only functions`

## How it routes notifications

- If `targetUserId` exists in notification doc: sends to topic `user_<uid>`.
- Else if `collegeCode` exists: sends to topic `college_<code>`.

The Flutter app subscribes users to these topics automatically at startup/login.
