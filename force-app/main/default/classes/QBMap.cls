/**
 * Map QBO API JSON to SF Objects and vice versa
 * @author Justin Wills
 * @created 01/07/2020
 * @version v1.0
 */

public class QBMap {
  
    /**
     * Map the SF Account data to the QB customer JSON
     * @param acc The account data that is mapped
     * @return the QB json that can be used to CRUD a customer in QBO
     */
    public static String mapAccountData(Account acc){
        QBCustomerJSON.Customer customer = new QBCustomerJSON.Customer();

        //Map given account fields
        customer.CompanyName = acc.Name;
        customer.Taxable = True;       
        customer.SyncToken = acc.QBO_SyncToken__c;
        customer.sparse = True;

        //Create Shipping address
        QBCustomerJSON.BillAddr shipAddy = new QBCustomerJSON.BillAddr();
        shipAddy.City = acc.ShippingCity;
        shipAddy.Line1 = acc.ShippingStreet;
        shipAddy.CountrySubDivisionCode = acc.ShippingState;
        shipAddy.PostalCode = acc.ShippingPostalCode;
        shipAddy.Country = acc.ShippingCountry;
        customer.ShipAddr = shipAddy;

        customer.PrintOnCheckName = acc.Name;
        //Create Primary Phone
        QBCustomerJSON.PrimaryPhone phone = new QBCustomerJSON.PrimaryPhone ();
        phone.FreeFormNumber = acc.Phone;
        customer.PrimaryPhone = phone;
        //customer.PrimaryEmailAddr = acc.Email; //does not have correct mapping
        customer.Job = False;
        customer.IsProject = False;
        customer.Id = acc.QBO_ID__c;
        customer.DisplayName = acc.Name;

        //Create Billing Address
        QBCustomerJSON.BillAddr billAddy = new QBCustomerJSON.BillAddr();
        billAddy.City = acc.BillingCity;
        billAddy.Line1 = acc.BillingStreet;
        billAddy.CountrySubDivisionCode = acc.BillingState;
        billAddy.PostalCode = acc.BillingPostalCode;
        billAddy.Lat = String.valueOf(acc.BillingLatitude);
        billAddy.Long_x = String.valueOf(acc.BillingLongitude);
        billAddy.Country = acc.BillingCountry;
        customer.BillAddr = billAddy;

        customer.Active = True;

        return JSON.serialize(customer, True).replace('"Long_x":', '"Long":');
    }

    /**
     * Map the SF Contact data to the QB customer JSON
     * @param acc The account data that is mapped
     * @param QBID the qbid if the record is not synced
     * @return the QB json that can be used to CRUD a customer in QBO
     */
    public static String mapContactData(Contact con, String QBID){
        QBCustomerJSON.Customer customer = new QBCustomerJSON.Customer();

        //Map given contact fields
        customer.GivenName = con.FirstName;
        customer.FamilyName = con.LastName;
        customer.CompanyName = con.account.Name;
        customer.Taxable = True;
        customer.SyncToken = con.QBO_SyncToken__c;
        customer.sparse = True;
        /*
        //Create Shipping address
        QBCustomerJSON.BillAddr shipAddy = new QBCustomerJSON.BillAddr();
        shipAddy.City = con.ShippingCity;
        shipAddy.Line1 = acc.ShippingStreet;
        shipAddy.CountrySubDivisionCode = acc.ShippingCountry;
        shipAddy.PostalCode = acc.ShippingPostalCode;
        customer.ShipAddr = shipAddy;
        */
        customer.PrintOnCheckName = con.Account.Name;
        //Create Primary Phone
        QBCustomerJSON.PrimaryPhone phone = new QBCustomerJSON.PrimaryPhone ();
        phone.FreeFormNumber = con.Phone;
        customer.PrimaryPhone = phone;
        
        //Create Email address
        QBCustomerJSON.PrimaryEmailAddr email = new QBCustomerJSON.PrimaryEmailAddr();
        email.Address = con.Email;
        customer.PrimaryEmailAddr = email; 
        
        //Create ParentReference
        QBCustomerJSON.ParentRef pr = new QBCustomerJSON.ParentRef();
        pr.value = con.Account.QBO_Id__c;
        if(pr.value == null){
            pr.value = QBID;
        }
        customer.ParentRef = pr;
        customer.BillWithParent = True;
        customer.Job = True;
        customer.IsProject = False;
        customer.Id = con.QBO_ID__c;

        
        //Create Billing Address
        QBCustomerJSON.BillAddr billAddy = new QBCustomerJSON.BillAddr();
        billAddy.City = con.Account.BillingCity;
        billAddy.Line1 = con.Account.BillingStreet;
        billAddy.CountrySubDivisionCode = con.Account.BillingState;
        billAddy.PostalCode = con.Account.BillingPostalCode;
        billAddy.Country = con.Account.BillingCountry;
        billAddy.Lat = String.valueOf(con.Account.BillingLatitude);
        billAddy.Long_x = String.valueOf(con.Account.BillingLongitude);
        customer.BillAddr = billAddy;

        //Create Shipping address
        QBCustomerJSON.BillAddr shipAddy = new QBCustomerJSON.BillAddr();
        shipAddy.City = con.Account.ShippingCity;
        shipAddy.Line1 = con.Account.ShippingStreet;
        shipAddy.CountrySubDivisionCode = con.Account.ShippingState;
        shipAddy.PostalCode = con.Account.ShippingPostalCode;
        shipAddy.Country = con.Account.ShippingCountry;
        customer.ShipAddr = shipAddy;
        

        customer.Active = True;

        return JSON.serialize(customer, True);
    }

