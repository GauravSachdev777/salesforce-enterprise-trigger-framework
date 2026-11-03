# Architecture

```text
Salesforce DML
    |
    v
Object Trigger
    |
    v
Trigger Dispatcher
    |
    +--> Load/cache handler CMDT
    +--> Resolve TriggerOperation
    +--> Apply activation, event, permission and bypass checks
    +--> Apply recursion/re-entry policy
    +--> Execute handlers in deterministic order
    |
    v
ITriggerHandler
    |
    +--> Validation handler
    +--> Defaulting handler
    +--> Integration handler
    +--> Rollup handler
    |
    v
Domain / service / selector / integration layers
```

## Responsibilities

| Layer | Responsibility |
|---|---|
| Trigger | Delegate to dispatcher only |
| Dispatcher | Resolve and invoke eligible handlers |
| Handler | Coordinate one cohesive trigger responsibility |
| Domain/service | Implement business operations |
| Selector | Encapsulate data access where adopted |
| Custom Metadata | Register handlers and configure execution |
| Bypass service | Apply explicit, centrally governed bypass rules |

## Important boundaries

The framework controls only the Apex handlers registered through it. It does not establish a universal execution order against record-triggered Flows, managed-package triggers, or other platform automation.

Sharing, CRUD, FLS, and system-context behaviour must be deliberate design decisions. `with sharing` alone does not enforce CRUD or field-level security.
