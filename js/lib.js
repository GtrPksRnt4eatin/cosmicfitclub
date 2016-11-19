api = 'http://' + window.location.hostname + ':4567'

function updateModel(model, data, nested_arr){
	if(model==null) { return data;  }
	if(data==null)  { return model; }
    if(typeof data == 'number' || typeof data == 'string' || typeof data == 'boolean')
		{ model = data; }
	for(var prop in model) {
        if(data.hasOwnProperty(prop)) {
            if( typeof model[prop]=='object')
            {   if ( Object.prototype.toString.call( model[prop] ) == '[object Array]' )
                {   if(nested_arr) {
						if( nested_arr[prop] ) { fill_array( model[prop], data[prop], nested_arr[prop], nested_arr ); }
						else                   { fill_array( model[prop], data[prop], null, nested_arr ); }						
                    }	else				   { fill_array( model[prop], data[prop]); }
                }                
                else 
                {   updateModel(model[prop], data[prop], nested_arr); }
            }
            else { model[prop] = data[prop]; }
        }
    }
    model.update && model.update();
    return model;
}

function fill_array(array, data, cls, nested_arr) {
    try {
        while(array.length>data.length) 
        {   remove_ref(array,array[array.length-1]); }
        for(var i=0; i<array.length; i++)
        {   array[i] = updateModel(array[i],data[i], nested_arr); }
        for(var i=array.length; i<data.length; i++)
        {   if(cls)   {   array.push(updateModel(new cls(), data[i], nested_arr)); }
            else      {   array.splice(array.length,0,data[i]); }
        }
    }   catch(e) { console.log('error while filling array: ' + e.message); }
}

jQuery.extend({
    put: function(url, data, callback, type) {
        return _ajax_request(url, data, callback, type, 'PUT');
    },
    del: function(url, data, callback, type) {
        return _ajax_request(url, data, callback, type, 'DELETE');
    }
});

function _ajax_request(url, data, callback, type, method) {
    if (jQuery.isFunction(data)) {
        callback = data;
        data = {};
    }
    return jQuery.ajax({
        type: method,
        url: url,
        data: data,
        success: callback,
        dataType: type
        });
}

function remove(arr,obj,prop) {
    var i = inArray(arr,obj,prop);
    if(i!=-1) { arr.splice(i,1); } 
}

function remove_ref(arr,obj) {
    var i = $.inArray(obj,arr);
    if(i!=-1) { arr.splice(i,1); }
}

function customFilter(prop,val,object){
    if(object==null) return null;
    if(object.hasOwnProperty(prop) && object[prop]==val)
        return object;

    for(var i=0;i<Object.keys(object).length;i++){
        if(typeof object[Object.keys(object)[i]]=="object"){
            o=customFilter(prop,val,object[Object.keys(object)[i]]);
            if(o!=null)
                return o;
        }
    }
    return null;
}

function lookup(array, prop, value) {
    for (var i = 0, len = array.length; i < len; i++)
        if (array[i][prop] === value) return array[i];
}


function cancelEvent(e) 
{ e.stopPropagation(); e.cancelBubble = true; }

function inArray(array,object,prop) {
    if (object.hasOwnProperty(prop)) {
        for (var i = 0; i < array.length; i++) {
            if (array[i].hasOwnProperty(prop)) {
                if (array[i][prop] == object[prop]) { return i; } } } }
    return -1;
}

function getCookie(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(':');
    for(var i=0; i<ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1);
        if (c.indexOf(name) != -1) return c.substring(name.length,c.length);
    }
    return "";
}

function delete_cookie(name) {
    document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
}

function def(obj) { return(typeof obj != 'undefined'); }

function longpoll(source,callback,stream) {
    if(typeof stream === 'object' && typeof stream.close === 'function') { stream.close(); }
    var evt = new EventSource(source);
    evt.onmessage = function(e) { callback(JSON.parse(e.data)); };
    return evt;
}

function linkJSON(local,remote,cls) { 
    return longpoll(remote, function(data) { fill_array(local,data,cls); } ); 
}