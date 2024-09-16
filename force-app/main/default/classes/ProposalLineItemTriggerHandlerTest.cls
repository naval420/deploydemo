@isTest
public with sharing class ProposalLineItemTriggerHandlerTest {

@testSetup 
 public static void createData()
 {
  Account account= new Account();
  account.Name='Test Account';
  account.CountryISOCode__c='US';
  account.Partnership_Applied__c=true;
  account.Type='Agency';
  Insert account;

  Account advertiser= new Account();
  advertiser.Name='Test Advertiser';
  advertiser.CountryISOCode__c='US';
  advertiser.Type='Advertiser';
 // advertiser.RecordTypeId='0124L000000kc4VQAQ';
  Insert advertiser;

  Contract contract= new Contract();
  contract.AccountId=account.Id;
  contract.Partnership_Type__c='North America Enterprise Partnership';
  //contract.Status='Proposal in process';
  contract.Active__c=true;
  contract.StartDate=System.today();
  contract.ContractTerm=12;
  contract.Do_you_want_to_Include_Products__c=true;
  Insert contract;


  Partnership_Discount__c partnershipDiscount= new Partnership_Discount__c();
  partnershipDiscount.Partnership_Agreement__c= contract.Id;
  partnershipDiscount.Upper_Limit__c=750000;
  partnershipDiscount.Lower_Limit__c=500000;
  partnershipDiscount.Tier__c='1';
  partnershipDiscount.Discount__c=10;

  Insert partnershipDiscount;

  Partnership_Discount__c partnershipDiscount1= new Partnership_Discount__c();
  partnershipDiscount1.Partnership_Agreement__c= contract.Id;
  partnershipDiscount1.Upper_Limit__c=1000000;
  partnershipDiscount1.Lower_Limit__c=750000;
  partnershipDiscount1.Tier__c='2';
  partnershipDiscount1.Discount__c=15;

  Insert partnershipDiscount1;

  Partnership_Discount__c partnershipDiscount2= new Partnership_Discount__c();
  partnershipDiscount2.Partnership_Agreement__c= contract.Id;
  partnershipDiscount2.Upper_Limit__c=1250000;
  partnershipDiscount2.Lower_Limit__c=1000000;
  partnershipDiscount2.Tier__c='3';
  partnershipDiscount2.Discount__c=20;
  Insert partnershipDiscount2;

  Partnership_Discount__c partnershipDiscount3= new Partnership_Discount__c();
  partnershipDiscount3.Partnership_Agreement__c= contract.Id;
  partnershipDiscount3.Upper_Limit__c=1500000;
  partnershipDiscount3.Lower_Limit__c=1250000;
  partnershipDiscount3.Tier__c='4';
  partnershipDiscount3.Discount__c=25;
  Insert partnershipDiscount3;

  Partnership_Discount__c partnershipDiscount4= new Partnership_Discount__c();
  partnershipDiscount4.Partnership_Agreement__c= contract.Id;
  partnershipDiscount4.Upper_Limit__c=1750000;
  partnershipDiscount4.Lower_Limit__c=1500000;
  partnershipDiscount4.Tier__c='5';
  partnershipDiscount4.Discount__c=30;
  Insert partnershipDiscount4;

  Partnership_Discount__c partnershipDiscount5= new Partnership_Discount__c();
  partnershipDiscount5.Partnership_Agreement__c= contract.Id;
  partnershipDiscount5.Upper_Limit__c=2000000;
  partnershipDiscount5.Lower_Limit__c=1750000;
  partnershipDiscount5.Tier__c='6';
  partnershipDiscount5.Discount__c=32;
  Insert partnershipDiscount5;


  Partnership_Discount__c partnershipDiscount6= new Partnership_Discount__c();
  partnershipDiscount6.Partnership_Agreement__c= contract.Id;
  partnershipDiscount6.Upper_Limit__c=2500000;
  partnershipDiscount6.Lower_Limit__c=2000000;
  partnershipDiscount6.Tier__c='7';
  partnershipDiscount6.Discount__c=35;
  Insert partnershipDiscount6;



  Account_Relationships__c AR= new Account_Relationships__c();
  AR.Advertiser__c=advertiser.Id;
  AR.Agency__c=account.Id;
  AR.Financial_Year__c='FY2021';
  AR.Amount_Spent__c=2442000;

  Insert AR;

  Id pricebookId = Test.getStandardPricebookId();

  Product2 pro= new Product2();
  pro.Family= 'AwesomeAds - Direct';
  pro.Name='Test Product';
  pro.IsActive=true;
  Insert pro;

  Product2 product2= new Product2();
  product2.Family= 'AwesomeAds - Direct';
  product2.Name='Test Product2';
  product2.IsActive=true;
  Insert product2;

  Partnership_Exception__c partnershipException =new Partnership_Exception__c();
  partnershipException.Include_Exclude__c='Include';
  partnershipException.Include_Product__c=pro.Id;
  partnershipException.Tier_1_Discount__c=10;
  partnershipException.Tier_2_Discount__c=15;
  partnershipException.Tier_3_Discount__c=20;
  partnershipException.Customer_Partnership__c=contract.Id;

  Insert partnershipException;
  
  PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = pro.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
   Insert pbEntry;

  Opportunity opportunity= new opportunity();
  opportunity.Name='Test Proposal';
  opportunity.AccountId=account.Id;
  opportunity.Advertiser__c=advertiser.Id;
  opportunity.StageName='Proactive';
  opportunity.CloseDate=system.today().addDays(90);
  opportunity.Pricebook2Id = Test.getStandardPricebookId();
  Insert opportunity;
  
}

 private static testMethod void ProposalLineItemTriggerbeforeInsertTest(){
     list<Opportunity> opportunityList= [select Id,Name,AccountId,Advertiser__c,Pricebook2Id from Opportunity where name='Test Proposal'];
     list<Product2> productList= [select Id,Family,Name from Product2 where name='Test Product'];
     list<PricebookEntry> pbEntryList= [select Id,Pricebook2Id,Product2Id,UnitPrice,IsActive from PricebookEntry where IsActive=true];
     OpportunityLineItem opportunityLineItem = new OpportunityLineItem();
    // opportunityLineItem.Product2Id=productList[0].Id;
     opportunityLineItem.OpportunityId=opportunityList[0].Id;
     opportunityLineItem.Quantity=100;
     opportunityLineItem.UnitPrice=50;
     opportunityLineItem.Sales_Metric__c='CPA';
     opportunityLineItem.Target_Gender__c='Boys';
     opportunityLineItem.Target_Age__c='Parents';
     //opportunityLineItem.Target_Age_Multi__c='0-3';
     opportunityLineItem.PricebookEntryId = pbEntryList[0].Id;
     opportunityLineItem.Device_Type__c='Desktop';
     opportunityLineItem.Start_Date__c=system.today().addDays(10);
     opportunityLineItem.End_Date__c=system.today().addDays(90);
     //opportunityLineItem.TotalPrice = 0;
      
      test.startTest();
      Insert opportunityLineItem;
      test.stopTest();

 }


 private static testMethod void ProposalLineItemTriggerAfterDeleteTest(){

  list<Opportunity> opportunityList= [select Id,Name,AccountId,Advertiser__c,Pricebook2Id from Opportunity where name='Test Proposal'];
     list<Product2> productList= [select Id,Family,Name from Product2 where name='Test Product'];
     //list<Product2> productList1= [select Id,Family,Name from Product2 where name='Test Product2'];
     list<PricebookEntry> pbEntryList= [select Id,Pricebook2Id,Product2Id,UnitPrice,IsActive from PricebookEntry where IsActive=true and Product2Id=:productList[0].Id];
     //list<PricebookEntry> pbEntryList1= [select Id,Pricebook2Id,Product2Id,UnitPrice,IsActive from PricebookEntry where IsActive=true and Product2Id=:productList1[0].Id];

     OpportunityLineItem opportunityLineItem = new OpportunityLineItem();
    // opportunityLineItem.Product2Id=productList[0].Id;
     opportunityLineItem.OpportunityId=opportunityList[0].Id;
     opportunityLineItem.Quantity=100;
     opportunityLineItem.UnitPrice=50;
     opportunityLineItem.Sales_Metric__c='CPA';
     opportunityLineItem.Target_Gender__c='Boys';
     opportunityLineItem.Target_Age__c='Parents';
     //opportunityLineItem.Target_Age_Multi__c='0-3';
     opportunityLineItem.PricebookEntryId = pbEntryList[0].Id;
     opportunityLineItem.Device_Type__c='Desktop';
     opportunityLineItem.Start_Date__c=system.today().addDays(10);
     opportunityLineItem.End_Date__c=system.today().addDays(90);
     Insert opportunityLineItem;
     //opportunityLineItem.TotalPrice = 0;

     OpportunityLineItem opportunityLineItem1 = new OpportunityLineItem();
    // opportunityLineItem1.Product2Id=productList[0].Id;
     opportunityLineItem1.OpportunityId=opportunityList[0].Id;
     opportunityLineItem1.Quantity=10;
     opportunityLineItem1.UnitPrice=30;
     opportunityLineItem1.Sales_Metric__c='CPA';
     opportunityLineItem1.Target_Gender__c='Boys';
     opportunityLineItem1.Target_Age__c='Parents';
     //opportunityLineItem.Target_Age_Multi__c='0-3';
     opportunityLineItem1.PricebookEntryId = pbEntryList[0].Id;
     opportunityLineItem1.Device_Type__c='Desktop';
     opportunityLineItem1.Start_Date__c=system.today().addDays(20);
     opportunityLineItem1.End_Date__c=system.today().addDays(40);
     Insert opportunityLineItem1;

     test.startTest();
     Delete opportunityLineItem1;
     test.stopTest();

}

}