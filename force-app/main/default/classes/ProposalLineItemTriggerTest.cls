/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2021-08-19
* @group CloudShiftGroup
* @description Test class for ProposalLineItemTrigger
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 19/08/2021        Buddy Winter        Created Class
*/
@IsTest
public without sharing class ProposalLineItemTriggerTest {

    /**
	* Method tested: beforeInsert()
	* Test Scenario: LineItem is inserted with a correct device type selected
	* Expected Result: LineItem is inserted
	*/
    @IsTest
    static void testBeforeInsertDeviceType(){
        SuperAwesomeOrgSetting__c globalSetting = new SuperAwesomeOrgSetting__c(Run_Apex_Triggers__c = true);
        insert globalSetting;
        
        Product2 product = new Product2(Name = 'Test Product', ProductCode = 'Any');
        insert product;
        PriceBookEntry pbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, Product2Id = product.Id, UnitPrice = 200);
        insert pbe;
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'New', CloseDate = System.TODAY() + 7);
        insert opp;
        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opp.Id, PriceBookEntryId = pbe.Id, Quantity = 1, TotalPrice = 200);
        Test.startTest();
        insert item;
        Test.stopTest();
        System.assertNotEquals(null, item.Id, 'Item is inserted');
    }

    /**
	* Method tested: beforeUpdate()
	* Test Scenario: LineItem is inserted with an incorrect device type selected
	* Expected Result: Update is blocked
	*/
    @IsTest
    static void testBeforeUpdateDeviceType(){
        SuperAwesomeOrgSetting__c globalSetting = new SuperAwesomeOrgSetting__c(Run_Apex_Triggers__c = true);
        insert globalSetting;
        
        Product2 product = new Product2(Name = 'Test Product', ProductCode = 'Desktop');
        insert product;
        PriceBookEntry pbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, Product2Id = product.Id, UnitPrice = 200);
        insert pbe;
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'New', CloseDate = System.TODAY() + 7);
        insert opp;
        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opp.Id, PriceBookEntryId = pbe.Id, Quantity = 1, TotalPrice = 200, Device_Type__c = 'Desktop');
        insert item;
        Test.startTest();
        item.Device_Type__c = 'Desktop;Tablet';
        Database.SaveResult sr = Database.update(item, false);
        Test.stopTest();
        System.assertEquals(1, sr.getErrors().size(), 'Item update is blocked');
    }

}