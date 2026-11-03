# Salesforce Enterprise Trigger Framework

A reusable, metadata-driven Apex Trigger Framework intended to standardize trigger execution across Salesforce projects and client orgs.

> **Status: Architecture baseline / starter repository.** The framework design is documented, but the Apex implementation must be completed, compiled, and tested against the target org's API version before production use.

## What this project aims to provide

- One thin trigger per object.
- A central dispatcher.
- A consistent handler interface and trigger context.
- Custom Metadata-driven handler registration, activation, event selection, and execution order.
- Explicit bypass controls.
- Deliberate recursion and idempotency strategies.
- Bulk-safe handler development standards.
- Consistent testing, deployment, and pull-request governance.

## Repository layout

```text
docs/                 Architecture and engineering standards
force-app/            Salesforce DX source structure
examples/             Example trigger and handler patterns
manifest/             Package manifest
.github/              Contribution and issue templates
```

## Documentation

- [Framework design](docs/FRAMEWORK_DESIGN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Developer guidelines](docs/DEVELOPER_GUIDELINES.md)
- [Deployment guide](docs/DEPLOYMENT_GUIDE.md)
- [Best practices](docs/BEST_PRACTICES.md)

## Getting started

1. Read the framework design document.
2. Confirm the CMDT field API names and supported trigger operations for your org.
3. Implement and compile the framework core in a Salesforce DX project.
4. Add CMDT registrations and permission configuration.
5. Add handlers and tests.
6. Validate bulk, recursion, bypass, security, and automation interactions in a representative sandbox.
7. Deploy only after code review and successful validation.

## Design principles

1. One trigger per object.
2. No business logic in triggers.
3. Small, single-responsibility handlers.
4. Exact configuration matching.
5. Explicit bypass rather than stack-trace inference.
6. Bulk safety and meaningful tests are mandatory.
7. Code and metadata configuration ship together.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Contributions should include tests and documentation where appropriate.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
