public with sharing class SalesOrderLineItemTriggerHandler {
    public static Boolean isFirstTime=True;
    public static Boolean isDeleteFirstTime=True;
    public static void handleBeforeInsertUpdate(list<QuoteLineItem> quoteLineItemNew) 
    {
        isFirstTime=False;
        system.debug('inside trigger handler');
        set<Id> opportunityIdSet= new set<Id>();
        set<Id> accountIdSet= new set<Id>();
        set<Id> salesOrderIdSet= new set<Id>();
        set<Id> agencyIdSet= new set<Id>();
        set<Id> advertiserIdSet= new set<Id>();
        Decimal sumOfQuoteLineItems=0;
        set<Id> quoteLineItemNewIdSet= new set<Id>();
        set<Id> quoteLineItemOldIdSet= new set<Id>();
        Decimal sumOfQuoteLineItemsOld=0;
        List<QuoteLineItem> oldQuoteLineItemList=new List<QuoteLineItem>(); 
        //List<Opportunity> opportunityList;
        map<Id,Opportunity> opportunityMap= new map<Id,Opportunity>();

        for(QuoteLineItem quoteLineItem : QuoteLineItemNew){ 
            salesOrderIdSet.add(quoteLineItem.QuoteId);
            quoteLineItemNewIdSet.add(quoteLineItem.Id);  
            if(quoteLineItem.Sales_Metric__c=='CPM'){
                sumOfQuoteLineItems+=((quoteLineItem.Quantity/1000)*quoteLineItem.UnitPrice);
                }
                else{
                sumOfQuoteLineItems+=(quoteLineItem.Quantity*quoteLineItem.UnitPrice); 
                }
         }

   system.debug('sumOfQuoteLineItems===>'+sumOfQuoteLineItems);
   system.debug('salesOrderIdSet'+salesOrderIdSet);

   list<QuoteLineItem> QuoteLineItemList= [select Id,Amount__c,QuoteId,Current_Tier__c,Partnership_Discount__c,Product2Id from QuoteLineItem where QuoteId in:salesOrderIdSet];
   If(QuoteLineItemList.size()>0){
    for(QuoteLineItem quoteLineItem: QuoteLineItemList){
        if(!quoteLineItemNewIdSet.contains(quoteLineItem.Id)){
        sumOfQuoteLineItemsOld+=quoteLineItem.Amount__c;
        quoteLineItemOldIdSet.add(quoteLineItem.Id);
       }
    }
  } 

  oldQuoteLineItemList= [select Id,Amount__c,QuoteId,Current_Tier__c,Partnership_Discount__c,Product2Id from QuoteLineItem where Id in:quoteLineItemOldIdSet];
  system.debug('OldQuoteLineItemList'+ oldQuoteLineItemList);
  system.debug('sumOfQuoteLineItemsOld===>'+sumOfQuoteLineItemsOld);

   list<Quote> salesOrderList=[select Id,OpportunityId,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c,Amount_Subtotal__c,CurrencyIsoCode from Quote where Id in:salesOrderIdSet]; 

    for(Quote quote : salesOrderList){ 
           opportunityIdSet.add(quote.OpportunityId);
         }

   list<Opportunity> oppList= [select Id,AccountId,Advertiser__c from Opportunity where Id in:OpportunityIdSet];
   //map<Id,Opportunity> opportunityMap= new map<Id,Opportunity>([select Id,AccountId,Advertiser__c from Opportunity where Id in:OpportunityIdSet]);

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
    List<Opportunity> opportunityList =[select Id,AccountId,Proposal_Amount_pre_discount__c,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c from Opportunity where Id in :OpportunityIdSet];
    for(Opportunity opp:opportunityList){
        opportunityMap.put(opp.Id,opp);
    }
   // map<Id,Opportunity> opportunityMap= new map<Id,Opportunity>([select Id,AccountId,Proposal_Amount_pre_discount__c,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c from Opportunity where Id in :OpportunityIdSet]);
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

try {

    for(Quote quote : salesOrderList)
    {   
        Decimal conversionRate;
        List<Partnership_Exception__c> accountPartnershipExceptionList= new List<Partnership_Exception__c>();
        Decimal UpdatedAmount;
        if(isoWithRateMap.containsKey(quote.CurrencyIsoCode)){
            conversionRate=isoWithRateMap.get(quote.CurrencyIsoCode);
           }
        if(quote.Relationship_Type__c=='Advertiser'){
            Decimal AmountSpent=getAmountSpent(quote.Advertiser__c,isoWithRateMap);
            system.debug('AmountSpent in FY'+AmountSpent);
            //if(AmountSpent !=null){
            system.debug('Proposal amount'+integer.valueOf(quote.Amount_Subtotal__c));
            UpdatedAmount=AmountSpent+(sumOfQuoteLineItemsOld/conversionRate)+(sumOfQuoteLineItems/conversionRate);
            //UpdatedAmount= (AmountSpent==null)? (sumOfQuoteLineItemsOld/conversionRate)+(sumOfQuoteLineItems/conversionRate):AmountSpent+(sumOfQuoteLineItemsOld/conversionRate)+(sumOfQuoteLineItems/conversionRate);
            //}
        }
    
        else if(quote.Relationship_Type__c=='Agency'){
            system.debug('opportunity.Advertiser__c'+ quote.Advertiser__c);
            system.debug('opportunity.Agency__c'+ quote.Agency__c);
            Decimal AmountSpent= getAmountSpent(quote.Advertiser__c,quote.Agency__c,isoWithRateMap);
            system.debug('AmountSpent'+AmountSpent);
            //if(AmountSpent !=null){
            UpdatedAmount=AmountSpent+(sumOfQuoteLineItemsOld/conversionRate)+(sumOfQuoteLineItems/conversionRate);
            //UpdatedAmount= (AmountSpent==null)? (sumOfQuoteLineItemsOld/conversionRate)+(sumOfQuoteLineItems/conversionRate):AmountSpent+(sumOfQuoteLineItemsOld/conversionRate)+(sumOfQuoteLineItems/conversionRate);
            //}
        }
        system.debug('UpdatedAmount'+UpdatedAmount);
           

         Opportunity opportunity= opportunityMap.get(quote.OpportunityId);
        if(accountWithPartnerShipMap.containsKey(opportunity.AccountId) || accountWithPartnerShipMap.containsKey(opportunity.Advertiser__c)){
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
           Partnership_Discount__c discount= checkEligibleTierlevel(UpdatedAmount,contractMap,isoWithRateMap);
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
            updateSalesOrderLineItemRecord(quote,discount,quoteLineItemNew,accountPartnershipExceptionList,contractMap);
            updateOldSalesOrderLineItemRecord(quote,discount,oldQuoteLineItemList,accountPartnershipExceptionList,contractMap);
            system.debug('after line item update');
            }
        }

    }

}

  catch (Exception ex) {
      system.debug('There is an error creating Line Item'+ ex.getMessage());  
}

} 


