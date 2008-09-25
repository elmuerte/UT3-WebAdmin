<form method="post" action="<%page.fulluri%>" id="profileform">
<fieldset>
  <legend><%profile.friendlyname%></legend>
  <input type="hidden" name="profilename" value="<%profilename%>" />
  
  <div id="pfactions">
  <br />
  <button type="submit" name="action" value="save">save</button>
  <button type="submit" name="action" value="delete">delete</button>
  </div>
</fieldset>
</form>
