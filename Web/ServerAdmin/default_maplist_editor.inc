<div id="mleditor">
<table class="noborder">
<thead>
<tr>
    <th>Available Maps</th>
    <th>Map Cycle</th>
</tr>
</thead>

<tbody id="noscript">
<tr>
    <td><textarea rows="15" cols="30" id="allmaps" readonly="readonly"><%allmaps.plain%></textarea></td>
    <td><textarea rows="15" cols="30" name="mapcycle" id="mapcycle"><%cycle.plain%></textarea></td>
</tr>
</tbody>

<tbody id="jsmaplist" display="none">
<tr>
    <td><ul id="jsallmaps"></ul></td>
    <td><ol id="jsmapcycle"></ol></td>
</tr>
</tbody>
</table>

<p id="noscriptHint"><em>Note:</em> you get the best map list editing experiance in a JavaScript capable browser. Enter one map per line, you can include URL options like ?LinkSetup=...</p>
<p id="jsmaplistHint"><em>Note:</em> drag items from the left list to the right list to add a map to the cycle. To move a map to a different position in the cycle, simply drag it to the desired location.
Press the "x" button next to the map cycle entry to remove it. You can manually add a map to the cycle using the "manual add" button below.
</p>

</div>

<script type="text/javascript">
//<![CDATA[

// prevents flicker
$('#noscript').hide();

$(document).ready(function() {
    $('#noscript').hide();
    $('#noscriptHint').hide();
    
    _allmaps = $('#allmaps').val().split("\n");
    _jsallmaps = $('#jsallmaps');
    for (i = 0; i < _allmaps.length; i++)
    {
        str = jQuery.trim(_allmaps[i]);
        if (str.length > 0)
        {
            _jsallmaps.append('<li><span class="entry">'+str+'</span></li>');
        }
    }
    
    _mapcycle = $('#mapcycle').val().split("\n");    
    _jsmapcycle = $('#jsmapcycle');    
    for (i = 0; i < _mapcycle.length; i++)
    {
        str = jQuery.trim(_mapcycle[i]);
        if (str.length > 0)
        {
            var item = jQuery('<li><span class="entry">'+str+'</span></li>');
            _jsmapcycle.append(item);
            getDeleteMe($(item));
        }
    }
    _jsmapcycle.sortable({ 
        axis: "y", 
        containment: "parent",
        start: function(ev, ui) {
            $(ui.helper).addClass('dragging');
        },
        stop: function(ev, ui) {
            $(ui.helper).removeClass('dragging');
        }
    });
    $('#jsallmaps li').draggable({
        helper: 'clone',
        zIndex: 100,
        start: function(ev, ui) {
            $(ui.helper).addClass('dragging');
        },
        stop: function(ev, ui) {
            $(ui.helper).removeClass('dragging');
        }
    });
    $('#jsmapcycle').parent().droppable({
        accept: "li",
        activeClass: "droppable",
        drop: function(ev, ui) {
            var item = $(ui.draggable).clone();            
            getDeleteMe(item);
            _jsmapcycle.append(item);            
            _jsmapcycle.sortable("refresh");
            _jsmapcycle.sortable("refreshPositions");
        }
    });
    
    $('#jsmaplist').show();
    $('#jsmaplistHint').show();
    
    simpleEditBtn = jQuery('<button type="button" id="simpleEditBtn" title="switch to basic map cycle editing mode">basic edit mode</button>');
    simpleEditBtn = $(simpleEditBtn);
    simpleEditBtn.click(function(){
       $(this).remove();
       $('#manualAddBtn').remove();
       updateTextMapList();
       $('#jsmaplist').remove();
       $('#jsmaplistHint').remove();
       $('#noscript').show();
       $('#noscriptHint').show();
    });
    manualAddBtn = jQuery('<button type="button" id="manualAddBtn" title="add a map by entering the name">manual add</button>');
    manualAddBtn = $(manualAddBtn);
    manualAddBtn.click(function(){
        var res = jQuery.trim(prompt("Enter the map name (without extension) to be added to the map cycle. \nHint: you can include URL options like ?LinkSetup=...", ""));
        if (res != "") {
            item = jQuery('<li><span class="entry">'+res+'</span></li>');
            getDeleteMe($(item));
            _jsmapcycle.append(item);
            _jsmapcycle.sortable("refresh");
            _jsmapcycle.sortable("refreshPositions");
        }      
    });
    $('#btnsave').after(simpleEditBtn).after(" ").after(manualAddBtn).after(" ");
    $('#maplistform').submit(function () {
        updateTextMapList();
        return true;
    });
});

function getDeleteMe(forItem) {
    var res = jQuery('<span class="deleteButton" title="delete this map"></span>');
    res = $(res);
    res.click(deleteme);
    forItem.prepend(res);
    forItem.hover(function() {
        $(this).addClass('sorting');
    }, function() {
        $(this).removeClass('sorting');
    });
}

function deleteme() {
    $(this).parent().remove();
}

function updateTextMapList() {
    // check manual mode  
    if ($('#jsmapcycle').size() == 0)
    {
        return;      
    }
    var maplist = $('#jsmapcycle li');
    var txtlist = "";
    for (i = 0; i < maplist.size(); i++) {
        txtlist += jQuery.trim($('.entry', maplist.get(i)).text())+'\n';
    }
    $('#mapcycle').val(txtlist);
}

//]]>
</script>
