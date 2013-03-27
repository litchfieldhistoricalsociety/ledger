// confirmation_dlg.js
//
// This inserts a confirmation dialog between clicking a link and following it. Since the typical reason for
// for wanting a confirmation is that the user is about to change data on the server, there is a good chance
// that, to be restful, the method should be PUT or DELETE instead of POST, so the option for that is provided.
//
// To use: create an <a> tag that contains the class "fxn_confirm" and the attributes "data-confirm" and (optionally) "data-method".
// The url in "href" is what will be followed.
// For instance:
// <a href="/delete_lots_of_stuff" class="fxn_confirm" data-confirm="Are you really sure about this?" data-method='delete'>Delete Lots of Stuff</a>
//
// Dependencies:
// The YUI 3 minimum file "yui-min.js"
// The function createForm
//
// Reserved items:
// classes: fxn_confirm
//

/*global YUI, document */
/*global createForm */
YUI().use("overlay", 'node', function(Y) {

	function ask(event) {
		// We still need to stop the event or the original click will also get submitted.
		event.halt();

		// Get the confirmation message and give the user a chance to respond.
		var message = event.target._node.getAttribute('data-confirm');
		if (message && !confirm(message)) {
			return false;
		}

		// Dummy up a form that contains no fields and submit it. This way we can cause the method to be whatever the user has specified.
		var form = createForm(event.target._node.href, { method: event.target._node.getAttribute('data-method') });
		document.body.appendChild(form);
		form.submit();

		return false;
	}

	Y.on("click", function(e) {
		return ask(e);
	}, '.fxn_confirm');
});

