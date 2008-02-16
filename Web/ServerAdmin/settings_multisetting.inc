<%mutlisetting.predef%>
<%mutlisetting.raw%>
<script type="text/javascript">
$(document).ready(function() {
  $('#settings_<%setting.name%>_raw').hide().before(' <button id=\"settings_<%setting.name%>_btn\" type=\"button\" title=\"Enter a custom value instead of the preselected values.\">custom value</button> ');
  $('#settings_<%setting.name%>_btn').click(function(){
    $(this).remove();
    elm = $('#settings_<%setting.name%>');
    rawelm = $('#settings_<%setting.name%>_raw');
    rawelm.val(elm.val());
    rawelm.attr('id', elm.attr('id'));
    rawelm.attr('name', elm.attr('name'));
    elm.remove();
    rawelm.show();
  });
});
</script>
