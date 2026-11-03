# Enterprise Salesforce Apex Trigger Framework

## Team Standard: Metadata-Driven Trigger Handler (TDTM)

**Document type:** Engineering standard\
**Audience:** Salesforce architects, technical leads, developers,
reviewers and release engineers\
**Version:** 1.0\
**Status:** Proposed team baseline\
**Applies to:** Salesforce Apex projects across clients and orgs

------------------------------------------------------------------------

## 1. Executive summary

This document defines a reusable, team-wide Apex trigger framework. Its
purpose is to make trigger execution predictable, bulk-safe, testable,
maintainable and consistent across client implementations.

The framework uses:

-   One thin trigger per object.
-   A central dispatcher/router.
-   Small, single-purpose handler classes.
-   Custom Metadata Types (CMDT) for handler registration, activation,
    execution order and trigger-event selection.
-   Explicit bypass mechanisms rather than hidden or inferred
    transaction behaviour.
-   Transaction-scoped state for recursion control and caching.
-   A standard testing and code-review approach.

The supplied proposal is a useful starting point: it separates trigger
routing from business logic and uses metadata to control which handlers
run. However, several implementation details should not be adopted
as-is. In particular, parsing stack traces to identify the initiating
class, substring matching for metadata values, and relying on
method-name exclusions create fragile behaviour. This document retains
the metadata-driven architecture while replacing those weak points with
explicit contracts.

**Core principle:** metadata may decide *which registered handler is
eligible to run and in what order*. It must not become a substitute for
understandable business logic, explicit dependencies, or proper testing.

------------------------------------------------------------------------

## 2. Design goals and non-goals

### 2.1 Goals

1.  Establish one consistent trigger pattern across the team.
2.  Keep trigger files free of business logic.
3.  Support all standard trigger operations.
4.  Make handlers independently testable and reusable.
5.  Enforce bulk-safe processing.
6.  Make execution order and handler activation configurable.
7.  Provide safe, auditable bypass controls.
8.  Prevent accidental recursion without suppressing legitimate work.
9.  Make failures visible and preserve transaction integrity.
10. Keep the framework small enough that developers can understand and
    debug it.

### 2.2 Non-goals

The framework is not intended to:

-   Turn every method or line of business logic into metadata.
-   Provide a generic workflow engine.
-   Replace record-triggered Flows where Flow is the better fit.
-   Guarantee a particular order between Apex, Flow, workflow-style
    automation, managed packages or platform automation outside the
    framework's control.
-   Make an unsafe handler safe merely because it is called through a
    router.
-   Infer business intent from the current user's profile, username or
    an Apex stack trace.

------------------------------------------------------------------------

## 3. Recommended architecture

``` text
Salesforce DML
    |
    v
Object Trigger (one per object)
    |
    v
Trigger Dispatcher
    |
    +--> Read/cache handler configuration (CMDT)
    |
    +--> Identify current TriggerOperation
    |
    +--> Apply active/event/bypass/recursion checks
    |
    +--> Sort by execution order and stable tie-breaker
    |
    v
Handler interface
    |
    +--> AccountValidationHandler
    +--> AccountDefaultsHandler
    +--> AccountIntegrationHandler
    +--> AccountRollupHandler
    |
    v
Domain/service/selector/integration classes
```

### 3.1 Responsibility boundaries

  -----------------------------------------------------------------------
  Component               Responsibility          Must not do
  ----------------------- ----------------------- -----------------------
  Trigger                 Invoke the dispatcher   Contain business logic,
                          for its object          SOQL, DML or branching

  Dispatcher              Resolve eligible        Contain object-specific
                          handlers and invoke     business rules
                          them                    

  Handler                 Coordinate one focused  Become a large
                          trigger responsibility  collection of unrelated
                                                  features

  Domain/service class    Implement business      Depend unnecessarily on
                          operations              trigger globals

  Selector/repository     Encapsulate data access Hide unbounded queries
                          where the project uses  
                          this pattern            

  CMDT                    Register and configure  Store secrets or
                          handlers                complex business
                                                  decision trees

  Bypass service          Apply explicit,         Silently bypass all
                          centrally governed      automation for broad
                          bypass rules            user groups
  -----------------------------------------------------------------------

### 3.2 One trigger per object