public static Decimal getAmountSpent(Id Advertiser,Map<String,Decimal> isoWithRateMap){
    Decimal amountSpent;
    Decimal conversionRate;
    Decimal cumulativeSpent;
    system.debug('inside Advertiser amount spent');
    list<Account_Relationships__c> ARList = [select Id,	Advertiser__c,Amount_Spent__c,CurrencyIsoCode from Account_Relationships__c where Advertiser__c=:Advertiser];
    if(ARList.size()>0){
        if(isoWithRateMap.containsKey(ARList[0].CurrencyIsoCode)){
            conversionRate=isoWithRateMap.get(ARList[0].CurrencyIsoCode);
            system.debug('conversionRate'+conversionRate);
          }
        amountSpent=ARList[0].Amount_Spent__c;
    }  
    cumulativeSpent= (amountSpent==null)? 0: amountSpent/conversionRate;
    return cumulativeSpent;
}

public static Decimal getAmountSpent(Id Advertiser,Id Agency,Map<String,Decimal> isoWithRateMap){
     Decimal amountSpent;
     Decimal conversionRate;
     Decimal cumulativeSpent;
    system.debug('inside get Agency amount spent');
list<Account_Relationships__c> ARList = [select Id,	Advertiser__c,Agency__c,Amount_Spent__c,CurrencyIsoCode from Account_Relationships__c where Advertiser__c=:Advertiser and Agency__c=:Agency];
    if(ARList.size()>0){
        if(isoWithRateMap.containsKey(ARList[0].CurrencyIsoCode)){
            conversionRate=isoWithRateMap.get(ARList[0].CurrencyIsoCode);
            system.debug('conversionRate'+conversionRate);
          }
        amountSpent =ARList[0].Amount_Spent__c;
    }
    
    cumulativeSpent= (amountSpent==null)? 0: amountSpent/conversionRate;
    return cumulativeSpent;
}


