$(function() {
	var data = {};
	$('input').each(function(){
	    data[$(this).attr('name')] = $(this).val();
	});
	
	$.get("/busy.cgi?user="+data["user"]+"&sign="+data["sign"], function (data) {
		var lines		= data.split(/\r?\n/);
		if ( lines[0] == 0 ) {
			
		}
});

// ŽcŠ[ ‹C‚ªŒü‚¢‚½‚ç‚â‚é
