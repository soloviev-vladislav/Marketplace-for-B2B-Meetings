# PRD — B2B Bounty Marketplace

Version: MVP 0.1

## 1. Product Summary

Платформа соединяет:
- бизнесы, которым нужны новые B2B-встречи;
- независимых SDR, sales-менеджеров, аутричеров и коннекторов, которые умеют такие встречи получать.

Бизнес публикует bounty с точным ICP и фиксированной оплатой за состоявшуюся квалифицированную встречу.

SDR выбирает bounty и работает за собственный счёт и собственными методами в рамках правил платформы.

Платформа:
- стандартизирует ТЗ;
- фиксирует ownership prospect/account;
- хранит депозит/статус обеспечения;
- проверяет результат;
- разрешает споры;
- ведёт рейтинги;
- организует расчёты.

## 2. Problem

### Для бизнеса
Outbound требует найма SDR/агентства, управления людьми, авансовой оплаты и принятия риска результата.

### Для SDR
Нужно искать клиентов, продавать свои услуги, договариваться об оплате, контролировать расчёты и зависеть от одного/нескольких заказчиков.

## 3. Value Proposition

### Business
«Публикуешь, кого хочешь встретить и сколько готов платить. Платишь только за состоявшийся квалифицированный результат.»

### SDR
«Открываешь ленту оплачиваемых B2B-задач, выбираешь подходящие и зарабатываешь без продажи собственных услуг заказчику.»

## 4. Primary Actors

### BUSINESS
Компания-заказчик.

### SDR
Исполнитель, который приводит встречу.

### ADMIN / MODERATOR
Площадка. Модерирует bounty, проверяет спорные случаи и управляет рисками.

## 5. MVP Success Event

`QUALIFIED_MEETING_ACCEPTED`

Встреча считается accepted, если:
1. prospect соответствует обязательным критериям bounty;
2. встреча состоялась;
3. выполнены минимальные условия события;
4. заказчик подтвердил её либо истёк dispute window;
5. нет подтверждённого нарушения правил.

## 6. Core Object: Bounty

Каждый bounty содержит:

### Commercial
- title
- reward_to_sdr
- platform_fee
- total_cost_to_business
- meeting_limit
- active_until
- current_status

### ICP — required
- countries/regions
- industries
- company size criteria
- revenue criteria
- allowed decision-maker roles
- excluded industries
- excluded companies/accounts
- additional hard filters

### Meeting acceptance
- minimum duration, если применимо
- online/offline
- required attendee role
- what counts as attended
- reschedule rules
- no-show rules
- existing CRM rule
- duplicate rule

### Sales context
- product description
- pains/triggers
- value propositions
- references/cases
- website
- attachments
- prohibited claims
- preferred outreach notes

## 7. Hard Rule

В MVP **нет полностью свободной формулировки критерия оплаты**.

Оплачиваемым событием является только:
`QUALIFIED_ATTENDED_MEETING`

Дополнительные пожелания бизнеса могут храниться как notes, но не превращаются в основание отказа, если не были записаны как hard criterion до регистрации prospect.

## 8. Marketplace Feed

SDR видит:
- reward;
- category;
- geography;
- ICP preview;
- decision makers;
- available slots / remaining quota;
- advertiser rating;
- dispute rate;
- average acceptance time.

Фильтры:
- reward;
- industry;
- geography;
- role;
- remote/offline.

## 9. Take Bounty

SDR может нажать `Take bounty`.

Это:
- не создаёт эксклюзивность на все аккаунты;
- добавляет bounty в workspace SDR;
- открывает полный brief;
- позволяет регистрировать prospects.

## 10. Prospect Registration

SDR передаёт:
- company legal name;
- INN;
- website/domain;
- contact full name;
- job title;
- corporate email;
- optional LinkedIn/Telegram/phone;
- evidence/source note;
- planned meeting date/time.

Platform checks:
- bounty active;
- quota available;
- company fits hard criteria where data is available;
- no active ownership conflict;
- prospect not excluded;
- basic duplicate detection.

## 11. Ownership

### MVP rule
Ownership выдаётся **на конкретный company + contact**, а не на компанию навсегда.

### Protection
- On accepted prospect registration: 30 days.
- If a meeting is scheduled: through meeting date + 7 days.
- Reschedule extends protection according to policy.
- Expired ownership can be reclaimed by another SDR.

### Collision
If another SDR already owns the same company + contact:
- new registration rejected;
- existence of protected contact is shown without revealing SDR identity or contact data.

Future:
- account-level protection for verified active conversations.

## 12. Deposit

До раскрытия полного контакта бизнесу meeting должен иметь `funding_status = SECURED`.

MVP implementation may be:
- real payment provider;
- or admin-confirmed manual deposit.

