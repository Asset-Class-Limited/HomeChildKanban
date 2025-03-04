/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class HomeChildKanbanObjUtil{
    @AuraEnabled
    public string objName {get; set;}

    @AuraEnabled
    public string objLabel {get; set;}

    public HomeChildKanbanObjUtil(string oName, string oLabel){
        this.objName = oName;
        this.objLabel = oLabel;
    }
}