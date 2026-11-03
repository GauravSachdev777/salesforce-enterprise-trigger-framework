/**
 * Contract implemented by every metadata-registered trigger handler.
 */
public interface ITriggerHandler {
    void run(TriggerContext context);
}