public static Partnership_Discount__c checkEligibleTierlevel(Decimal updatedAmount,map<Id,Contract> contractMap,Map<String,Decimal> isoWithRateMap){
    Decimal elgibleAmount;
    Partnership_Discount__c eligibleDiscount;
    system.debug('updatedAmount'+ updatedAmount);
    system.debug('contractIdset'+ contractMap.keySet());
    List<Partnership_Discount__c> partnershipDiscountList= [select Id,Discount__c,Lower_Limit__c,Upper_Limit__c,Tier__c,Partnership_Agreement__c,CurrencyIsoCode from Partnership_Discount__c where Partnership_Agreement__c in:contractMap.keySet()];
    system.debug('partnershipDiscountList'+ partnershipDiscountList);
    Integer HighestTierLevel= getHighestTierLevel(partnershipDiscountList);
    for(Partnership_Discount__c discount :partnershipDiscountList){
        if(contractMap.containsKey(discount.Partnership_Agreement__c)){
            Decimal contractTarget= contractMap.get(discount.Partnership_Agreement__c).Partnership_Target__c;
            system.debug(contractTarget);
            if(contractTarget!=null){
                if(updatedAmount<contractTarget){
                    elgibleAmount=contractTarget;
                    eligibleDiscount=checkEligibleDiscount(elgibleAmount,discount,HighestTierLevel,isoWithRateMap);
                    if(eligibleDiscount!=null){
                        break;
                    }
                   }
                 else{
                  elgibleAmount=updatedAmount;
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

public static void updateSalesOrderLineItemRecord(Quote quote,Partnership_Discount__c discount,list<QuoteLineItem> quoteLineItemNew,List<Partnership_Exception__c> accountPartnershipExceptionList,Map<Id,Contract> contractMap){
    system.debug('inside opp line item update');

    for(QuoteLineItem quoteLineItem : quoteLineItemNew){
        PartnershipIncludeAndExclude partnershipDetails= checkDiscountEligibility(quote,quoteLineItem,accountPartnershipExceptionList,discount,contractMap);
        system.debug('partnershipDetails==>'+partnershipDetails);
        if(partnershipDetails.isElgible && quoteLineItem.QuoteId==quote.Id)
        {
          if(partnershipDetails.isInclude){
            quoteLineItem.Partnership_Discount__c=partnershipDetails.productDiscount;
            quoteLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
          else {
            quoteLineItem.Partnership_Discount__c=discount.Discount__c;
            quoteLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
        }
    }
} 

public static void updateOldSalesOrderLineItemRecord(Quote quote,Partnership_Discount__c discount,list<QuoteLineItem> oldQuoteLineItemList,List<Partnership_Exception__c> accountPartnershipExceptionList,Map<Id,Contract> contractMap){
    system.debug('inside old line item update');
    system.debug('discount==>'+discount);
    List<QuoteLineItem> newQuoteLineItemList=  new list<QuoteLineItem>();
    for(QuoteLineItem quoteLineItem : oldQuoteLineItemList){
        PartnershipIncludeAndExclude partnershipDetails= checkDiscountEligibility(quote,quoteLineItem,accountPartnershipExceptionList,discount,contractMap);
        system.debug('partnershipDetails==>'+partnershipDetails);
        if(partnershipDetails.isElgible && quoteLineItem.QuoteId==quote.Id)
        {
          if(partnershipDetails.isInclude){
            quoteLineItem.Partnership_Discount__c=partnershipDetails.productDiscount;
            quoteLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
          else {
            quoteLineItem.Partnership_Discount__c=discount.Discount__c;
            quoteLineItem.Current_Tier__c=integer.valueOf(discount.Tier__c);
          }
       }
     newQuoteLineItemList.add(quoteLineItem); 
    }
    Update newQuoteLineItemList;
} 

public static PartnershipIncludeAndExclude checkDiscountEligibility(Quote quote,QuoteLineItem quoteLineItem,List<Partnership_Exception__c> accountPartnershipExceptionList,Partnership_Discount__c discount, Map<Id,Contract> contractMap) {
    
    PartnershipIncludeAndExclude PIE= new PartnershipIncludeAndExclude();
    PIE.isElgible=true;
    PIE.isInclude=false;
    system.debug('opp Line Item===>'+quoteLineItem);
    system.debug('accountPartnershipExceptionList'+ accountPartnershipExceptionList);
    if(!accountPartnershipExceptionList.isEmpty()){
    for(Partnership_Exception__c PE :accountPartnershipExceptionList)
    {
         //system.debug(contractMap);
         Contract contract= contractMap.get(PE.Customer_Partnership__c);
         //system.debug(contract);

        if(!contract.Do_you_want_to_Include_Products__c && PE.Include_Exclude__c=='Exclude' && (PE.Exclude_Location_Region__c ==quote.Customer_Location_Region__c || PE.Exclude_Product__c==quoteLineItem.Product2Id)){
            system.debug(' inside excldue partnership Exception===>'+ PE);
            PIE.isElgible=false;
        }

        else if(contract.Do_you_want_to_Include_Products__c ){
         PIE.isElgible=false;

         if(PE.Include_Exclude__c=='Include' && PE.Include_Product__c== quoteLineItem.Product2Id) 
        {
            system.debug(' inside include partnership Exception===>'+ PE);
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

    if(discount.Tier__c=='1' && Amount<=(discount.Upper_Limit__c/conversionRate)){
        system.debug('inside Tier 1 discount');
        eligibleDiscount=discount;
        system.debug(eligibleDiscount);
    }
   else if(Amount >=(discount.Lower_Limit__c/conversionRate) && Amount<=(discount.Upper_Limit__c/conversionRate)){
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

 public static void handleAfterDelete(list<QuoteLineItem> quoteLineItemItemOld) 
    {
        isDeleteFirstTime=False;
        system.debug('inside trigger handler');
        set<Id> opportunityIdSet= new set<Id>();
        set<Id> accountIdSet= new set<Id>();
        set<Id> salesOrderIdSet= new set<Id>();
        set<Id> agencyIdSet= new set<Id>();
        set<Id> advertiserIdSet= new set<Id>();
        //Decimal sumOfQuoteLineItems=0;
        set<Id> quoteLineItemNewIdSet= new set<Id>();
        set<Id> quoteLineItemOldIdSet= new set<Id>();
        Decimal sumOfQuoteLineItemsOld=0;
        List<QuoteLineItem> oldQuoteLineItemList=new List<QuoteLineItem>(); 
        //List<Opportunity> opportunityList;
        map<Id,Opportunity> opportunityMap= new map<Id,Opportunity>();

        for(QuoteLineItem quoteLineItem : quoteLineItemItemOld){ 
            salesOrderIdSet.add(quoteLineItem.QuoteId);
            quoteLineItemNewIdSet.add(quoteLineItem.Id);
         }

   //system.debug('sumOfQuoteLineItems===>'+sumOfQuoteLineItems);
   system.debug('salesOrderIdSet'+salesOrderIdSet);

   list<QuoteLineItem> QuoteLineItemList= [select Id,Amount__c,QuoteId,Current_Tier__c,Partnership_Discount__c,Product2Id from QuoteLineItem where QuoteId in:salesOrderIdSet];
   If(QuoteLineItemList.size()>0){
    for(QuoteLineItem quoteLineItem: QuoteLineItemList){
        if(!quoteLineItemNewIdSet.contains(quoteLineItem.Id)){
        sumOfQuoteLineItemsOld+=quoteLineItem.Amount__c;
        quoteLineItemOldIdSet.add(quoteLineItem.Id);
       }
    }
  } 

  oldQuoteLineItemList= [select Id,Amount__c,QuoteId,Current_Tier__c,Partnership_Discount__c,Product2Id from QuoteLineItem where Id in:quoteLineItemOldIdSet];
  system.debug('OldQuoteLineItemList'+ oldQuoteLineItemList);
  system.debug('sumOfQuoteLineItemsOld===>'+sumOfQuoteLineItemsOld);

   list<Quote> salesOrderList=[select Id,OpportunityId,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c,Amount_Subtotal__c,CurrencyIsoCode from Quote where Id in:salesOrderIdSet]; 

    for(Quote quote : salesOrderList){ 
           opportunityIdSet.add(quote.OpportunityId);
         }

   list<Opportunity> oppList= [select Id,AccountId,Advertiser__c from Opportunity where Id in:OpportunityIdSet];
   //map<Id,Opportunity> opportunityMap= new map<Id,Opportunity>([select Id,AccountId,Advertiser__c from Opportunity where Id in:OpportunityIdSet]);

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
    List<Opportunity> opportunityList =[select Id,AccountId,Proposal_Amount_pre_discount__c,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c from Opportunity where Id in :OpportunityIdSet];
    for(Opportunity opp:opportunityList){
        opportunityMap.put(opp.Id,opp);
    }
   // map<Id,Opportunity> opportunityMap= new map<Id,Opportunity>([select Id,AccountId,Proposal_Amount_pre_discount__c,Relationship_Type__c,Advertiser__c,Agency__c,Customer_Location_Region__c from Opportunity where Id in :OpportunityIdSet]);
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

try {

    for(Quote quote : salesOrderList)
    {   
        Decimal conversionRate;
        List<Partnership_Exception__c> accountPartnershipExceptionList= new List<Partnership_Exception__c>();
        Decimal UpdatedAmount;
        if(isoWithRateMap.containsKey(quote.CurrencyIsoCode)){
            conversionRate=isoWithRateMap.get(quote.CurrencyIsoCode);
           }
        if(quote.Relationship_Type__c=='Advertiser'){
            Decimal AmountSpent=getAmountSpent(quote.Advertiser__c,isoWithRateMap);
            system.debug('AmountSpent in FY'+AmountSpent);
            //if(AmountSpent !=null){
            system.debug('Proposal amount'+integer.valueOf(quote.Amount_Subtotal__c));
            UpdatedAmount=AmountSpent+(sumOfQuoteLineItemsOld/conversionRate);
            //UpdatedAmount= (AmountSpent==null)? (sumOfQuoteLineItemsOld/conversionRate):AmountSpent+(sumOfQuoteLineItemsOld/conversionRate);
            //}
        }
    
        else if(quote.Relationship_Type__c=='Agency'){
            system.debug('opportunity.Advertiser__c'+ quote.Advertiser__c);
            system.debug('opportunity.Agency__c'+ quote.Agency__c);
            Decimal AmountSpent= getAmountSpent(quote.Advertiser__c,quote.Agency__c,isoWithRateMap);
            system.debug('AmountSpent'+AmountSpent);
            //if(AmountSpent !=null){
              UpdatedAmount=AmountSpent+(sumOfQuoteLineItemsOld/conversionRate);
            //UpdatedAmount= (AmountSpent==null)? (sumOfQuoteLineItemsOld/conversionRate):AmountSpent+(sumOfQuoteLineItemsOld/conversionRate);
            //}
        }
        system.debug('UpdatedAmount'+UpdatedAmount);
           

         Opportunity opportunity= opportunityMap.get(quote.OpportunityId);
        if(accountWithPartnerShipMap.containsKey(opportunity.AccountId) || accountWithPartnerShipMap.containsKey(opportunity.Advertiser__c)){
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
           Partnership_Discount__c discount= checkEligibleTierlevel(UpdatedAmount,contractMap,isoWithRateMap);
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
            updateOldSalesOrderLineItemRecord(quote,discount,oldQuoteLineItemList,accountPartnershipExceptionList,contractMap);
            system.debug('after line item update');
            }
        }

    }

}

  catch (Exception ex) {
      system.debug('There is an error creating Line Item'+ ex.getMessage());  
}

 }

}