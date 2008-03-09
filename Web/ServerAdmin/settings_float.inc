<input type="text" id="<%setting.formname%>" name="<%setting.formname%>" value="<%setting.value%>" />
<script type="text/javascript">
//<![CDATA[
$(document).ready(function(){
  var elm = $('#<%setting.formname%>');
  elm.numeric();
});
//]]>
</script>
