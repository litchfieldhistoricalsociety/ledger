/*global YUI */
// This changes a textarea into one that will auto size as the user types.
// To use, just load this file, and mark all desired textareas with the class "TextAreaGrow".
// There should be a <div> as the direct ancestor of the the textarea.
YUI().use('node', function(Y) {
	function autoSize(el) {
		// Copy textarea contents; browser will calculate correct height of copy,
		// which will make overall container taller, which will make textarea taller.
		var text = el._node.value.replace(/\n/g, '<br/>');
		var copy = el.next();
		copy._node.innerHTML = text;
	}

	// On every keyup, recalculate the size.
    Y.on("keyup", function(e) {
		autoSize(this);
    }, ".textAreaGrow");

	Y.on("domready", function() {
		// Find all the textareas that should be turned into grow type textareas and add the necessary divs to the dom.
		var all = Y.all('.textAreaGrow');
		all.each(function(el) {
			// For each textarea, wrap it in a div, then add a class to its new parent, and add a div after it to hold the copy
			var parent = el.ancestor();
			parent.append("<div class='textarea_container'><div class='textCopy'></div></div>");
			parent.one('.textarea_container').insert(el, 0);

			// The textarea starts out hidden so that there is no flash, so make it visible.
			el.setStyle('visibility', 'visible');

			// Call autoSize immediately so that it starts with the correct height.
			autoSize(el);
		});
	});
});
