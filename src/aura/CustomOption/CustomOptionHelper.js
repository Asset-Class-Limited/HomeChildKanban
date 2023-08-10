/*
    Strike by Appiphony
    Version: 1.0.0
    Website: http://www.lightningstrike.io
    GitHub: https://github.com/appiphony/Strike-Components
    License: BSD 3-Clause License

    This component is part of the Kanban project
    It may have some differences to meet Asset Class code standards
*/
({
    updateLabel: function(component, event, _helper) {
        var optionLabel = component.get('v.label');
        var optionLabelLc = $A.util.isEmpty(optionLabel) ? '' : optionLabel.toLowerCase();
        var searchTerm = event.getParam('arguments');
        var searchTermLc = $A.util.isEmpty(searchTerm) ? '' : searchTerm[0].toLowerCase();

        component.set('v.filtered', optionLabelLc.indexOf(searchTermLc) === -1);
        component.set('v.labelHtml', optionLabel.replace(new RegExp('(' + searchTerm + ')', 'i'), '<mark>$1</mark>'));
    }
})