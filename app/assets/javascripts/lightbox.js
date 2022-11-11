/*global YUI */
YUI().use('overlay', 'node', 'io-base', 'json-parse', 'autocomplete', "autocomplete-highlighters", "datasource-get", function(Y) {

    /* Create a new Overlay instance, with content generated from script */
    var overlay = null;

	function create_overlay() {
		overlay = new Y.Overlay({
			visible:false,
			zIndex:10,
			headerContent: "<button id='lightbox_hide'>Close</button>",
			bodyContent: "<img id='overlay_img' src='../images/ajax-loader.gif' alt='detailed image'>"
		});

		overlay.render();
	}

    Y.delegate("click", function(e) {
		if (overlay === null)
			create_overlay();

		var img = this.one('img');
		img = img._node;
		var src = img.src;
		src = src.replace("/small/", "/original/");
		src = src.replace("/thumb/", "/original/");
		Y.one("#overlay_img")._node.src = src;
		//overlay.centered("#content_container");
        overlay.show();
    }, 'body', ".lightbox_thumbnail");

	Y.on("load", function(e) {
		//overlay.centered("#content_container");
	}, "#overlay_img");

    Y.delegate("click", function(e) {
        overlay.hide();
    }, 'body', "#lightbox_hide");

});