The team standard is one trigger per SObject per org. The trigger
delegates immediately to the dispatcher.

Example:

``` apex
trigger AccountTrigger on Account (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    TriggerDispatcher.run(Account.SObjectType);
}
```

Do not add handler-specific conditions to the trigger. If the object
does not need every event, the trigger can declare only the events
actually required by the object. The metadata configuration must never
request an event that the trigger does not subscribe to.

------------------------------------------------------------------------

## 4. Configuration model

Create a Custom Metadata Type:

**Label:** Trigger Handler\
**API name:** `Trigger_Handler__mdt`

Recommended fields:

  -----------------------------------------------------------------------------------------------
  Field label    API name                        Type           Required       Purpose
  -------------- ------------------------------- -------------- -------------- ------------------
  Object API     `Object_Name__c`                Text(100)      Yes            Target SObject API
  Name                                                                         name,
                                                                               e.g. `Account`

  Handler Class  `Class_Name__c`                 Text(255)      Yes            Apex class
  Name                                                                         implementing the
                                                                               handler interface

  Execution      `Execution_Order__c`            Number(6,0)    Yes            Lower number runs
  Order                                                                        first

  Active         `Active__c`                     Checkbox       Yes            Enables/disables
                                                                               the handler

  Trigger Events `Trigger_Events__c`             Text(255)      Yes            Delimited event
                                                                               API values
                                                                               supported by the
                                                                               framework

  Bypass Custom  `Bypass_Custom_Permission__c`   Text(255)      No             Optional custom
  Permission                                                                   permission that
                                                                               bypasses this
                                                                               handler

  Bypass Setting `Bypass_Key__c`                 Text(100)      No             Optional key
  Key                                                                          understood by the
                                                                               project's central
                                                                               bypass service

  Description    `Description__c`                Text(255)      No             Explains the
                                                                               handler's purpose
                                                                               and operational
                                                                               impact
  -----------------------------------------------------------------------------------------------

Use a delimiter-based Text field or another configuration representation
that can be parsed exactly. A Multi-Select Picklist can also be used,
but do not use `String.contains()` to test membership. Parse values into
a `Set<String>` and compare exact tokens.

### 4.1 Example CMDT records

  ----------------------------------------------------------------------------------------------------------------------
  Developer Name        Object      Class                                Order Active      Events
  --------------------- ----------- --------------------------- -------------- ----------- -----------------------------
  Account_Validation    Account     AccountValidationHandler                10 true        BEFORE_INSERT;BEFORE_UPDATE

  Account_Defaults      Account     AccountDefaultsHandler                  20 true        BEFORE_INSERT

  Account_Integration   Account     AccountIntegrationHandler               50 true        AFTER_INSERT;AFTER_UPDATE
  ----------------------------------------------------------------------------------------------------------------------

Use gaps such as 10, 20, 30 to make inserting a handler between existing
handlers easier.

### 4.2 Configuration rules

-   Developer Name must be unique and descriptive.
-   Class names must match the Apex class exactly.
-   Event names must be valid values from the framework's supported
    event list.
-   Each object/class registration should be unique unless there is a
    documented reason to register the same class more than once.
-   Equal execution-order values should be treated as a configuration
    defect, or resolved by a deterministic secondary sort such as
    Developer Name. The team should choose one policy and enforce it
    consistently.
-   An inactive record is ignored.
-   Missing or invalid configuration must fail visibly in tests and
    deployment validation. Do not silently skip a broken production
    handler.
-   CMDT changes must be version-controlled and deployed with the
    corresponding Apex changes.

**Important:** Custom Metadata is deployable configuration, not a secret
store. Never put credentials, tokens or sensitive personal data in it.

------------------------------------------------------------------------

## 5. Handler contract

Use a small interface with a consistent context object. `public` is
sufficient when the framework and handlers are in the same
namespace/package. Use `global` only when a genuine cross-namespace or
managed-package API requirement exists.

### 5.1 Trigger context DTO

