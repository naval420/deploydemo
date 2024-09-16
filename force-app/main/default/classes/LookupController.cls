public class LookupController {

    @AuraEnabled(cacheable=true)
 public static List<sObject> lookUp(String searchTerm, String objectName, String filters, String recordId, String fields,String currencyCode) {
       
        //Integer limitNum = 20;
        List<sObject> allProducts= new List<sObject>();

        String productName='%'+searchTerm+'%';
        system.debug('productName'+productName);
        system.debug('pricebookId'+ filters);

        List<PricebookEntry> pricebookList=[select Id,Product2Id,Pricebook2Id,CurrencyISOCode  from PricebookEntry where Pricebook2Id=:filters and CurrencyISOCode=:currencyCode];

         set<Id> productIdSet= new set<Id> ();

         for(PriceBookEntry pricebook :pricebookList){
            productIdSet.add(pricebook.Product2Id);
         }

         system.debug('productIdset'+productIdSet);
         if(productName!=null)  
          allProducts= [select Id,Name,IsActive,toLabel(Target_GEO__c) from Product2 where Id in:productIdSet and Name like:productName and IsActive=true];
         else {
          allProducts= [select Id,Name,IsActive,toLabel(Target_GEO__c) from Product2 where Id in:productIdSet and IsActive=true];
         }
       system.debug('all products'+allProducts.size());
         return allProducts;

       /* String finalQuery = 'SELECT ' + fields + ' FROM ' + objectName;

        if(String.isBlank(recordId)){
            if(String.isNotBlank(searchTerm)){
                finalQuery += ' WHERE Name Like  \'%' + searchTerm + '%\' ';
            }
            
            if(String.isNotBlank(filters)){
                finalQuery += String.isNotBlank(searchTerm) ? ' AND ' : ' WHERE ';
                finalQuery += 'Id in:'+productIdSet ;
            }
        }
        
        else{
            finalQuery += ' WHERE Id =  \'' + recordId + '\'';
        }

        finalQuery+= ' LIMIT ' + limitNum;

        System.debug('Final Query::::' + finalQuery);

        List<sObject> lookUpList = database.query(finalQuery);

        return lookUpList; */
    }
    
}