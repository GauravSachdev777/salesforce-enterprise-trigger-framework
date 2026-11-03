@IsTest
private class TriggerExecutionGuardTest {
    @IsTest
    static void blocksOnlyConcurrentReentry() {
        TriggerExecutionGuard.clearAll();

        System.assertEquals(true, TriggerExecutionGuard.enter('Account:HandlerA'));
        System.assertEquals(false, TriggerExecutionGuard.enter('Account:HandlerA'));

        TriggerExecutionGuard.exit('Account:HandlerA');
        System.assertEquals(true, TriggerExecutionGuard.enter('Account:HandlerA'));
        TriggerExecutionGuard.exit('Account:HandlerA');
    }
}
