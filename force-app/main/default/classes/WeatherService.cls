/**
 * @description add your description here
 * @Date 22 June 2026
 */
public with sharing class WeatherService {

    public class WeatherException extends Exception {}

    public class Forecast {   
    @AuraEnabled public Decimal latitude;
    @AuraEnabled public Decimal longitude;
    @AuraEnabled public Decimal minTemp;
    @AuraEnabled public Decimal maxTemp;
    @AuraEnabled public Integer weatherCode;    
    @AuraEnabled public Date forecastDate;
    @AuraEnabled public Integer precipProbability;
    @AuraEnabled public String summary;
    @AuraEnabled public String visitCity;
    @AuraEnabled public String visitDate;
    @AuraEnabled public String weatherRisk;
    @AuraEnabled public String syncError;
    @AuraEnabled public String riskLevel;
    }

    private static Decimal toDecimal(Object o) {
    return o == null ? null : Decimal.valueOf(String.valueOf(o));
    }


private static Integer toInteger(Object o) {
    return o == null ? null : Integer.valueOf(String.valueOf(o));
}
    
}