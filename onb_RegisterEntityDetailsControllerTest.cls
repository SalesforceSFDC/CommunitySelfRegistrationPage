
@isTest
//test class verifies that the method works as expected by calling it with different 
//inputs. 
private class onb_RegisterEntityDetailsControllerTest {
    @isTest static void testRegistration() {
        Id register = onb_RegisterEntityDetailsController.completeRegistration(10);
        System.assertEquals();
    }

    @isTest static void testCurrentUserId() {
        onb_RegisterEntityDetailsController reg = new onb_RegisterEntityDetailsController();
        //Id newUserId = reg.
        System.assertEquals(1234, 1234);
    }

    @isTest static void testCompleteRegistration() {
        // Create an user 
        onb_RegisterEntityDetailsController reg = new onb_RegisterEntityDetailsController();
        insert reg;
        reg.userId = '';
        reg.account = 'TestAccount';
        reg.app = 'NewTestApp';
        // registerUser always returns null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);
    }

    @isTest static void testSelectedOptions() {
        onb_RegisterEntityDetailsController reg = new onb_RegisterEntityDetailsController();
        List<String> selected = reg.getSelectOptions(sObject objObject, string fld);
        System.assertEquals();
    }

    @isTest static void testProductSelection() {

    }

    @isTest
    static void TestFakeException() {
        DiagnosticsMain.FakeException = true;
        List<Opportunity> ops =     
            CreateOpportunities('optest', 
            NumberOfStageUpdateOpportunities);
        
        for(Opportunity op : ops) {
            op.CloseDate = Date.Today().addDays(5);
            op.StageName = 'Prospecting';
        }

        List<DebugInfo__c> dbg = [Select ID FROM DebugInfo__c];
        System.Assert(dbg.size()>0);

        Test.StartTest();
        insert ops;
        Test.StopTest();
    }

    @IsTest
    static void testIsValidPassword() {
        System.assert(onb_LightningSelfRegisterController.isValidPassword('password?@12334', 'password?@12334') == true);
        System.assert(onb_LightningSelfRegisterController.isValidPassword('password?@12334', 'dummyPassword') == false);
        System.assert(onb_LightningSelfRegisterController.isValidPassword('password?@12334', null) == false);
        System.assert(onb_LightningSelfRegisterController.isValidPassword(null, 'fakePwd') == false);
}
}




@isTest static void testCurrentUserId() {
    onb_RegisterEntityDetailsController reg = new onb_RegisterEntityDetailsController();
    //Id newUserId = reg.
    System.assertEquals(1234, 1234);
}

@isTest static void testCompleteRegistration() {
    onb_RegisterEntityDetailsController reg = new onb_RegisterEntityDetailsController();
    reg.userId = '';
    reg.account = 'TestAccount';
    reg.app = 'NewTestApp';
    // registerUser always returns null when the page isn't accessed as a guest user
    System.assert(controller.registerUser() == null);
}

@isTest
private class SiteRegisterControllerTest {
    // Test method for verifying the positive test case
    static testMethod void testRegistration() {
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        // registerUser always returns null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);
    }
}



// Create a new account as the generic type sObject
sObject s = new Account();

// Verify that the generic sObject is an Account sObject
System.assert(s.getsObjectType() == Account.sObjectType);

// Get the sObject describe result for the Account object
Schema.DescribeSObjectResult dsr = Account.sObjectType.getDescribe();

// Get the field describe result for the Name field on the Account object
Schema.DescribeFieldResult dfr = Schema.sObjectType.Account.fields.Name;

// Verify that the field token is the token for the Name field on an Account object
System.assert(dfr.getSObjectField() == Account.Name);

// Get the field describe result from the token
dfr = dfr.getSObjectField().getDescribe();


     
  // global community owner user
  // roles for community license users?
  // sharing sets for community users
  // record detail lightning component - 
  // 