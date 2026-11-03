# Best Practices

- Keep trigger files thin.
- Prefer focused handlers over monolithic classes.
- Use exact token matching for configured events and keys.
- Cache metadata per transaction where appropriate.
- Fail visibly on invalid handler configuration.
- Use stable ordering and define a tie-breaker.
- Make integrations idempotent.
- Use asynchronous/event-driven patterns for callouts where appropriate.
- Do not treat trigger execution as proof that CRUD/FLS is enforced.
- Avoid verbose per-record production logging.
- Do not put credentials or secrets in Custom Metadata.
- Test multiple DML operations in one transaction, not only a single insert.
