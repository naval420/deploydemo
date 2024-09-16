@isTest
public with sharing class AddProductsControllerTest {
    
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

 List<Opportunity> opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity];

 test.startTest();
 AddProductsController.getProducts(opp[0].Id);
 test.stopTest();

}

public static testMethod void getProductsByNameTest(){
List<Opportunity> opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity];
test.startTest();
AddProductsController.getProductsByName('test',null,opp[0].Id);
test.stopTest();
}

public static testMethod void applyProductFiltersTest(){
    List<Opportunity> opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity];
    List<Product2> productList= [select Id,Name,Format__c,Media_Type__c,Delivery_Type__c,Family,Device_Type_Options_Code__c,
    CurrencyIsoCode,Target_GEO__c,ProductCode from Product2];
    List<PriceBookEntry> pricebookEntryList= [select Id,UnitPrice,CurrencyIsoCode from PriceBookEntry];

    List<AddProductsController.ProductPriceWrapper> productPriceList= new List<AddProductsController.ProductPriceWrapper>();
    for(Integer i=0;i<10;i++){
        AddProductsController.ProductPriceWrapper wrapper= new AddProductsController.ProductPriceWrapper();
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
    test.startTest();
    AddProductsController.applyProductFilters(family,productPriceList,opp[0].Id,geo);
    test.stopTest();
}


public static testMethod void createLineItemsTest(){
    List<Opportunity> opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity];
    List<Product2> productList= [select Id,Name,Format__c,Media_Type__c,Delivery_Type__c,Family,Device_Type_Options_Code__c,
    CurrencyIsoCode,Target_GEO__c,ProductCode from Product2];
    List<PriceBookEntry> pricebookEntryList= [select Id,UnitPrice,CurrencyIsoCode from PriceBookEntry];

    List<AddProductsController.ProductAttributes> attributesList= new List<AddProductsController.ProductAttributes>();
    for(Integer i=1;i<=5;i++){
        AddProductsController.ProductAttributes wrapper= new AddProductsController.ProductAttributes();
           wrapper.id= String.valueOf(i);
           wrapper.startDate=System.today().addDays(100);
           wrapper.endDate=System.today().addDays(300);
           wrapper.UnitPrice=10;
           wrapper.Quantity=30;
           wrapper.description= 'test';
           wrapper.frequencyCap=2;
         attributesList.add(wrapper);
    }

    List<AddProductsController.ProductWrapper> wrapperList= new List<AddProductsController.ProductWrapper>();
    for(Integer i=1;i<=5;i++){
        AddProductsController.ProductWrapper wrapper= new AddProductsController.ProductWrapper();
           wrapper.id= String.valueOf(i);
           wrapper.targetGender='Boys & Girls';
           wrapper.targetAudience='Kids & Tweens';
           wrapper.targetAge='7-9,10-12';
           wrapper.deviceType='Phone & Desktop';
           wrapper.productId=productList[i].Id;
           wrapper.kpi='Click-Through Rate';
           wrapperList.add(wrapper);
    }

    test.startTest();
    AddProductsController.createLineItems(attributesList,opp[0].Id,wrapperList);
    test.stopTest();
}


public static testMethod void getProductDetailsTest(){

    List<Opportunity> opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity];
    List<Product2> productList= [select Id,Name from Product2];
   
    test.startTest();
    AddProductsController.getProductDetails(productList[0].Id,opp[0].Id);
    test.stopTest();
   
   }


   public static testMethod void getProductLineItemsTest(){

    List<Opportunity> opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity];
    test.startTest();
    AddProductsController.getProductLineItems(opp[0].Id);
    test.stopTest();
   
   }
}