@isTest
public class WeatherCalloutMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        String url = req.getEndpoint();

        if (url.contains('/v1/search')) {
            res.setBody(
                '{"results":[{"latitude":-23.55,"longitude":-46.63}]}'
            );
        } else if (url.contains('/v1/forecast')) {
            res.setBody(
                '{"daily":{' +
                  '"time":["' + String.valueOf(Date.today().addDays(2)) + '"],' +
                  '"temperature_2m_max":[24.5],' +
                  '"temperature_2m_min":[14.1],' +
                  '"precipitation_probability_max":[100],' +
                  '"weathercode":[95]' +
                '}}'
            );
        }
        return res;
    }
}