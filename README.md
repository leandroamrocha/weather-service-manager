# Weather-Aware Service Appointment Manager

A Service Cloud application that enriches field-service Cases with live weather
forecasts and flags visits at risk of bad weather, so dispatchers can reschedule
before a technician is sent into a storm.

Built as a portfolio project demonstrating **REST integration with public APIs,
Apex triggers, asynchronous Apex, Lightning Web Components, and Flow** working
together with proper bulkification, error handling and test coverage.

---

## What it does

1. A Case is created or updated with a **Visit City** and **Visit Date**.
2. An `after` trigger detects the change and enqueues an async job (triggers
   can't call out synchronously).
3. A **Queueable** calls two public [Open-Meteo](https://open-meteo.com) REST
   endpoints — geocoding (city → coordinates) then the daily forecast — and
   writes back a computed **Weather Risk** (None / Low / Medium / High),
   precipitation probability, max temperature and a readable summary.
4. A **record-triggered Flow** creates a high-priority follow-up Task whenever a
   visit is flagged **High** risk.
5. A **Lightning Web Component** dashboard lists upcoming visits with colour-coded
   risk badges and lets the user re-evaluate or reschedule a visit inline.

---

## Architecture

```
Case (insert/update)
   │
   ▼
CaseWeatherTrigger ──► CaseWeatherHandler ──► WeatherCalloutQueueable
                          (bulkified,            (Database.AllowsCallouts)
                           recursion guard)              │
                                                         ▼
                                                  WeatherService
                                         ┌───────────────┴───────────────┐
                                         ▼                               ▼
                              Open_Meteo_Geocoding NC          Open_Meteo_Forecast NC
                                  (/v1/search)                     (/v1/forecast)

Case fields updated ──► record-triggered Flow ──► follow-up Task (High risk)
                   └──► weatherServicePanel LWC (wire + refreshApex)
```

## Components

| Component | Type | Responsibility |
|-----------|------|----------------|
| `WeatherService` | Apex | Both REST callouts, JSON parsing, risk model, WMO-code descriptions |
| `WeatherCalloutQueueable` | Apex (Queueable) | Async, bulk callouts + write-back, per-record error capture |
| `CaseWeatherHandler` | Apex | Decides which Cases need (re)evaluation; recursion + limit guards |
| `CaseWeatherTrigger` | Trigger | Thin `after insert/update` delegating to the handler |
| `WeatherPanelController` | Apex | `cacheable` read + imperative re-evaluate / reschedule |
| `weatherServicePanel` | LWC | Dashboard with risk badges, refreshApex, reschedule modal |
| `High_Weather_Risk_Followup` | Flow | Creates a Task when risk = High |
| `WeatherCalloutMock` | Apex (test) | Single mock answering both endpoints, with error toggles |

## Custom fields on Case

`Visit_City__c`, `Visit_Date__c`, `Weather_Risk__c`, `Precip_Probability__c`,
`Max_Temp__c`, `Weather_Summary__c`, `Weather_Sync_Error__c`.

## Engineering notes

- **No callouts in the trigger** — work is offloaded to a Queueable.
- **Bulkified end-to-end** — a 50-record insert produces a single async job and
  one DML update; covered by a governor-safe bulk test.
- **No hard-coded endpoints** — both base URLs live in Named Credentials, reached
  via `callout:Open_Meteo_*`.
- **Resilient** — each record's callout is isolated; failures are written to
  `Weather_Sync_Error__c` instead of aborting the batch.
- **Tested** — happy paths, every error branch, the bulk path and the controller.
  Mock simulates non-200s and empty geocoding results.

## Setup

```bash
# 1. Authorise a dev hub / target org, then create a scratch org
sf org create scratch --definition-file config/project-scratch-def.json \
   --alias weather --set-default --duration-days 7

# 2. Deploy
sf project deploy start

# 3. After deploy, open Setup → Named Credentials and confirm both
#    Open_Meteo_Geocoding and Open_Meteo_Forecast are active.
#    (Open-Meteo needs no key — the External Credential uses No Authentication.)

# 4. (Optional) seed demo data
sf apex run --file scripts/apex/sample-data.apex

# 5. Run tests
sf apex run test --result-format human --code-coverage
```

Then drop the **Weather Service Panel** component onto a Lightning App or Home
page via the Lightning App Builder.

## APIs used

- **Open-Meteo Geocoding** — `https://geocoding-api.open-meteo.com/v1/search`
- **Open-Meteo Forecast** — `https://api.open-meteo.com/v1/forecast`

Both are free and require no API key.

---

*Author: Leandro Rocha*
