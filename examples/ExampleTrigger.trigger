trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    TriggerDispatcher.run(Account.SObjectType);
}
