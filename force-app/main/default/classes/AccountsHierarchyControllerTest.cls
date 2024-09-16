@isTest
public with sharing class AccountsHierarchyControllerTest {

 @testSetup
public static void createData(){

    Account parentAccount= new Account();
    parentAccount.Name='Parent Account';
    parentAccount.CountryISOCode__c='US';
    parentAccount.Partnership_Applied__c=true;
     Insert parentAccount;

     Account childAccount= new Account();
        childAccount.Name='Child Account1';
        childAccount.CountryISOCode__c='US';
        childAccount.ParentId=parentAccount.Id;
     Insert childAccount;
     
     Account childAccount1= new Account();
        childAccount1.Name='Child Account2';
        childAccount1.CountryISOCode__c='US';
        childAccount1.ParentId=childAccount.Id;
     Insert childAccount1;

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

private static testMethod void getChildAccountsTest(){

    list<contract> contractList= [select Id,ContractTerm from Contract where ContractTerm=12 limit 1];
    test.startTest();
    list<Account> accountList=AccountsHierarchyController.getChildAccounts(contractList[0].Id);
    test.stopTest();
}


}