``` apex
public class TriggerContext {
    public Schema.SObjectType sObjectType { get; private set; }
    public System.TriggerOperation operation { get; private set; }
    public List<SObject> newRecords { get; private set; }
    public List<SObject> oldRecords { get; private set; }
    public Map<Id, SObject> newMap { get; private set; }
    public Map<Id, SObject> oldMap { get; private set; }

    public TriggerContext(
        Schema.SObjectType sObjectType,
        System.TriggerOperation operation,
        List<SObject> newRecords,
        List<SObject> oldRecords,
        Map<Id, SObject> newMap,
        Map<Id, SObject> oldMap
    ) {
        this.sObjectType = sObjectType;
        this.operation = operation;
        this.newRecords = newRecords;
        this.oldRecords = oldRecords;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }
}
```

The dispatcher constructs this object from trigger context variables. In
contexts where a collection or map does not exist, its value is null.
Handlers must not assume that `Trigger.new`, `Trigger.old`,
`Trigger.newMap` or `Trigger.oldMap` is populated for every operation.

### 5.2 Handler interface

``` apex
public interface ITriggerHandler {
    void execute(TriggerContext context);
}
```

Keep the interface stable. If the framework later needs additional
information, prefer extending the context DTO in a backward-compatible
way rather than adding a long list of parameters to every handler.

### 5.3 Handler example

``` apex
public with sharing class AccountValidationHandler implements ITriggerHandler {

    public void execute(TriggerContext context) {
        if (context.operation == System.TriggerOperation.BEFORE_INSERT) {
            validateNewAccounts((List<Account>) context.newRecords);
        } else if (context.operation == System.TriggerOperation.BEFORE_UPDATE) {
            validateAccountChanges(
                (List<Account>) context.newRecords,
                (Map<Id, Account>) context.oldMap
            );
        }
    }

    private void validateNewAccounts(List<Account> accounts) {
        for (Account accountRecord : accounts) {
            if (String.isBlank(accountRecord.Name)) {
                accountRecord.addError('Account Name is required.');
            }
        }
    }

    private void validateAccountChanges(
        List<Account> newAccounts,
        Map<Id, Account> oldAccountsById
    ) {
        for (Account accountRecord : newAccounts) {
            Account oldRecord = oldAccountsById.get(accountRecord.Id);

            if (oldRecord != null && accountRecord.Name != oldRecord.Name) {
                // Add focused validation here.
            }
        }
    }
}
```

The handler should coordinate the operation and delegate complex logic
to service/domain classes. Keep methods private unless another class
genuinely needs to call them.

------------------------------------------------------------------------

## 6. Dispatcher implementation blueprint

The following is a reference implementation blueprint. It intentionally
avoids stack-trace inspection and substring-based matching. Adapt and
compile it against the exact CMDT field names created in the org.

### 6.1 Dispatcher

