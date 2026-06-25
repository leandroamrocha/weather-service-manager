import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUpcomingVisits from '@salesforce/apex/WeatherPanelController.getUpcomingVisits';
import reevaluate from '@salesforce/apex/WeatherPanelController.reevaluate';
import reschedule from '@salesforce/apex/WeatherPanelController.reschedule';

export default class WeatherServicePanel extends LightningElement {

    visits;
    error;
    wiredResult;

    @wire(getUpcomingVisits)
    wiredVisits(result) {
        this.wiredResult = result;
        if (result.data) {
            this.visits = result.data.map(visit => {
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
        } else if (result.error) {
            this.error = result.error;
            this.visits = undefined;
        }
    }

    async handleReevaluate(event) {
        const caseId = event.target.dataset.id;
        try {
            await reevaluate({ caseId });
            this.showToast('Reavaliação iniciada', 'O clima será atualizado em instantes.', 'success');
        } catch (e) {
            this.showToast('Erro', e.body.message, 'error');
        }
    }

    async handleReschedule(event) {
        const caseId = event.target.dataset.id;
        const newDate = prompt('Nova data da visita (formato AAAA-MM-DD):');
        if (!newDate) return;
        try {
            await reschedule({ caseId, newDate });
            this.showToast('Visita remarcada', 'O clima será recalculado para a nova data.', 'success');
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.showToast('Erro', e.body.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}