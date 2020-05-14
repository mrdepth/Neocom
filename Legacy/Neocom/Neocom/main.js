Dropzone.options.formUpload = {
	acceptedFiles: ".xml,.cfg",
	init: function() {
		this.on("queuecomplete", function() {
//				window.location.reload();
				document.getElementById('content').contentWindow.location.reload(true);
				});
	}

};

function resizeIframe(obj){
	obj.style.height = 0;
	obj.style.height = obj.contentWindow.document.body.scrollHeight + 'px';
}
