/*global window, document, Image */
/*global baseUrl, preload_image_object */
// Preloading the CSS hover images
window.onload = function() {
	if (document.images)
	{
		var image_url = [ 'ledger_home_rollover.jpg', 'ledger_nav_search_dn.gif', 'ledger_nav_studies_dn.gif',
			'ledger_nav_about_dn.gif', 'ledger_nav_home_dn.gif', 'ledger_nav_browse_dn.gif' ];

		var base = baseUrl + "/images/";
		var i = 0;
		for (i = 0; i < image_url.length; i++) {
			preload_image_object = new Image();
			preload_image_object.src = base + image_url[i];
		}
	}
};