    /**
     * Map an invoice from Salesforce to QBO JSON
     * @param inv The invoice that is used for the mapping
     * @return The json String that is used for the body of the request callout 
     */
    public static String mapInvoice(Invoice__c inv){
        //Initialize invoice object
        QBInvoiceJSON invoiceObj = new QBInvoiceJSON();

        //Initialize line items for invoice mapping
        QBInvoiceJSON.Line line = new QBInvoiceJSON.Line();
        QBInvoiceJSON.SalesItemLineDetail detail = new QBInvoiceJSON.SalesItemLineDetail();
        invoiceObj.Line = new List<QBInvoiceJSON.Line>();
        
        //map line item fields
        line.Amount = inv.Subtotal__c;
        //@todo unhardcode this
        line.DetailType = 'SalesItemLineDetail';
        invoiceObj.Id = inv.QBO_Id__c;
        invoiceObj.SyncToken = inv.QBO_SyncToken__c;
        invoiceObj.DueDate = inv.Due_Date__c;
        invoiceObj.AllowOnlineACHPayment = True;
        invoiceObj.AllowOnlineCreditCardPayment = True;
        String invNumber = inv.name.replace('INV-', '');
        invoiceObj.DocNumber  = invNumber;
        invoiceObj.EmailStatus = 'NotSet';
        QBInvoiceJSON.EmailAddress email = new QBInvoiceJSON.EmailAddress();
        email.Address = inv.Opportunity__r.Account.contact__r.email;
        invoiceObj.BillEmail = email;

        QBInvoiceJSON.CustomerRef customerRef = new QBInvoiceJSON.CustomerRef();
        customerRef.value = inv.Opportunity__r.Account.QBO_Id__c;
        invoiceObj.CustomerRef = customerRef;
        
        //Map description
        QBInvoiceJSON.MemoRef memoRef = new QBInvoiceJSON.MemoRef();
        memoRef.value = inv.Description__c;
        invoiceObj.CustomerMemo = memoRef;
        QBInvoiceJSON.SalesTermRef sales = new QBInvoiceJSON.SalesTermRef();
        if(inv.Terms__c == '50% deposit / Balance Prior To Shipping'){
            sales.value = '5';
        }else if(inv.Terms__c == 'Due on receipt / Balance Due'){
            sales.value = '1';
        }else if(inv.Terms__c == 'Net 15'){
            sales.value = '2';
        }else if(inv.Terms__c == 'Net 30'){
            sales.value = '3';
        }else if(inv.Terms__c == 'Partial Payment'){
            sales.value = '6';
        }else{
            sales.value = '4';
        }
        invoiceObj.SalesTermRef = sales;
        
        //Create Billing Address
        QBInvoiceJSON.BillAddr billAddy = new QBInvoiceJSON.BillAddr();
        billAddy.City = inv.Opportunity__r.Account.BillingCity;
        billAddy.Line1 = inv.Opportunity__r.Account.BillingStreet;
        billAddy.CountrySubDivisionCode = inv.Opportunity__r.Account.BillingState;
        billAddy.PostalCode = inv.Opportunity__r.Account.BillingPostalCode;
        billAddy.Country = inv.Opportunity__r.Account.BillingCountry;
        invoiceObj.BillAddr = billAddy;

        //Create Shipping Address
        QBInvoiceJSON.BillAddr shipAddy = new QBInvoiceJSON.BillAddr();
        if(inv.Opportunity__r.Account != null){
            String phone = '';
            String cName = '';

            if(inv.Opportunity__r.Account != null){
                cName = inv.Opportunity__r.Account.Name;

            }
            if(inv.Opportunity__r.Account.Contact__c != null){
                cName = inv.Opportunity__r.Account.Contact__r.Name;
            }
            String contactLine = cName + phone;

            shipAddy.Line1 = inv.Opportunity__r.Account.Name;
            shipAddy.Line2 = contactLine ;
            shipAddy.Line3 = inv.Opportunity__r.Account.ShippingStreet;
            //shipAddy.City = inv.Opportunity__r.Account.ShippingCity;

            shipAddy.Line4 = inv.Opportunity__r.Account.ShippingCity + ', '+ 
                               inv.Opportunity__r.Account.ShippingState + '  ' +
                               inv.Opportunity__r.Account.ShippingPostalCode + '\n';
            //shipAddy.CountrySubDivisionCode = inv.Opportunity__r.Account.ShippingState;
            ///shipAddy.PostalCode = inv.Opportunity__r.Account.ShippingPostalCode;
            shipAddy.Lat = String.valueOf(inv.Opportunity__r.Account.ShippingLatitude);
            shipAddy.Long_x = String.valueOf(inv.Opportunity__r.Account.ShippingLongitude);
            invoiceObj.ShipAddr = shipAddy;
        }

        //map line detail fields
        QBInvoiceJSON.ItemRef itemRef = new QBInvoiceJSON.ItemRef();
        //Pull this from QB instance
        //Map to 1 product
        //@todo unhardcode this
        itemRef.name = 'Sales';//Sandbox: 'Services';
        itemRef.value = '1'; //Sandbox: '19'; Prod '1'
        detail.ItemRef = itemRef;

        //map taxable status for an invoice
        detail.TaxCodeRef = new QBInvoiceJSON.ItemRef();
        detail.TaxCodeRef.value = 'TAX';
        line.SalesItemLineDetail = detail;

        invoiceObj.Line.add(line);

        return JSON.serialize(invoiceObj, True).replace('"Long_x":', '"Long":');
    }

}