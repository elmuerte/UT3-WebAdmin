<tbody>
<form method="POST" action="<%page.fulluri%>">
<tr>
  <td><%ban.playername%></td>
  <td><%ban.hash%></td>

  <td>
    <input type="hidden" name="banid" value="<%ban.banid%>" />
    <button type="submit" name="action" value="delete">Delete</button>
  </td>
</tr>
</form>
</tbody>