SDR must see whether the bounty is:
- funded;
- partially funded;
- unfunded.

Recommended marketplace rule:
**SDR cannot hand over a booked meeting unless one meeting reward + platform fee is secured.**

## 13. Meeting Lifecycle

States:

`DRAFT`
→ `SUBMITTED`
→ `PROSPECT_APPROVED`
→ `AWAITING_DEPOSIT`
→ `SECURED`
→ `SCHEDULED`
→ `AWAITING_RESULT`
→ `ACCEPTED`
or
→ `DISPUTED`
→ `ACCEPTED` / `REJECTED`
→ `PAYOUT_DUE`
→ `PAID`

Separate:
`CANCELLED`
`NO_SHOW`
`RESCHEDULED`

## 14. Default Acceptance

After scheduled meeting time:
- system opens review window;
- business has 24 hours to accept or dispute;
- if no dispute is filed, meeting auto-accepts.

Configurable later. MVP global setting = 24h.

## 15. Allowed Dispute Reasons

Business cannot reject by subjective feedback.

Allowed:
1. meeting did not occur;
2. wrong company;
3. wrong decision-maker role;
4. hard ICP criterion violated;
5. contact was an existing active CRM opportunity before SDR registration;
6. duplicate already validly registered;
7. fabricated identity/evidence;
8. explicit prohibited method/rule violation.

Dispute requires:
- reason code;
- explanation;
- evidence attachment or structured evidence.

Money/reward remains frozen while dispute is open.

## 16. No-show

Recommended MVP:
- Prospect no-show is not automatically SDR fault.
- First verified prospect no-show → allow one reschedule within 14 days.
- If no meeting after reschedule window → no payout.
- Business no-show → SDR is paid if SDR proves prospect attended / was ready to attend.
- Mutual technical failure → reschedule.

## 17. Ratings

### SDR stats
- total submitted;
- accepted;
- rejected;
- disputed;
- won/lost disputes;
- show rate;
- acceptance rate;
- median reward;
- total earned.

### Business stats
- total bounties;
- meetings funded;
- acceptance rate;
- dispute rate;
- disputes lost;
- median review time;
- total paid.

Do not use a single opaque 1–5 score at first. Show verifiable stats.

## 18. Admin

Admin can:
- approve/reject businesses;
- approve/pause bounties;
- edit normalized bounty fields with audit trail;
- see all meeting submissions;
- resolve disputes;
- manage financial ledger;
- suspend users;
- add fraud flags;
- see event history.

## 19. Fraud Controls — MVP

Rules:
- verified email for all users;
- business domain verification where possible;
- INN required for advertiser;
- INN required for prospect company;
- corporate prospect email required by default;
- uniqueness checks for prospect emails;
- IP/device logging limited to legitimate security needs;
- rate limits;
- immutable audit events;
- manual flags.

Risk signals:
- same prospect repeatedly used;
- abnormal dispute win/loss;
- repeated meetings from same domain/contact;
- unusual booking velocity;
- multiple accounts;
- high cancellation/no-show rate.

## 20. Notifications

Telegram/email:
- new matching bounty;
- prospect accepted/rejected;
- deposit secured;
- meeting due;
- review required;
- dispute opened;
- dispute decision;
- payout due/paid.

## 21. Out of Scope MVP

- built-in video calls;
- automatic recording;
- call transcription;
- AI qualification from video;
- internal outreach sending;
- automated lead enrichment at scale;
- partner integrations with email infra;
- sales commission on closed revenue;
- closer marketplace;
- multi-currency;
- complex teams/agency hierarchies;
- native iOS/Android.

## 22. North-star and Guardrail Metrics

North-star:
- accepted qualified meetings / week.

Marketplace:
- time to first accepted meeting per bounty;
- bounty fill rate;
- active funded bounty value;
- active SDRs completing at least one meeting.

Quality:
- dispute rate;
- rejection rate;
- no-show rate;
- repeat advertiser rate.

Economics:
- GMV;
- platform revenue;
- average bounty;
- average payouts per productive SDR.

## 23. MVP Validation Thresholds

Do not treat as universal truth; initial operating targets:
- 5–10 paying businesses;
- 30–50 activated SDRs;
- 50+ submitted meetings;
- 25+ accepted meetings;
- <15% disputes;
- at least 30% of advertisers publish another bounty.

## 24. Critical Product Questions to Learn

1. What bounty is sufficient to attract competent SDRs?
2. Which ICPs fill fastest?
3. How often prospects collide?
4. What creates most disputes?
5. Does 24h default acceptance work?
6. What percentage of SDRs ever deliver one meeting?
7. Do top SDRs concentrate on a few bounty types?
8. What advertiser stats materially affect SDR choice?
