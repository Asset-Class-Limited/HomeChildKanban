/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
global with sharing class KanbanConfigList extends VisualEditor.DynamicPickList{

	global override VisualEditor.DataRow getDefaultValue(){
        KanbanConfiguration__c klist = [Select Id, Name from KanbanConfiguration__c order by createddate desc limit 1][0];
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(string.valueOf(klist.Name), string.valueOf(klist.id));
        return defaultValue;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        List<KanbanConfiguration__c> klist = [Select Id, Name from KanbanConfiguration__c];
        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
        for(KanbanConfiguration__c k : klist){
            myValues.addRow(new VisualEditor.DataRow(string.valueOf(k.Name), string.valueOf(k.id)));
        }
        return myValues;
    }
}