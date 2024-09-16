/**
* @author Buddy Winter <buddy.winter@cloudshiftgroup.com>
* @date 2021-08-18
* @group CloudShiftGroup
* @description Handles validating that Product Line Items have a correct Device Type selected.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 18/08/2021        Buddy Winter        Created Class
*/
public without sharing class DeviceTypeOptionValidation {

    /**
     * To handle upsertion (insert or update) of an Event record.
     *
     * @param  optionsValue  Value of Device Type Options
     * @param  selection     Value of Device Type
     * @return               Boolean if the Device Type selected conforms to the product's Device Type Options.
     */
    public static Boolean validate(String optionsValue, String selection){
        // If All options are available, any selection is allowed
        if(optionsValue == 'Any'){
            return true;
        }
        // Convert each individual option into a list of semi-colon separated values (in alphabetical order)
        optionsValue = optionsValue.trim();
        optionsValue = optionsValue.replaceAll(' Only', '');
        optionsValue = optionsValue.replaceAll (' & ', ';');
        List<String> optionsBeforeSort = optionsValue.split(',');
        List<String> optionsAfterSort = new List<String>();
        for(String option : optionsBeforeSort){
            optionsAfterSort.add(alphabetiseMultiSelect(option));
        }
        // Confirm if the selection is an option in the Device Type Options
        if(!optionsAfterSort.contains(alphabetiseMultiSelect(selection))){
            return false;
        }
        return true;
    }

    /**
     * Alphabetises an individual string representing a multi-select picklist
     *
     * @param  value  		String containing the multi-select picklist option
     * @return              String containing the multi-select picklist alphabetised
     */
    @TestVisible
    private static String alphabetiseMultiSelect(String value){
        if(value.split(';').size() > 1){
            List<String> options = value.split(';');
            options.sort();
            String returnString = String.join(options, ';');
            return returnString;
        } else {
            return value;
        }
    }
}