``` apex
public with sharing class TriggerDispatcher {

    private static Map<String, List<Trigger_Handler__mdt>> configByObject =
        new Map<String, List<Trigger_Handler__mdt>>();

    private static Set<String> handlersCurrentlyExecuting = new Set<String>();

    public static void run(Schema.SObjectType sObjectType) {
        if (sObjectType == null) {
            throw new TriggerFrameworkException('SObjectType cannot be null.');
        }

        TriggerContext context = buildContext(sObjectType);
        String objectApiName = sObjectType.getDescribe().getName();

        List<Trigger_Handler__mdt> configuredHandlers =
            getHandlersForObject(objectApiName);

        for (Trigger_Handler__mdt config : configuredHandlers) {
            if (!isEligible(config, context)) {
                continue;
            }

            String executionKey = buildExecutionKey(config, context);

            // Same handler + same event cannot re-enter while it is executing.
            if (handlersCurrentlyExecuting.contains(executionKey)) {
                continue;
            }

            Type handlerType = Type.forName(config.Class_Name__c);
            if (handlerType == null) {
                throw new TriggerFrameworkException(
                    'Handler class not found: ' + config.Class_Name__c
                );
            }

            Object instance = handlerType.newInstance();
            if (!(instance instanceof ITriggerHandler)) {
                throw new TriggerFrameworkException(
                    'Handler must implement ITriggerHandler: ' +
                    config.Class_Name__c
                );
            }

            handlersCurrentlyExecuting.add(executionKey);
            try {
                ((ITriggerHandler) instance).execute(context);
            } catch (Exception ex) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Trigger handler failed. Object=' + objectApiName +
                    ', Handler=' + config.Class_Name__c +
                    ', Operation=' + context.operation +
                    ', Message=' + ex.getMessage() +
                    ', Stack=' + ex.getStackTraceString()
                );
                throw ex;
            } finally {
                handlersCurrentlyExecuting.remove(executionKey);
            }
        }
    }

    private static TriggerContext buildContext(
        Schema.SObjectType sObjectType
    ) {
        return new TriggerContext(
            sObjectType,
            Trigger.operationType,
            Trigger.isExecuting && Trigger.isInsert ||
                Trigger.isExecuting && Trigger.isUpdate ||
                Trigger.isExecuting && Trigger.isUndelete
                    ? Trigger.new : null,
            Trigger.isExecuting && Trigger.isUpdate ||
                Trigger.isExecuting && Trigger.isDelete
                    ? Trigger.old : null,
            Trigger.isExecuting && (Trigger.isInsert ||
                Trigger.isUpdate || Trigger.isUndelete)
                    ? Trigger.newMap : null,
            Trigger.isExecuting && (Trigger.isUpdate ||
                Trigger.isDelete)
                    ? Trigger.oldMap : null
        );
    }

    private static List<Trigger_Handler__mdt> getHandlersForObject(
        String objectApiName
    ) {
        if (!configByObject.containsKey(objectApiName)) {
            List<Trigger_Handler__mdt> records =
                new List<Trigger_Handler__mdt>();

            for (Trigger_Handler__mdt config :
                Trigger_Handler__mdt.getAll().values()) {
                if (config.Active__c &&
                    config.Object_Name__c == objectApiName) {
                    records.add(config);
                }
            }

            records.sort(new HandlerConfigComparator());
            configByObject.put(objectApiName, records);
        }

        return configByObject.get(objectApiName);
    }

    private static Boolean isEligible(
        Trigger_Handler__mdt config,
        TriggerContext context
    ) {
        if (config == null || !config.Active__c) {
            return false;
        }

        Set<String> configuredEvents = new Set<String>();
        if (String.isNotBlank(config.Trigger_Events__c)) {
            for (String eventName : config.Trigger_Events__c.split(';')) {
                configuredEvents.add(eventName.trim().toUpperCase());
            }
        }

        if (!configuredEvents.contains(
            String.valueOf(context.operation).toUpperCase()
        )) {
            return false;
        }

        if (isHandlerBypassed(config)) {
            return false;
        }

        return true;
    }

    private static Boolean isHandlerBypassed(
        Trigger_Handler__mdt config
    ) {
        if (String.isNotBlank(config.Bypass_Custom_Permission__c)) {
            // Replace with the project's approved custom-permission check.
            // Example: FeatureManagement.checkPermission(permissionName)
            if (FeatureManagement.checkPermission(
                config.Bypass_Custom_Permission__c
            )) {
                return true;
            }
        }

        return TriggerBypassService.isBypassed(config.Bypass_Key__c);
    }

    private static String buildExecutionKey(
        Trigger_Handler__mdt config,
        TriggerContext context
    ) {
        return config.DeveloperName + ':' +
            String.valueOf(context.operation);
    }

    public class HandlerConfigComparator
        implements Comparator<Trigger_Handler__mdt> {

        public Integer compare(
            Trigger_Handler__mdt left,
            Trigger_Handler__mdt right
        ) {
            if (left.Execution_Order__c < right.Execution_Order__c) {
                return -1;
            }
            if (left.Execution_Order__c > right.Execution_Order__c) {
                return 1;
            }
            return left.DeveloperName.compareTo(right.DeveloperName);
        }
    }

    public class TriggerFrameworkException extends Exception {}
}
```

### 6.2 Important implementation notes

This blueprint illustrates the architecture, not a copy-paste-certified
package. Before adopting it:

1.  Compile it in a scratch org or development org using the exact
    metadata schema.
2.  Confirm the target API version supports every language/API feature
    used.
3.  Review `buildContext` against every trigger operation in the
    supported API version. A simpler, explicit
    `switch on Trigger.operationType` is also valid and may be easier to
    maintain.
4.  Add a central `TriggerBypassService` implementation and tests.
5.  Decide whether recursion prevention should be a re-entry guard only,
    a once-per-transaction guard, or a more specific record/operation
    guard. Do not silently choose a broad static Boolean.
