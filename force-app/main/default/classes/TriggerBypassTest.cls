@IsTest
private class TriggerBypassTest {
    @IsTest
    static void bypassCanBeAddedAndCleared() {
        TriggerBypass.clearAll();
        System.assertEquals(false, TriggerBypass.isBypassed('Account_Audit'));

        TriggerBypass.bypassHandler('Account_Audit');
        System.assertEquals(true, TriggerBypass.isBypassed('Account_Audit'));

        TriggerBypass.clearHandler('Account_Audit');
        System.assertEquals(false, TriggerBypass.isBypassed('Account_Audit'));
    }
}
