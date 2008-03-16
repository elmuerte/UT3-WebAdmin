<div id="settingsWrapper">
<%settings%>
</div>
<script type="text/javascript">
//<![CDATA[
$(document).ready(function() {
    var tabs = $('<ul id="settingstabs"></ul>');
    $('#settingsWrapper').prepend(tabs);
    $('#settingsWrapper div.SettingsGroup').each(function() {
        var title = $('h4', this);
        tabs.append('<li><a href="#'+this.id+'"><span>'+title.text()+'</span></a></li>');
        title.remove();
    });
    tabs.tabs();    
});
//]]>
</script>
