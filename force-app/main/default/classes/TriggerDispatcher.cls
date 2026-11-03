/**
 * Metadata-driven trigger handler dispatcher.
 *
 * Trigger entry point:
 * TriggerDispatcher.run(
 *     Account.SObjectType, Trigger.new, Trigger.oldMap, Trigger.operationType
 * );
 */
public class TriggerDispatcher {
    public static void run(
        Schema.SObjectType objectType,
        List<SObject> newRecords,
        Map<Id, SObject> oldRecords,
        System.TriggerOperation operation
    ) {
        if (objectType == null || operation == null) {
            throw new TriggerFrameworkException('Object type and trigger operation are required.');
        }

        TriggerContext context = new TriggerContext(
            objectType, newRecords, oldRecords, operation
        );
        String objectApiName = objectType.getDescribe().getName();

        for (Trigger_Handler__mdt config :
            TriggerMetadataService.getHandlersForObject(objectApiName)) {

            if (!isEventEnabled(config.Trigger_Events__c, operation)) {
                continue;
            }
            if (TriggerBypass.isBypassed(config.DeveloperName)) {
                continue;
            }
            if (!String.isBlank(config.Bypass_Custom_Permission__c) &&
                FeatureManagement.checkPermission(config.Bypass_Custom_Permission__c)) {
                continue;
            }

            executeHandler(config, context, objectApiName);
        }
    }

    private static Boolean isEventEnabled(
        String configuredEvents,
        System.TriggerOperation operation
    ) {
        if (String.isBlank(configuredEvents)) {
            return false;
        }

        String requestedEvent = String.valueOf(operation).toUpperCase();
        for (String configuredEvent : configuredEvents.split(',')) {
            if (configuredEvent != null &&
                configuredEvent.trim().toUpperCase() == requestedEvent) {
                return true;
            }
        }
        return false;
    }

    private static void executeHandler(
        Trigger_Handler__mdt config,
        TriggerContext context,
        String objectApiName
    ) {
        if (String.isBlank(config.Handler_Class__c)) {
            throw new TriggerFrameworkException(
                'Handler class is blank for metadata record ' + config.DeveloperName
            );
        }

        Type handlerType = Type.forName(config.Handler_Class__c.trim());
        if (handlerType == null) {
            throw new TriggerFrameworkException(
                'Unable to find handler class ' + config.Handler_Class__c +
                ' configured by ' + config.DeveloperName
            );
        }

        Object instance = handlerType.newInstance();
        if (!(instance instanceof ITriggerHandler)) {
            throw new TriggerFrameworkException(
                'Configured class ' + config.Handler_Class__c +
                ' must implement ITriggerHandler.'
            );
        }

        String executionKey = objectApiName + ':' + config.DeveloperName;
        if (!TriggerExecutionGuard.enter(executionKey)) {
            return;
        }

        try {
            ((ITriggerHandler) instance).run(context);
        } finally {
            TriggerExecutionGuard.exit(executionKey);
        }
    }
}
