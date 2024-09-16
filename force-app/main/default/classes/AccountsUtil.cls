public without sharing class AccountsUtil {

  @InvocableMethod
public static list<Response> getChildAccounts (list<Request> inputs) {

  Id accountId = inputs[0].accountId;
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

 list<Partnership_Exception__c> partnershipExcpetionList = [select Id,Name,Exclude_Account__c from Partnership_Exception__c where Customer_Partnership__c= :inputs[0].contractId and Exclude_Account__c!=null];
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
list<Account> updatedchildAccountlist= [select Id,Name from Account where Id in: updatedAccountIdSet];
system.debug('updatedchildAccountlist' + updatedchildAccountlist);

list<Response> responseList= new list<Response>();

Response response= new Response();
response.accountList= updatedchildAccountlist;
responseList.add(response);

return responseList;
}

public class Request{
@InvocableVariable 
public string accountId;
@InvocableVariable 
public string contractId;
}

public class Response{
@InvocableVariable 
public list<Account> accountList;

}

}