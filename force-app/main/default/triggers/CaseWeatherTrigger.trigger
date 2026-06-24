trigger CaseWeatherTrigger on Case (after insert, after update) {
    CaseWeatherHandler.handleAfter(Trigger.new, Trigger.oldMap);
}