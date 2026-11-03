/**
 * Immutable snapshot of the trigger context supplied to handlers.
 * The contained SObjects remain mutable, as required for before triggers.
 */
public class TriggerContext {
    public Schema.SObjectType objectType { get; private set; }
    public List<SObject> newRecords { get; private set; }
    public Map<Id, SObject> oldRecords { get; private set; }
    public System.TriggerOperation operation { get; private set; }

    public TriggerContext(
        Schema.SObjectType objectType,
        List<SObject> newRecords,
        Map<Id, SObject> oldRecords,
        System.TriggerOperation operation
    ) {
        this.objectType = objectType;
        this.newRecords = newRecords == null ? new List<SObject>() : newRecords;
        this.oldRecords = oldRecords == null ? new Map<Id, SObject>() : oldRecords;
        this.operation = operation;
    }

    public Boolean isInsert() {
        return operation == System.TriggerOperation.BEFORE_INSERT ||
            operation == System.TriggerOperation.AFTER_INSERT;
    }

    public Boolean isUpdate() {
        return operation == System.TriggerOperation.BEFORE_UPDATE ||
            operation == System.TriggerOperation.AFTER_UPDATE;
    }

    public Boolean isDelete() {
        return operation == System.TriggerOperation.BEFORE_DELETE ||
            operation == System.TriggerOperation.AFTER_DELETE;
    }

    public Boolean isUndelete() {
        return operation == System.TriggerOperation.AFTER_UNDELETE;
    }

    public Boolean isBefore() {
        return operation == System.TriggerOperation.BEFORE_INSERT ||
            operation == System.TriggerOperation.BEFORE_UPDATE ||
            operation == System.TriggerOperation.BEFORE_DELETE;
    }

    public Boolean isAfter() {
        return !isBefore();
    }

    public Map<Id, SObject> getNewMap() {
        Map<Id, SObject> result = new Map<Id, SObject>();
        for (SObject record : newRecords) {
            if (record.Id != null) {
                result.put(record.Id, record);
            }
        }
        return result;
    }
}
