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
    unrender: function(component) {
        this.superUnrender();

        window.removeEventListener('click', component.closeMenu);
    }
})