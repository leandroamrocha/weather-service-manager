public with sharing class CaseWeatherHandler {
    @TestVisible private static Boolean bypass = false;
    
    public static void handleAfter(List<Case> newList, Map<Id, Case> oldMap) {
        if (bypass) return;
        
        Set<Id> toProcess = new Set<Id>();
        for (Case c : newList) {
            if (String.isBlank(c.Visit_City__c) || c.Visit_Date__c == null) {
                continue;
            }
            if (c.Visit_Date__c < Date.today()) {
                continue;
            }
            
            Boolean changed = (oldMap == null);
            if (oldMap != null) {
                Case old = oldMap.get(c.Id);
                changed = (old.Visit_City__c != c.Visit_City__c)
                    || (old.Visit_Date__c != c.Visit_Date__c);
            }
            if (changed) {
                toProcess.add(c.Id);
            }
        }
        if (!toProcess.isEmpty() && !System.isBatch() && !System.isFuture()) {
            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(new WeatherCalloutQueueable(toProcess));
            }
        }
    }
}