import { LightningElement, wire, track } from 'lwc';
import getOpenCasesByRisk from '@salesforce/apex/CaseSlaController.getOpenCasesByRisk';

export default class CaseSlaDashboard extends LightningElement {
    @track cases = [];
    error;

    @wire(getOpenCasesByRisk)
    wiredCases({ data, error }) {
        if (data) {
            // Enriqulece cada linha com a classe CSS do badge de status
            this.cases = data.map((row) => {
                return { ...row, badgeClass: this.resolveBadgeClass(row.slaStatusLive) };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.cases = [];
        }
    }

    resolveBadgeClass(status) {
        const base = 'slds-badge sla-badge ';
        if (status === 'Breached') return base + 'sla-breached';
        if (status === 'At Risk') return base + 'sla-atrisk';
        if (status === 'On Track') return base + 'sla-ontrack';
        return base;
    }

    get hasCases() {
        return this.cases && this.cases.length > 0;
    }
}