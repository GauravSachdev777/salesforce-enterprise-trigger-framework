# Framework implementation v1

## Included
- `ITriggerHandler`: common handler contract.
- `TriggerContext`: typed trigger-operation snapshot.
- `TriggerDispatcher`: metadata-driven ordered execution.
- `TriggerMetadataService`: transaction-scoped Custom Metadata cache.
- `TriggerBypass`: explicit transaction-scoped handler bypass.
- `TriggerExecutionGuard`: blocks re-entry while a handler is already executing.
- `TriggerFrameworkException`: configuration/runtime exception.
- `Trigger_Handler__mdt`: handler registration metadata.

## Metadata configuration
Create one `Trigger_Handler__mdt` record per handler.

| Field | Example | Meaning |
|---|---|---|
| Developer Name | `Account_Audit` | Unique handler key and bypass key |
| `Object_API_Name__c` | `Account` | Object API name |
| `Handler_Class__c` | `AccountAuditHandler` | Apex class implementing `ITriggerHandler` |
| `Execution_Order__c` | `10` | Lower values execute first |
| `Active__c` | `true` | Enables the registration |
| `Trigger_Events__c` | `BEFORE_INSERT,AFTER_UPDATE` | Exact `System.TriggerOperation` names |
| `Bypass_Custom_Permission__c` | `Bypass_Account_Audit` | Optional Custom Permission name |

Events supported: `BEFORE_INSERT`, `BEFORE_UPDATE`, `BEFORE_DELETE`, `AFTER_INSERT`, `AFTER_UPDATE`, `AFTER_DELETE`, `AFTER_UNDELETE`.

## Trigger entry point
Use one trigger per object:

```apex
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    TriggerDispatcher.run(
        Account.SObjectType,
        Trigger.new,
        Trigger.oldMap,
        Trigger.operationType
    );
}
```

## Handler example
Place this class in the org and register it with Custom Metadata:

```apex
public class AccountAuditHandler implements ITriggerHandler {
    public void run(TriggerContext context) {
        if (context.isBefore() && context.isInsert()) {
            for (SObject row : context.newRecords) {
                Account accountRecord = (Account) row;
                if (String.isBlank(accountRecord.Description)) {
                    accountRecord.Description = 'Created through trigger framework';
                }
            }
        }
    }
}
```

## Bypass example
```apex
TriggerBypass.bypassHandler('Account_Audit');
try {
    // Perform work that should bypass this handler.
} finally {
    TriggerBypass.clearHandler('Account_Audit');
}
```

## Important design boundaries
- The dispatcher does not perform business logic.
- Handlers must bulkify SOQL and DML and must not issue DML on `Trigger.new` records in before contexts.
- Re-entry protection is per handler while that handler is on the call stack. It does not replace business-level idempotency or prevent later sequential trigger invocations.
- The bypass API is transaction-scoped. Always clear temporary bypasses in `finally`.
- A Custom Permission configured in metadata is checked with `FeatureManagement.checkPermission`.
- Sharing, CRUD and FLS decisions belong in the relevant service/handler layer. `with sharing` alone does not enforce CRUD/FLS.
- This initial release intentionally does not implement stack-trace caller detection, username exclusions, or method-name exclusions.

## Validation required before production use
Compile and run all tests in a scratch org or sandbox on the target API version. Confirm Custom Metadata field names, namespace behavior for `Type.forName`, Custom Permission configuration, and org-specific deployment policies. Review security and transaction behavior for each handler.
