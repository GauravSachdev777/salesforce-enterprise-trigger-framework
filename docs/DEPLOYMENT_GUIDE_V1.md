# Deployment guide

1. Deploy the contents of `force-app/main/default` using Salesforce CLI, VS Code, DevOps Center, or your approved deployment tool.
2. Run the included Apex tests.
3. Create handler registration records under Setup → Custom Metadata Types → Trigger Handler → Manage Records.
4. Create any referenced Custom Permissions and assign them through Permission Sets.
5. Add one thin trigger per object, following the entry-point example in `IMPLEMENTATION_V1.md`.
6. Add handler classes and tests for the business behavior in your org.

Do not activate a handler metadata record until its Apex class is deployed and tested.

## Package scope
The `manifest/package.xml` deploys Apex classes and the `Trigger_Handler__mdt` type. It does not deploy object triggers or business-specific handler registrations.
