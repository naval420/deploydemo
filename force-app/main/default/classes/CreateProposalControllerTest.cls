/**********************************************************************
 * Name:CreateProposalControllerTest
 * Description: Test Class for the CreateProposalController.
 * Create Date:
 * Created By:Sudhir Baljeplli
 * ******************************************************************/
 @isTest
 Public class CreateProposalControllerTest{
 @isTest
 public Static void testProposalCreation(){
 Test.StartTest();
 // Create proposal
  Opportunity Opp=New Opportunity();
  Opp.Name='Proposal Test';
  Opp.StageName='Proactive';
  Opp.CloseDate=Date.Today().addDays(1);
  Opp.SA_Subsidiary__c='SuperAwesome Trading Ltd';
  // Create Account
  Account acc=New Account();
  acc.Name='Test Account';
  acc.Type='Agency';
  acc.SA_Subsidiary__c='SuperAwesome Trading Ltd';
  insert acc;
  
  //Create the Contact
  Contact con=new Contact();
  con.LastName='Test Last Name';
  insert con;
   Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorgtest.com',SA_Subsidiary__c='SuperAwesome Trading Ltd');

        System.runAs(u) {
         CreateProposalController.doCreateProposal(Opp,u.id);
        }   
  CreateProposalController.getAccountDetails(acc.Id);
  CreateProposalController.getContacts(con.Id);
  System.AssertEquals('Agency',acc.Type,'Accout Type');   
  Test.StopTest();
 }
   @isTest
 public Static void testTheExceptions(){
 Test.StartTest();
 
  CreateProposalController.doCreateProposal(null,null);
  CreateProposalController.getAccountDetails(null);
  CreateProposalController.getContacts(null);
  Test.StopTest();
 }   
 
 }