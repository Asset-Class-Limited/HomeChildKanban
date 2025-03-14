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
    destroyComponent: function (component) {
        component.destroy();
    },
    notifyParent: function (component) {
        var destroyEvent = component.getEvent("strike_evt_componentDestroyed");
        destroyEvent.setParams({
            'data' : {"value": component.get('v.value')}
        });
        destroyEvent.fire();
    }
})