# Marketplace Rules & Arbitration Spec

This is a product rules document, not final legal terms.

## 1. Core rule

The SDR is paid for a **qualified attended meeting**, not for:
- a reply;
- a contact;
- a calendar invite alone;
- subjective interest;
- a proposal request;
- a future sale.

## 2. Criteria precedence

When deciding a dispute:

1. structured hard criteria saved at prospect registration time;
2. meeting event rules;
3. platform-wide rules;
4. evidence;
5. soft campaign notes are informative only.

A business cannot retrospectively change criteria for an already registered prospect.

## 3. Qualification

Qualification should be determined mostly before the meeting.

A prospect fails qualification only when an explicit hard criterion is violated.

Examples:
- revenue below minimum;
- company in excluded industry;
- person does not hold allowed role;
- geography excluded;
- company explicitly excluded;
- active CRM opportunity existed before registration under the campaign rule.

«Не наш клиент», «не понравился», «нет бюджета» are not valid reasons unless the bounty explicitly made the relevant fact a pre-meeting hard criterion that can be objectively verified.

## 4. Existing CRM

Recommended definition:

No payout if before SDR prospect registration:
- the exact company/contact was an open sales opportunity;
OR
- there was documented substantive sales communication in the previous X days.

Merely existing somewhere in CRM as an old/contact record should not automatically invalidate.

For MVP choose:
`active opportunity OR meaningful outbound/inbound conversation in previous 90 days`.

Business must prove timestamp.

## 5. Duplicate

Priority:
1. earliest valid APPROVED registration;
2. active ownership window;
3. if expired, new SDR may register.

## 6. Evidence hierarchy

Strong:
- calendar attendance metadata;
- meeting recording with consent;
- video platform attendance log;
- emails from corporate domain confirming meeting;
- calendar invite acceptance;
- business CRM timestamp export;
- provider logs.

Medium:
- screenshots with visible timestamps;
- correspondence.

Weak:
- plain written statement without evidence.

## 7. Review window

24 hours after scheduled meeting end.

No dispute within window → automatic acceptance.

Admin can reopen only for clear fraud/security reasons.

## 8. Fraud

Immediate manual review can be triggered by:
- fabricated identity;
- collusion;
- repeated recycling of contacts;
- manipulated evidence;
- account farming;
- chargeback abuse;
- prohibited outreach behavior.

## 9. Bounty changes

Changes to hard criteria create a new bounty version.

Existing registered prospects are adjudicated against the version active at their registration time.

Store:
- bounty_version;
- criteria_snapshot JSON in prospect/meeting.

This is critical.

## 10. Recommended future automation

At meeting creation store a machine-readable `qualification_snapshot`:
- bounty id/version;
- company facts;
- contact facts;
- hard-rule checks;
- timestamps.

Then dispute UI can show:
`8/8 hard criteria passed at registration`.

## 11. Video calls — later

Own video is not necessary for proof.

Before building a Telemost-like system, integrate external meeting providers/calendar data where possible.

The valuable product is **proof + workflow**, not WebRTC itself.

Later an internal meeting room can add:
- attendance events;
- consented recording;
- transcription;
- AI summary;
- automatic show verification.

Build only after meeting volume justifies it.
