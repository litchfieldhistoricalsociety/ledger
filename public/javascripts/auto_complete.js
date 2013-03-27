/*global YUI */
/*extern baseUrl */

function add_autocomplete_to_node(Y, node, type) {
	// Create a DataSource instance.
	var ds = new Y.DataSource.Get({
		source: baseUrl + "/search/autocomplete?type=" + type
	});

	node.plug(Y.Plugin.AutoComplete, {
		maxResults: 25,
		resultHighlighter: 'wordMatch',
		resultTextLocator: 'name',

		// Use the DataSource instance as the result source.
		source: ds,

		// YQL query to use for each request (URL-encoded, except for the
		// {query} placeholder). This will be appended to the URL that was supplied
		// to the DataSource's "source" config above.
		requestTemplate: "&prefix={query}",

		// Custom result list locator to parse the results out of the YQL response.
		// This is necessary because YQL sometimes returns an array of results, and
		// sometimes just a single result that isn't in an array.
		resultListLocator: function (response) {
			var results = response[0].query.results;

			return results;
		}
	});

//	var autoComp = new Y.ACWidget({
//		ac : node.plug(Y.Plugin.ACPlugin, {
//		queryTemplate : function (q) { return "&prefix="+ encodeURIComponent(q); },
//		dataSource : new Y.DataSource.IO({
//		   source : baseUrl + "/search/autocomplete?type=" + type
//		}).plug({fn : Y.Plugin.DataSourceJSONSchema, cfg : {
//					   schema : { resultListLocator : "result",metaFields:{total:'resultCount'} }
//				   }}).plug(Y.Plugin.DataSourceRegExCache, {max:25})
//		}).ac,
//		zIndex:110,
//		align: {node:node,points:["tl","bl"]}
//	});
//	autoComp.get('boundingBox').addClass('msa-menu').addClass('yui3-widget-bd');
}

YUI().use('node', 'autocomplete', "autocomplete-highlighters", "datasource-get", function (Y) {
	var attachToNode = function(node, type) {
		add_autocomplete_to_node(Y, node, type);
	};

	var nodeList = Y.all(".auto_complete.student");
	nodeList.each(function(node) { attachToNode(node, 'student'); });

	nodeList = Y.all(".auto_complete.material");
	nodeList.each(function(node) { attachToNode(node, 'material'); });
});
