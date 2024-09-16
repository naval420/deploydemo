trigger ProposalLineItemTrigger on OpportunityLineItem (before insert,before update,after delete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            if(ProposalLineItemTriggerHandler.isFirstTime){
            ProposalLineItemTriggerHandler.handleBeforeInsertUpdate(Trigger.new);
            }
        }
    }  
        if(Trigger.isAfter){
            if(Trigger.isDelete){
             if(ProposalLineItemTriggerHandler.isFirstTimeDelete){
                ProposalLineItemTriggerHandler.handleAfterDelete(Trigger.old); 
              }
            }
        }


    /*set<Id> OpportunityIdSet= new set<Id>();
set<Id> AccountIdSet= new set<Id>();
//list<Contract> contractList= new list<Contract>();

for(OpportunityLineItem opportunityLineItem : trigger.new){
if(opportunityLineItem.Opportunity.account.Partnership_Applied__c==true);
{
OpportunityIdSet.add(opportunityLineItem.OpportunityId);
AccountIdSet.add(opportunityLineItem.Opportunity.AccountId);
}


list<Contract> contractList=[select Id,AccountId,Partnership_Type__c from Contract where AccountId in :AccountIdSet]; 


List<Opportunity> opportunityList =[select Id,AccountId,Proposal_Amount_pre_discount__c,Relationship_Type__c,Advertiser__c,Agency__c from Opportunity where Id in :OpportunityIdSet];

Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([select Id,AccountId,Proposal_Amount_pre_discount__c,Relationship_Type__c,Advertiser__c,Agency__c from Opportunity where Id in :OpportunityIdSet]);

list<EMEA_Enterprise_Partnership__mdt> EnterpriseList = [select Id,Discount__c,Lower_Limit__c,Tier__c,Upper_Limit__c from EMEA_Enterprise_Partnership__mdt];


for(Opportunity opportunity : opportunityList)
{
    if(opportunity.Relationship_Type__c=='Advertiser'){


    }

    else if(opportunity.Relationship_Type__c=='Agency'){
        
    }
}
for(OpportunityLineItem opportunityLineItem : trigger.new){

    if(opportunityMap.containsKey(opportunityLineItem.OpportunityId))
    {
        Opportunity opp=opportunityMap.get(opportunityLineItem.OpportunityId);
        string updatedAmount= opp.Proposal_Amount_pre_discount__c+opportunityLineItem.Amount__c;
        
    }
}
 */
/*for(Opportunity opp:opportunityList)
{
AccountIdSet.add(opp.AccountId);
}

List<Account> accountList= [select Id,Name,Partnership_Applied__c from Account where Id in:AccountIdSet]; */


}