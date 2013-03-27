// carousel.js
//
// This creates a carousel to display a number of pictures.
//

/*global YUI, YAHOO */

// Instantiate and configure Loader:
var loader = new YAHOO.util.YUILoader({

    // Identify the components you want to load.  Loader will automatically identify
    // any additional dependencies required for the specified components.
    require: ["carousel"],

    // Configure loader to pull in optional dependencies.  For example, animation
    // is an optional dependency for slider.
    loadOptional: true,

    // The function to call when all script/css resources have been loaded
    onSuccess: function() {
		YUI().use('node', function(Y) {

			var el = Y.one("#carousel");
			if (el === null)
				return;

			var carousel = new YAHOO.widget.Carousel(null);
			carousel.CONFIG.MAX_PAGER_BUTTONS = 20;
			carousel.init("carousel", {
				animation: { speed: 0.5 },
				navigation: { prev: 'carousel_left', next: 'carousel_right' }
			});
			carousel.render(); // get ready for rendering the widget
			carousel.show();   // display the widget
		});
    },

    // Configure the Get utility to timeout after 10 seconds for any given node insert
    timeout: 10000,

    // Combine YUI files into a single request (per file type) by using the Yahoo! CDN combo service.
    combine: true
});

// Load the files using the insert() method. The insert method takes an optional
// configuration object, and in this case we have configured everything in
// the constructor, so we don't need to pass anything to insert().
loader.insert();
