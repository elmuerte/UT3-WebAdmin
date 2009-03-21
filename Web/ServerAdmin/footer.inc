
<div id="promptDialog">
  <div id="promptWindow">
  <p></p>
  <input type="text" size="40" /><br />
  <button type="button" id="promptOk">Ok</button>
  <button type="button" id="promptCancel">Cancel</button>
  </div>
</div>

<div id="footer">
Copyright 2008-2009 Epic Games, Inc.
&#8212;
<a href="<%webadmin.path%>/about" title="v<%build.version%> - <%build.timestamp%>">About the UT3 WebAdmin</a>
</div>

<script type="text/javascript">
//<![CDATA[

var windowAlert = window.alert;

$('#promptDialog').hide();

$(document).ready(function(){
  if (jQuery.browser.msie && parseFloat(jQuery.browser.version) < 7) {
    // fix "buttons" to work properly in MSIE<7
    $('button[name!=""]').each(function() {
      this.realBtnName = this.name;
      this.name = '';
      $(this).click(function() {
        this.name = this.realBtnName;
        this.form.submit();
      });
    });
  } /* end if */
  $('#menu a[href='+window.location.pathname+']').addClass('active');
  window.alert = messageAlert;
});

function messageAlert(text, type) {
  if (text == undefined) text = "";
  if (type == undefined) type = "error";
  var old = $('#messages .oldMessage');
  text = ""+text;
  var newmsg = $('<div class="message '+type+'">'+text.replace("\n", "\n<br />")+'</div>');
  newmsg.hide();
  $('#messages').prepend(newmsg);
  newmsg.fadeIn();
  old.remove();
  $('#messages *').addClass('oldMessage');
  var pos = $('#messages').offset();
  if (pos.top < $(window).scrollTop()) {
    window.scrollTo(pos.left, pos.top);
  }
}

function messagePrompt(text, callback, defVal) {
  var promptUI = $('#promptDialog');
  if (promptUI) {
    if (callback == undefined) callback = function () {};
    var edit = $('input[type=text]', promptUI);
    edit.val(defVal);
    $('p', promptUI).remove();
    edit.before('<p>'+text+'</p>');
    var btnCancel = $('#promptCancel');
    btnCancel.click(function(){ promptUI.hide(); });
    var btnOk = $('#promptOk');
    btnOk.click(function(){ promptUI.hide(); callback(edit.val());} );
    edit.keypress(function (e) { 
      if (e.which == 13) btnOk.click();
      else if (e.keyCode == 27) btnCancel.click();
    });
    promptUI.show();
    edit.focus();
  }
  else {
    var val = window.prompt(text, defVal);
    if (val != undefined && callback != undefined) {
      callback(val);
    }
  }
}

//]]>
</script>

</body>
</html>
