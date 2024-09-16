/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2021-08-19
* @group CloudShiftGroup
* @description Test class for DeviceTypeOptionValidation
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 19/08/2021        Buddy Winter        Created Class
*/
@IsTest
public without sharing class DeviceTypeOptionValidationTest {

    /**
	* Method tested: alphabetiseMultiSelect()
	* Test Scenario: An unsorted multi-select picklist is entered
	* Expected Result: A sorted multi-select picklist is returned
	*/
    @IsTest
    static void alphabetiseMultiSelectTest(){
        String multiSelect = 'Tablet;Phone;Desktop';
        Test.startTest();
        String result = DeviceTypeOptionValidation.alphabetiseMultiSelect(multiSelect);
        Test.stopTest();
        System.assertEquals('Desktop;Phone;Tablet', result, 'Multi Select picklist has been sorted');
    }

    /**
	* Method tested: alphabetiseMultiSelect()
	* Test Scenario: A single picklist value is provided.
	* Expected Result: The original value is returned
	*/
    @IsTest
    static void alphabetiseMultiSelectTestFail(){
        String multiSelect = 'Desktop';
        Test.startTest();
        String result = DeviceTypeOptionValidation.alphabetiseMultiSelect(multiSelect);
        Test.stopTest();
        System.assertEquals('Desktop', result, 'The original value is returned');
    }

    /**
	* Method tested: validate()
	* Test Scenario: A device type is selected that is part of the device type options
	* Expected Result: The selection passes the validation
	*/
    @IsTest
    static void validateTestPass(){
        String selection = 'Tablet;Phone';
        String options = 'Tablet & Phone, Phone Only, Tablet Only';
        Test.startTest();
        Boolean result = DeviceTypeOptionValidation.validate(options, selection);
        Test.stopTest();
        System.assertEquals(true, result, 'Selection passes validation');
    }

    /**
	* Method tested: validate()
	* Test Scenario: A device type is selected that is not part of the device type options
	* Expected Result: The selection fails the validation
	*/
    @IsTest
    static void validateTestFail(){
        String selection = 'Tablet;Phone;Desktop';
        String options = 'Tablet & Phone, Phone Only, Tablet Only';
        Test.startTest();
        Boolean result = DeviceTypeOptionValidation.validate(options, selection);
        Test.stopTest();
        System.assertEquals(false, result, 'Selection fails validation');
    }


}