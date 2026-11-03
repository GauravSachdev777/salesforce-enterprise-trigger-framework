/**
 * Loads and transaction-caches active handler metadata by object API name.
 */
public class TriggerMetadataService {
    private static Map<String, List<Trigger_Handler__mdt>> handlersByObject =
        new Map<String, List<Trigger_Handler__mdt>>();

    public static List<Trigger_Handler__mdt> getHandlersForObject(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return new List<Trigger_Handler__mdt>();
        }

        String cacheKey = objectApiName.trim().toLowerCase();
        if (!handlersByObject.containsKey(cacheKey)) {
            List<Trigger_Handler__mdt> records = [
                SELECT DeveloperName, Object_API_Name__c, Handler_Class__c,
                       Execution_Order__c, Active__c, Trigger_Events__c,
                       Bypass_Custom_Permission__c
                FROM Trigger_Handler__mdt
                WHERE Active__c = true
                  AND Object_API_Name__c = :objectApiName
                ORDER BY Execution_Order__c ASC, DeveloperName ASC
            ];
            handlersByObject.put(cacheKey, records);
        }
        return handlersByObject.get(cacheKey);
    }

    @TestVisible
    private static void clearCache() {
        handlersByObject.clear();
    }
}
