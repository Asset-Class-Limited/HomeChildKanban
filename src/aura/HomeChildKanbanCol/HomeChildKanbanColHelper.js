
/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({
    countUpHelper : function(component) {
        var sMap = component.get('v.summaryMap');
        var pSumVal = component.get('v.pSumVal');
        if(sMap){
            var options = {
                useEasing : true,
                useGrouping : true,
                separator : ',',
                decimal : '.',
            };
            //console.log(component.get('v.isCurrency'));
            var fType = component.get('v.rsFld');
            var decimalValue = 0;
            if(fType == "CURRENCY"){
                options.prefix = $A.get("$Locale.currency");
            } else if(fType == "DOUBLE"){
                decimalValue = 2;
            }
            /*if(component.get('v.isCurrency')){
                options.prefix = $A.get("$Locale.currency");
            }*/
            if(!isNaN(sMap[component.get('v.pickValue')])){
                var demo = new CountUp(component.find('cup').getElement(), pSumVal, sMap[component.get('v.pickValue')], decimalValue, 1, options);
                demo.start();
                component.set('v.pSumVal',sMap[component.get('v.pickValue')]);
            }
        }
    }
})