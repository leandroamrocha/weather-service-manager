@isTest
private class WeatherServiceTest {

    @isTest
    static void getForecastForCity_happyPath() {
        Test.setMock(HttpCalloutMock.class, new WeatherCalloutMock());

        Test.startTest();
        WeatherService.Forecast f =
            WeatherService.getForecastForCity('São Paulo', Date.today().addDays(2));
        Test.stopTest();

        System.assertEquals('High', f.riskLevel, 'Tempestade + chuva alta deve dar High');
        System.assertEquals(95, f.weatherCode);
        System.assertEquals(100, f.precipProbability);
    }
}