/*global YUI, window */
/*global baseUrl */
YUI().use('node', function(Y) {
	function show_students() {
		var nodes = Y.all('.students');
		nodes.removeClass('hidden');
		nodes = Y.all('.materials');
		nodes.addClass('hidden');
	}

	function show_materials() {
		var nodes = Y.all('.students');
		nodes.addClass('hidden');
		nodes = Y.all('.materials');
		nodes.removeClass('hidden');
	}

	function clear_form() {
		var nodes = Y.all('input[type=input]');
		nodes.each(function(n) { n._node.value = ''; });
		nodes = Y.all('input[type=checkbox]');
		nodes.each(function(n) { n._node.checked = false; });
		var node = Y.one('#advanced_search_students');
		node._node.checked = true;
		show_students();
	}

	function only_students() {
		var el = this._node;
		var param = el.checked === true ? "true" : "false";
		window.location = baseUrl + "/students/limit?only_students=" + param;
	}

	function date_control_hider() {
		var el = this._node;
		var id = el.id;
		if (el.options[el.selectedIndex].value === 'Between')
			Y.one('#between_date_' + id).removeClass('hidden');
		else
			Y.one('#between_date_' + id).addClass('hidden');
	}

	Y.on("click", show_students, "#advanced_search_students");
	Y.on("click", show_materials, "#advanced_search_materials");
	Y.on("click", clear_form, "#clear_btn");
	Y.on("click", only_students, "#show_only_students");

	Y.on("change", date_control_hider, ".date_controller");
	Y.on("keyup", date_control_hider, ".date_controller");
});
