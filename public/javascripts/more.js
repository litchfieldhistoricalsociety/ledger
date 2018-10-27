/*global YUI */
YUI().use('overlay', 'node', 'io-base', 'json-parse', 'autocomplete', "autocomplete-highlighters", "datasource-get", function(Y) {

	function expand(node) {
		var text = node.previous('.start_hidden');
		var ellipsis = node.previous('.ellipsis');
		var less = node.next('.less_link');
		text.removeClass('hidden');
		ellipsis.addClass('hidden');
		node.addClass('hidden');
		less.removeClass('hidden');
	}

	function contract(node) {
		var text = node.previous('.start_hidden');
		var ellipsis = node.previous('.ellipsis');
		var more = node.previous('.more_link');
		text.addClass('hidden');
		ellipsis.removeClass('hidden');
		node.addClass('hidden');
		more.removeClass('hidden');
	}

    Y.on("click", function(e) {
        expand(e.target);
    }, ".more_link");

    Y.on("click", function(e) {
        contract(e.target);
    }, ".less_link");
});
