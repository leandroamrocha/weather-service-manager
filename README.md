# Weather-Aware Service Appointment Manager

A Salesforce Service Cloud application that enriches field-service Cases with live
weather forecasts and flags visits at risk of bad weather, so dispatchers can
reschedule before sending a technician into a storm.

Built end-to-end as a portfolio project demonstrating **REST integration with
public APIs, Apex triggers, asynchronous Apex, Lightning Web Components, and
Flow** — wired together with bulkification, error handling, and test coverage.

---

## What it does

1. A Case is created or updated with a **Visit City** and **Visit Date**.
2. An `after` trigger detects the change and enqueues an asynchronous job
   (triggers can't make callouts synchronously).
3. A **Queueable** calls two public [Open-Meteo](https://open-meteo.com) REST
   endpoints — geocoding (city → coordinates), then the daily forecast — and
   writes back a computed **Weather Risk** (None / Low / Medium / High), the
   precipitation probability, max temperature, and a readable summary.
4. A **record-triggered Flow** creates a high-priority follow-up Task whenever a
   visit is flagged **High** risk.
5. A **Lightning Web Component** dashboard lists upcoming visits with
   colour-coded risk badges and lets the user re-evaluate or reschedule a visit
   inline.

---

## Architecture

```
Case (insert / update)
   │
   ▼
CaseWeatherTrigger ──► CaseWeatherHandler ──► WeatherCalloutQueueable
                        (bulkified,            (Database.AllowsCallouts)
                         recursion-safe)               │
                                                       ▼
                                                WeatherService
                                       ┌───────────────┴───────────────┐
                                       ▼                               ▼
                            Open_Meteo_Geocoding NC          Open_Meteo_Forecast NC
                                (/v1/search)                     (/v1/forecast)

Case weather fields updated ──► record-triggered Flow ──► follow-up Task (High risk)
                           └──► weatherServicePanel LWC (@wire + refreshApex)
```

The flow chains together cleanly: saving a Case kicks off the trigger, the
forecast is fetched asynchronously, the risk is written back, and if it lands on
**High**, the Flow raises a Task — code and declarative automation working
together.

---

## Components

| Component | Type | Responsibility |
|-----------|------|----------------|
| `WeatherService` | Apex | Both REST callouts, JSON parsing, risk model, WMO-code descriptions |
| `WeatherCalloutQueueable` | Apex (Queueable) | Async, bulk callouts + write-back, per-record error capture |
| `CaseWeatherHandler` | Apex | Decides which Cases need (re)evaluation; recursion + limit guards |
| `CaseWeatherTrigger` | Trigger | Thin `after insert/update` delegating to the handler |
| `WeatherPanelController` | Apex | `cacheable` read + imperative re-evaluate / reschedule |
| `weatherServicePanel` | LWC | Dashboard: risk badges, refreshApex, re-evaluate & reschedule |
| `Alerta de Clima Alto` | Flow | Creates a Task when risk = High |
| `WeatherCalloutMock` | Apex (test) | Single mock answering both endpoints |
| `WeatherServiceTest` / `CaseWeatherFlowTest` | Apex (test) | Service unit tests + full trigger→queueable→controller coverage |

### Custom fields on Case

`Visit_City__c`, `Visit_Date__c`, `Weather_Risk__c`, `Precip_Probability__c`,
`Max_Temp__c`, `Weather_Summary__c`, `Weather_Sync_Error__c`.

---

## Engineering notes

- **No callouts in the trigger** — work is offloaded to a Queueable that
  implements `Database.AllowsCallouts`.
- **Bulkified end-to-end** — the handler collects Ids into a `Set` and enqueues a
  single job; the Queueable queries once and updates once.
- **No hard-coded endpoints** — both base URLs live in Named Credentials, reached
  via `callout:Open_Meteo_*`.
- **Resilient** — each record's callout is isolated in its own try/catch;
  failures are written to `Weather_Sync_Error__c` instead of aborting the batch.
- **Recursion-safe** — the write-back only touches result fields, so the handler's
  change-detection prevents an infinite trigger loop.
- **Tested** — the happy path plus the full automatic chain
  (trigger → handler → queueable → service → write-back) and the controller
  methods, using an `HttpCalloutMock` so no real network calls run in tests.

---

## Tech stack

Apex · Lightning Web Components · SOQL · Flow · REST callouts · Named Credentials
· Salesforce DX · Open-Meteo API

---

## APIs used

- **Open-Meteo Geocoding** — `https://geocoding-api.open-meteo.com/v1/search`
- **Open-Meteo Forecast** — `https://api.open-meteo.com/v1/forecast`

Both are free and require no API key.

---

## Setup

```bash
# 1. Authorise your org
sf org login web --alias my-org --instance-url https://login.salesforce.com

# 2. Deploy the metadata
sf project deploy start --target-org my-org

# 3. In Setup, confirm the two Named Credentials (Open_Meteo_Geocoding and
#    Open_Meteo_Forecast) exist and that your user has access to the
#    Open_Meteo External Credential principal.

# 4. Run the tests
sf apex run test --result-format human --code-coverage --target-org my-org
```

Then drop the **Weather Service Panel** component onto a Lightning App or Home
page via the Lightning App Builder.

---

*Built by [Leandro Rocha](https://www.linkedin.com/in/leandroamrocha) as a
hands-on Salesforce portfolio project.*