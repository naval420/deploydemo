public with sharing class ChildAccounts {
    
    @InvocableMethod
public static list<Response> getAllChildAccounts (list<Request> inputs) {

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

list<Response> responseList= new list<Response>();

Response response= new Response();
response.accountList= allChildren;
responseList.add(response);

return responseList;
}

public class Request{
@InvocableVariable 
public string accountId;
}

public class Response{
@InvocableVariable 
public list<Account> accountList;
}

}