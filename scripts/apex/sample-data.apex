// Sample data — run via: sf apex run --file scripts/apex/sample-data.apex
// Creates a few field-visit Cases. The trigger will fetch live forecasts.
List<Case> demo = new List<Case>{
    new Case(Subject = 'AC unit install',     Visit_City__c = 'São Paulo',      Visit_Date__c = Date.today().addDays(1)),
    new Case(Subject = 'Fiber rollout',       Visit_City__c = 'Rio de Janeiro', Visit_Date__c = Date.today().addDays(2)),
    new Case(Subject = 'Solar panel survey',  Visit_City__c = 'Curitiba',       Visit_Date__c = Date.today().addDays(3)),
    new Case(Subject = 'Generator service',   Visit_City__c = 'Belo Horizonte', Visit_Date__c = Date.today().addDays(4))
};
insert demo;
System.debug('Inserted ' + demo.size() + ' demo cases. Forecasts will populate asynchronously.');
