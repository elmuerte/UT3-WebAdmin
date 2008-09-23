
<div id="footer">
Copyright 2008 Epic Games, Inc.
&mdash;
<a href="<%webadmin.path%>/about" title="v<%build.version%> - <%build.timestamp%>">About the UT3 WebAdmin</a>
</div>

<script type="text/javascript">
<!--
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
});
// -->
</script>

</body>
</html>
