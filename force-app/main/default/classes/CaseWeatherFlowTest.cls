@isTest
private class CaseWeatherFlowTest {

    @isTest
    static void insertCase_buscaPrevisaoEPreencheCampos() {
        Test.setMock(HttpCalloutMock.class, new WeatherCalloutMock());

        Test.startTest();
        Case c = new Case(
            Subject = 'Visita teste',
            Visit_City__c = 'São Paulo',
            Visit_Date__c = Date.today().addDays(2)
        );
        insert c;
        Test.stopTest();

        Case resultado = [
            SELECT Weather_Risk__c, Precip_Probability__c, Weather_Summary__c
            FROM Case WHERE Id = :c.Id
        ];
        System.assertEquals('High', resultado.Weather_Risk__c, 'Mock devolve tempestade = High');
    }

@isTest
    static void reschedule_mudaDataDoCase() {
        Test.setMock(HttpCalloutMock.class, new WeatherCalloutMock());

        // GIVEN: um Case já existente (bypass evita o callout no setup)
        CaseWeatherHandler.bypass = true;
        Case c = new Case(
            Subject = 'Visita',
            Visit_City__c = 'São Paulo',
            Visit_Date__c = Date.today().addDays(2)
        );
        insert c;
        CaseWeatherHandler.bypass = false;

        // WHEN: remarca para outra data
        Date novaData = Date.today().addDays(5);
        Test.startTest();
        WeatherPanelController.reschedule(c.Id, novaData);
        Test.stopTest();

        // THEN: a data mudou
        Case resultado = [SELECT Visit_Date__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(novaData, resultado.Visit_Date__c, 'A data deve ter sido atualizada');
    }

    @isTest
    static void reevaluate_disparaQueueable() {
        Test.setMock(HttpCalloutMock.class, new WeatherCalloutMock());

        CaseWeatherHandler.bypass = true;
        Case c = new Case(
            Subject = 'Visita',
            Visit_City__c = 'São Paulo',
            Visit_Date__c = Date.today().addDays(2)
        );
        insert c;
        CaseWeatherHandler.bypass = false;

        // WHEN: reavalia manualmente
        Test.startTest();
        WeatherPanelController.reevaluate(c.Id);
        Test.stopTest();   // força o queueable disparado pelo reevaluate

        // THEN: o clima foi preenchido
        Case resultado = [SELECT Weather_Risk__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('High', resultado.Weather_Risk__c);
    }

    @isTest
    static void getUpcomingVisits_retornaVisitasFuturas() {
        CaseWeatherHandler.bypass = true;
        Case c = new Case(
            Subject = 'Visita',
            Visit_City__c = 'São Paulo',
            Visit_Date__c = Date.today().addDays(3)
        );
        insert c;
        CaseWeatherHandler.bypass = false;

        Test.startTest();
        List<Case> visitas = WeatherPanelController.getUpcomingVisits();
        Test.stopTest();

        System.assert(!visitas.isEmpty(), 'Deve retornar ao menos a visita criada');
    }
}