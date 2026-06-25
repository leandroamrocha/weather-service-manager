public with sharing class WeatherPanelController {
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getUpcomingVisits() {
        return [
            SELECT Id, CaseNumber, Subject, Status,
                   Visit_City__c, Visit_Date__c,
                   Weather_Risk__c, Precip_Probability__c,
                   Max_Temp__c, Weather_Summary__c, Weather_Sync_Error__c
            FROM Case
            WHERE Visit_Date__c >= TODAY
              AND Visit_City__c != null
            WITH USER_MODE
            ORDER BY Visit_Date__c ASC
            LIMIT 200
        ];
    }
    @AuraEnabled
    public static void reevaluate(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('A Case Id is required.');
        }
        System.enqueueJob(new WeatherCalloutQueueable(new Set<Id>{ caseId }));
    }
    
    @AuraEnabled
    public static void reschedule(Id caseId, Date newDate) {
        if (caseId == null || newDate == null) {
            throw new AuraHandledException('Case Id and new date are required.');
        }
        if (newDate < Date.today()) {
            throw new AuraHandledException('New visit date cannot be in the past.');
        }
        update as user new Case(Id = caseId, Visit_Date__c = newDate);
    }
}