6.  Confirm whether the team wants `with sharing`, `without sharing` or
    `inherited sharing` for each handler/service. Trigger execution and
    record-level sharing are separate concerns; sharing declarations
    must be an intentional security decision.
7.  If handlers are expected to run in managed packages or across
    namespaces, revisit visibility and reflection constraints.

### 6.3 Bypass service contract

Use explicit bypass APIs rather than inspecting stack traces or guessing
which class initiated DML.

``` apex
public class TriggerBypassService {

    private static Set<String> bypassedKeys = new Set<String>();

    public static void bypass(String key) {
        if (String.isNotBlank(key)) {
            bypassedKeys.add(key.trim().toLowerCase());
        }
    }

    public static void clearBypass(String key) {
        if (String.isNotBlank(key)) {
            bypassedKeys.remove(key.trim().toLowerCase());
        }
    }

    public static Boolean isBypassed(String key) {
        return String.isNotBlank(key) &&
            bypassedKeys.contains(key.trim().toLowerCase());
    }

    @TestVisible
    private static void clearAll() {
        bypassedKeys.clear();
    }
}
```

Example use in a controlled data operation:

``` apex
TriggerBypassService.bypass('AccountIntegration');
try {
    update accountsToUpdate;
} finally {
    TriggerBypassService.clearBypass('AccountIntegration');
}
```

Always use `try/finally` so a bypass does not leak into later work in
the same transaction. A bypass should be narrow, documented and
temporary.

For administrator-controlled bypass, use Custom Permissions and check
them through `FeatureManagement.checkPermission()`. Avoid
username/profile string lists as the primary security or governance
mechanism: names change, profiles are coarse, and user-specific
exceptions are difficult to audit.

------------------------------------------------------------------------

## 7. Design decisions and improvements over the supplied proposal

  -------------------------------------------------------------------------------
  Supplied proposal               Risk / limitation       Team standard
  ------------------------------- ----------------------- -----------------------
  `global` interface              Exposes a wider API     Use `public`; use
                                  than most org-local     `global` only for a
                                  frameworks need         real package boundary

  `Excluded_Usernames__c`         Fragile matching, user  Prefer Custom
  comma-separated list            renames and difficult   Permissions and
                                  governance              explicit bypass service

  `Excluded_Context_Classes__c`   Stack-trace-based       Explicit bypass API at
                                  caller identification   the initiating code
                                  is unreliable and       
                                  brittle                 

  Stack trace parsed to identify  Stack trace format is   Never use it for normal
  caller                          not a stable business   routing or business
                                  contract; adds CPU and  decisions
                                  maintenance cost        

  `String.contains()` for         Partial matches can     Parse exact tokens into
  event/user/method matching      cause false positives   Sets

  `Excluded_Methods__c`           Couples metadata to     Split distinct
                                  private implementation  responsibilities into
                                  details and encourages  separate handlers; use
                                  feature toggles at      feature configuration
                                  method granularity      only when there is a
                                                          genuine business
                                                          requirement

  Handler receives raw CMDT       Makes business handlers Pass a focused context
  record                          dependent on framework  DTO; pass configuration
                                  configuration schema    only when a handler has
                                                          a justified
                                                          configuration need

  Dynamic class instantiation     Misconfigured class can Validate class
  without contract validation     fail late or with       existence and interface
                                  unclear errors          implementation; fail
                                                          clearly

  Query CMDT on each trigger      Repeated work in one    Cache per object for
  invocation                      transaction             the transaction; use
                                                          CMDT static accessors
                                                          where suitable

  No deterministic tie-breaker    Equal order values can  Enforce unique order
                                  produce ambiguous       values or add stable
                                  ordering                secondary sort

  No explicit recursion policy    Can create infinite     Define and test a
                                  loops or suppress valid documented recursion
                                  work                    strategy

  Debug-only configuration errors Broken automation can   Fail visibly and
                                  go unnoticed            validate configuration
                                                          in tests/deployment

  No testing standard             Framework may work in   Require dispatcher,
                                  one path and fail in    handler, bypass, bulk
                                  others                  and integration tests
  -------------------------------------------------------------------------------

------------------------------------------------------------------------

## 8. Recursion and re-entry strategy

Recursion is not one problem with one universal Boolean fix. The
framework must distinguish:

-   **Re-entry protection:** prevent the same handler from calling
    itself recursively while it is still executing.
