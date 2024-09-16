/**********************************************************************
 * Name:CreateProposalController
 * Description: Controller Class for CreateProposal LWC componenet
 * Create Date:
 * Created By:Sudhir Baljeplli
 * ******************************************************************/
public with sharing class CreateProposalController {
   @AuraEnabled
   public static string doCreateProposal(Opportunity proposalData,String userId){
        try {
            if(proposalData !=null && userId !=null){
                user usr=[select id,SA_Subsidiary__c from user where id=:userId]; 
                system.debug('user subsidary'+usr.SA_Subsidiary__c);
                if(usr !=null){
                    proposalData.SA_Subsidiary__c=usr.SA_Subsidiary__c;
                }
                system.debug('proposal subsidary'+proposalData.SA_Subsidiary__c);
                insert proposalData; 
                return proposalData.Id;
            }
            return null;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
@AuraEnabled
    public static Account getAccountDetails(String accId){
        if(accId !=null){
             Account acc=[select id,Name,Type,Relationship_Type__c,SA_Subsidiary__c from Account where id=:accId limit 1];
            return acc;
        }
        return null;
    }
  @AuraEnabled
  public static Contact getContacts(String conId){ 
      if(conId !=null){
          Contact con=[Select Id,Name,Email from Contact where id=:conId limit 1];
          return con;
      }
      return null;
  }   
}