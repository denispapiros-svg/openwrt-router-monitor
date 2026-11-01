'use strict';
'require view';

return view.extend({
	render: function() {
		return E('iframe', {
			src: '/cgi-bin/mon',
			style: 'width:100%;height:88vh;border:0;background:#0f1115'
		});
	},
	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
