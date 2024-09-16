trigger SalesOrderLineItemTrigger on QuoteLineItem (before insert,before update,after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            if(SalesOrderLineItemTriggerHandler.isFirstTime){
            SalesOrderLineItemTriggerHandler.handleBeforeInsertUpdate(Trigger.new);
            }
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isDelete){
         if(SalesOrderLineItemTriggerHandler.isDeleteFirstTime){
            SalesOrderLineItemTriggerHandler.handleAfterDelete(Trigger.old); 
          }
        }
    }

}