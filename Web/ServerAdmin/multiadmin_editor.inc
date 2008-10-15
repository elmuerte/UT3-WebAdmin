<form method="post" action="<%page.fulluri%>" id="profileform">
<fieldset>
  <legend><%adminid%></legend>
  <input type="hidden" name="adminid" value="<%adminid%>" />
  
  <dl>
    <dt title="Show this as the name of the administrator rather than the user name"><label for="displayname">Display name</label></dt>
    <dd><input type="text" name="displayname" id="displayname" value="<%displayname%>" size="40" maxlength="128" /></dd>
    
    <dt><label for="password1">Password</label></dt>
    <dd><input type="text" name="password1" id="password1" value="" size="40" maxlength="128" /></dd>
    
    <dt><label for="password2">Confirm password</label></dt>
    <dd><input type="text" name="password2" id="password2" value="" size="40" maxlength="128" /></dd>
    
    <dt>Access order</dt>
    <dd>
      <input type="radio" name="order" id="DenyAllow" value="DenyAllow" <%order.denyallow%> /> <label for="DenyAllow" title="Deny access unless it is eplicitly allow. Defaults to allow.">Deny, Allow</label>
      <br />
      <input type="radio" name="order" id="AllowDeny" value="AllowDeny" <%order.allowdeny%> /> <label for="AllowDeny" title="Access is denied if it is now allowed. Defaults to deny.">Allow, Deny</label>
    </dd>
  
    <dt><label for="deny">Deny patterns</label></dt>
    <dd><textarea id="deny" name="deny" cols="60" rows="6"><%deny%></textarea></dd>
    
    <dt><label for="allow">Allow patterns</label></dt>
    <dd><textarea id="allow" name="allow" cols="60" rows="6"><%allow%></textarea></dd>
    
    <dd>....</dd>
  
  </dl>
  
  <div id="pfactions">
  <br />
  <button type="submit" name="action" value="save">save</button>
  <button type="submit" name="action" value="delete">delete</button>
  </div>
</fieldset>
</form>

<script type="text/javascript">
//<![CDATA[

$(document).ready(function() {
  $('#pfactions button[value="delete"]').click(function () {
    return window.confirm("Are you sure you want to delete this administrator?");
  });
});

//]]>
</script>
