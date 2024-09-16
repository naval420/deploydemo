@isTest
public with sharing class SalesOrderAddProductsControllerTest {
  
    @TestSetup
public static void makeData(){

   /* Pricebook2 pricebook= new Pricebook2();
    pricebook.Name='Test Pricebook';
    pricebook.IsActive=true;
    insert pricebook;*/

    Opportunity opportunity= new Opportunity();
    opportunity.Name='Test Opportunity';
    opportunity.CurrencyISOCode='GBP';
    opportunity.Pricebook2Id=Test.getStandardPricebookId();
    opportunity.StageName='Proactive';
    opportunity.CloseDate=System.today().addDays(300);

    insert opportunity;

    Quote quote= new Quote();
    quote.Name='Test Quote';
    quote.OpportunityId=opportunity.Id;

    insert quote;

  List<Product2> productList= new List<Product2>();
    for(Integer i=0;i<10;i++){
    Product2 product= new Product2();
    product.IsActive=true;
    product.CurrencyIsoCode='GBP';
    product.Name='test'+i;
    product.Family='AwesomeAds';
    product.Format__c='Billboard';
    product.Media_Type__c='Awesome Ads';
    product.Delivery_Type__c='Direct';
    product.Target_GEO__c='226';
    product.ProductCode='Phone & Tablet';
    product.Device_Type_Options_Code__c='113';

    productList.add(product);
    }
   insert productList;

   List<PricebookEntry> pricebookEntryList= new List<PricebookEntry>();

    for(Integer i=0;i<10;i++){
    PricebookEntry pricebookEntry= new PricebookEntry();
    pricebookEntry.UnitPrice=10;
    pricebookEntry.UseStandardPrice=false;
    pricebookEntry.CurrencyIsoCode=opportunity.CurrencyISOCode;
    pricebookEntry.Pricebook2Id=Test.getStandardPricebookId();
    pricebookEntry.Product2Id=productList[i].Id;
    pricebookEntryList.add(pricebookEntry);
 }
   insert pricebookEntryList;

}

public static testMethod void getProductsTest(){

 List<Quote> quote= [select Id,OpportunityId from Quote];

 test.startTest();
 SalesOrderAddProductsController.getProducts(quote[0].Id);
 test.stopTest();

}

public static testMethod void getProductsByNameTest(){

List<Quote> quote= [select Id,OpportunityId from Quote];
test.startTest();
SalesOrderAddProductsController.getProductsByName('test',null,quote[0].Id);
test.stopTest();
}

public static testMethod void applyProductFiltersTest(){
    List<Quote> quote= [select Id,OpportunityId from Quote];
    List<Product2> productList= [select Id,Name,Format__c,Media_Type__c,Delivery_Type__c,Family,Device_Type_Options_Code__c,
    CurrencyIsoCode,Target_GEO__c,ProductCode from Product2];
    List<PriceBookEntry> pricebookEntryList= [select Id,UnitPrice,CurrencyIsoCode from PriceBookEntry];

    List<SalesOrderAddProductsController.ProductPriceWrapper> productPriceList= new List<SalesOrderAddProductsController.ProductPriceWrapper>();
    for(Integer i=0;i<10;i++){
        SalesOrderAddProductsController.ProductPriceWrapper wrapper= new SalesOrderAddProductsController.ProductPriceWrapper();
           wrapper.id= productList[i].Id;
           wrapper.name=productList[i].Name;
           wrapper.family=productList[i].Family;
           wrapper.deviceTypeOptions=productList[i].ProductCode;
           wrapper.format=productList[i].Format__c;
           wrapper.targetGeo= productList[i].Target_GEO__c;
           wrapper.mediaType=productList[i].Media_Type__c;
           wrapper.deliveryType=productList[i].Delivery_Type__c;
           wrapper.pricebookId=Test.getStandardPricebookId();
           wrapper.unitPrice=pricebookEntryList[i].UnitPrice;
           wrapper.deviceTypeCode=productList[i].Device_Type_Options_Code__c;
           wrapper.currencyISOCode=pricebookEntryList[i].CurrencyIsoCode;
           productPriceList.add(wrapper);
    }

    List<String> family = new List<String>{'AwesomeAds'};
    List<String> geo= new List<String> {'226'};
    String quoteId= string.valueOf(quote[0].Id);
    test.startTest();
    SalesOrderAddProductsController.applyProductFilters(family,productPriceList,quoteId,geo);
    test.stopTest();
}


public static testMethod void createLineItemsTest(){
    List<Quote> quote= [select Id,OpportunityId from Quote];
    List<Product2> productList= [select Id,Name,Format__c,Media_Type__c,Delivery_Type__c,Family,Device_Type_Options_Code__c,
    CurrencyIsoCode,Target_GEO__c,ProductCode from Product2];
    List<PriceBookEntry> pricebookEntryList= [select Id,UnitPrice,CurrencyIsoCode from PriceBookEntry];

    List<SalesOrderAddProductsController.ProductAttributes> attributesList= new List<SalesOrderAddProductsController.ProductAttributes>();
    for(Integer i=1;i<=5;i++){
        SalesOrderAddProductsController.ProductAttributes wrapper= new SalesOrderAddProductsController.ProductAttributes();
           wrapper.id= String.valueOf(i);
           wrapper.startDate=System.today().addDays(100);
           wrapper.endDate=System.today().addDays(300);
           wrapper.UnitPrice=10;
           wrapper.Quantity=30;
           wrapper.description='test';
           wrapper.frequencyCap=2;
         attributesList.add(wrapper);
    }

    List<SalesOrderAddProductsController.ProductWrapper> wrapperList= new List<SalesOrderAddProductsController.ProductWrapper>();
    string dateStamp=string.valueOf(System.today());
    for(Integer i=1;i<=5;i++){
        SalesOrderAddProductsController.ProductWrapper wrapper= new SalesOrderAddProductsController.ProductWrapper();
           wrapper.id= String.valueOf(i);
          wrapper.targetGender='Boys & Girls';
           wrapper.targetAudience='Kids & Tweens';
           wrapper.targetAge='13-16';
           wrapper.deviceType='Phone & Desktop';
           wrapper.productId=productList[i].Id;
           wrapper.kpi='Click-Through Rate';
           wrapper.budget='Downweight';
           wrapper.format='Standard Display';
           wrapper.mediaType='Programmatic';
           wrapper.deliveryType='Programmatic';
           wrapper.deviceTypeCode='109';
           wrapper.dateStamp=dateStamp;
           wrapperList.add(wrapper);
    }

    test.startTest();
    SalesOrderAddProductsController.createLineItems(attributesList,quote[0].Id,wrapperList);
    test.stopTest();
}


public static testMethod void getProductDetailsTest(){

    List<Quote> quote= [select Id,OpportunityId from Quote];
    List<Product2> productList= [select Id,Name from Product2];
   
    test.startTest();
    SalesOrderAddProductsController.getProductDetails(productList[0].Id,quote[0].Id);
    test.stopTest();
   
   }


   public static testMethod void getProductLineItemsTest(){
    
    List<Quote> quote= [select Id,OpportunityId from Quote];
    List<Opportunity> opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity];
    test.startTest();
    SalesOrderAddProductsController.getProductLineItems(quote[0].Id);
    test.stopTest();
   
   }
}