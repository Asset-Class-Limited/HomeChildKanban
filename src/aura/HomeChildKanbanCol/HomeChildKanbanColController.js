
/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({
    doInit : function(component, _event, _helper) {
        component.set('v.recs', component.get('v.recsMap')[component.get('v.pickValue')]);
    },
    allowDrop : function(component, event, _helper) {
        event.preventDefault();
    },
    drag : function (component, event, _helper) {
        var co = {'from': event.currentTarget.parentElement.getAttribute('data-Pick-Val'),
                  'pos' : event.currentTarget.value}
        event.dataTransfer.setData("text", JSON.stringify(co));
    },
    drop : function (component, event, _helper) {
        event.preventDefault();
        var data = JSON.parse(event.dataTransfer.getData("text"));
        data.to = event.currentTarget.getAttribute('data-Pick-Val');
        component.set('v.goingTo', event.currentTarget.getAttribute('data-Pick-Val'));

        var kcevt = component.getEvent('kanbanChildChanged');
        kcevt.setParams({
            "KanbanChildChange" : data
        });
        kcevt.fire();

        var ulEle = component.find('hckCol').getElement();
        if(!ulEle.scrollTop == 0)
            ulEle.scrollTop = 0;

    },
    recordsChanged  : function (component, _event, helper) {
        component.set('v.recs', component.get('v.recsMap')[component.get('v.pickValue')]);
        helper.countUpHelper(component);
    },
    sLoaded : function (component, _event, helper) {
        helper.countUpHelper(component);
    }
})