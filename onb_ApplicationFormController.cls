/**
 * Created by joshuakrinsky on 2019-02-05.
 */

//fixme: running without sharing since user is not correctly associated to their account yet: jk 02/06/18
public without sharing class onb_ApplicationFormController extends onb_BaseLightningController {

    @AuraEnabled
    public static ResponseObject getApplicationFormInitialState(){

        String userId = UserInfo.getUserId();

        //todo: determine user's locale
        String locale = UserInfo.getLocale();

        //fixme: we need to lookup the account for the user right now since we aren't able to associate them to their own account because of a limitation with community licenses
        Account account = [Select Id from Account where Onboarding_Community_User__c=:userId];

        //todo: query db for account's currently open application
        //todo: extract to service
        onb_Onboarding_Application__c app = [SELECT
                Application_Product_Families__c,
                Application_Submitted__c,
                Applying_Contact__c,
                Business_Address_City__c,
                Business_Address_Country__c,
                Business_Address_Line_1__c,
                Business_Address_Line_2__c,
                Business_Address_Postal_Code__c,
                Business_Address_State__c,
                //Business_Reviews_Remaining__c,
                //Compliance_Recommendation_Notes__c,
                //Compliance_Recommendation__c,
                //Compliance_Reviewer__c,
                //Compliance_Review_Time_Complete__c,
                Country_of_Incorporation_Registration__c,
                //CreatedById,
                //CreatedDate,
                Date_of_Birth__c,
                Id,
                ID_Number__c,
                //IsDeleted,
                //LastActivityDate,
                //LastModifiedById,
                //LastModifiedDate,
                //LastReferencedDate,
                //LastViewedDate,
                Legal_Entity_Type__c,
                Legal_Name__c,
                Name,
                Onboarding_Account__c,
                Onboarding_Application_Review_Case__c,
                //Ops_Reviewer__c,
                //Ops_Review_Status_Notes__c,
                //Ops_Review_Status__c,
                //Ops_Review_Time_Complete__c,
                //Overall_Risk_Score__c,
                //Review_Decision_Notes__c,
                //Review_Decision_Reviewer__c,
                //Review_Decision_Time_Complete__c,
                //Review_Decision__c,
                //Risk_Rating__c,
                State_Province__c,
                //SystemModstamp,
                (Select Id, Name from Onboarding_Application_Products__r)
            FROM onb_Onboarding_Application__c
            WHERE Onboarding_Account__c = :account.Id
            AND Status__c = 'New'
            ORDER BY CreatedDate DESC NULLS LAST
            LIMIT 1];


        //todo: generate search key -- this will allow us to select only rules that are relevant to the current application as the ruleset starts to expand

        //todo: initialize rules engine operations
        SFDCRulesOperations opObj = SFDCRulesOperations.getInstance();
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('&&'));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('=='));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('!='));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('||'));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('('));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance(')'));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('<'));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('<='));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('>'));
        opObj.registerOperation(SFDCRulesOperationFactory.getInstance('>='));

        //todo: initialize bindings -- create a binding for each field that might be evaluated
        Map<String, String>bindings = new Map<String, String>();
        //application
        //products
        for(onb_Onboarding_Application_Product__c product : app.Onboarding_Application_Products__r){
            bindings.put('onb_Onboarding_Application_Product__r.Name'.toLowerCase(), product.Name.replaceAll('\\s+',''));//fixme: NOTE binding values cannot contain spaces!!!!! :O :O :O wtf???
        }


        //todo: load all rules
        //todo: extract into service
        List<onb_Onboarding_Rule__c> ruleDefs = [SELECT Developer_Id__c,Expression__c,Field_Metadata__c,Id,Name FROM onb_Onboarding_Rule__c];

        //todo: iterate through rules
        SFDCRulesRule rule;
        Map<String, Object>  fieldMetadata;
        Set<Object> fields = new Set<Object>();

        //todo: add field metadata for fired rules to response
        for(onb_Onboarding_Rule__c r : ruleDefs){

            rule = new SFDCRulesRule().setExpression(r.Expression__c);

            if(rule.eval(bindings)){

                //parse list
                fieldMetadata = (Map<String, Object>) JSON.deserializeUntyped(r.Field_Metadata__c);

                System.debug('fieldMetadata:');
                System.debug(fieldMetadata);
                System.debug('fields.size() = ' + fields.size());

                //merge field metadata into complete list
                fields.addAll((List<Object>)fieldMetadata.get('fields'));

            }else{
                System.debug('nope');
            }

        }



        Schema.SObjectType objectType = app.Id.getSobjectType();
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        //Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        //Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
        //List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        Map<String, Schema.SObjectField> oFields = objectDescribe.fields.getMap();

        List<Field> fieldList= new List<Field>();

        for (Object field : fields) {
            String fieldName = field.toString();
            Schema.SObjectField sObjectField = oFields.get(fieldName);
            Field f = new Field(fieldName, sObjectField);

            fieldList.add(f);
        }






        ResponseObject resp = new ResponseObject();
        resp.fields = fieldList;
        resp.record = app;




        //todo: return response
        //return JSON.serialize(fields);
        return resp;
    }

    @AuraEnabled
    //public static void upsertRecord(SObject recordToUpsert) {
    public static void upsertRecord(SObject j) {

        System.debug('upsertRecord');
        System.debug(j);

        update j;
    }

    public class ResponseObject{

        @AuraEnabled
        public List<Field> fields { get; set; }

        @AuraEnabled
        public SObject record { get; set; }

        public ResponseObject(){
            fields = new List<Field>();
        }
    }

    public class Field {

        public Field(String fieldName, Schema.SObjectField f){

            Schema.DescribeFieldResult fieldDescribe = f.getDescribe();

            this.DBRequired = false;
            this.APIName = fieldName;
            this.Label = fieldDescribe.label;
            this.Required = false;
            this.Type = String.valueOf(fieldDescribe.getType());
        }

        public Field(Boolean DBRequired) {
            this.DBRequired = DBRequired;
        }

        @AuraEnabled
        public Boolean DBRequired { get;set; }

        @AuraEnabled
        public String APIName { get;set; }

        @AuraEnabled
        public String Label { get;set; }

        @AuraEnabled
        public Boolean Required { get;set; }

        @AuraEnabled
        public String Type { get; set; }
    }
}