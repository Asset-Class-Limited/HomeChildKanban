
/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({
    handleRecordUpdated : function(component, event, helper){
        var currentRec = component.get('v.record');
        if(!$A.util.isUndefinedOrNull(currentRec)){
            var recFields = currentRec.fields;
            var evtSrc = event.getSource();
            if(evtSrc.getLocalId() == 'refreshButton'){
                helper.spinnerHelper(component, true);
                $A.util.addClass(evtSrc,'refreshSpin');
                window.setTimeout($A.getCallback(function(){
                    if(component.isValid()){
                        $A.util.removeClass(evtSrc,'refreshSpin');
                    }
                }), 400);
            }
            var recId = component.get('v.recordId');
            var objName = recFields.ChildObject__c.value;
            var objRelField = recFields.RelationField__c.value;
            var objFields = recFields.FieldsToShow__c.value;
            var kanbanPicklistField = recFields.GroupBy__c.value;
            var excludeValue = recFields.ExcludeFromGroupBy__c.value;
            var KbObjNameField = recFields.NameField__c.value;
            var ExcFVal = excludeValue ? excludeValue.split(';') : '';
            if(ExcFVal != ''){
                for(var i=0; i<ExcFVal.length; i++){
                    ExcFVal[i] = ExcFVal[i].trim();
                }
            }
            var agrField = recFields.SummarizeBy__c.value;
            var agrFieldVal = agrField ? agrField : null;

            if(objName && objFields && kanbanPicklistField){
                //alert(recId + objName + objRelField + objFields + kanbanPicklistField);
                var action = component.get('c.getKanban');
                action.setParams({
                    'objName' : objName,
                    'objFields' : objFields.split(';'),
                    'kanbanField' : kanbanPicklistField,
                    'summarizeField' : agrFieldVal,
                    'ParentRecId' : recId,
                    'relField' : objRelField,
                    'excludeValue' : ExcFVal,
                    'KbObjNameField' : KbObjNameField
                });
                action.setCallback(this, function(resp){
                /*
                console.log(resp.getState());
                console.log(resp.getError());
                console.clear();
                console.log(resp.getReturnValue());
                */
                helper.spinnerHelper(component, false);
                if(resp.getState() === 'SUCCESS'){
                    var rVal = resp.getReturnValue();
                    component.set('v.isSuccess', rVal.isSuccess);
                    if(rVal.isSuccess){
                        for(var i=0; i<rVal.records.length; i++){
                            rVal.records[i].kanbanField = rVal.records[i][kanbanPicklistField];
                        }
                        component.set('v.kanbanWrap',rVal);
                    } else {
                        component.set('v.errorMessage', rVal.errorMessage);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        }
    },
    childChanged : function(component, event, _helper) {
        var recFields = component.get('v.record').fields;
        var data = event.getParam('KanbanChildChange');
        if(data.from != data.to){
            var recsMap = component.get('v.kanbanWrap');
            var rec = recsMap.records[data.from][data.pos];
            var nameInToast;
            var simpleRecord = component.get('v.simpleRecord');
            if(!$A.util.isUndefinedOrNull(simpleRecord.NameField__c) && simpleRecord.NameField__c != 'false'){
                if($A.util.isUndefinedOrNull(rec[simpleRecord.NameField__c])){
                    nameInToast = component.get('v.kanbanWrap').cObjName;
                } else {
                	nameInToast = rec[simpleRecord.NameField__c];
                }
            } else {
                nameInToast = component.get('v.kanbanWrap').cObjName;
            }
            var kField = recFields.GroupBy__c.value;
            var sField = recFields.SummarizeBy__c.value;

            if(rec[sField] && !isNaN(rec[sField])){
                var sMap = recsMap.rollupData;
                sMap[data.from] = sMap[data.from] - rec[sField];
                sMap[data.to] = sMap[data.to] + rec[sField];
                recsMap.rollupData = sMap;
            }

            rec[kField] = data.to;
            recsMap.records[data.to].unshift(rec);
            recsMap.records[data.from].splice(data.pos, 1);

            component.set('v.kanbanWrap',recsMap);
            var toastEvent = $A.get("e.force:showToast");
            var action = component.get('c.updateRec');
            action.setParams({
                'recId' : rec.Id,
                'recField' : kField,
                'recVal' : data.to
            });
            action.setCallback(this, function(res){
                if(res.getState() === 'SUCCESS' && res.getReturnValue() === 'true'){
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "success",
                        "duration" : 400,
                        "message": nameInToast+' moved to '+ data.to
                    });
                    toastEvent.fire();
                } else {
                    var em = 'An Unknown Error Occurred';
                    if(res.getState() === 'SUCCESS' && res.getReturnValue() != 'true'){
                        em = res.getReturnValue();
                    } else if(res.getState() === 'ERROR'){
                        var errors = res.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                em = errors[0].message;
                            }
                        } else {
                            em = 'An Unknown Error Occurred';
                        }
                    }
                    toastEvent.setParams({
                        "title": "Error",
                        "type" : "error",
                        "duration" : 400,
                        "message": em
                    });
                    toastEvent.fire();
                    var rec = recsMap.records[data.to][0];
                    rec[kField] = data.from;
                    recsMap.records[data.to].splice(0, 1);
                    recsMap.records[data.from].splice(data.pos, 0, rec);
                    component.set('v.kanbanWrap',recsMap);
                }
            });
            $A.enqueueAction(action);
        }
    },
    childDelete : function(component, event, helper) {
        var data = event.getParam('KanbanChildDelete');
        component.set('v.delInfo', data);
        helper.modalHelper(component, 'srModal', 'modalBackDrop', true);
    },
    deleteRecord : function(component, _event, helper) {
        var recFields = component.get('v.record').fields;
        helper.modalHelper(component, 'srModal', 'modalBackDrop', false);
        helper.spinnerHelper(component, true);
        var data = component.get('v.delInfo');
        console.log(data);
        var recsMap = component.get('v.kanbanWrap');
        var rec = recsMap.records[data.from][data.pos];
        console.log(rec);
        var action = component.get('c.deleteRec');
        var sField = recFields.SummarizeBy__c.value;
        action.setParams({
            'obj' : rec
        });
        action.setCallback(this, function(res){
            helper.spinnerHelper(component, false);
            var state = res.getState();
            var toastEvent = $A.get("e.force:showToast");
            if(state === 'SUCCESS'){
                recsMap.records[data.from].splice(data.pos, 1);

                if(rec[sField] && !isNaN(rec[sField])){
                    var sMap = recsMap.rollupData;
                    sMap[data.from] = sMap[data.from] - rec[sField];
                    recsMap.rollupData = sMap;
                }
                toastEvent.setParams({
                    "title": "Success",
                    "type" : "success",
                    "duration" : 400,
                    "message" : "The record has been delete successfully."
                });
                toastEvent.fire();
                component.set('v.kanbanWrap',recsMap);

            } else if(state === 'ERROR'){
                var errors = res.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        em = errors[0].message;
                    }
                } else {
                    em = 'An Unknown Error Occurred';
                }
                toastEvent.setParams({
                    "title": "Error",
                    "type" : "error",
                    "duration" : 400,
                    "message" : em
                });
                toastEvent.fire();
            }

        });
        $A.enqueueAction(action);
    },
    closeModal : function(component, _event, helper) {
        helper.modalHelper(component, 'srModal', 'modalBackDrop', false);
        component.set('v.delInfo', null);
    },
    initiateNewRecordCreation : function(component, _event, _helper) {
        var recordId = component.get('v.recordId');
        if($A.util.isUndefinedOrNull(recordId)){
            var simpleRecord = component.get('v.simpleRecord');
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": simpleRecord.ForObject__c
            });
            createRecordEvent.fire();
        } else {
            var simpleRecord = component.get('v.simpleRecord');
            var createRecordEvent = $A.get("e.force:createRecord");
            var recObj = {};
            recObj[simpleRecord.RelationField__c] = recordId;
            createRecordEvent.setParams({
                "entityApiName": simpleRecord.ChildObject__c,
                "defaultFieldValues": recObj
            });
            createRecordEvent.fire();
        }
    }
})