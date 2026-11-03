/**
 * Prevents a handler from re-entering itself while it is already executing.
 * Sequential trigger invocations are allowed after the current invocation exits.
 */
public class TriggerExecutionGuard {
    private static Set<String> activeExecutions = new Set<String>();

    public static Boolean enter(String executionKey) {
        if (String.isBlank(executionKey) || activeExecutions.contains(executionKey)) {
            return false;
        }
        activeExecutions.add(executionKey);
        return true;
    }

    public static void exit(String executionKey) {
        activeExecutions.remove(executionKey);
    }

    @TestVisible
    private static void clearAll() {
        activeExecutions.clear();
    }
}
