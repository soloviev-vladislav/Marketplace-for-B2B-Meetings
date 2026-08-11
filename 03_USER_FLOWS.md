# User Flows

## Flow A — Business onboarding

1. User signs up.
2. Selects `Business`.
3. Adds:
   - legal name;
   - INN;
   - website;
   - corporate email/domain.
4. Status = PENDING.
5. Admin verifies.
6. Status = ACTIVE.

MVP: admin can create businesses manually to reduce onboarding complexity.

---

## Flow B — Create bounty

1. Business/admin creates draft.
2. Inputs commercial fields.
3. Completes structured ICP.
4. Adds meeting acceptance rules.
5. Adds sales context/materials.
6. Submits to moderation.
7. Admin:
   - checks ambiguity;
   - normalizes titles/industries;
   - marks hard vs soft rules;
   - approves.
8. Bounty = ACTIVE.
9. Telegram notification may be posted.

For initial concierge MVP:
**only admin creates/publishes bounty after interview with business.**

---

## Flow C — SDR onboarding

1. Sign up.
2. Choose SDR.
3. Add display name and optional bio/specialties.
4. Verify email.
5. Accept platform agreement.
6. Browse bounties.

Keep friction low until first payout.

---

## Flow D — Take bounty

1. SDR opens bounty card.
2. Sees public preview.
3. Clicks `Take bounty`.
4. Full sales brief becomes available.
5. Bounty added to `My Work`.

No account ownership is created yet.

---

## Flow E — Register prospect

1. SDR clicks `Register prospect`.
2. Enters company INN/domain + contact identity.
3. Backend normalizes email/domain/INN.
4. Checks:
   - bounty active;
   - no protected duplicate;
   - quota not exhausted.
5. Prospect stored.
6. Admin or automated rules validate basic ICP.
7. Prospect `APPROVED` or `REJECTED`.
8. If approved, ownership window starts.

Important:
Do not reveal prospect identity to business before funding requirement is satisfied if that would allow bypass.

---

## Flow F — Submit booked meeting

1. SDR selects approved prospect.
2. Adds scheduled date/time and meeting URL.
3. Meeting status = SUBMITTED.
4. Platform checks bounty funding.
5. If one reward + platform fee secured:
   - SECURED;
   - meeting details released according to policy.
6. Otherwise:
   - AWAITING_DEPOSIT;
   - business notified.
7. Business funds.
8. Meeting = SCHEDULED.

---

## Flow G — Meeting result

At scheduled_at:
- meeting remains SCHEDULED.

After expected meeting end:
- status → AWAITING_RESULT;
- review_deadline = +24h;
- business gets notification.

Business:
### Accept
→ ACCEPTED
→ ledger releases reward to SDR
→ platform fee recognized
→ PAYOUT_DUE

### Dispute
→ DISPUTED
→ choose reason
→ evidence required
→ funds remain held

### No action
At deadline:
→ auto ACCEPTED.

---

## Flow H — Dispute

1. Business opens dispute within deadline.
2. Selects allowed reason.
3. Uploads evidence.
4. SDR notified.
5. SDR can reply/upload evidence.
6. Admin sees timeline + bounty criteria + evidence.
7. Admin rules.

If SDR wins:
- ACCEPTED → payout due.

If Business wins:
- REJECTED;
- held amount returns/credits business;
- stats update.

Admin decision generates immutable event.

---

## Flow I — No-show

### Prospect no-show
1. Business marks prospect no-show.
2. Evidence/request for reschedule.
3. SDR receives 14-day reschedule window.
4. If rescheduled, update meeting.
5. If window expires, close without payout.

### Business no-show
If prospect attendance/readiness is evidenced:
- pay SDR.

Because proof is difficult, keep business-no-show cases under manual moderation in MVP.

---

## Flow J — Payout

MVP:
1. Meeting becomes PAYOUT_DUE.
2. Admin pays SDR manually.
3. Stores payment reference.
4. Clicks `Mark paid`.
5. Ledger event appended.
6. Meeting = PAID.

Later:
- payment provider API triggers payout automatically.
