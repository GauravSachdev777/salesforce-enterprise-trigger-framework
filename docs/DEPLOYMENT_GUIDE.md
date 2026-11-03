# Deployment Guide

## Deploy together

A feature is incomplete until all required components are committed and deployed together:

- Trigger or trigger change
- Dispatcher, interface, and context DTO
- Handler classes
- CMDT type, fields, and records
- Supporting services/selectors
- Unit tests
- Custom Permissions and permission sets
- Documentation and operational notes

## Release checklist

- [ ] One trigger per object.
- [ ] Trigger delegates only to the dispatcher.
- [ ] Handler classes implement the standard contract.
- [ ] CMDT records are included in source control.
- [ ] Class names, object API names, and event values are valid.
- [ ] Execution order is deterministic.
- [ ] No SOQL/DML in loops.
- [ ] Bypass behaviour is documented and tested.
- [ ] Recursion policy is documented and tested.
- [ ] Sharing and CRUD/FLS decisions are reviewed.
- [ ] Positive, negative, and bulk tests pass.
- [ ] Existing Flows and managed-package automation interactions are assessed.
- [ ] Deployment validation passes in a representative target org.

## Client adoption

1. Inventory existing triggers, Flows, and managed-package automation.
2. Confirm API version, namespace, and packaging constraints.
3. Agree on security and bypass governance.
4. Deploy the framework core.
5. Migrate one low-risk object first.
6. Validate interactions and ordering.
7. Migrate incrementally and remove obsolete triggers only after regression testing.
8. Record client-specific deviations as architecture decisions.
