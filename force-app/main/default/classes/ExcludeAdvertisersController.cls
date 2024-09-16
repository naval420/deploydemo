public with sharing class ExcludeAdvertisersController {
   
    @AuraEnabled (cacheable=true)
    public static list<Account> getAdverstisers(String recordId) {
       
    list<Contract> contract =[select Id, AccountId from Contract where Id=:recordId limit 1];
        Id accountId = contract[0].accountId;
        list<account> allChildren = new list<account> {};
        Set<Id> parentIds = new Set<Id>{accountId};
        list<account> children;
        do {
            children = [select Id, Name from Account where ParentId in :parentIds];
            allChildren.addAll(children);
            parentIds.clear();
            for (Account child : children) parentIds.add(child.Id);
        } while (children.size() > 0);
      
        set<Id> childAccountIdSet= new set<Id>();
        for(Account childList : allChildren)
        {
          childAccountIdSet.add(childList.Id);
        }
        system.debug(childAccountIdSet);
        //including parent account
        childAccountIdSet.add(accountId);
      
       list<Partnership_Exception__c> partnershipExcpetionList = [select Id,Name,Exclude_Account__c from Partnership_Exception__c where Customer_Partnership__c= :contract[0].Id and Exclude_Account__c!=null];
         set<Id> excludedAccountIdSet= new set<Id>();
         for(Partnership_Exception__c exclAccountList : partnershipExcpetionList)
         {
          excludedAccountIdSet.add(exclAccountList.Exclude_Account__c);
         }
         system.debug('excludedAccountIdSet'+excludedAccountIdSet);
         set<Id> updatedAccountIdSet= new set<Id>();
      for(Id accId : childAccountIdSet)
      {
          if (!excludedAccountIdSet.contains(accId)){
              updatedAccountIdSet.add(accId);
          }
      }
      system.debug('updatedAccountIdSet'+updatedAccountIdSet);
      list<Account> updatedchildAccountlist= [select Id,Name,Relationship_Type__c from Account where Id in: updatedAccountIdSet];
      system.debug('updatedchildAccountlist' + updatedchildAccountlist);
      //list<Account> updatedAdverstiserList= new list<Account>();
      set<Id> updatedAdverstiserIdSet= new set<Id>();
    
      //return updatedchildAccountlist;

       for(Account acccount :updatedchildAccountlist){
        if(acccount.Relationship_Type__c=='Agency'){
            //updatedAdverstiserList= getRelatedAdvertisers(acccount.Id);
            updatedAdverstiserIdSet.addAll(getRelatedAdvertisers(acccount.Id));
       }
    }
    list<Account> updatedAdverstiserList =[select Id,Name from Account where Id in :updatedAdverstiserIdSet];
    return updatedAdverstiserList;
}  
    public static set<Id> getRelatedAdvertisers(Id agency){
        set<Id> adverstiserIdSet= new set<Id>();
        list<Account_Relationships__c> arList = [select Id,Advertiser__c,Agency__c from Account_Relationships__c where Agency__c=:agency];
        for(Account_Relationships__c accountRelation :arList){
            
            adverstiserIdSet.add(accountRelation.Advertiser__c);
        }
      // list<Account> adverstiserList = [select Id,Name from Account where Id in :adverstiserIdSet];
       return adverstiserIdSet;
    }
}