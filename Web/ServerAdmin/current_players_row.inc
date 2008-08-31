<tr class="<%evenodd%>">
  <td style="background: <%player.teamcolor%>; color: <%player.teamcolor%>;"><%player.teamid%>&nbsp;</td>
  <td><form method="post" action="<%page.fulluri%>"><div><%player.name%> <input type="hidden" name="playerid" value="<%player.playerid%>" /><input type="hidden" name="playerkey" value="<%player.playerkey%>" /><button type="submit" name="action" value="kick">Kick</button></div></form></td>
  <td><form method="post" action="<%page.fulluri%>"><div><input type="hidden" name="playerid" value="<%player.playerid%>" /><input type="hidden" name="playerkey" value="<%player.playerkey%>" /><button type="submit" name="action" value="sessionban">Session Ban</button></div></form></td>
  <td class="right"><%player.ping%></td>
  <td><form method="post" action="<%page.fulluri%>"><div><%player.ip%> <input type="hidden" name="playerid" value="<%player.playerid%>" /><input type="hidden" name="playerkey" value="<%player.playerkey%>" /><button type="submit" name="action" value="banip">Ban</button></div></form></td>
  <td><form method="post" action="<%page.fulluri%>"><div><%player.uniqueid%> <input type="hidden" name="playerid" value="<%player.playerid%>" /><input type="hidden" name="playerkey" value="<%player.playerkey%>" /><button type="submit" name="action" value="banid">Ban</button></div></form></td>
  <td><form method="post" action="<%page.fulluri%>"><div><%player.hashresponse%> <input type="hidden" name="playerid" value="<%player.playerid%>" /><input type="hidden" name="playerkey" value="<%player.playerkey%>" /><button type="submit" name="action" value="banhash">Ban</button></div></form></td>
  <td class="center"><%player.admin%></td>
</tr>
