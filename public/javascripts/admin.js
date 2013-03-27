/*global YUI, document */
/*global add_autocomplete_to_node */
/*global createForm, buildElement */
YUI().use('overlay', 'node', 'io-base', 'json-parse', 'autocomplete', "autocomplete-highlighters", "datasource-get", function(Y) {
	function get_nodes_data(event) {
		var div = event.target;
		var span = div.one('span');
		return span._node.innerHTML;
	}

	function set_nodes_data(event, data) {
		var div = event.target;
		var span = div.one('span');
		span._node.innerHTML = data;
	}

	function remove_row(event) {
		// The element looks like this: <div ... ><span class="hidden">marriage_0</span></div>
		// We want to delete the element that is inside that span.
		var id = get_nodes_data(event);
		var row = Y.one('#' + id);
		row.remove();
	}

	function set_image(event) {
		var sel = event.target._node;
		var img = Y.one('.main_image_img');
		img._node.src = '/' + sel.value;
	}

	function write_in_select(event) {
		var sel = event.target._node;
		var val = sel.value;
		var id = sel.id;
		id = id.substring(0, id.lastIndexOf('_'));
		var write_in = Y.one('#'+id+"_writein");
		if (val === "-1") {
			write_in.removeClass('hidden');
			write_in.focus();
		} else
			write_in.addClass('hidden');
	}

	function new_row_returned(id, o, arg) {
//		if (arg !== 'new_row_returned')
//			return false;

		var waitingButton = Y.one('.button_loading');
		if (waitingButton)
			waitingButton.removeClass('button_loading');
	
		if (o.status !== 200)
			return false;

		// var id = id; // Transaction ID.
		var resp = Y.JSON.parse(o.responseText);
		var el = Y.one('#'+resp.el);
		el.insert(resp.html, el);
		el._node.innerHTML = "";	// In case there was a prompt here to add an item.

		// attach all the events to our newly created controls. This mimics what happens on page load with existing elements.
		var insertedDiv = el.previous();
		var button = insertedDiv.one('.minus_button');
		button.on("click", function(e) {
			return remove_row(e);
		});
		var select = insertedDiv.one('.write_in_select');
		if (select) {
			select.on("change", function(e) {
				return write_in_select(e);
			});
		}
		var autocomplete = insertedDiv.one(".auto_complete.student");
		if (autocomplete) {
			add_autocomplete_to_node(Y, autocomplete, "student");
		}
		autocomplete = insertedDiv.one(".auto_complete.material");
		if (autocomplete) {
			add_autocomplete_to_node(Y, autocomplete, "material");
		}
		return true;
	}

	//Y.on('io:complete', new_row_returned, Y, 'new_row_returned');

	function add_row(event) {
		event.currentTarget.addClass('button_loading');
		var callback_url = get_nodes_data(event);
		callback_url = callback_url.replace(/&amp;/g, '&');
		Y.io(callback_url, {on: {complete: new_row_returned}});

		var arr = callback_url.split('&');
		for (var i = 0; i < arr.length; i++) {
			if (arr[i].substring(0, 3) === 'id=') {
				var arr2 = arr[i].split('=');
				arr[i] = arr2[0] + '=' + (parseInt(arr2[1])+1);
			}
		}
		callback_url = arr.join('&');
		set_nodes_data(event, callback_url);

		return false;
	}

	// To use this set up your control like this:
	// <input type='input' class='vague_date' /><span class='date_error'></span>
	// Then in your controller, if you return a status other than 200, then whatever text you return will show up in the span.
	function validate_date(event) {
		var date = event.target._node.value;

		var date_return = function(id, o) {
			var status = event.target.next(".date_error");
			if (o.status === 200)
				status._node.innerHTML = "";
			else
				status._node.innerHTML = o.responseText;
		};
		Y.io(baseUrl + '/admin/validate_date', {data: 'date=' + date, on: {complete: date_return}});
	}

    var overlay = null;

	function create_overlay(title, url, prompt) {
		var body = createForm(url, {isMultipart: true});
		buildElement(body, 'p', null, prompt);
		buildElement(body, 'input', { type: 'file', name: 'file', size: '60'});
		buildElement(body, 'input', { type: 'submit', Value: 'Upload' });
		buildElement(body, 'button', { id: 'file_dlg_hide'}, 'Cancel');

		overlay = new Y.Overlay({
			visible:false,
			zIndex:10,
			headerContent: title,
			bodyContent: body
		});

		overlay.render();
		overlay.centered();
	}

	function add_image(event) {
		event.halt();
		create_overlay("Image Upload", event.target._node.href, "Upload an image file (JPG, PNG, or GIF)");
		overlay.show();
		return false;
	}

	function add_transcription(event) {
		event.halt();
		create_overlay("Image Upload", event.target._node.href, "Upload a transcription file (PDF)");
		overlay.show();
		return false;
	}

	Y.on("click", function(e) {
		return remove_row(e);
	}, '.minus_button');

	Y.on("click", function(e) {
		return add_to_select(e);
	}, '.add_to_select');

	Y.on("change", function(e) {
		return set_image(e);
	}, '#student_main_image');

	Y.on("click", function(e) {
		return add_row(e);
	}, '.plus_btn');

	Y.on("change", function(e) {
		return write_in_select(e);
	}, '.write_in_select');

	Y.on("blur", function(e) {
		return validate_date(e);
	}, '.vague_date');

	Y.on("click", function(e) {
		return add_image(e);
	}, '.fxn_add_image');

	Y.on("click", function(e) {
		return add_transcription(e);
	}, '.fxn_add_transcription');

    Y.delegate("click", function(e) {
		e.halt();
        overlay.hide();
    }, 'body', "#file_dlg_hide");
});

