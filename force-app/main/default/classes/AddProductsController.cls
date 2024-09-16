public Without sharing class AddProductsController {
   
    @AuraEnabled (cacheable=true)
    public static List<ProductPriceWrapper> getProducts(string proposalId){
        try {
        Map<Id,PricebookEntry> productToPricebookMap= getproductToPricebookMap(proposalId); 
        List<Product2> allProducts= [select Id,Name,IsActive,ProductCode,Family,Format__c,toLabel(Target_GEO__c),Type__c,Media_Type__c,Delivery_Type__c,Device_Type_Options_Code__c,Main_KPI__c from Product2 where Id in:productToPricebookMap.keySet() and IsActive=true];
        List<ProductPriceWrapper> productWrapperList= new List<ProductPriceWrapper>();
        productWrapperList.addAll(createProductPriceWrapper(allProducts,productToPricebookMap));
          return productWrapperList;
     } 
        catch (Exception e) {
            system.debug('error'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ProductPriceWrapper> getProductsByName(string name, List<ProductPriceWrapper> selctPrds,string proposalId ){

        Map<Id,PricebookEntry> productToPricebookMap= getproductToPricebookMap(proposalId); 
        String productName='%'+name+'%';
        Set<ProductPriceWrapper> unqSeltPrd = new Set<ProductPriceWrapper>();

        if(selctPrds != null){
            unqSeltPrd.addAll(selctPrds);
        }                
        try {
            List<ProductPriceWrapper> products = new List<ProductPriceWrapper>();            
            List<Product2> prdRslt = [select Id,IsActive,Name,ProductCode,Family,Format__c,toLabel(Target_GEO__c),Type__c,Media_Type__c,Delivery_Type__c,Device_Type_Options_Code__c,Main_KPI__c from Product2 where Name like :productName and IsActive=true and Id in:productToPricebookMap.keySet()];
           
            if(unqSeltPrd.size() > 0){
              products.addAll(unqSeltPrd);
              products.addAll(createProductPriceWrapper(prdRslt,productToPricebookMap));
            }
             else 
            { 
            products.addAll(createProductPriceWrapper(prdRslt,productToPricebookMap)); 
            }
            return products;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

  @AuraEnabled
  public static List<Result> createLineItems(List<ProductAttributes> attributes,string proposalId,List<ProductWrapper> productWrapper ){
     String result;
     List<OpportunityLineItem> lineItemsList= new List<OpportunityLineItem>();
     Opportunity opp= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity where Id=:proposalId Limit 1];
     String pricebId=opp.Pricebook2Id;
     string currencyISOCode=opp.CurrencyISOCode;
    
    Map<String,ProductAttributes> attributesMap= new Map<String,ProductAttributes>();
    for(ProductAttributes att :attributes){
        attributesMap.put(String.valueOf(att.id),att);
    }
    List<String> prdIds = New List<String>();
    for(ProductWrapper itr : productWrapper){
        prdIds.add(itr.productId);
    }
    List<PricebookEntry> pbe = [select id, name, CurrencyIsoCode, Product2Id from PriceBookEntry where Pricebook2id =:pricebId and Product2Id in: prdIds and CurrencyIsoCode=:currencyISOCode];
    Map<String,String> prdPb = new Map<String, String>();
    for(PricebookEntry itr : pbe){
        prdPb.put(itr.Product2Id, itr.id);
    }

      try {
      for(ProductWrapper product :productWrapper){
        OpportunityLineItem lineItem= new OpportunityLineItem();
        lineItem.Start_Date__c =  product.startDate;
        lineItem.End_Date__c=  product.endDate;
        lineItem.UnitPrice=   product.UnitPrice;
        lineItem.Sale_Price__c=  product.UnitPrice;  
        lineItem.Quantity=product.Quantity;
        lineItem.Line_Description__c=product.description;
         lineItem.Frequency_Cap__c=product.frequencyCap;   
         lineItem.Commission_Amount__c=product.commissionAmount;      
         lineItem.Target_Gender__c=product.targetGender;
         lineItem.Target_Audience__c=product.targetAudience;
         lineItem.Device_Type__c=product.deviceType;
         lineItem.KSV_Price_Plan__c=product.ksvPricePlan;
         lineItem.Target_Age_Multi__c=product.targetAge;
         lineItem.OpportunityId=proposalId;
         lineItem.Product2Id=product.productId;
         lineItem.Sales_Metric__c=product.salesMetric;
         lineItem.LWC_row_number__c=product.id;
         lineItem.SA_Team_Provided_Creatives_at_Proposal__c=product.creative;
         lineItem.Design__c=product.design;
         lineItem.Frequency_Cap_Period__c=product.period;
         lineItem.Main_KPI__c=product.kpi;
         lineItem.Budget_Class__c=product.budget;
         lineItem.PricebookEntryId=prdPb.get(product.productId);
         lineItemsList.add(lineItem); 
      }
      system.debug('line item list'+ lineItemsList);
     Database.SaveResult[] srList = Database.insert(lineItemsList,false);
     List<Result> resultList= new List<Result>();
     for (Integer i=0; i<srList.size();i++) {
        if (!srList[i].isSuccess()) {
            Result res= new Result();
            for(Database.Error err : srList[i].getErrors()) { 
                res.status='error';
                res.message= err.getMessage();
                res.id=lineItemsList.get(i).LWC_row_number__c;
                resultList.add(res);
            }
        }
        else if(srList[i].isSuccess()){
            Result res= new Result();
            res.status='success';
            res.id=lineItemsList.get(i).LWC_row_number__c;
            resultList.add(res);
        }
    } 
      return resultList;       
      } 
 catch (Exception e) {
            system.debug('Exception '+e.getMessage());
          throw new AuraHandledException(e.getMessage());
      } 
  }

  @AuraEnabled
  public static List<OpportunityLineItem> getProductLineItems(string proposalId){
      try {
       List<OpportunityLineItem> proposalItemList= [Select Id,Product2.Name,Quantity,Sales_Metric__c,Format__c,Start_Date__c,Media_Type__c,Delivery_Type__c,End_Date__c,Budget_Class__c,
       Target_Gender__c,Target_Audience__c,	Target_Age_Multi__c,toLabel(Target_Geo_Display__c),Device_Type__c,
       UnitPrice,Sale_Price__c,Amount__c,OpportunityId,Main_KPI__c,KSV_Price_Plan__c,Frequency_Cap__c,Frequency_Cap_Period__c,Design__c,toLabel(SA_Team_Provided_Creatives_at_Proposal__c),Line_Description__c,Partnership_Amount__c,Commission_Amount__c from OpportunityLineItem where OpportunityId=:proposalId];
          return proposalItemList;
      } 
      catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  }
    
    @AuraEnabled
    public static List<ProductPriceWrapper> applyProductFilters(list<String> family ,list<ProductPriceWrapper> productsList,string proposalId,List<String> geoValues ){
        system.debug('family values'+family);
        system.debug('geo values'+geoValues);
        List<ProductPriceWrapper> productWrapperList= new List<ProductPriceWrapper>();
        List<Product2> Updatedproducts= new List<Product2>();
        set<Id> productIds= new set<Id>();
        for(ProductPriceWrapper product :productsList)
        {
        productIds.add(product.id);
        }
        Map<Id,PricebookEntry> pricebookMap= getproductToPricebookMap(proposalId); 

        try {
            if(geoValues.isEmpty()){
             Updatedproducts= [select Id,Name,ProductCode,Family,Format__c,toLabel(Target_GEO__c),Type__c,Media_Type__c,Delivery_Type__c,Device_Type_Options_Code__c,Main_KPI__c from Product2 where Id in :productIds and Family in:family];
            }
            else if(family.isEmpty()) {
            Updatedproducts= [select Id,Name,ProductCode,Family,Format__c,toLabel(Target_GEO__c),Type__c,Media_Type__c,Delivery_Type__c,Device_Type_Options_Code__c,Main_KPI__c from Product2 where Id in :productIds and Target_GEO__c in:geoValues];
            }
            else if(!geoValues.isEmpty() && !family.isEmpty())
            {
            Updatedproducts= [select Id,Name,ProductCode,Family,Format__c,toLabel(Target_GEO__c),Type__c,Media_Type__c,Delivery_Type__c,Device_Type_Options_Code__c,Main_KPI__c from Product2 where Id in :productIds and Family in:family and Target_GEO__c in:geoValues];
            }
            system.debug('products'+Updatedproducts);
            productWrapperList.addAll(createProductPriceWrapper(Updatedproducts,pricebookMap));
           return productWrapperList;
        } 

catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

  }

  @AuraEnabled
  public static ProductPriceWrapper getProductDetails(string productId,string proposalId ){
    List<Opportunity> opportunity= [select Id,Pricebook2Id,CurrencyISOCode from Opportunity where Id=:proposalId];
    String pricebookId= opportunity[0].Pricebook2Id; 
    String currencyISOCode=opportunity[0].CurrencyIsoCode;

    Map<Id,PricebookEntry> productToPricebookMap = new Map<Id,PricebookEntry>();
   
    List<PricebookEntry> pricebookList=[select Id,Product2Id,Pricebook2Id,UnitPrice,CurrencyISOCode from PricebookEntry where Pricebook2Id=:pricebookId and CurrencyISOCode=:currencyISOCode and Product2Id=:productId];
       try{              
      List<Product2> products = [select Id,IsActive,Name,ProductCode,Family,Format__c,toLabel(Target_GEO__c),Type__c,Media_Type__c,Delivery_Type__c,Device_Type_Options_Code__c from Product2 where Id=:productId];
          ProductPriceWrapper wrapper= new ProductPriceWrapper();
          wrapper.id= products[0].Id;
          wrapper.name=products[0].Name;
          wrapper.family=products[0].Family;
          wrapper.deviceTypeOptions=products[0].ProductCode;
          wrapper.format=products[0].Format__c;
          wrapper.targetGeo= products[0].Target_GEO__c;
          wrapper.mediaType= products[0].Media_Type__c;
          wrapper.deliveryType=products[0].Delivery_Type__c;
          wrapper.pricebookId=pricebookList[0].Pricebook2Id;
          wrapper.unitPrice=pricebookList[0].UnitPrice;
          wrapper.deviceTypeCode=products[0].Device_Type_Options_Code__c;

          return wrapper;
      } 
      catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  }

  @AuraEnabled
  public static List<ProductPriceWrapper> getGeoProducts(String proposalId,String geoValue ){
      List<ProductPriceWrapper> productWrapperList= getProducts(proposalId);
      List<ProductPriceWrapper> newProductWrapperList= new List<ProductPriceWrapper>();
      List<Product2> Updatedproducts= new List<Product2>();
      set<Id> productIds= new set<Id>();
      for(ProductPriceWrapper product :productWrapperList)
      {
      productIds.add(product.id);
      }
      Map<Id,PricebookEntry> pricebookMap= getproductToPricebookMap(proposalId); 

      try {
          if(geoValue!=null){
           Updatedproducts= [select Id,Name,ProductCode,Family,Format__c,toLabel(Target_GEO__c),Type__c,Media_Type__c,Delivery_Type__c,Device_Type_Options_Code__c,Main_KPI__c from Product2 where Id in :productIds and Target_GEO__c =:geoValue];
          }
          system.debug('geo products'+Updatedproducts);
          newProductWrapperList.addAll(createProductPriceWrapper(Updatedproducts,pricebookMap));
         return newProductWrapperList;
      } 

catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }

}
  
  public static Map<Id,PricebookEntry> getproductToPricebookMap(string proposalId){
    List<Opportunity> opportunity= [select Id,Pricebook2Id,CurrencyIsoCode from Opportunity where Id=:proposalId];
    String pricebookId= opportunity[0].Pricebook2Id; 
    string currencyISOCode=opportunity[0].CurrencyIsoCode;

    List<PricebookEntry> pricebookList=[select Id,Product2Id,Pricebook2Id,UnitPrice,CurrencyIsoCode from PricebookEntry where Pricebook2Id=:pricebookId and CurrencyISOCode=:currencyISOCode];

    Map<Id,PricebookEntry> productToPricebookMap = new Map<Id,PricebookEntry>();

    for(PriceBookEntry pricebook :pricebookList){
       productToPricebookMap.put(pricebook.Product2Id,pricebook);
    }

    return productToPricebookMap;
  }

  public static List<ProductPriceWrapper> createProductPriceWrapper(List<Product2> products,Map<Id,PricebookEntry> pricebookMap){
    List<ProductPriceWrapper> productsWrapper = new List<ProductPriceWrapper>();

    for(Product2 product: products){
        if(pricebookMap.containsKey(product.Id)){
       PriceBookEntry pricebook= (PriceBookEntry) pricebookMap.get(product.Id);
       ProductPriceWrapper wrapper= new ProductPriceWrapper();
       wrapper.id= product.Id;
       wrapper.name=product.Name;
       wrapper.family=product.Family;
       wrapper.deviceTypeOptions=product.ProductCode;
       wrapper.format=product.Format__c;
       wrapper.targetGeo= product.Target_GEO__c;
       wrapper.mediaType=product.Media_Type__c;
       wrapper.deliveryType=product.Delivery_Type__c;
       wrapper.mainKpi=product.Main_KPI__c;
       wrapper.pricebookId=pricebook.Pricebook2Id;
       wrapper.unitPrice=pricebook.UnitPrice;
       wrapper.deviceTypeCode=product.Device_Type_Options_Code__c;
       wrapper.currencyISOCode=pricebook.CurrencyIsoCode;
       productsWrapper.add(wrapper);
        }
     }
     system.debug('products'+productsWrapper);
     system.debug('products size'+productsWrapper.size());
     return productsWrapper;
  }

  public class ProductAttributes
  {
   @AuraEnabled
   public String id{get;set;}
   @AuraEnabled
   public Decimal Quantity{get;set;}
   @AuraEnabled
   public Decimal UnitPrice{get;set;}
   @AuraEnabled
   public Date startDate{get;set;}
   @AuraEnabled
   public Date endDate{get;set;}
   @AuraEnabled    
   public String salesMetric{get;set;}
   @AuraEnabled    
   public String targetAudience{get;set;}
   @AuraEnabled    
   public String targetGender{get;set;}
   @AuraEnabled    
   public String targetAge{get;set;}
   @AuraEnabled    
   public String deviceType{get;set;}
   @AuraEnabled    
   public String ksvPricePlan{get;set;}
   @AuraEnabled
   public String description{get;set;}
   @AuraEnabled
   public Integer frequencyCap{get;set;}
   @AuraEnabled
   public String design{get;set;}
   @AuraEnabled
   public String creative{get;set;}
   @AuraEnabled
   public String period{get;set;}
   @AuraEnabled
   public String kpi{get;set;}
   @AuraEnabled
   public String budget{get;set;}
   @AuraEnabled
   public Decimal commissionAmount{get;set;}
  // @AuraEnabled    
  // public String FrequencyCapPeriod{get;set;}
 }


 public class ProductWrapper{
    @AuraEnabled    
    public String id{get;set;}
    @AuraEnabled    
    public String name{get;set;}
    @AuraEnabled    
    public Decimal Quantity{get;set;}
    @AuraEnabled    
    public Decimal UnitPrice{get;set;}
    @AuraEnabled    
    public String salesMetric{get;set;}
    @AuraEnabled    
    public String targetAudience{get;set;}
    @AuraEnabled    
    public String targetGender{get;set;}
    @AuraEnabled    
    public String targetAge{get;set;}  
    @AuraEnabled    
    public Date startDate{get;set;}  
    @AuraEnabled    
    public Date endDate{get;set;}  
    @AuraEnabled    
    public String format{get;set;}  
    @AuraEnabled    
    public String mediaType{get;set;}  
    @AuraEnabled    
    public String deviceType{get;set;} 
    @AuraEnabled    
    public String deliveryType{get;set;}  
    @AuraEnabled    
    public String productId{get;set;}  
    @AuraEnabled    
    public String family{get;set;} 
    @AuraEnabled    
    public String ksvPricePlan{get;set;}  
    @AuraEnabled    
    public String pricebookId{get;set;} 
    @AuraEnabled    
    public String deviceTypeCode{get;set;}
    @AuraEnabled
    public String description{get;set;}
    @AuraEnabled
    public Integer frequencyCap{get;set;}
    @AuraEnabled
    public String design{get;set;}
    @AuraEnabled
    public String creative{get;set;}
    @AuraEnabled
    public String period{get;set;}
    @AuraEnabled
    public String kpi{get;set;} 
    @AuraEnabled
    public String currencyISOCode{get;set;}
    @AuraEnabled
    public String budget{get;set;}
    @AuraEnabled
   public Decimal commissionAmount{get;set;}
    

    //@AuraEnabled    
    //public String FrequencyCapPeriod{get;set;}  
}


public class ProductPriceWrapper{
    @AuraEnabled    
    public String id{get;set;}
    @AuraEnabled    
    public String name{get;set;}
    @AuraEnabled    
    public String format{get;set;}
    @AuraEnabled    
    public String targetGeo{get;set;}
    @AuraEnabled    
    public Decimal unitPrice{get;set;}
    @AuraEnabled    
    public String mediaType{get;set;}
    @AuraEnabled    
    public String deliveryType{get;set;}
    @AuraEnabled    
    public String family{get;set;}
    @AuraEnabled    
    public String deviceTypeOptions{get;set;}
    @AuraEnabled    
    public String pricebookId{get;set;}  
    @AuraEnabled
    public String deviceTypeCode{get;set;}
    @AuraEnabled
    public String currencyISOCode{get;set;}
    @AuraEnabled
   public Decimal commissionAmount{get;set;}
    @AuraEnabled
    public String mainKpi {get;set;}
}

public class Result{
    @AuraEnabled    
    public String id{get;set;}
    @AuraEnabled    
    public String message{get;set;}
    @AuraEnabled    
    public String status{get;set;}
}

}