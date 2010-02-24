$(document).ready(function() {
    $('a[id^=diff-]').click(function() {
	if (this.id.match(/diff-([0-9]*)/)) {
	    var id = RegExp.$1;
	    var diff = '#diff-' + id;
	    var diff_content = '#diff-content-' + id;

	    $(diff_content).load('/diff/' + id, function(text, status) {
		$(diff).toggleClass("diff-closed");
		$(diff).toggleClass("diff-open");
 		$(diff_content).html(text);
 		$(diff_content).toggle("normal");
		return false;
	    });
	}
	return false;
    });
});
