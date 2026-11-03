/**
 * Transaction-scoped, explicit handler bypass.
 * Always clear a bypass in a finally block when its scope is temporary.
 */
public class TriggerBypass {
    private static Set<String> bypassedHandlers = new Set<String>();

    public static void bypassHandler(String handlerDeveloperName) {
        if (!String.isBlank(handlerDeveloperName)) {
            bypassedHandlers.add(handlerDeveloperName.trim());
        }
    }

    public static void clearHandler(String handlerDeveloperName) {
        if (!String.isBlank(handlerDeveloperName)) {
            bypassedHandlers.remove(handlerDeveloperName.trim());
        }
    }

    public static Boolean isBypassed(String handlerDeveloperName) {
        return !String.isBlank(handlerDeveloperName) &&
            bypassedHandlers.contains(handlerDeveloperName.trim());
    }

    @TestVisible
    private static void clearAll() {
        bypassedHandlers.clear();
    }
}
