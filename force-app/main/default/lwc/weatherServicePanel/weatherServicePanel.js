import { LightningElement, wire } from 'lwc';
import getUpcomingVisits from '@salesforce/apex/WeatherPanelController.getUpcomingVisits';

export default class WeatherServicePanel extends LightningElement {

    visits;
    error;

    @wire(getUpcomingVisits)
    wiredVisits({ data, error }) {
        if (data) {
            this.visits = data.map(visit => {
                let badgeClass = 'risk-badge risk-none';
                if (visit.Weather_Risk__c === 'High') {
                    badgeClass = 'risk-badge risk-high';
                } else if (visit.Weather_Risk__c === 'Medium') {
                    badgeClass = 'risk-badge risk-medium';
                } else if (visit.Weather_Risk__c === 'Low') {
                    badgeClass = 'risk-badge risk-low';
                }
                return { ...visit, badgeClass };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.visits = undefined;
        }
    }
}