import { LightningElement, wire } from 'lwc';
import getUpcomingVisits from '@salesforce/apex/WeatherPanelController.getUpcomingVisits';

export default class WeatherServicePanel extends LightningElement {

    visits;
    error;

    @wire(getUpcomingVisits)
    wiredVisits({ data, error }) {
        if (data) {
            this.visits = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.visits = undefined;
        }
    }
}