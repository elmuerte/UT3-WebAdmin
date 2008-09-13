
<form method="post" action="<%page.fulluri%>">
<fieldset>
  <legend><%friendlyname%></legend>
  <input type="hidden" name="maplistid" value="<%maplistid%>" />

  <div id="mleditorSections">

    <div class="mleditSection" id="modeMaps">
      <h4>Maps</h4>
      
      
      
    </div>
    
    <div class="mleditSection" id="modePrefix">
      <h4>Auto-load Prefixes</h4>
      <table width="400">
      <tr>
        <td><textarea name="autoloadprefixes" cols="10" rows="8" title="One line per prefix"><%autoloadprefixes%></textarea></td>
        <td>
          <p>The map list will automatically be filled with maps that have this prefix. Maps will only be added once. New maps are added to the end of the list.</p>
          <p>A map prefix is the file name part before the first hyphen, for example <code>DM-Morbias</code> has the prefix <code>DM</code>.</p>
        </td>
      </tr>
      </table>
    </div>
  
  </div>
  
  <div id="mlactions">
  <br />
  <button type="submit" name="action" value="save">save</button>
  <button type="submit" name="action" value="activate" title="Make this map cycle the active map cycle for the gametype">activate</button>
  <button type="submit" name="action" value="delete">delete</button>
  </div>

</fieldset>
</form>

<script type="text/javascript">
//<![CDATA[
$(document).ready(function() {
    var tabs = $('<ul id="tabs"></ul>');
    var tabidx = 0;
    var idx = -1;
    $('#mleditorSections').prepend(tabs);
    $('#mleditorSections div.mleditSection').each(function() {
        var title = $('h4', this);
        ++idx;
        tabs.append('<li><a href="#'+this.id+'"><span>'+title.text()+'</span></a></li>');
        if ('#'+this.id == location.hash) {
          tabidx = idx;
        }
        title.remove();
    });
    tabs.tabs({ selected: tabidx });    
    
    $('#mlactions button[value="delete"]').click(function () {
      return window.confirm("Are you sure you want to delete this map list?");
    });
});
//]]>
</script>
