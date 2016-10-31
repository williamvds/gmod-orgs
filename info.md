# Load order
1. autorun/sh_box_orgs

2. sh_init
  * *sh_vercas_von*
  * *sh_box_netmsg*
  * *sh_util*
  >__Enums, default ranks, default org types__
  >_orgs.List, orgs.Ranks, orgs.Members, are networked_

  * *sv_init*

    * *provider*
      >mysqloo if applicable

    * *sv_networking*

    Added to CS: sh_netmsg, sh_util, cl_init, vgui folder

    > cl_init
      DEFINED: Colors, fonts, drawing functions
      > vgui folder  

# Netmsg system
## NetworkTable()
1. Set the tabID as given  
2. Copy the table to netmsg.Tables  
3. Find subtables to create IDs, NetworkTable them
3. Empty original (keeping tabID)  
4. Set metatable on original  
5. Send proxy to client  

## Syncing on connect
1. Client sends sync request when initialised
3. Iterate through NWVars, send if should
2. Server iterates through proxies, SyncTable() if shouldSend

## A new key is added or updated
1. Set value on proxy
3. Send tabID, key, value to clients
2. If key is a table (and not vector or color) NetworkTable

## Client receives key update
