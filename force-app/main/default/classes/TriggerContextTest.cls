@IsTest
private class TriggerContextTest {
    @IsTest
    static void exposesInsertContext() {
        Account accountRecord = new Account(Name = 'Context test');
        TriggerContext context = new TriggerContext(
            Account.SObjectType,
            new List<SObject>{ accountRecord },
            null,
            System.TriggerOperation.BEFORE_INSERT
        );

        System.assertEquals('Account', context.objectType.getDescribe().getName());
        System.assertEquals(1, context.newRecords.size());
        System.assertEquals(0, context.oldRecords.size());
        System.assert(context.isInsert());
        System.assert(context.isBefore());
        System.assertEquals(0, context.getNewMap().size(),
            'New records do not have IDs before insert.');
    }

    @IsTest
    static void exposesUpdateContextAndMaps() {
        Account oldAccount = new Account(Id = '001000000000001AAA', Name = 'Old');
        Account newAccount = new Account(Id = oldAccount.Id, Name = 'New');
        TriggerContext context = new TriggerContext(
            Account.SObjectType,
            new List<SObject>{ newAccount },
            new Map<Id, SObject>{ oldAccount.Id => oldAccount },
            System.TriggerOperation.AFTER_UPDATE
        );

        System.assert(context.isUpdate());
        System.assert(context.isAfter());
        System.assertEquals('Old', ((Account) context.oldRecords.get(oldAccount.Id)).Name);
        System.assertEquals('New', ((Account) context.getNewMap().get(newAccount.Id)).Name);
    }
}