-   **Once-per-transaction execution:** run a handler only once in the
    transaction. This can be wrong when a legitimate second DML
    operation should be processed.
-   **Record-level protection:** process a particular record/operation
    only once when the business requirement explicitly demands it.
-   **Business idempotency:** make an operation safe to repeat,
    especially for integrations and asynchronous work.

### Team rules

1.  Start with no global `static Boolean hasRun` pattern.
2.  Use an in-progress key to prevent immediate re-entry where
    appropriate.
3.  Add record-level state only when the business operation requires it.
4.  Prefer change detection (`new` versus `old`) to avoid unnecessary
    work on updates.
5.  Make integrations idempotent using a stable external/business key
    where possible.
6.  Never use recursion guards to hide an automation loop that should be
    fixed at its source.
7.  Test repeated updates in one transaction, not just a single insert.

A re-entry guard does not guarantee that a handler runs only once, and
it does not replace correct change detection.

------------------------------------------------------------------------

## 9. Handler development standards

Every handler must follow these rules:

### 9.1 Single responsibility

Good examples:

-   `AccountValidationHandler`
-   `AccountDefaultingHandler`
-   `AccountERPIntegrationHandler`
-   `ContactConsentHandler`
-   `OrderPricingHandler`

Avoid handlers such as `AccountAllAutomationHandler` that contain
validation, integration, rollups, notifications and unrelated updates.

### 9.2 Bulkification

-   Assume the trigger receives up to 200 records per trigger
    invocation.
-   No SOQL or DML inside record loops.
-   Query using collections of IDs or business keys.
-   Perform collection-based DML.
-   Avoid repeated queries across helper methods; pass queried data
    where appropriate or use a selector/cache.
-   Consider CPU, heap, query rows, DML rows, callouts and asynchronous
    limits.
-   Do not assume that a small test dataset represents production
    volume.

### 9.3 Before and after context

-   Use before insert/update to set or validate fields on the triggering
    records.
-   Use `addError()` for record-level validation failures.
-   Use after contexts when record IDs or committed-record relationships
    are needed.
-   Do not issue DML on the same triggering records from a before
    trigger.
-   Avoid unnecessary DML updates to records that can be changed
    directly in before context.
-   For callouts, use an appropriate asynchronous or event-driven design
    rather than attempting an ordinary synchronous callout from a
    trigger.

### 9.4 Change detection

For update logic, compare the new record with its old version and
execute only when relevant fields change.

``` apex
Boolean statusChanged =
    newRecord.Status__c != oldRecord.Status__c;

if (statusChanged) {
    // Execute the status-change behaviour.
}
```

Do not run expensive recalculation or integration logic on every update
if the fields that matter have not changed.

### 9.5 Exceptions and transaction integrity

-   Do not catch and suppress exceptions just to let the transaction
    continue.
-   If an exception is caught, the handler must have a deliberate
    recovery or error-reporting strategy.
-   Re-throw failures that should roll back the transaction.
-   Use `addError()` for expected record validation failures.
-   Do not expose sensitive data in debug logs.
-   Ensure error logs do not themselves cause recursive automation.

------------------------------------------------------------------------

## 10. Security and execution context

The framework must not treat trigger execution as proof that all data
access is automatically safe.

-   Make sharing behaviour explicit in handlers and services.
-   Apply CRUD/FLS enforcement where the code's security model requires
    it, particularly for user-facing operations.
-   Use user-mode database operations or security enforcement features
    where appropriate for the target API version and use case.
-   Do not assume `with sharing` enforces object permissions or
    field-level security; it addresses record-level sharing.
-   Do not use profile names as a substitute for permission-based
    access.
-   Keep secrets out of CMDT, Apex source and logs.
-   Document any intentional system-context processing.

The correct security approach depends on whether the automation is
intended to enforce system business rules or act on behalf of a user.
The architect must make that decision explicitly.

------------------------------------------------------------------------

## 11. Testing strategy

A framework test suite is mandatory. A successful deployment is not
evidence that all runtime paths are correct.

### 11.1 Framework-level tests

Test at least:

