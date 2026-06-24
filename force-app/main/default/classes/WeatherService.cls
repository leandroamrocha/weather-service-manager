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
    
    @TestVisible
    private static String describeCode(Integer code){
        Map<Integer, String> m = new Map<Integer, String>{
            1 => 'Mainly clear',
            2 => 'Partly cloudy',
            45 => 'Fog',
            63 => 'Moderate rain',
            65 => 'Heavy rain',
            80 => 'Showers',
            96 => 'Thunderstorm with hail'
        };
        return m.containsKey(code) ? m.get(code) : 'Unknown (' + code + ')';
    }
    
    @TestVisible
    private static String assessRisk(Integer precip, Integer code, Decimal maxTemp) {
        Set<Integer> severos = new Set<Integer>{65, 67, 75, 82, 95, 96, 99};
        if (precip == null) precip = 0;
        
        if (severos.contains(code) || precip >= 70) {
            return 'High';
        } else if (precip >= 40 || (maxTemp != null && maxTemp >= 38)) {
            return 'Medium';
        } else if (precip >= 20) {
            return 'Low';
        }
        return 'None';
    }
    
    public static Decimal[] getCoordinates(String city) {
        
        if (String.isBlank(city)) {
            throw new WeatherException('City is required.');
        }
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(20000);
        req.setEndpoint(
            'callout:Open_Meteo_Geocoding/v1/search'
            + '?name=' + EncodingUtil.urlEncode(city, 'UTF-8')
            + '&count=1&language=pt&format=json'
            );
        
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new WeatherException('Geocoding failed: ' + res.getStatusCode());
        }
        
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> results = (List<Object>) body.get('results');
        if (results == null || results.isEmpty()) {
            throw new WeatherException('No coordinates found for: ' + city);
        }
        Map<String, Object> first = (Map<String, Object>) results[0];
        Decimal lat = (Decimal) first.get('latitude');
        Decimal lon = (Decimal) first.get('longitude');
        
        return new Decimal[]{ lat, lon };
    }
    
    @TestVisible
    private static Forecast parseForecast(String jsonBody, Decimal lat, Decimal lon, Date targetDate) {
        
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        Map<String, Object> daily = (Map<String, Object>) body.get('daily');
        List<Object> times    = (List<Object>) daily.get('time');
        List<Object> maxTemps = (List<Object>) daily.get('temperature_2m_max');
        List<Object> minTemps = (List<Object>) daily.get('temperature_2m_min');
        List<Object> precips  = (List<Object>) daily.get('precipitation_probability_max');
        List<Object> codes    = (List<Object>) daily.get('weathercode');
        
        String wanted = String.valueOf(targetDate);   // "2026-06-23"
        Integer idx = -1;
        for (Integer i = 0; i < times.size(); i++) {
            if (((String) times[i]) == wanted) {
                idx = i;
                break;
            }
        }
        if (idx == -1) {
            throw new WeatherException('Date outside the 16-day window.');
        }
        
        Forecast f = new Forecast();
        f.latitude          = lat;
        f.longitude         = lon;
        f.forecastDate      = targetDate;
        f.maxTemp           = toDecimal(maxTemps[idx]);
        f.minTemp           = toDecimal(minTemps[idx]);
        f.precipProbability = toInteger(precips[idx]);
        f.weatherCode       = toInteger(codes[idx]);
        f.summary           = describeCode(f.weatherCode);
        f.riskLevel         = assessRisk(f.precipProbability, f.weatherCode, f.maxTemp);
        return f;
    }
    
}