# Contributing

Thanks for helping improve this Salesforce trigger framework.

## Contribution expectations

1. Open an issue for significant design changes before implementing them.
2. Keep changes focused and explain the problem they solve.
3. Include Apex tests for behavioural changes.
4. Include or update documentation when contracts or configuration change.
5. Do not introduce stack-trace-based routing or broad static-Boolean recursion guards.
6. Do not add SOQL or DML inside loops.
7. Keep secrets, org identifiers, customer data, and credentials out of commits.

## Pull request checklist

- [ ] The change follows the framework architecture.
- [ ] Tests cover positive, negative, and bulk behaviour where relevant.
- [ ] CMDT and permission changes are included.
- [ ] Documentation is updated.
- [ ] Security and automation interactions have been considered.
