# Developer guidelines

- Keep triggers as one-line entry points into `TriggerDispatcher`.
- Keep each handler focused on one business responsibility.
- Implement `ITriggerHandler`.
- Use `TriggerContext` rather than reading global Trigger variables inside handlers.
- Use exact event names in metadata, separated by commas.
- Keep execution order explicit; ties are resolved by metadata DeveloperName.
- Use `TriggerBypass` only for a narrow, documented transaction scope and clear it in `finally`.
- Never rely on static Boolean flags as a universal recursion solution.
- Bulkify all handlers for 1–200 records.
- Add positive, negative, bulk, and bypass tests for each business handler.
- Do not put SOQL/DML in loops.
- Review sharing, CRUD and FLS requirements independently.
