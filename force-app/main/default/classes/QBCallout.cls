public class QBCallout {
    //Access token used for authentication in QB
    private String accessToken{get;set;}
    private String refreshToken{get;set;}

    /**
     * Create new refresh token from previous access token
     * @return The access token and refresh token where access token = tokens[0] and refresh token = tokens[1]
     */
    private List<String> refresh(){
        //Get Custom setting data
        QBData__c QBData = [SELECT ID,
                                   Name,
                                   refresh_token__c,
                                   client_id__c,
                                   client_secret__c,
                                   auth_url__c
                            FROM QBData__c];

        //Initialize Request data
        String url = QBData.auth_url__c;
        String clientId = QBData.client_id__c;
        String clientSecret = QBData.client_secret__c;
        String header = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(clientId + ':' + clientSecret));
        String refresh_token = QBData.refresh_token__c;
        String body = 'grant_type=refresh_token&refresh_token=' + refresh_token;

        //Start http request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(body);
        req.setHeader('Authorization', header);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        res = h.send(req);
        System.debug(res.getBody());
        QBRefreshJSON json = QBRefreshJSON.parse(res.getBody());
        //System.debug(json);
        if(json.access_token == null){
            Throw new QBException('Refresh Token has expired.');
        }
        List<String> tokens = new List<String>{json.access_token,json.refresh_token};
        accessToken = tokens[0];
        refreshToken = tokens[1];
        return tokens;

    }
    
    /**
     * Query customer object from QBO
     * @param acc Account used to generate SQL to find customer in QBO
     * @return QBO Json for a found customer, null if no customer is found
     */
    public QBCustomerJSON getCustomer(Account acc){
        if(acc == null){
            Throw new NullPointerException();
        }
        //Initilize query
        String query = 'Select * from Customer where job = False and ' +
                             'DisplayName = \'' + acc.Name.replaceAll('\'', '\\\'') +'\'' ;
        if(acc.QBO_Id__c != null){
            query = 'Select * from Customer where job = False and Id = \'' + Acc.QBO_Id__c + '\'';
        }
        System.debug(query);

        //Initialze url endpoint
        QBO_Metadata__mdt QBData = [SELECT ID,
                            base_url__c,
                            Company_Id__c,
                            minorversion__c
                    FROM QBO_Metadata__mdt];
        String url = QBData.base_url__c + '/v3/company/' + QBData.Company_Id__c + '/query?minorversion=' + QBData.minorversion__c;


        //Start http request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        System.debug(accessToken);
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(query);
        req.setHeader('Authorization', 'Bearer '  + accessToken);
        req.setheader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/text');
        res = h.send(req);
        System.debug(res.getBody());
        handleResponseError(res.getBody());
        QBCustomerJSON json = QBCustomerJSON.parse(res.getBody());
        return json;
    }
	
    /**
     * Create a QB customer using account object
     * @param acc Account used to create  
     */
    public QBCustomerResponseJSON createCustomerCall(Account acc){

        //Map acc data to QB Customer JSON
        String body = QBMap.mapAccountData(acc);

        //Initialze url endpoint
        QBO_Metadata__mdt QBData = [SELECT ID,
                            base_url__c,
                            Company_Id__c,
                            minorversion__c
                    FROM QBO_Metadata__mdt];
        String url = QBData.base_url__c + '/v3/company/' + QBData.Company_Id__c + '/customer?minorversion=' + QBData.minorversion__c;

        //Start http request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(body);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setheader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        res = h.send(req);
        System.debug(res.getBody());
        handleResponseError(res.getBody());
        QBCustomerResponseJSON json = QBCustomerResponseJSON.parse(res.getBody());

        return json;
    }

    /**
     * Update the custom setting for the refresh token
     * @param refreshToken the current refresh token that will be updated
     */
    public void updateRefreshToken(){
        QBData__c QBData = [SELECT ID, Name,refresh_token__c, Last_Updated__c FROM QBData__c];
        QBData.refresh_token__c = refreshToken;
        QBData.Last_Updated__c = Datetime.now();
        update QBData;

    }

    /**
     * Query an invoice from QBO
     * @param inv invoice used to query QBO
     * @return response from QBO
     */
    public QBInvoiceQueryJSON getInvoice(Invoice__c inv){
        if(inv == null){
            Throw new NullPointerException();
        }
        if(inv.QBO_Id__c == null || inv.QBO_SyncToken__c == null){
            return null;
        }
        //Initilize query
        String query = 'Select * from invoice where id = \'' + inv.QBO_Id__c + '\'';

        //Initialze url endpoint
        QBO_Metadata__mdt QBData = [SELECT ID,
                            base_url__c,
                            Company_Id__c,
                            minorversion__c
                    FROM QBO_Metadata__mdt];
        String url = QBData.base_url__c + '/v3/company/' + QBData.Company_Id__c + '/query?minorversion=' + QBData.minorversion__c;

        //Start http request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(query);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setheader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/text');
        res = h.send(req);
        System.debug(res.getBody());
        handleResponseError(res.getBody());

        QBInvoiceQueryJSON json = QBInvoiceQueryJSON.parse(res.getBody());

        System.debug(json);

        return json;
    }
    
    /**
     * Throws exception if there is an error in the callout
     * @param body The json response from the QB callout
     */
    private void handleResponseError(String body){
        QBOErrorJSON error = QBOErrorJSON.parse(body);
        if(error != null){
            if(error.Fault != null && error.Fault.Error != null && error.Fault.Error.size() > 0)
            Throw new QBException(String.valueOf(error.Fault.Error[0]));
        }
    }

    /**
     * Create an invoice for QBO from invoice__c object
     * @param inv The invoice that is needed to create an invoice in QBO
     * @return Response object     
     */
    public QBInvoiceResponseJSON createInvoiceCall(Invoice__c inv){
        //Map inv data to QB Invoice JSON
        String body = QBMap.mapInvoice(inv);

        //Initialze url endpoint
        QBO_Metadata__mdt QBData = [SELECT ID,
                            base_url__c,
                            Company_Id__c,
                            minorversion__c
                    FROM QBO_Metadata__mdt];
        String url = QBData.base_url__c + '/v3/company/' + QBData.Company_Id__c + '/invoice?minorversion=' + QBData.minorversion__c;


        //Start http request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody(body);
        System.debug(body);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setheader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        res = h.send(req);
        System.debug(res.getBody());
        handleResponseError(res.getBody());

        return QBInvoiceResponseJSON.parse(res.getBody());
    }

    /**
     * Initialize the QB Callout by refreshing the current grant token
     */
    public QBCallout(){
        List<String> tokens = refresh();
        
    }


}