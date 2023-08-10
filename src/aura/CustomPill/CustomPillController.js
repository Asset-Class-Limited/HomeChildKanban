/*
    Strike by Appiphony
    Version: 0.9.0
    Website: http://www.lightningstrike.io
    GitHub: https://github.com/appiphony/Strike-Components
    License: BSD 3-Clause License

    This component is part of the Kanban project
    It may have some differences to meet Asset Class code standards
*/
({
    destroyPill: function (component, _event, helper) {
    	// Check to see if this component is in Strike Fiddler so we stop user from removing it
    	if (component.get('v.destroyable')) {
            helper.notifyParent(component);
            helper.destroyComponent(component);
        }
    }
})