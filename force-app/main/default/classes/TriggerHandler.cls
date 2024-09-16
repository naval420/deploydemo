/**
 * @author Patrick Fischer <patrick@cloudshiftgroup.com> (extended)
 * @author github.com/kevinohara80 (original)
 * @date 2018-04-06
 * @group CloudShiftGroup
 * @group-content ../ApexDocContent/Classes.html
 * @description Virtual class to be extended from object specific trigger handlers.
 */
public virtual class TriggerHandler {

    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }

    // constructor
    public TriggerHandler() {
        this.setTriggerContext();
    }

    /***************************************
     * public instance methods
     ***************************************/

    /**
     * Main method that will be called during execution
     */
    public void run() {

        if(!validateRun()) {
            return;
        }

        addToLoopCount();

        // dispatch to the correct handler method
        if(this.context == TriggerContext.BEFORE_INSERT) {
            this.bulkBefore();
            this.beforeInsert();
        } else if(this.context == TriggerContext.BEFORE_UPDATE) {
            this.bulkBefore();
            this.beforeUpdate();
        } else if(this.context == TriggerContext.BEFORE_DELETE) {
            this.bulkBefore();
            this.beforeDelete();
        } else if(this.context == TriggerContext.AFTER_INSERT) {
            this.bulkAfter();
            this.afterInsert();
        } else if(this.context == TriggerContext.AFTER_UPDATE) {
            this.bulkAfter();
            this.afterUpdate();
        } else if(this.context == TriggerContext.AFTER_DELETE) {
            this.bulkAfter();
            this.afterDelete();
        } else if(this.context == TriggerContext.AFTER_UNDELETE) {
            this.bulkAfter();
            this.afterUndelete();
        }

        this.andFinally();
    }

    /**
     * To ensure that a trigger runs once and only once within a single execution
     *
     * @param max Integer specifying the maximum execution amount
     */
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if(!TriggerHandler.loopCountMap.containsKey(handlerName)) {
            TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    /**
     * Reset the max loop count
     */
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    /***************************************
     * public static methods
     ***************************************/

    /**
     * To bypass a specific Trigger Handler from being executed
     *
     * @param handlerName String of the invoked Trigger Handler
     */
    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    /**
     * To clear a specific Trigger Handlers from being bypassed and execute it after all
     *
     * @param handlerName String of the invoked Trigger Handler
     */
    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    /**
     * To verify if a specific Trigger Handler is being bypassed
     *
     * @param handlerName String of the invoked Trigger Handler
     *
     * @return true if Trigger Handler is being bypassed, else false
     */
    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    /**
     * To clear all existing Trigger Handlers from being bypassed and execute them again
     */
    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

    /**
     * To retrieve the current count of a specific Trigger Handler
     *
     * @param handlerName of the invoked Trigger Handler
     *
     * @return Integer counting the trigger executions
     */
    public static Integer getCurrentTriggerCount(String handlerName) {
        if(TriggerHandler.loopCountMap.containsKey(handlerName)) {
            return TriggerHandler.loopCountMap.get(handlerName).getCount();
        } else {
            return 0;
        }
    }

    /***************************************
     * private instance methods
     ***************************************/

    /**
     * To set the current Trigger Context. Overloaded method for default execution.
     */
    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    /**
     * To set the current Trigger Context
     *
     * @param ctx inject the current Trigger Context as a String
     * @param testMode Boolean flag is true if invoked from Test Class, else false
     */
    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if(!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
                (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
                (ctx != null && ctx == 'before update')){
            this.context = TriggerContext.BEFORE_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
                (ctx != null && ctx == 'before delete')) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
                (ctx != null && ctx == 'after insert')) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
                (ctx != null && ctx == 'after update')) {
            this.context = TriggerContext.AFTER_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
                (ctx != null && ctx == 'after delete')) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
                (ctx != null && ctx == 'after undelete')) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    /**
     * To increment the loop count of a specifc handler
     */
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if(TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
            if(exceeded) {
                Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }

    /**
     * make sure this trigger should continue to run
     *
     * @return true if handler is valid to execute, else false
     */
    @TestVisible
    private Boolean validateRun() {
        if(!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        if(TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            return false;
        }
        if(!SuperAwesomeOrgSetting__c.getInstance().Run_Apex_Triggers__c){
            return false;
        }
        return true;
    }

    /**
     * To retrieve the name of the currently executed Trigger Handler
     *
     * @return String of current Trigger Handler being executed
     */
    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }

    /***************************************
     * context-specific methods for override
     ***************************************/

    @TestVisible
    protected virtual void beforeInsert(){}
    @TestVisible
    protected virtual void beforeUpdate(){}
    @TestVisible
    protected virtual void beforeDelete(){}
    @TestVisible
    protected virtual void afterInsert(){}
    @TestVisible
    protected virtual void afterUpdate(){}
    @TestVisible
    protected virtual void afterDelete(){}
    @TestVisible
    protected virtual void afterUndelete(){}

    /**
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    @TestVisible
    protected virtual void bulkBefore(){}

    /**
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    @TestVisible
    protected virtual void bulkAfter(){}

    /**
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    @TestVisible
    protected virtual void andFinally(){}

    /***************************************
     * inner classes
     ***************************************/

    /**
     * Inner class for managing the loop count per handler
     */
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            if(this.max < 0) {
                return false;
            }
            if(this.count > this.max) {
                return true;
            }
            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    /**
     * Possible trigger contexts
     */
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
        AFTER_UNDELETE
    }

    /**
     * Exception class
     */
    public class TriggerHandlerException extends Exception {}

}