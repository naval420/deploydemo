@isTest
public with sharing class ExcludeAdvertisersControllerTest {

 @testSetup
public static void createData(){

    Account parentAccount= new Account();
    parentAccount.Name='Parent Account';
    parentAccount.CountryISOCode__c='US';
    parentAccount.Partnership_Applied__c=true;
    parentAccount.Type='Agency';
     Insert parentAccount;

     Account childAccount= new Account();
        childAccount.Name='Child Account1';
        childAccount.CountryISOCode__c='US';
        childAccount.ParentId=parentAccount.Id;
     childAccount.Type='Agency';
     Insert childAccount;
     
     Account childAccount1= new Account();
        childAccount1.Name='Child Account2';
        childAccount1.CountryISOCode__c='US';
        childAccount1.ParentId=childAccount.Id;
    childAccount1.Type='Agency';
     Insert childAccount1;

     Account advertiser= new Account();
     advertiser.Name='Parent Advertiser';
     advertiser.CountryISOCode__c='US';
     advertiser.Type='Advertiser';
     //advertiser.RecordTypeId='0124L000000kc4VQAQ';
     Insert advertiser;

     Account childAdvertiser= new Account();
     childAdvertiser.Name='child Advertiser';
     childAdvertiser.CountryISOCode__c='US';
     childAdvertiser.Type='Advertiser';
     //childAdvertiser.RecordTypeId='0124L000000kc4VQAQ';
     Insert childAdvertiser;

     Account childAdvertiser1= new Account();
     childAdvertiser1.Name='child Advertiser1';
     childAdvertiser1.CountryISOCode__c='US';
     childAdvertiser1.Type='Advertiser';
     //childAdvertiser1.RecordTypeId='0124L000000kc4VQAQ';
     Insert childAdvertiser1;


    Account_Relationships__c AR= new Account_Relationships__c();
    AR.Advertiser__c=advertiser.Id;
    AR.Agency__c=parentAccount.Id;
    AR.Financial_Year__c='FY2021';
    AR.Amount_Spent__c=2442000;
    Insert AR;

    
    Account_Relationships__c AR1= new Account_Relationships__c();
    AR1.Advertiser__c=childAdvertiser.Id;
    AR1.Agency__c=childAccount.Id;
    AR1.Financial_Year__c='FY2021';
    AR1.Amount_Spent__c=1442000;
    Insert AR1;

    
    Account_Relationships__c AR2= new Account_Relationships__c();
    AR2.Advertiser__c=childAdvertiser1.Id;
    AR2.Agency__c=childAccount1.Id;
    AR2.Financial_Year__c='FY2021';
    AR2.Amount_Spent__c=742000;
    Insert AR2;

    Contract contract= new Contract();
    contract.AccountId=parentAccount.Id;
    contract.Partnership_Type__c='North America Enterprise Partnership';
    contract.Status='Draft';
    contract.StartDate=System.today();
    contract.ContractTerm=12;
    Insert contract;

    Partnership_Exception__c partnershipException =new Partnership_Exception__c();
    partnershipException.Include_Exclude__c='Exclude';
    partnershipException.Exclude_Account__c=childAccount1.Id;
    partnershipException.Customer_Partnership__c=contract.Id;

    Insert partnershipException;
}

private static testMethod void getAdverstisersTest(){

    list<contract> contractList= [select Id,ContractTerm from Contract where ContractTerm=12 limit 1];
    test.startTest();
    list<Account> accountList=ExcludeAdvertisersController.getAdverstisers(contractList[0].Id);
    test.stopTest();
}


}