/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class HomeChildKanban {

    @AuraEnabled
    public static string saveConfig(KanbanConfiguration__c obj){
        try{
            if(obj.KanbanFor__c == 'Child'){
                obj.NameField__c = HomeChildKanbanUtil.getNameField(obj.ChildObject__c);
            } else if(obj.KanbanFor__c == 'Home'){
                obj.NameField__c = HomeChildKanbanUtil.getNameField(obj.ForObject__c);
            }
            upsert obj;
            return 'true';
        }catch(exception e){
            return e.getMessage();
        }
    }

    @AuraEnabled
    public static Map<string, List<HomeChildKanbanObjUtil>> getObjs(){
        Map<string, List<HomeChildKanbanObjUtil>> objmap = new Map<string, List<HomeChildKanbanObjUtil>>();

        List<Schema.SObjectType> objs = Schema.getGlobalDescribe().values();

        List<HomeChildKanbanObjUtil> sList = new List<HomeChildKanbanObjUtil>();
        List<HomeChildKanbanObjUtil> cList = new List<HomeChildKanbanObjUtil>();

        for(Schema.SObjectType s : objs){
            Schema.DescribeSObjectResult ds = s.getDescribe();
            if(ds.isAccessible() && ds.isQueryable()){
                HomeChildKanbanObjUtil hcu = new HomeChildKanbanObjUtil(ds.getName(), ds.getLabel());
                if(ds.isCustom()){
                    cList.add(hcu);
                } else {
                    sList.add(hcu);
                }
            }
        }
        objmap.put('standard', sList);
        objmap.put('custom', cList);

        return objmap;
    }

    @AuraEnabled
    public static Map<string, List<HomeChildKanbanCObjUtil>> getObjChilds(string objName){
        Map<string, List<HomeChildKanbanCObjUtil>> objmap = new Map<string, List<HomeChildKanbanCObjUtil>>();
        List<HomeChildKanbanCObjUtil> sList = new List<HomeChildKanbanCObjUtil>();
        List<HomeChildKanbanCObjUtil> cList = new List<HomeChildKanbanCObjUtil>();
        List<Schema.ChildRelationship> cObjs = Schema.getGlobalDescribe().get(objName).getDescribe().getChildRelationships();
        for(Schema.ChildRelationship s : cObjs){
            Schema.DescribeSObjectResult sObj = s.getChildSObject().getDescribe();
            Schema.DescribeFieldResult sFld = s.getField().getDescribe();
            if(sObj.isDeprecatedAndHidden() != true && sObj.isAccessible() && sObj.isCreateable() && sObj.isUpdateable() && sObj.isQueryable() && sFld.isFilterable() && sFld.isAccessible()){
                HomeChildKanbanCObjUtil hcu = new HomeChildKanbanCObjUtil(sObj.getName()+'~;'+sFld.getName(), sObj.getLabel()+' ('+sFld.getName()+')', sFld.getName());
                if(sObj.isCustom()){
                    cList.add(hcu);
                } else {
                    sList.add(hcu);
                }
            }
        }
        objmap.put('standard', sList);
        objmap.put('custom', cList);
        return objmap;
    }

    @AuraEnabled
    public static Map<string, List<HomeChildKanbanObjUtil>> getObjFlds(string objName){
        Map<string, List<HomeChildKanbanObjUtil>> objFldmap = new Map<string, List<HomeChildKanbanObjUtil>>();
        Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();

        List<HomeChildKanbanObjUtil> aList = new List<HomeChildKanbanObjUtil>();
        List<HomeChildKanbanObjUtil> gList = new List<HomeChildKanbanObjUtil>();
        List<HomeChildKanbanObjUtil> sList = new List<HomeChildKanbanObjUtil>();

        for(Schema.SObjectField sField : fieldMap.Values())
        {
            schema.describefieldresult dfield = sField.getDescribe();
            if(dfield.isAccessible() && dfield.isDeprecatedAndHidden() != true){
                string fldType = string.valueOf(dfield.getType());
                HomeChildKanbanObjUtil hcu = new HomeChildKanbanObjUtil(dfield.getName(), dfield.getLabel());
                aList.add(hcu);
                if(dfield.isGroupable() && dfield.isUpdateable() && fldType == 'PICKLIST'){
                    gList.add(hcu);
                }
                if(fldType == 'Double' || fldType == 'Integer' || fldType == 'Currency'){
                    sList.add(hcu);
                }
            }
        }
        objFldmap.put('all', aList);
        objFldmap.put('groupBy', gList);
        objFldmap.put('sumBy', sList);
        return objFldmap;
    }

    @AuraEnabled
    public static List<HomeChildKanbanObjUtil> getPickVals(String FldName, String objName){
        List<HomeChildKanbanObjUtil> plist = new List<HomeChildKanbanObjUtil>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(FldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            plist.add(new HomeChildKanbanObjUtil(f.getLabel(), f.getValue()));
        }
        return plist;
    }

    @AuraEnabled
    public static HomeChildKanbanUtil getKanban(String objName, List<String> objFields, String kanbanField, String ParentRecId, String relField, List<string> excludeValue, String summarizeField, String KbObjNameField){

        if(summarizeField != null){
            objFields.add(summarizeField);
        }
        if(KbObjNameField != null && KbObjNameField != 'false'){
            if(Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(KbObjNameField) != null){
                objFields.add(KbObjNameField);
            }
        }
        objFields.add(kanbanField);
        Set<string> obFields = new Set<string>(objFields);
        obFields.remove('Id');
        /* Checks if all the requested fields are accessible */
        if(HomeChildKanbanUtil.checkAccessibleFLS(obFields, objName)){
            Set<string> kFieldCheck = new Set<string>();
            kFieldCheck.add(kanbanField);
            /* Checks if the Group By Field is Updatable */
            if(HomeChildKanbanUtil.checkAccessibleFLS(kFieldCheck, objName)){
                boolean ispdatable = HomeChildKanbanUtil.checkUpdateableFLS(kFieldCheck, objName);
                try{
                    Schema.DescribeSObjectResult actdsc = Schema.getGlobalDescribe().get(objName).getDescribe();
                    Map<String, Schema.SObjectField> allFieldMap = actdsc.fields.getMap();
                    string agrFieldName = null;
                    string sFldIsCurrency = null;
                    Map<string, decimal> aggQMap;
                    List<AggregateResult> sumQuery;
                    if(summarizeField != null){
                        Schema.DescribeFieldResult ads = allFieldMap.get(summarizeField).getDescribe();
                        string aftype = string.valueOf(ads.getType());
                        if(aftype == 'Double' || aftype == 'Integer' || aftype == 'Currency'){
                            agrFieldName = ads.getLabel();
                            sFldIsCurrency = aftype;
                            aggQMap = new Map<string, decimal>();
                        } else {
                            return new HomeChildKanbanUtil(null, null, false, 'The field '+summarizeField+' cannot be summarized.', null, null, null, null, null, null, null, null, null);
                        }
                    }

                    List<string> Pickvalslst = new List<String>();
                    Set<string> excludeValues = new Set<string>(excludeValue);
                    Map<string, list<sobject>> recMaps = new Map<string, list<sobject>>();

                    for(Schema.PicklistEntry s: allFieldMap.get(kanbanField).getDescribe().getpicklistValues()){
                        if(!excludeValues.contains(s.getValue()) && s.isActive()){
                            Pickvalslst.add(s.getValue());
                            recMaps.put(s.getValue(), new List<sobject>());
                            if(summarizeField != null){
                                aggQMap.put(s.getValue(), 0);
                            }
                        }
                    }

                    string cObName = actdsc.getLabel();
                    Schema.DescribeFieldResult utilResult = allFieldMap.get(kanbanField).getDescribe();
                    string gFldName = utilResult.getLabel();
                    boolean gFldEditable = utilResult.isUpdateable();
                    boolean isObjDeletable = actdsc.isDeletable();
                    boolean isObjectCreateable = actdsc.isCreateable();

                    //For Getting a Map of field name and its type
                    Map<String, Map<String, String>> fieldTypeMap = new Map<String, Map<String, String>>();

                    String qry = 'Select Id, ';
                    for(String s: obFields){
                        Schema.DescribeFieldResult currentFieldResult = allFieldMap.get(s).getDescribe();
                        string currentFieldType = string.valueOf(currentFieldResult.getType());
                        Map<String, String> currentMap = new Map<String, String>();
                        currentMap.put('type', currentFieldType);
                        if(currentFieldType == 'REFERENCE'){
                            string currentRelationName = currentFieldResult.getRelationshipName();
                            string refObjName;
                            if(currentFieldResult.isNamePointing()){
                                for(Schema.SObjectType reference : currentFieldResult.getReferenceTo()) {
                                    Schema.DescribeSObjectResult dsr = reference.getDescribe();
                                    if(dsr.isAccessible()){
                                        refObjName = dsr.getName();
                                        break;
                                    }
                                }
                                if(refObjName == null){
                                    return new HomeChildKanbanUtil(null, null, false, 'You do not have access to relational object. Please contact your administrator.', null, null, null, null, null, null, null, null, null);
                                }
                            } else {
                                refObjName = currentFieldResult.getReferenceTo()[0].getDescribe().getName();
                            }
                            string fName = HomeChildKanbanUtil.getNameField(refObjName);
                            if(fName != 'false'){
                             	qry += currentRelationName+'.'+fName+' ,';
                            } else {
                                return new HomeChildKanbanUtil(null, null, false, 'You do not have access to relation object '+refObjName+'. Please contact your administrator.', null, null, null, null, null, null, null, null, null);
                            }
                            currentMap.put('relationName', currentRelationName+'~*!'+fName);
                        }
                        qry += s+' ,';
                        fieldTypeMap.put(s, currentMap);
                    }
                    qry = qry.removeEnd(',');

                    qry += ' From '+objName+' where '+kanbanField+' in :Pickvalslst';

                    if(ParentRecId != '' && ParentRecId != null && relField != '' && relField != null){
                        qry += ' and '+relField+'=\''+ParentRecId+'\'';
                    }

                    for(sobject s: database.query(qry)){
                        recMaps.get(string.valueOf(s.get(kanbanField))).add(s);
                        if(summarizeField != null){
                            decimal sVal = (Decimal)s.get(summarizeField);
                            if(sVal != null){
                                aggQMap.put(string.valueOf(s.get(kanbanField)), (Decimal)s.get(summarizeField) + (Decimal)aggQMap.get(string.valueOf(s.get(kanbanField))) );
                            }
                        }
                    }
                    return new HomeChildKanbanUtil(recMaps, Pickvalslst, true, null, gFldName, cObName, agrFieldName, sFldIsCurrency, aggQMap, gFldEditable, isObjDeletable, fieldTypeMap, isObjectCreateable);
                }catch (exception e){
                    return new HomeChildKanbanUtil(null, null, false, e.getMessage(), null, null, null, null, null, null, null, null, null);
                }
            } else {
                return new HomeChildKanbanUtil(null, null, false, 'You do not have access to the specified Group By field. Please contact your administrator.', null, null, null, null, null, null, null, null, null);
            }
        } else {
            return new HomeChildKanbanUtil(null, null, false, 'You do not have access to the requested fields. Please contact your administrator.', null, null, null, null, null, null, null, null, null);
        }

    }

    @AuraEnabled
    public static string updateRec(string recId, string recField, string recVal){
        try{
            Schema.DescribeSObjectResult sObjRes = Id.valueOf(recId).getSObjectType().getDescribe();
            Schema.DescribeFieldResult fldRes = sObjRes.fields.getMap().get(recField).getDescribe();
            if(sObjRes.isAccessible() && sObjRes.isUpdateable() && fldRes.isUpdateable()){
                String sObjName = sObjRes.getName();
                sObject s = Schema.getGlobalDescribe().get(sObjName).newSObject() ;
                s.Id = recId;
                s.put(recField, recVal);
                update s;
                return 'true';
            } else {
                return 'You do not have update access to object. Please contact your administrator.';
            }

        }
        catch(exception e){
            return e.getMessage();
        }
    }

    @AuraEnabled
    public static string deleteRec(sobject obj){
        Schema.DescribeSObjectResult sObjRes = Id.valueOf(obj.Id).getSObjectType().getDescribe();
        if(sObjRes.isDeletable()){
            try{
            	delete obj;
                return 'true';
            }catch(exception e){
                return e.getMessage();
            }
        } else {
            return 'You do not have permissions to delete the record. Please contact your administrator.';
        }
    }


}