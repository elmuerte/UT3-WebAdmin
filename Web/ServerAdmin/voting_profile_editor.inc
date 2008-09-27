<form method="post" action="<%page.fulluri%>" id="profileform">
<fieldset>
  <legend><%profile.friendlyname%></legend>
  <input type="hidden" name="profilename" value="<%profilename%>" />
  
  <dl>
    <dt><label for="friendlyname">Profile name</label></dt>
    <dd><input type="text" name="friendlyname" id="friendlyname" value="<%profile.friendlyname%>" size="40" maxlength="128" /></dd>
    
    <dt><label for="gameclass">Game type</label></dt>
    <dd><select id="gameclass" name="gameclass"><%gametypes%></select></dd>
    
    <dt><label for="maplist">Map list</label></dt>
    <dd><select id="maplist" name="maplist"><%maplists%></select></dd>
  
    <dt><label for="options">Options</label></dt>
    <dd><textarea id="options" name="options" cols="40" rows="4"><%profile.options%></textarea></dd>
    
    <dt><label for="mutators">Mutators</label></dt>
    <dd><textarea id="mutators" name="mutators" cols="40" rows="4"><%profile.mutators%></textarea></dd>
    
    <dt title="A list of mutators which are disallowed when playing under this game profile">Excluded mutators</dt>
    <dd><%excludedmuts%></dd>
  
  </dl>
  <input type="hidden" name="excludedmutcount" value="<%excludedmutcount%>" />
  
  <div id="pfactions">
  <br />
  <button type="submit" name="action" value="save">save</button>
  <button type="submit" name="action" value="delete">delete</button>
  </div>
</fieldset>
</form>

<script type="text/javascript">
//<![CDATA[

var mutatorData;

$(document).ready(function() {
  $('#pfactions button[value="delete"]').click(function () {
    return window.confirm("Are you sure you want to delete this profile?");
  });
  
  var btn = $('<span class="inlineEdit" title="Edit this value"><span>[edit]</span></span>');
  btn.click(function(){
    $('#rofriendlyname').remove();
    $('#friendlyname').show().focus();    
    $(this).remove();
  });
  $('#friendlyname').hide().before('<span id="rofriendlyname">'+$('#friendlyname').val()+'</span> ').after(btn);
  
  $('#mutators').after('<ul id="mutatorsJs"></ul>').hide();
  
  $.ajax({
    type: "POST",
    url: '<%webadmin.path%>/data',
    data: {ajax: 1, type: 'mutators'},
    success: populateMutatorData,
    error: ajaxError
  });
});

function ajaxError(XMLHttpRequest, textStatus, errorThrown) {
  if (XMLHttpRequest.status == 403) {
    document.location = '<%page.fulluri%>';
  }
}

function handleMessages(jdata, textStatus) {
    var old = $('#messages .oldMessage');
    var newmsg = $(jdata.find('request messages').text());
    newmsg.hide();
    $('#messages').prepend(newmsg);
    newmsg.fadeIn();
    old.remove();
    $('#messages *').addClass('oldMessage');
}

function populateMutatorData(data, textStatus) {
  if (data.length == 0) {
    alert("Network error during updating.");
  }
  var jdata = $(data);
  handleMessages(jdata, textStatus);
  
  mutatorData = jdata.find('request mutatorGroup');
  populateMutatorList($('#mutators').val(), $('#mutatorsJs'));
}

function populateMutatorList(source, target) {
  $('li', target).remove();
  var items = source.split("\n");
  for (var i = 0; i < items.length; i++) {
    var txt = jQuery.trim(items[i]);
    if (txt.length == 0) continue;
    var x = mutatorData.find('class:contains("'+txt+'")').parent();
    if (x.size() > 0)
    {
      txt = $(x.get(0)).find('friendlyname').text();
    }
    target.append('<li>'+txt+'</li>');
  }
}

//]]>
</script>
