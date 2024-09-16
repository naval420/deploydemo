@isTest
public with sharing class LookupControllerTest {

@TestSetup
static void makeData(){
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
    pricebookEntry.CurrencyIsoCode='GBP';
    pricebookEntry.Pricebook2Id=Test.getStandardPricebookId();
    pricebookEntry.Product2Id=productList[i].Id;
    pricebookEntryList.add(pricebookEntry);
 }
   insert pricebookEntryList;
    
}

  private static testMethod void lookUpTest(){
        test.startTest();
        LookupController.lookUp('test',null,Test.getStandardPricebookId(),null,null,'GBP');
        test.stopTest();
        }

}