public with sharing class ProposalLineItemTriggerHandler {

    public static Boolean isFirstTime=True;
    public static Boolean isFirstTimeDelete=True;
   
    public static void handleBeforeInsertUpdate(list<OpportunityLineItem> OpportunityLineItemNew) 
    {
        try { 
       isFirstTime=false;      
       system.debug('inside trigger handler');
        set<Id> OpportunityIdSet= new set<Id>();
        set<Id> AccountIdSet= new set<Id>();
        set<Id> agencyIdSet= new set<Id>();
        set<Id> advertiserIdSet= new set<Id>();
        set<Id> opportunityLineItemNewIdSet= new set<Id>();
        set<Id> opportunityLineItemOldIdSet= new set<Id>();
        List<Opportunity> opportunityList;
        Decimal sumOfOpportunityLineItems=0;
        Decimal sumOfOpportunityLineItemsOld=0;
        List<OpportunityLineItem> OldOpportunityLineItemList=new List<OpportunityLineItem>(); 

        for(OpportunityLineItem opportunityLineItem :OpportunityLineItemNew){ 
            OpportunityIdSet.add(opportunityLineItem.OpportunityId);
            opportunityLineItemNewIdSet.add(opportunityLineItem.Id);  
            if(opportunityLineItem.Sales_Metric__c=='CPM'){
            sumOfOpportunityLineItems+=((opportunityLineItem.Quantity/1000)*opportunityLineItem.UnitPrice);
            }
            else{
            sumOfOpportunityLineItems+=(opportunityLineItem.Quantity*opportunityLineItem.UnitPrice); 
            }
         }
    system.debug('opportunityLineItemNewIdSet===>'+opportunityLineItemNewIdSet);       
    system.debug('sumOfOpportunityLineItems===>'+sumOfOpportunityLineItems);      
    system.debug('OpportunityIdSet'+OpportunityIdSet);

   list<OpportunityLineItem> opportunityLineItemList= [select Id,Amount__c,OpportunityId,Current_Tier__c,Partnership_Discount__c,Product2Id from OpportunityLineItem where OpportunityId in:OpportunityIdSet];
   If(opportunityLineItemList.size()>0){
    for(OpportunityLineItem opportunityLineItem: opportunityLineItemList){
        if(!opportunityLineItemNewIdSet.contains(opportunityLineItem.Id)){
        sumOfOpportunityLineItemsOld+=opportunityLineItem.Amount__c;
        opportunityLineItemOldIdSet.add(opportunityLineItem.Id);
       }
    }
  } 
  OldOpportunityLineItemList= [select Id,Amount__c,OpportunityId,Current_Tier__c,Partnership_Discount__c,Product2Id from OpportunityLineItem where Id in:opportunityLineItemOldIdSet];
  system.debug('OldOpportunityLineItemList'+ OldOpportunityLineItemList);
  system.debug('sumOfOpportunityLineItemsOld===>'+sumOfOpportunityLineItemsOld);

   list<Opportunity> oppList= [select Id,AccountId,Advertiser__c from Opportunity where Id in:OpportunityIdSet];

   for(Opportunity opp : oppList){ 
    agencyIdSet.add(opp.AccountId);
    if(opp.Advertiser__c!=null){
    advertiserIdSet.add(opp.Advertiser__c);
     }
   }
    AccountIdSet.addAll(agencyIdSet);
    AccountIdSet.addAll(advertiserIdSet);

 system.debug('AccountIdSet'+AccountIdSet);
   list<Account> accountList= [select Id,Partnership_Applied__c,Partnership_Applied_From__c,Parent_Level_Partnership_Applied__c from Account where Id in:AccountIdSet];
   set<Id> accountWithPartnerShipIdSet= new set<Id>();
   set<Id> newAccountIdSet =  new set<Id>();

   for(Account account :accountList){
       if(account.Partnership_Applied__c==true){
        accountWithPartnerShipIdSet.add(account.Id);
        newAccountIdSet.add(account.Id);

       }
       else if(account.Parent_Level_Partnership_Applied__c==true) {
        accountWithPartnerShipIdSet.add(account.Id);
        newAccountIdSet.add(account.Partnership_Applied_From__c);
       }
   }

   system.debug('newAccountIdSet==>'+newAccountIdSet);
   system.debug('accountWithPartnerShipIdSet==>'+accountWithPartnerShipIdSet);
   Map<Id,Account> accountWithPartnerShipMap=new Map<Id,Account>([select Id,Partnership_Applied__c,Partnership_Applied_From__c,Parent_Level_Partnership_Applied__c,Customer_Location_Region__c,Relationship_Type__c from Account where Id in:accountWithPartnerShipIdSet]);
   

if(accountWithPartnerShipIdSet!=null){
    opportunityList =[select Id,AccountId,Proposal_Amount_pre_discount__c,CurrencyIsoCode,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c from Opportunity where Id in :OpportunityIdSet];
    system.debug('opportunityList===>'+opportunityList);
    system.debug('size==>'+ opportunityList.size());
}


list<Contract> contractList= [select Id,AccountId,Partnership_Type__c,Active__c,Partnership_Target__c from Contract where AccountId in:newAccountIdSet and Active__c=true];
map<Id,Contract> contractMap= new map<Id,Contract>([select Id,AccountId,Partnership_Type__c,Do_you_want_to_Include_Products__c,Active__c,Partnership_Target__c from Contract where AccountId in:newAccountIdSet and Active__c=true]);
set<Id> contractIdset= new set<Id>();


for(Contract contract :contractList){
    contractIdset.add(contract.Id);
}

Map<Id,list<Partnership_Exception__c>> contractTopartnershipExceptionMap = new Map<Id,list<Partnership_Exception__c>>();

for(Partnership_Exception__c parException :[select Id,Include_Product__c,Include_Exclude__c,Customer_Partnership__c,Exclude_Location_Region__c,Exclude_Product__c,Tier_1_Discount__c,Tier_2_Discount__c,Tier_3_Discount__c,Tier_4_Discount__c,Tier_5_Discount__c,Tier_6_Discount__c,Tier_7_Discount__c from Partnership_Exception__c where Customer_Partnership__c in:contractIdset])
{
    if(contractTopartnershipExceptionMap.containsKey(parException.Customer_Partnership__c)){
        contractTopartnershipExceptionMap.get(parException.Customer_Partnership__c).add(parException);
    }
    else{
        contractTopartnershipExceptionMap.put(parException.Customer_Partnership__c, new list<Partnership_Exception__c> {parException});
    }
 
}

system.debug('contractTopartnershipExceptionMap'+ contractTopartnershipExceptionMap);

Map<Id,list<Contract>> accountToContractMap= new Map<Id,list<Contract>>() ;
for(Contract contract :contractList){

    if(accountToContractMap.containsKey(contract.AccountId)){
        accountToContractMap.get(contract.AccountId).add(contract);    
    }

    else{
        accountToContractMap.put(contract.AccountId, new list<Contract> {contract});
    }

}

system.debug('accountToContractMap'+ accountToContractMap);

List<CurrencyType> currencyTpyeList = [select Id,IsoCode,ConversionRate from CurrencyType where isActive = true] ;
	Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
	for(CurrencyType c : currencyTpyeList) {
        isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
	}
    //system.debug('isoWithRateMap'+isoWithRateMap);
    for(Opportunity opportunity : opportunityList)
    {   
        Decimal conversionRate;
        List<Partnership_Exception__c> accountPartnershipExceptionList= new List<Partnership_Exception__c>();
        Decimal UpdatedAmount;
        if(isoWithRateMap.containsKey(opportunity.CurrencyIsoCode)){
         conversionRate=isoWithRateMap.get(opportunity.CurrencyIsoCode);
        }
        system.debug('conversionRate'+conversionRate);
        if(opportunity.Relationship_Type__c=='Advertiser'){
            Decimal AmountSpent=getAmountSpent(opportunity.Advertiser__c,isoWithRateMap);
            system.debug('AmountSpent in FY'+AmountSpent);
            UpdatedAmount=AmountSpent+(sumOfOpportunityLineItemsOld/conversionRate)+(sumOfOpportunityLineItems/conversionRate);
         }
    
        else if(opportunity.Relationship_Type__c=='Agency'){
            system.debug('opportunity.Advertiser__c'+ opportunity.Advertiser__c);
            system.debug('opportunity.Agency__c'+ opportunity.Agency__c);
            Decimal AmountSpent= getAmountSpent(opportunity.Advertiser__c,opportunity.AccountId,isoWithRateMap);
            system.debug('AmountSpent'+AmountSpent);
             UpdatedAmount=AmountSpent+(sumOfOpportunityLineItemsOld/conversionRate)+(sumOfOpportunityLineItems/conversionRate);
        }
        system.debug('UpdatedAmount'+UpdatedAmount);
        if(accountWithPartnerShipMap.containsKey(opportunity.AccountId) || accountWithPartnerShipMap.containsKey(opportunity.Advertiser__c) ){
            Id accountwithPartnershipId;
            Account acc= accountWithPartnerShipMap.get(opportunity.AccountId);
            if(acc==null){
               acc=accountWithPartnerShipMap.get(opportunity.Advertiser__c);
            }
            system.debug(acc);
            if(acc.Parent_Level_Partnership_Applied__c){
                accountwithPartnershipId= acc.Partnership_Applied_From__c;
            }
            else{
                accountwithPartnershipId=acc.Id;
            }
           Partnership_Discount__c discount= checkEligibleTierlevel(UpdatedAmount,contractIdset,contractMap,isoWithRateMap);
            system.debug(discount);
            if(discount!=null && accountToContractMap.containsKey(accountwithPartnershipId)){
             system.debug('inside if statement');   
            List<Contract> newContractList= accountToContractMap.get(accountwithPartnershipId);
            system.debug('newContractList====>'+ newContractList);
            for (Contract con :newContractList){
                if(contractTopartnershipExceptionMap.containsKey(con.Id)){
                    system.debug('inside partnership exception for contract');
                    accountPartnershipExceptionList= contractTopartnershipExceptionMap.get(con.Id); 
                    system.debug('accountPartnershipExceptionList===>'+ accountPartnershipExceptionList);  
                }
            }
            system.debug('before line item update');
            updateOpportunityLineItemRecord(opportunity,discount,OpportunityLineItemNew,accountPartnershipExceptionList,contractMap);
            updateOldOpportunityLineItemRecord(opportunity,discount,OldOpportunityLineItemList,accountPartnershipExceptionList,contractMap);
            system.debug('after line item update');
            }
        }

    }

}

  catch (Exception ex) {
      system.debug('There is an error creating Line Item'+ ex.getMessage()+'line number'+ex.getLineNumber());  
}

} 

public static Decimal getAmountSpent(Id Advertiser,Map<String,Decimal> isoWithRateMap){
    Decimal amountSpent;
    Decimal conversionRate;
    Decimal cumulativeSpent;
    system.debug('inside Advertiser amount spent');
    list<Account_Relationships__c> ARList = [select Id,	Advertiser__c,Amount_Spent__c,CurrencyIsoCode from Account_Relationships__c where Advertiser__c=:Advertiser];
    if(ARList.size()>0){
        amountSpent=ARList[0].Amount_Spent__c;
        if(isoWithRateMap.containsKey(ARList[0].CurrencyIsoCode)){
           conversionRate=isoWithRateMap.get(ARList[0].CurrencyIsoCode);
           system.debug('conversionRate'+conversionRate);
         }
    }  
    cumulativeSpent= (amountSpent==null)?0:amountSpent/conversionRate;
    return cumulativeSpent;
}

public static Decimal getAmountSpent(Id Advertiser,Id Agency,Map<String,Decimal> isoWithRateMap){
    Decimal amountSpent;
    Decimal cumulativeSpent;
    Decimal conversionRate;
    system.debug('inside get Agency amount spent');
list<Account_Relationships__c> ARList = [select Id,	Advertiser__c,Agency__c,Amount_Spent__c,CurrencyIsoCode from Account_Relationships__c where Advertiser__c=:Advertiser and Agency__c=:Agency];
    if(ARList.size()>0){
        amountSpent =ARList[0].Amount_Spent__c;
        if(isoWithRateMap.containsKey(ARList[0].CurrencyIsoCode)){
            conversionRate=isoWithRateMap.get(ARList[0].CurrencyIsoCode);
            system.debug('conversionRate'+conversionRate);
          }
    }
    cumulativeSpent= (amountSpent==null)?0:amountSpent/conversionRate;
    return cumulativeSpent;
}

public static Partnership_Discount__c checkEligibleTierlevel(Decimal updatedAmount,set<Id> contractIdset,map<Id,Contract> contractMap,Map<String,Decimal> isoWithRateMap){
    Decimal elgibleAmount;
    system.debug('updatedAmount'+ updatedAmount);
    system.debug('contractIdset'+ contractIdset);
    Partnership_Discount__c eligibleDiscount;
    list<Partnership_Discount__c> partnershipDiscountList= [select Id,Discount__c,Lower_Limit__c,Upper_Limit__c,Tier__c,Partnership_Agreement__c,CurrencyIsoCode from Partnership_Discount__c where Partnership_Agreement__c in:contractIdset];
    system.debug('partnershipDiscountList'+ partnershipDiscountList);
    Integer HighestTierLevel= getHighestTierLevel(partnershipDiscountList);
    for(Partnership_Discount__c discount :partnershipDiscountList){
        if(contractMap.containsKey(discount.Partnership_Agreement__c)){
            Decimal contractTarget= contractMap.get(discount.Partnership_Agreement__c).Partnership_Target__c;
            system.debug(contractTarget);
            if(contractTarget!=null){
                if(updatedAmount<contractTarget){
                    elgibleAmount=contractTarget;
                    system.debug('eligible amount===>'+ elgibleAmount);
                    eligibleDiscount=checkEligibleDiscount(elgibleAmount,discount,HighestTierLevel,isoWithRateMap);
                    if(eligibleDiscount!=null){
                        break;
                    }
                   }
                 else{
                  elgibleAmount=updatedAmount;
                  system.debug('eligible amount===>'+ elgibleAmount);
                  eligibleDiscount=checkEligibleDiscount(elgibleAmount,discount,HighestTierLevel,isoWithRateMap);
                  if(eligibleDiscount!=null){
                    break;
                   }
                 }
            }
           else{
            system.debug('discount===>'+discount);
            eligibleDiscount=checkEligibleDiscount(updatedAmount,discount,HighestTierLevel,isoWithRateMap);
            if(eligibleDiscount!=null){
                break;
            }

           }
        }
    }  
 return eligibleDiscount;
}

public static void updateOpportunityLineItemRecord(Opportunity opp,Partnership_Discount__c discount,List<OpportunityLineItem> OpportunityLineItemNew ,List<Partnership_Exception__c> accountPartnershipExceptionList,Map<Id,Contract> contractMap){
    system.debug('inside opp line item update');
  //List<OpportunityLineItem> newOpportunityLineItemList=  new list<OpportunityLineItem>();
    for(OpportunityLineItem opportunityLineItem : OpportunityLineItemNew){
        PartnershipIncludeAndExclude partnershipDetails= checkDiscountEligibility(opp,opportunityLineItem,accountPartnershipExceptionList,discount,contractMap);
        system.debug('partnershipDetails==>'+partnershipDetails);
        if(partnershipDetails.isElgible && opportunityLineItem.OpportunityId==opp.Id)
        {
          if(partnershipDetails.isInclude){
            opportunityLineItem.Partnership_Discount__c=partnershipDetails.productDiscount;
            opportunityLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
          else {
            opportunityLineItem.Partnership_Discount__c=discount.Discount__c;
            opportunityLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
        }
    }
} 


public static void updateOldOpportunityLineItemRecord(Opportunity opp,Partnership_Discount__c discount,List<OpportunityLineItem> OldOpportunityLineItemList ,List<Partnership_Exception__c> accountPartnershipExceptionList,Map<Id,Contract> contractMap){
    system.debug('inside old opp line item update');
    List<OpportunityLineItem> newOpportunityLineItemList=  new list<OpportunityLineItem>();
    for(OpportunityLineItem opportunityLineItem : OldOpportunityLineItemList){
        PartnershipIncludeAndExclude partnershipDetails= checkDiscountEligibility(opp,opportunityLineItem,accountPartnershipExceptionList,discount,contractMap);
        system.debug('partnershipDetails==>'+partnershipDetails);
        if(partnershipDetails.isElgible && opportunityLineItem.OpportunityId==opp.Id)
        {
          if(partnershipDetails.isInclude){
            opportunityLineItem.Partnership_Discount__c=partnershipDetails.productDiscount;
            opportunityLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
          else {
            opportunityLineItem.Partnership_Discount__c=discount.Discount__c;
            opportunityLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
        }
          newOpportunityLineItemList.add(opportunityLineItem);
        system.debug('oldOpportunityLineItemList'+newOpportunityLineItemList);
    }
    Update newOpportunityLineItemList;
} 


public static PartnershipIncludeAndExclude checkDiscountEligibility(Opportunity opp,OpportunityLineItem opportunityLineItem,List<Partnership_Exception__c> accountPartnershipExceptionList,Partnership_Discount__c discount, Map<Id,Contract> contractMap) {
    
    PartnershipIncludeAndExclude PIE= new PartnershipIncludeAndExclude();
    PIE.isElgible=true;
    PIE.isInclude=false;
    system.debug('opp Line Item===>'+opportunityLineItem);
    system.debug('accountPartnershipExceptionList'+ accountPartnershipExceptionList);
    if(!accountPartnershipExceptionList.isEmpty()){
    for(Partnership_Exception__c PE :accountPartnershipExceptionList)
    {
         Contract contract= contractMap.get(PE.Customer_Partnership__c);

      if(!contract.Do_you_want_to_Include_Products__c && PE.Include_Exclude__c=='Exclude' && (PE.Exclude_Location_Region__c ==opp.Customer_Location_Region__c || PE.Exclude_Product__c==OpportunityLineItem.Product2Id)){
            system.debug(' inside excldue partnership Exception===> exclude'+ PE);
            PIE.isElgible=false;
        }

        else if(contract.Do_you_want_to_Include_Products__c){
             PIE.isElgible=false;

         if(PE.Include_Exclude__c=='Include' && PE.Include_Product__c== OpportunityLineItem.Product2Id) 
        {
            system.debug(' inside include partnership Exception===> include'+ PE);
            PIE.isInclude=true;
            PIE.isElgible=true;

           switch on discount.Tier__c {
               when '1'  {
                system.debug('discount Tier===>'+ discount.Tier__c);
                PIE.productDiscount=PE.Tier_1_Discount__c;
                break;
               }
               when '2' {
                system.debug('discount Tier===>'+ discount.Tier__c);
                PIE.productDiscount=PE.Tier_2_Discount__c;
                break;
               }
               when '3' {
                system.debug('discount Tier===>'+ discount.Tier__c); 
                PIE.productDiscount=PE.Tier_3_Discount__c;
                break;
               }
               when '4' {
                system.debug('discount Tier===>'+ discount.Tier__c);
                PIE.productDiscount=PE.Tier_4_Discount__c;
                break;
               }
               when '5' {
                system.debug('discount Tier===>'+ discount.Tier__c);  
                PIE.productDiscount=PE.Tier_5_Discount__c;
                break;
               }
               when '6' {
                PIE.productDiscount=PE.Tier_6_Discount__c;
                break;
               }
               when '7' {
                PIE.productDiscount=PE.Tier_7_Discount__c;
                break;
               }
           }
        }
      } 
    }
  } 
   return PIE; 
}

public static Partnership_Discount__c checkEligibleDiscount(Decimal Amount,Partnership_Discount__c discount,Integer HighestTierLevel,Map<String,Decimal> isoWithRateMap){
    Partnership_Discount__c eligibleDiscount;
    Decimal conversionRate;
    if(isoWithRateMap.containsKey(discount.CurrencyIsoCode)){
      conversionRate=isoWithRateMap.get(discount.CurrencyIsoCode);
        }
    system.debug('conversionRate'+conversionRate);

    if(discount.Tier__c=='1' && Amount<= (discount.Upper_Limit__c/conversionRate)){
        system.debug('inside Tier 1 discount');
        eligibleDiscount=discount;
        system.debug(eligibleDiscount);
    }
   else if(Amount >=(discount.Lower_Limit__c/conversionRate) && Amount<= (discount.Upper_Limit__c/conversionRate)){
    system.debug('inside other Tiers discounnt');
        eligibleDiscount=discount;
        system.debug(eligibleDiscount);
    } 
else if(integer.valueOf(discount.Tier__c)==HighestTierLevel && Amount>=(discount.Lower_Limit__c/conversionRate)){
    system.debug('inside Last Tier discount');
    eligibleDiscount=discount; 
}
return eligibleDiscount;
}

public static Integer getHighestTierLevel(list<Partnership_Discount__c> partnershipDiscountList){
 Integer HighestTierLevel=1;
for(Partnership_Discount__c discount:partnershipDiscountList){
 if(integer.valueOf(discount.Tier__c)>HighestTierLevel){
    HighestTierLevel=integer.valueOf(discount.Tier__c);
  }
}
system.debug('HighestTierLevel'+HighestTierLevel);
return HighestTierLevel;
}

    public class PartnershipIncludeAndExclude {
    Boolean isElgible;
    Boolean isInclude;
    Decimal productDiscount;
 }

 public static void handleAfterDelete(list<OpportunityLineItem> OpportunityLineItemOld) 
 {
     try { 
    isFirstTimeDelete=false;      
    system.debug('inside trigger handler');
     set<Id> OpportunityIdSet= new set<Id>();
     set<Id> AccountIdSet= new set<Id>();
     set<Id> agencyIdSet= new set<Id>();
     set<Id> advertiserIdSet= new set<Id>();
     set<Id> opportunityLineItemNewIdSet= new set<Id>();
     set<Id> opportunityLineItemOldIdSet= new set<Id>();
     List<Opportunity> opportunityList;
     Decimal sumOfOpportunityLineItemsOld=0;
     List<OpportunityLineItem> OldOpportunityLineItemList=new List<OpportunityLineItem>(); 

     for(OpportunityLineItem opportunityLineItem :OpportunityLineItemOld){ 
         OpportunityIdSet.add(opportunityLineItem.OpportunityId);
         opportunityLineItemNewIdSet.add(opportunityLineItem.Id);  
      }

 system.debug('opportunityLineItemNewIdSet===>'+opportunityLineItemNewIdSet);          
 system.debug('OpportunityIdSet'+OpportunityIdSet);

list<OpportunityLineItem> opportunityLineItemList= [select Id,Amount__c,OpportunityId,Current_Tier__c,Partnership_Discount__c,Product2Id from OpportunityLineItem where OpportunityId in:OpportunityIdSet];
If(opportunityLineItemList.size()>0){
 for(OpportunityLineItem opportunityLineItem: opportunityLineItemList){
     if(!opportunityLineItemNewIdSet.contains(opportunityLineItem.Id)){
     sumOfOpportunityLineItemsOld+=opportunityLineItem.Amount__c;
     opportunityLineItemOldIdSet.add(opportunityLineItem.Id);
    }
 }
} 
OldOpportunityLineItemList= [select Id,Amount__c,OpportunityId,Current_Tier__c,Partnership_Discount__c,Product2Id from OpportunityLineItem where Id in:opportunityLineItemOldIdSet];
system.debug('OldOpportunityLineItemList'+ OldOpportunityLineItemList);
system.debug('sumOfOpportunityLineItemsOld===>'+sumOfOpportunityLineItemsOld);

list<Opportunity> oppList= [select Id,AccountId,Advertiser__c from Opportunity where Id in:OpportunityIdSet];

for(Opportunity opp : oppList){ 
 agencyIdSet.add(opp.AccountId);
 if(opp.Advertiser__c!=null){
 advertiserIdSet.add(opp.Advertiser__c);
  }
}
 AccountIdSet.addAll(agencyIdSet);
 AccountIdSet.addAll(advertiserIdSet);

system.debug('AccountIdSet'+AccountIdSet);
list<Account> accountList= [select Id,Partnership_Applied__c,Partnership_Applied_From__c,Parent_Level_Partnership_Applied__c from Account where Id in:AccountIdSet];
set<Id> accountWithPartnerShipIdSet= new set<Id>();
set<Id> newAccountIdSet =  new set<Id>();

for(Account account :accountList){
    if(account.Partnership_Applied__c==true){
     accountWithPartnerShipIdSet.add(account.Id);
     newAccountIdSet.add(account.Id);

    }
    else if(account.Parent_Level_Partnership_Applied__c==true) {
     accountWithPartnerShipIdSet.add(account.Id);
     newAccountIdSet.add(account.Partnership_Applied_From__c);
    }
}

system.debug('newAccountIdSet==>'+newAccountIdSet);
system.debug('accountWithPartnerShipIdSet==>'+accountWithPartnerShipIdSet);
Map<Id,Account> accountWithPartnerShipMap=new Map<Id,Account>([select Id,Partnership_Applied__c,Partnership_Applied_From__c,Parent_Level_Partnership_Applied__c,Customer_Location_Region__c,Relationship_Type__c from Account where Id in:accountWithPartnerShipIdSet]);


if(accountWithPartnerShipIdSet!=null){
 opportunityList =[select Id,AccountId,Proposal_Amount_pre_discount__c,CurrencyIsoCode,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c from Opportunity where Id in :OpportunityIdSet];
 system.debug('opportunityList===>'+opportunityList);
 system.debug('size==>'+ opportunityList.size());
}


list<Contract> contractList= [select Id,AccountId,Partnership_Type__c,Active__c,Partnership_Target__c from Contract where AccountId in:newAccountIdSet and Active__c=true];
map<Id,Contract> contractMap= new map<Id,Contract>([select Id,AccountId,Partnership_Type__c,Do_you_want_to_Include_Products__c,Active__c,Partnership_Target__c from Contract where AccountId in:newAccountIdSet and Active__c=true]);
set<Id> contractIdset= new set<Id>();


for(Contract contract :contractList){
 contractIdset.add(contract.Id);
}

Map<Id,list<Partnership_Exception__c>> contractTopartnershipExceptionMap = new Map<Id,list<Partnership_Exception__c>>();

for(Partnership_Exception__c parException :[select Id,Include_Product__c,Include_Exclude__c,Customer_Partnership__c,Exclude_Location_Region__c,Exclude_Product__c,Tier_1_Discount__c,Tier_2_Discount__c,Tier_3_Discount__c,Tier_4_Discount__c,Tier_5_Discount__c,Tier_6_Discount__c,Tier_7_Discount__c from Partnership_Exception__c where Customer_Partnership__c in:contractIdset])
{
 if(contractTopartnershipExceptionMap.containsKey(parException.Customer_Partnership__c)){
     contractTopartnershipExceptionMap.get(parException.Customer_Partnership__c).add(parException);
 }
 else{
     contractTopartnershipExceptionMap.put(parException.Customer_Partnership__c, new list<Partnership_Exception__c> {parException});
 }

}

system.debug('contractTopartnershipExceptionMap'+ contractTopartnershipExceptionMap);

Map<Id,list<Contract>> accountToContractMap= new Map<Id,list<Contract>>() ;
for(Contract contract :contractList){

 if(accountToContractMap.containsKey(contract.AccountId)){
     accountToContractMap.get(contract.AccountId).add(contract);    
 }

 else{
     accountToContractMap.put(contract.AccountId, new list<Contract> {contract});
 }

}

system.debug('accountToContractMap'+ accountToContractMap);

List<CurrencyType> currencyTpyeList = [select Id,IsoCode,ConversionRate from CurrencyType where isActive = true] ;
 Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
 for(CurrencyType c : currencyTpyeList) {
     isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
 }
 //system.debug('isoWithRateMap'+isoWithRateMap);
 for(Opportunity opportunity : opportunityList)
 {   
     Decimal conversionRate;
     List<Partnership_Exception__c> accountPartnershipExceptionList= new List<Partnership_Exception__c>();
     Decimal UpdatedAmount;
     if(isoWithRateMap.containsKey(opportunity.CurrencyIsoCode)){
      conversionRate=isoWithRateMap.get(opportunity.CurrencyIsoCode);
     }
     system.debug('conversionRate'+conversionRate);
     if(opportunity.Relationship_Type__c=='Advertiser'){
         Decimal AmountSpent=getAmountSpent(opportunity.Advertiser__c,isoWithRateMap);
         system.debug('AmountSpent in FY'+AmountSpent);
         UpdatedAmount=AmountSpent+(sumOfOpportunityLineItemsOld/conversionRate);
     }
 
     else if(opportunity.Relationship_Type__c=='Agency'){
         system.debug('opportunity.Advertiser__c'+ opportunity.Advertiser__c);
         system.debug('opportunity.Agency__c'+ opportunity.Agency__c);
         Decimal AmountSpent= getAmountSpent(opportunity.Advertiser__c,opportunity.AccountId,isoWithRateMap);
         system.debug('AmountSpent'+AmountSpent);
         UpdatedAmount=AmountSpent+(sumOfOpportunityLineItemsOld/conversionRate);
     }
     system.debug('UpdatedAmount'+UpdatedAmount);
     if(accountWithPartnerShipMap.containsKey(opportunity.AccountId) || accountWithPartnerShipMap.containsKey(opportunity.Advertiser__c) ){
         Id accountwithPartnershipId;
         Account acc= accountWithPartnerShipMap.get(opportunity.AccountId);
         if(acc==null){
            acc=accountWithPartnerShipMap.get(opportunity.Advertiser__c);
         }
         system.debug(acc);
         if(acc.Parent_Level_Partnership_Applied__c){
             accountwithPartnershipId= acc.Partnership_Applied_From__c;
         }
         else{
             accountwithPartnershipId=acc.Id;
         }
        Partnership_Discount__c discount= checkEligibleTierlevel(UpdatedAmount,contractIdset,contractMap,isoWithRateMap);
         system.debug(discount);
         if(discount!=null && accountToContractMap.containsKey(accountwithPartnershipId)){
          system.debug('inside if statement');   
         List<Contract> newContractList= accountToContractMap.get(accountwithPartnershipId);
         system.debug('newContractList====>'+ newContractList);
         for (Contract con :newContractList){
             if(contractTopartnershipExceptionMap.containsKey(con.Id)){
                 system.debug('inside partnership exception for contract');
                 accountPartnershipExceptionList= contractTopartnershipExceptionMap.get(con.Id); 
                 system.debug('accountPartnershipExceptionList===>'+ accountPartnershipExceptionList);  
             }
         }
         system.debug('before line item update');
         updateOldOpportunityLineItemRecord(opportunity,discount,OldOpportunityLineItemList,accountPartnershipExceptionList,contractMap);
         system.debug('after line item update');
         }
     }

 }

}

catch (Exception ex) {
   system.debug('There is an error creating Line Item'+ ex.getMessage()+'line number'+ex.getLineNumber());  
}


 }

}