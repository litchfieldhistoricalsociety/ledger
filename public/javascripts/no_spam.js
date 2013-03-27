// Just create the email like this: <a href='domain com name' class='no_spam' />
// If the innerHTML is $, then replace that with the address, too.
YUI().use('node', function(Y) {
	Y.later(500, this, function() {
		var emails = Y.all('.no_spam');
		emails.each(function(email) {
			var href = email._node.getAttribute('href');
			var arr = href.split(' ');
			var address = arr[2] + '@' + arr[0] + '.' + arr[1];
			email._node.setAttribute('href', "mailto:" + address);
			if (email._node.innerHTML === '$')
				email._node.innerHTML = address;
		});
	});
});
