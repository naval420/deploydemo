@isTest
public with sharing class AccountsUtilTest {
    @testSetup
    public static void createData(){
    
        Account parentAccount= new Account();
        parentAccount.Name='Parent Account';
        parentAccount.CountryISOCode__c='US';
        parentAccount.Partnership_Applied__c=true;
         Insert parentAccount;
    
         Account childAccount= new Account();
            childAccount.Name='Child Account';
            childAccount.CountryISOCode__c='US';
            childAccount.ParentId=parentAccount.Id;
         Insert childAccount;
         
         Account childAccount1= new Account();
            childAccount1.Name='Child Account1';
            childAccount1.CountryISOCode__c='US';
            childAccount1.ParentId=childAccount.Id;
         Insert childAccount1;
    
      Contract contract= new Contract();
      contract.AccountId=parentAccount.Id;
      contract.Partnership_Type__c='North America Enterprise Partnership';
      //contract.Status='Draft';
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
 Account account= [select Id, Name from Account where Name='Parent Account' Limit 1];
 Contract contract= [select Id,AccountId from Contract where AccountId=:account.Id Limit 1];
 List<AccountsUtil.Request> requestList= new List<AccountsUtil.Request>();
 AccountsUtil.Request request= new AccountsUtil.Request();
 request.accountId=account.Id;
 request.contractId=contract.Id;
 requestList.add(request);
 test.startTest();
 AccountsUtil.getChildAccounts(requestList);
 test.stopTest();

}

}