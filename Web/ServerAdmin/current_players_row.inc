<tr class="<%evenodd%>">
  <td style="background: <%player.teamcolor%>; color: <%player.teamcolor%>;"><%player.teamid%>&nbsp;</td>
  <td><%player.name%></td>
  <td class="right"><%player.ping%></td>
  <td><%player.ip%></td>
  <td><%player.uniqueid%></td>
  <td><%player.hashresponse%></td>
  <td class="center"><%player.admin%></td>
  <td>
    <form method="POST" action="<%page.fulluri%>">
    <input type="hidden" name="playerid" value="<%player.playerid%>" />
    <button type="submit" name="action" value="kick">Kick</button>
    <button type="submit" name="action" value="banid">Ban unique ID</button>
    <button type="submit" name="action" value="banhash">Ban Client Hash</button>
    <button type="submit" name="action" value="banip">Ban IP</button>
    </form>
  </td>
</tr>
