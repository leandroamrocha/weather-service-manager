public class WeatherCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> caseIds;
    public WeatherCalloutQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds;
        
        public void execute(QueueableContext ctx) {
            List<Case> cases = [
            SELECT Id, Visit_City__c, Visit_Date__c
            FROM Case WHERE Id IN :caseIds WITH USER_MODE
        ];
            
            List<Case> toUpdate = new List<Case>();
            for (Case c : cases) {
                Case upd = new Case(Id = c.Id);
                try {
                    WeatherService.Forecast f =
                        WeatherService.getForecastForCity(c.Visit_City__c, c.Visit_Date__c);
                    upd.Weather_Risk__c       = f.riskLevel;
                    upd.Precip_Probability__c = f.precipProbability;
                    upd.Max_Temp__c           = f.maxTemp;
                    upd.Weather_Summary__c    = f.summary;
                    upd.Weather_Sync_Error__c = null;
                } catch (Exception e) {
                    upd.Weather_Risk__c       = 'None';
                    upd.Weather_Sync_Error__c = e.getMessage().abbreviate(255);
                }
                toUpdate.add(upd);
            }
            
            if (!toUpdate.isEmpty()) {
                update as user toUpdate;
            }
        }
    }
}