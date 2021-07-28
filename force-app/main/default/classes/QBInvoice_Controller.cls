/**
 * This class is the controller for the Global Action 'Sync with QB'. This will glue the code from the QBCallout class to
 * make the QB integration function properly.
 * @author Justin Wills
 * @created 10/06/2019
 * @version v1.0
 */

public with sharing class QBInvoice_Controller {

    public Id invId{get;set;}
    public Invoice__c inv {get;set;}

    public QBInvoice_Controller(ApexPages.StandardController controller) {
        invId = controller.getRecord().Id;
        inv = [SELECT Id,
                     Due_Date__c,
                      Subtotal__c,
                       Name, 
                       QBO_Id__c, 
                       QBO_SyncToken__c,
                       Terms__c,
                       Description__c,
                       Invoice__c.Opportunity__r.Name,
                       Invoice__c.Opportunity__r.Account.contact__r.email,
                       Invoice__c.Opportunity__r.Account.QBO_Id__c,
                       Invoice__c.opportunity__r.account.BillingCity,  
                       Invoice__c.opportunity__r.account.BillingStreet,  
                       Invoice__c.opportunity__r.account.BillingState,  
                       Invoice__c.opportunity__r.account.BillingPostalCode,  
                       Invoice__c.opportunity__r.account.BillingLatitude,  
                       Invoice__c.opportunity__r.account.BillingLongitude,  
                       Invoice__c.opportunity__r.account.BillingCountry,
                       Invoice__c.opportunity__r.account.name,
                       Invoice__c.opportunity__r.account.contact__r.Name,
                       Invoice__c.opportunity__r.account.contact__r.Phone,
                       Invoice__c.opportunity__r.account.ShippingCity, 
                       Invoice__c.opportunity__r.account.ShippingStreet, 
                       Invoice__c.opportunity__r.account.ShippingState, 
                       Invoice__c.opportunity__r.account.ShippingPostalCode, 
                       Invoice__c.opportunity__r.account.ShippingLatitude, 
                       Invoice__c.opportunity__r.account.ShippingLongitude, 
                       Invoice__c.opportunity__r.account.ShippingCountry 

                    FROM Invoice__c 
                    WHERE Id =: invId];
    }

    public Pagereference syncQB(){
        QBCallout callout = new QBCallout();
        QBInvoiceQueryJSON queryJson = callout.getInvoice(inv);

        //Check if an invoice was found
        if(queryJson != null){
            if(queryJson.QueryResponse.Invoice.size() == 1){
                inv.QBO_Id__c = queryJson.QueryResponse.Invoice[0].Id;
                inv.QBO_SyncToken__c = queryJson.QueryResponse.Invoice[0].SyncToken;
            }else{
                //Multiple Customer Error Handling
               throw new ListException(); 
            }
        }
        QBInvoiceResponseJSON res = callout.createInvoiceCall(inv);

        callout.updateRefreshToken();

        
        inv.QBO_Id__c = res.Invoice.Id;
        inv.QBO_SyncToken__c = res.Invoice.SyncToken;
        inv.tax__c = res.Invoice.TxnTaxDetail.TotalTax;
        inv.total__c = res.Invoice.TotalAmt;
        inv.Balance_Due__c = res.Invoice.Balance;
        //DML After Callouts

        update inv;
        return new PageReference('/'+ invId);
    }
    
}