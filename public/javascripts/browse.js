// browse.js
//
// This opens and closes tree-like nodes when the user clicks on the parent.
//
// To use, add the class "toggleTree" to an element that contains an id, and create a number of other elements that contain
// a specially constructed class (see below for details.)
//
// The id of the element should contain one underscore. The portion after the underscore is the key to which elements should
// be controlled by clicking. The elements to be controlled should have the class "Child_*" where * is the key defined in the id.
//
// Example:
//<span id="toggle_92" class="toggleTree">Parent</span>
//<div class="child_92">First Child</div>
//<div class="child_92">Second Child</div>
//
// Dependencies:
// The YUI 3 minimum file "yui-min.js"
// class: 'hidden', defined to contain "display:none;"
//
// Reserved items:
// classes: toggleTree
//

/*global YUI */
YUI().use('node', function(Y) {
	function toggleTree() {
		var el = this._node;
		var el_id = el.id;
		var id = el_id.split('_')[1];
		var children = Y.all('.child_' + id);
		children.toggleClass('hidden');
	}
	Y.on("click", toggleTree, ".toggleTree");
});