1.  Active handler executes.
2.  Inactive handler does not execute.
3.  Correct object registration is selected.
4.  Correct trigger event is selected.
5.  Non-matching event is skipped.
6.  Execution order is respected.
7.  Equal-order tie-breaker is deterministic, if supported.
8.  Missing class produces a clear framework exception.
9.  Class not implementing the interface produces a clear error.
10. Custom Permission bypass works.
11. Programmatic bypass works.
12. Bypass is cleared in `finally`.
13. Re-entry protection behaves as documented.
14. Handler exception is not swallowed.
15. Configuration with missing required values is detected.

### 11.2 Handler-level tests

Each handler must have tests for:

-   Positive behaviour.
-   Negative behaviour.
-   Before insert/update behaviour as applicable.
-   After insert/update/delete/undelete behaviour as applicable.
-   Old/new comparison and field-change detection.
-   Bulk data (at least 200 records where relevant).
-   Null and optional relationship values.
-   Validation errors.
-   Security behaviour where applicable.

### 11.3 Test isolation

CMDT records are visible to Apex tests without `SeeAllData=true`. Use
deployed test configuration or an abstraction that allows test-specific
configuration to be supplied. Do not make production metadata depend on
test-only records.

Where CMDT cannot be modified in a test, isolate configuration retrieval
behind a provider interface or `@TestVisible` injection point. Keep such
test seams small and do not weaken production validation.

### 11.4 Test data

-   Use a test data factory for shared objects and required
    relationships.
-   Do not depend on existing org data.
-   Assert outcomes, not merely that no exception occurred.
-   Test realistic bulk and mixed-record scenarios.
-   Ensure test setup does not accidentally bypass the handler being
    tested.

------------------------------------------------------------------------

## 12. Deployment and release management

A feature is not complete until all required pieces are committed and
deployed together:

-   Trigger or trigger change.
-   Dispatcher/interface/context changes, if needed.
-   Handler class(es).
-   CMDT type/field changes, if needed.
-   CMDT records.
-   Supporting service, selector and utility classes.
-   Unit tests.
-   Permission sets/custom permissions required for bypass.
-   Documentation and operational notes.

### Release checklist

-   [ ] One trigger per object.
-   [ ] Trigger contains only dispatcher invocation.
-   [ ] All handlers implement the standard interface.
-   [ ] CMDT records are included in source control.
-   [ ] Class names and object API names are valid.
-   [ ] Trigger event values are valid and match the trigger
    declaration.
-   [ ] Execution order is documented and deterministic.
-   [ ] No SOQL/DML in loops.
-   [ ] No unapproved stack-trace parsing or broad static Boolean
    recursion guards.
-   [ ] Bypass behaviour is documented and tested.
-   [ ] Sharing/CRUD/FLS decisions are reviewed.
-   [ ] Positive, negative and bulk tests pass.
-   [ ] Deployment validation passes in a representative target org.
-   [ ] Existing Flows, managed-package triggers and other automation
    interactions are assessed.

------------------------------------------------------------------------

## 13. Pull request governance

The following rules are mandatory for every project adopting this
framework.

### Rule 1: Zero business logic in triggers

Trigger files may only invoke the dispatcher. No SOQL, DML, helper
calls, business conditions or handler instantiation in the trigger.

### Rule 2: Single responsibility

Handlers must focus on one cohesive responsibility. Split unrelated
behaviour into separate handlers or service classes.

### Rule 3: Code and configuration travel together

A new handler is not complete without its CMDT registration, tests and
required permissions/configuration. Commit and deploy them together.

### Rule 4: No hidden execution-context inference

Do not parse stack traces to identify the caller. Do not use
username/profile substring matching for bypass. Use explicit custom
permissions or the central bypass API.

### Rule 5: Exact configuration matching

Do not use substring matching for event names, class names, usernames or
bypass keys. Parse and compare exact values.

### Rule 6: Bulk safety is non-negotiable

No SOQL/DML in loops. Review CPU and query behaviour for large datasets.

### Rule 7: Recursion must be intentional

Every recursion guard must state what it protects, its scope and why
legitimate repeated processing is not being blocked.

### Rule 8: Tests must assert behaviour

Tests must prove that the correct handler ran or was skipped and that
the business outcome is correct.

### Rule 9: Fail visibly

Do not silently swallow handler/configuration failures. Logging and
exception handling must preserve the intended transaction semantics.

### Rule 10: Security decisions must be explicit

