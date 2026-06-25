@isTest
private class CaseWeatherFlowTest {

    @isTest
    static void insertCase_buscaPrevisaoEPreencheCampos() {
        // GIVEN: o mock no lugar da internet
        Test.setMock(HttpCalloutMock.class, new WeatherCalloutMock());

        // WHEN: cria um Case com cidade e data futura
        Test.startTest();
        Case c = new Case(
            Subject = 'Visita teste',
            Visit_City__c = 'São Paulo',
            Visit_Date__c = Date.today().addDays(2)
        );
        insert c;
        Test.stopTest();   // força o Queueable a rodar

        // THEN: os campos de clima foram preenchidos
        Case resultado = [
            SELECT Weather_Risk__c, Precip_Probability__c, Weather_Summary__c
            FROM Case WHERE Id = :c.Id
        ];
        System.assertEquals('High', resultado.Weather_Risk__c, 'Mock devolve tempestade = High');
    }
}