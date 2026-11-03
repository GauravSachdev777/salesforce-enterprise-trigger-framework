# Developer Guidelines

## Handler design

- Implement the agreed handler interface.
- Keep each handler focused on one responsibility.
- Delegate complex work to service/domain classes.
- Detect relevant field changes using new and old values.
- Use `addError()` for record-level validation failures where appropriate.

## Bulk safety

- Assume up to 200 records per trigger invocation.
- Never perform SOQL or DML inside record loops.
- Query by collections of IDs or business keys.
- Use collection-based DML.
- Consider CPU, heap, query rows, DML rows, callouts, and async limits.

## Trigger contexts

- Use before insert/update to set or validate fields on triggering records.
- Use after contexts when IDs or persisted relationships are needed.
- Do not issue DML on the same triggering records from before context.
- Do not assume Trigger.new, Trigger.old, Trigger.newMap, or Trigger.oldMap exists in every operation.

## Bypass

- Prefer Custom Permissions for administrator-controlled bypass.
- Use a central programmatic bypass API for controlled data operations.
- Always clear programmatic bypass in `finally`.
- Never infer the initiating class by parsing stack traces.

## Recursion

Do not use a broad static Boolean as a default recursion solution. Distinguish re-entry protection, once-per-transaction behaviour, record-level protection, and business idempotency. Document and test the chosen scope.

## Exceptions

Do not swallow exceptions to hide failures. Use `addError()` for expected record validation failures. Re-throw failures that should roll back the transaction. Avoid logging secrets or unnecessary personal data.
