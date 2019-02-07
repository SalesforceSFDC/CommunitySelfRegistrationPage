global without sharing class onb_LightningSelfRegisterController extends onb_BaseLightningController {

    public onb_LightningSelfRegisterController() {

    }

    /**
     *
     *
     * @param password
     * @param confirmPassword
     *
     * @return
     */
    @TestVisible
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }

    /**
     *
     *
     * @param communityUrl
     *
     * @return
     */
    @TestVisible
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }

    /**
     *
     *
     * @param u
     * @param password
     * @param confirmPassword
     */
    @TestVisible
    private static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
            Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }



    /**
     *
     *
     * @param firstname
     * @param lastname
     * @param email
     * @param password
     * @param businessEntityType
     * @param confirmPassword
     * @param accountId
     * @param regConfirmUrl
     * @param extraFields
     * @param startUrl
     * @param includePassword
     *
     * @return
     */
    @AuraEnabled
    public static String selfRegister(String firstname ,String lastname, String email, String password, String businessEntityType, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {

        return selfRegisterNew(firstname,lastname,email,password,businessEntityType,confirmPassword,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
    }

    private static String selfRegisterExperimental(String firstname ,String lastname, String email, String password, String businessEntityType, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {
        System.debug('currentUserId = ' + UserInfo.getUserId());


        Savepoint sp = null;

        try {
            sp = Database.setSavepoint();

            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }

            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }


            String fullName = firstname + ' ' + lastname;
            String accountName = (fullName + ' Account');
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Institutional_Top_Account').getRecordTypeId();

            User u = new User();

            u.Username = email;
            u.Email = email;
            u.FirstName = firstname;
            u.LastName = lastname;

            String networkId = Network.getNetworkId();

            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }

            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);

            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    u.put(sof, thisField.get('value'));
                }
            }

            if (includePassword) {
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
                validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }

            password = generateRandomString(12);

            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            String userId = Site.createPortalUser(u, accountId, password);

            u = [select Id, ContactId from user where Id = :userId];

            //create new account
            Account account = new Account(
                    Name = accountName,
                    RecordTypeId = recordTypeId,
                    Applying_Contact__c = u.ContactId,
                    Email_Address__c = email,
                    Onboarding_Community_User__c = u.Id
            );

            Database.insert(account);

            //note: if we change the account id within the same transaction that we create the portal user, it will cause an error.
            //but that's ok, we  can set the contact and user account id later
            //accountId = account.Id;

            //create new application
            onb_Onboarding_Application__c app = new onb_Onboarding_Application__c(
                    Legal_Entity_Type__c = businessEntityType,
                    Name =  (fullName + ' Application'),
                    Onboarding_Account__c = account.Id
                    //Applying_Contact__c = u.ContactId
            );

            Database.insert(app);

            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';
            }
            if (userId != null) {
                if (includePassword && password != null && password.length() > 1) {
                    PageReference lgn = Site.login(email, password, startUrl);
                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }
                } else {

                    /*
                    PageReference confirmRef = new PageReference(regConfirmUrl);
                    if(!Test.isRunningTest()) {
                        aura.redirect(confirmRef);
                    }
                    */

                    System.debug('regConfirmUrl = ' + regConfirmUrl);

                    PageReference lgn = Site.login(email, password, '/s/RegisterEntityDetails?app=' + app.Id);

                    //PageReference confirmRef = new PageReference(regConfirmUrl);

                    System.debug('currentUserId = ' + UserInfo.getUserId());

                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }

                }
            }
            return null;
        }
        catch (Exception ex) {

            Database.rollback(sp);
            return ex.getMessage();
        }
    }

    /**
     *
     *
     * @param firstname
     * @param lastname
     * @param email
     * @param password
     * @param businessEntityType
     * @param confirmPassword
     * @param accountId
     * @param regConfirmUrl
     * @param extraFields
     * @param startUrl
     * @param includePassword
     *
     * @return
     */
    private static String selfRegisterWorking(String firstname ,String lastname, String email, String password, String businessEntityType, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {

        System.debug('currentUserId = ' + UserInfo.getUserId());

        Savepoint sp = null;

        try {
            sp = Database.setSavepoint();

            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }

            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }


            String fullName = firstname + ' ' + lastname;
            String accountName = (fullName + ' Account');
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Institutional_Top_Account').getRecordTypeId();

            User u = new User();

            u.Username = email;
            u.Email = email;
            u.FirstName = firstname;
            u.LastName = lastname;

            String networkId = Network.getNetworkId();

            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }

            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);

            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    u.put(sof, thisField.get('value'));
                }
            }

            if (includePassword) {
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
                validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }

            password = generateRandomString(12);

            System.debug('password = ' + password);

            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            String userId = Site.createPortalUser(u, accountId, password);

            u = [select Id, ContactId from user where Id = :userId];

            //create new account
            Account account = new Account(
                    Name = accountName,
                    RecordTypeId = recordTypeId,
                    Applying_Contact__c = u.ContactId,
                    Email_Address__c = email,
                    Onboarding_Community_User__c = u.Id
            );

            Database.insert(account);

            //note: if we change the account id within the same transaction that we create the portal user, it will cause an error.
            //but that's ok, we  can set the contact and user account id later
            //accountId = account.Id;

            //create new application
            onb_Onboarding_Application__c app = new onb_Onboarding_Application__c(
                    Legal_Entity_Type__c = businessEntityType,
                    Name =  (fullName + ' Application'),
                    Onboarding_Account__c = account.Id
                    //Applying_Contact__c = u.ContactId//fixme: it complains about this because the contact must belong to the same account that the application belongs to
            );

            Database.insert(app);

            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';
            }

            if (userId != null) {
                if (includePassword && password != null && password.length() > 1) {

                    PageReference lgn = Site.login(email, password, startUrl);

                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }

                } else {

                    PageReference lgn = Site.login(email, password, '/s/RegisterEntityDetails');

                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }

                }
            }
            return null;
        }
        catch (Exception ex) {

            Database.rollback(sp);
            return ex.getMessage();
        }
    }









    private static String selfRegisterNew(String firstname ,String lastname, String email, String password, String businessEntityType, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {

        System.debug('currentUserId = ' + UserInfo.getUserId());

        Savepoint sp = null;

        try {

            Map<String, String> response = new Map<String, String>();

            sp = Database.setSavepoint();

            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }

            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }


            String fullName = firstname + ' ' + lastname;
            String accountName = (fullName + ' Account');
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Institutional_Top_Account').getRecordTypeId();


            //create the account
            Account account = new Account(
                    Name = accountName,
                    RecordTypeId = recordTypeId,
                    //Applying_Contact__c = u.ContactId,
                    Email_Address__c = email
                    //Onboarding_Community_User__c = u.Id
            );

            Database.insert(account);

            response.put('accountId', account.Id);


            //create the contact
            Contact contact = new Contact(
                    FirstName = firstname,
                    LastName = lastname,
                    Email = email,
                    AccountId = account.Id
            );

            Database.insert(contact);

            response.put('contactId', account.Id);


            //create the user
/*
            UserRole role = [select Id from UserRole where DeveloperName = :'Onboarding_Prospect'];

            User u = new User(
                    UserRoleId = role.Id,
                    UserName = email,
                    Email = email,
                    FirstName = firstname,
                    LastName = lastname,
                    ContactId = contact.Id,
                    //CommunityNickname = generateRandomString(8),
                    //Alias = generateRandomString(10),
                    TimeZoneSidKey = 'America/Phoenix', // Required
                    LocaleSidKey = 'en_US', // Required
                    EmailEncodingKey = 'ISO-8859-1', // Required
                    LanguageLocaleKey = 'en_US' // Required
            );

            u.Username = email;
            u.Email = email;
            u.FirstName = firstname;
            u.LastName = lastname;

            String networkId = Network.getNetworkId();


            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }

            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);

            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    u.put(sof, thisField.get('value'));
                }
            }

            if (includePassword) {
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
                validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }

            password = generateRandomString(12);

            System.debug('password = ' + password);

            Database.insert(u);

            System.setPassword(u.id, password);


            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            //String userId = Site.createPortalUser(u, accountId, password);
            String userId = u.Id;
*/
            //u = [select Id, ContactId from user where Id = :userId];

            //create the application





            //note: if we change the account id within the same transaction that we create the portal user, it will cause an error.
            //but that's ok, we  can set the contact and user account id later
            //accountId = account.Id;

            /*
            //create new application
            onb_Onboarding_Application__c app = new onb_Onboarding_Application__c(
                    Legal_Entity_Type__c = businessEntityType,
                    Name =  (fullName + ' Application'),
                    Onboarding_Account__c = account.Id
                    //Applying_Contact__c = u.ContactId//fixme: it complains about this because the contact must belong to the same account that the application belongs to
            );

            Database.insert(app);
            */


            /*
            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';
            }

            if (userId != null) {
                if (includePassword && password != null && password.length() > 1) {

                    PageReference lgn = Site.login(email, password, startUrl);

                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }

                } else {

                    PageReference lgn = Site.login(email, password, '/s/RegisterEntityDetails');

                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }

                }
            }
            */

            return JSON.serialize(response);


            //return null;



        }
        catch (Exception ex) {

            Database.rollback(sp);
            return ex.getMessage();
        }
    }


    @AuraEnabled
    public static String selfRegisterNewCtd(String firstname ,String lastname, String email, String password, String businessEntityType, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {

        System.debug('currentUserId = ' + UserInfo.getUserId());

        Savepoint sp = null;

        try {


            sp = Database.setSavepoint();

            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }

            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }

            /*
            String fullName = firstname + ' ' + lastname;
            String accountName = (fullName + ' Account');
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Institutional_Top_Account').getRecordTypeId();


            //create the account
            Account account = new Account(
                    Name = accountName,
                    RecordTypeId = recordTypeId,
                    //Applying_Contact__c = u.ContactId,
                    Email_Address__c = email
                    //Onboarding_Community_User__c = u.Id
            );

            Database.insert(account);

            //create the contact
            Contact contact = new Contact(
                    FirstName = firstname,
                    LastName = lastname,
                    Email = email,
                    AccountId = accountId
            );

            Database.insert(contact);
*/
            //create the user

            UserRole role = [select Id from UserRole where DeveloperName = :'Onboarding_Prospect'];

            User u = new User(
                    //UserRoleId = role.Id,
                    UserName = email,
                    Email = email,
                    FirstName = firstname,
                    LastName = lastname
                    //ContactId = contact.Id,
                    //CommunityNickname = generateRandomString(8),
                    //Alias = generateRandomString(10),
                    //TimeZoneSidKey = 'America/Phoenix', // Required
                    //LocaleSidKey = 'en_US', // Required
                    //EmailEncodingKey = 'ISO-8859-1', // Required
                    //LanguageLocaleKey = 'en_US' // Required
            );

            u.Username = email;
            u.Email = email;
            u.FirstName = firstname;
            u.LastName = lastname;

            String networkId = Network.getNetworkId();


            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }

            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);

            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    u.put(sof, thisField.get('value'));
                }
            }

            if (includePassword) {
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
                validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }

            password = generateRandomString(12);

            System.debug('password = ' + password);

            //Database.insert(u);

            //System.setPassword(u.id, password);

            System.debug(1);

            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            String userId = Site.createPortalUser(u, accountId, password);
            //String userId = u.Id;

            System.debug(2);

            u = [select Id, ContactId from user where Id = :userId];

            System.debug(3);

            //create the application


            //note: if we change the account id within the same transaction that we create the portal user, it will cause an error.
            //but that's ok, we  can set the contact and user account id later
            //accountId = account.Id;


            //create new application

            System.debug(4);

            String fullName = firstname + ' ' + lastname;

            System.debug(5);


            onb_Onboarding_Application__c app = new onb_Onboarding_Application__c(
                    Legal_Entity_Type__c = businessEntityType,
                    Name =  (fullName + ' Application'),
                    Onboarding_Account__c = accountId,
                    Applying_Contact__c = u.ContactId//fixme: it complains about this because the contact must belong to the same account that the application belongs to
            );

            System.debug(6);

            Database.insert(app);

            System.debug(7);

            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';
            }

            System.debug(8);

            if (userId != null) {

                System.debug(9);

                if (includePassword && password != null && password.length() > 1) {

                    System.debug(10);

                    PageReference lgn = Site.login(email, password, startUrl);

                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }

                } else {

                    System.debug(11);

                    PageReference lgn = Site.login(email, password, '/s/RegisterEntityDetails');

                    if(!Test.isRunningTest()) {

                        System.debug(12);

                        aura.redirect(lgn);
                    }

                }
            }

            return null;



        }
        catch (Exception ex) {

            Database.rollback(sp);
            throw ex;
            //return ex.getMessage();
        }
    }



    /**
     *
     *
     * @param extraFieldsFieldSet
     *
     * @return
     */
    @AuraEnabled
    public static List<Map<String,Object>> getExtraFields(String extraFieldsFieldSet) {
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.User.fieldSets.getMap().get(extraFieldsFieldSet);
        if(!Test.isRunningTest()) {
            if (fieldSet != null) {
                for (Schema.FieldSetMember f : fieldSet.getFields()) {
                    Map<String, Object> fieldDetail = new Map<String, Object>();
                    fieldDetail.put('dbRequired', f.getDBRequired());
                    fieldDetail.put('fieldPath', f.getFieldPath());
                    fieldDetail.put('label', f.getLabel());
                    fieldDetail.put('required', f.getRequired());
                    fieldDetail.put('type', f.getType());
                    fieldDetail.put('value', '');   // client will populate
                    extraFields.add(fieldDetail);
                }}}
        return extraFields;
    }

    /**
     *
     *
     * @param expId
     *
     * @return
     */
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null;
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }

    /**
     *
     *
     * @param objObject
     * @param fld
     *
     * @return
     */
    @AuraEnabled
    public static List < String > getSelectOptions(sObject objObject, string fld) {
        return onb_BaseLightningController.getSelectOptions(objObject, fld);
    }
}