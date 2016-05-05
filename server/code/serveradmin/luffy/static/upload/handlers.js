function preLoad() {
	if (!this.support.loading) {
		alert("请安装FLASH插件.");
		return false;
	} 
}
function loadFailed() {
	alert("加载失败。");
}

function fileDialogComplete(numFilesSelected, numFilesQueued) {
	try {
		if (numFilesQueued > 0) {
			this.startUpload(); 
			//$('#SWFUpload_0').css({'width':'1px'});
			$('#loadingPlaceholder').show();
		}
	} catch (ex) {
		this.debug(ex);
	}
}
 
function uploadSuccess(file, serverData) {
	$('#loadingPlaceholder').hide();
	try { 
		if (serverData.substring(0, 7) === "FILEID:") { 
			var img_id = serverData.substring(7);
			var img_url = this.customSettings.upload_img_url.replace('IMGID',img_id);
			$('#thumbnails').html('<img src="'+ img_url +'" /> <a href="javascript:void()" id="'+ img_id +'" onclick="delete_img(this);">删除</a>')
		} else {
			$('#thumbnails').html('图片上传失败了：' + serverData);
			//$('#spanButtonPlaceholder').show();
		} 
	} catch (ex) {
		this.debug(ex);
	}
}

function uploadError(file, errorCode, message) {
	$('#loadingPlaceholder').hide();
	//$('#spanButtonPlaceholder').show();
	try {
		switch (errorCode) {
		case SWFUpload.UPLOAD_ERROR.FILE_CANCELLED:
			break;
		case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
			break;
		case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
			imageName = "uploadlimit.gif";
			break; 
		}
		$('#thumbnails').html('图片上传失败了：' + message); 

	} catch (ex3) {
		this.debug(ex3);
	}

}

 