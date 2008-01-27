<tbody>
<form method="POST" action="<%page.fulluri%>">
<tr>
  <td><input type="text" name="ipmask" value="<%policy.ipmask%>" class="monospace"" /></td>
  <td><select name="policy"><option value="DENY" <%policy.selected.DENY%>>Deny</option><option value="ACCEPT" <%policy.selected.ACCEPT%>>Accept</option></select></td>
  <td>
    <input type="hidden" name="policyid" value="<%policy.id%>" />
    <button type="submit" name="action" value="update">Update</button>
    <button type="submit" name="action" value="delete">Delete</button>
  </td>
</tr>
</form>
</tbody>