Review sharing, CRUD/FLS and system-context behaviour for each
handler/service.

------------------------------------------------------------------------

## 14. Operational observability

For production support, the framework should make it possible to
identify:

-   Which object and trigger operation ran.
-   Which handler was eligible and executed.
-   Which handler was bypassed and why.
-   Which configuration record selected the handler.
-   Which handler failed and the relevant correlation/request
    identifier, where available.

Do not add verbose logging to every record in normal production
execution. Prefer structured, appropriately gated diagnostics and
platform monitoring. Never log credentials, tokens or unnecessary
personal data.

A future enhancement may add a framework diagnostic mode or a custom
logging interface. Do not make a custom logging object mandatory for the
initial framework unless the client has a real operational requirement.

------------------------------------------------------------------------

## 15. Adoption strategy across clients

The framework should be a shared engineering standard, not a rigid
package forced unchanged into every org.

For each client:

1.  Review existing triggers, trigger frameworks, Flows and
    managed-package automation.
2.  Identify the org's Apex API version and package/namespace
    constraints.
3.  Agree on security execution model.
4.  Agree on bypass governance and who may use bypass permissions.
5.  Create the CMDT schema and deploy the framework core.
6.  Migrate one low-risk object first.
7.  Validate ordering and interactions with existing automation.
8.  Migrate remaining objects incrementally.
9.  Remove obsolete triggers only after regression testing.
10. Document client-specific deviations from this standard.

Do not run two competing trigger frameworks on the same object during
migration unless the interaction is explicitly understood and tested.

------------------------------------------------------------------------

## 16. Future enhancements (only when justified)

Potential extensions include:

-   Handler health/diagnostic mode.
-   Configuration validation utility for CI/CD.
-   A deployment-time check that all configured classes exist and
    implement the interface.
-   Per-handler execution metrics.
-   A selector/domain layer standard.
-   Platform Event or Queueable orchestration for integrations.
-   Feature flags for business capabilities that genuinely need runtime
    control.
-   A dependency declaration model if execution-order numbers become
    insufficient.

Avoid building these pre-emptively. A framework should solve recurring
problems, not become a second platform that the team has to maintain.

------------------------------------------------------------------------

## 17. Final team standard

The team's default pattern is:

1.  One trigger per object.
2.  One central dispatcher.
3.  One stable handler interface and context DTO.
4.  Small, focused handlers.
5.  CMDT registration for activation, event selection and ordering.
6.  Explicit Custom Permission/programmatic bypass.
7.  No stack-trace-based routing.
8.  Exact token matching.
9.  Deliberate recursion and idempotency controls.
10. Bulk-safe, security-reviewed code with meaningful tests.
11. Code and CMDT deployed together.
12. Documented exceptions only.

This design provides a consistent foundation across client projects
while leaving room for org-specific security, integration and automation
requirements.

------------------------------------------------------------------------

## Appendix A: Framework implementation checklist

Before calling the framework production-ready, confirm all of the
following:

-   [ ] CMDT type and fields created with agreed API names.
-   [ ] `ITriggerHandler` interface deployed.
-   [ ] `TriggerContext` DTO deployed.
-   [ ] Dispatcher deployed and compiled against the org's API version.
-   [ ] Trigger bypass service deployed.
-   [ ] Trigger template reviewed.
-   [ ] Configuration provider/cache tested.
-   [ ] Handler type and interface validation tested.
-   [ ] Execution order and tie-breaker tested.
-   [ ] Trigger operation mapping tested for every supported operation.
-   [ ] Recursion/re-entry behaviour tested.
-   [ ] Error propagation tested.
-   [ ] Bulk tests pass.
-   [ ] Security review completed.
-   [ ] CI/CD validation includes CMDT records and custom permissions.
-   [ ] Developer onboarding guide and PR checklist published.

## Appendix B: Important implementation caveat

The code in this document is an architectural reference and starting
point. It is not a managed package or a complete drop-in implementation
for every Salesforce org. In particular, compile and validate the exact
trigger-context mapping, CMDT schema, API-version compatibility,
namespace behaviour, permission checks and test seams in a
representative org before standardising it.

Apex platform behaviour, org automation and package constraints can
differ between clients. The framework's contract and governance rules
should remain consistent; implementation details may be adapted with an
explicit architecture decision.
