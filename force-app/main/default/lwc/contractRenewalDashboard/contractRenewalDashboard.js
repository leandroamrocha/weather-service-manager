import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getExpiringContracts from '@salesforce/apex/ContractRenewalController.getExpiringContracts';
import createRenewal from '@salesforce/apex/ContractRenewalController.createRenewal';

const COLUMNS = [
    { label: 'Contrato', fieldName: 'contractNumber', type: 'text' },
    { label: 'Conta', fieldName: 'accountName', type: 'text' },
    { label: 'Vencimento', fieldName: 'endDate', type: 'date' },
    { label: 'Dias p/ vencer', fieldName: 'daysUntilExpiration', type: 'number',
      cellAttributes: { alignment: 'center' } },
    { label: 'Urgencia', fieldName: 'urgency', type: 'text' },
    { label: 'Status Renovacao', fieldName: 'renewalStatus', type: 'text' },
    {
        type: 'button',
        typeAttributes: {
            label: 'Criar Renovacao',
            name: 'create_renewal',
            variant: 'brand',
            disabled: { fieldName: 'hasRenewal' }
        }
    }
];

export default class ContractRenewalDashboard extends LightningElement {
    columns = COLUMNS;
    contracts = [];
    error;
    wiredResult; // guarda o resultado do wire para o refreshApex

    @wire(getExpiringContracts)
    wiredContracts(result) {
        this.wiredResult = result;
        if (result.data) {
            this.contracts = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.contracts = [];
        }
    }

    get hasContracts() {
        return this.contracts && this.contracts.length > 0;
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'create_renewal') {
            try {
                await createRenewal({ contractId: row.contractId });
                this.showToast('Sucesso', 'Renovacao criada para ' + row.contractNumber, 'success');
                // Atualiza a tabela: o contrato agora tem renovacao
                await refreshApex(this.wiredResult);
            } catch (e) {
                const msg = e.body ? e.body.message : 'Erro ao criar renovacao';
                this.showToast('Erro', msg, 'error');
            }
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}