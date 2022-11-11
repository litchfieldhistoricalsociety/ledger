/*global YUI, document */
/*extern createForm, buildElement */

// params is a hash that could contain { isMultipart: true, method: 'delete' }
function createForm(action, params) {
	var form = document.createElement('form');
	form.setAttribute("method", 'POST');
	form.setAttribute("action", action);
	if (params.isMultipart === true)
		form.setAttribute("enctype", "multipart/form-data");
	if (params.method) {
		var hiddenField = document.createElement("input");
		hiddenField.setAttribute("type", "hidden");
		hiddenField.setAttribute("name", "_method");
		hiddenField.setAttribute("value", params.method);
		form.appendChild(hiddenField);
	}
	YUI().use('overlay', 'node', 'io-base', 'json-parse', 'autocomplete', "autocomplete-highlighters", "datasource-get", function(Y) {
		var csrf_param = Y.one('meta[name=csrf-param]')._node.content;
		var csrf_token = Y.one('meta[name=csrf-token]')._node.content;
		var hiddenField = document.createElement("input");
		hiddenField.setAttribute("type", "hidden");
		hiddenField.setAttribute("name", csrf_param);
		hiddenField.setAttribute("value", csrf_token);
		form.appendChild(hiddenField);
	});
	return form;
}

function buildElement(parent, type, attributes, inner) {
	var el = document.createElement(type);
	if (attributes) {
		for (attr in attributes) {
			if (attributes.hasOwnProperty(attr))
				el.setAttribute(attr, attributes[attr]);
		}
	}
	parent.appendChild(el);
	if (inner)
		el.innerHTML = inner;
}

