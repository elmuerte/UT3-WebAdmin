<fieldset>
<legend>Settings for <em><%editmutator.name%></em></legend>
<form method="POST" action="<%page.fulluri%>">
<input type="hidden" name="mutator" value="<%editmutator.class%>" />
<dl>
<%settings%>
</dl>
<button type="submit" name="action" value="save" id="btnsave">save settings</button>
</form>
</fieldset>
