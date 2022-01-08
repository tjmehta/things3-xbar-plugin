#!/usr/bin/osascript

### General Utils

on stringSplit(str, delimeter)
  -- save delimiters to restore old settings
  set oldDelimiter to AppleScript's text item delimiters
  -- set delimiters to delimiter to be used
  set AppleScript's text item delimiters to delimeter
  -- create the array
  set textList to every text item of str
  -- restore the old setting
  set AppleScript's text item delimiters to oldDelimiter
  -- convert to strings
  set stringList to {}
  repeat with textItem in textList
  copy textItem as string to end of stringList
  end repeat
  -- return the result
  return stringList
end stringSplit

on listJoin(stringList, delimeter)
  -- save delimiters to restore old settings
  set oldDelimiter to AppleScript's text item delimiters
  -- set delimiters to delimiter to be used
  set AppleScript's text item delimiters to delimeter
  -- create the string
  set str to the stringList as string
  -- restore the old setting
  set AppleScript's text item delimiters to oldDelimiter
  -- return the result
  return str
end listJoin

### Todo Tag Utils

on getTagList(todo)
  tell application "Things3"
    set tagList to tags of todo
  end tell
  return tagList
end getTagList

on setTagList(todo, tagList)
  set tagNames to listJoin(tagList, ", ")
  tell application "Things3"
    set tag names of todo to tagNames
  end tell
end setTagList

on addNowTag(todo)
  set tagList to getTagList(todo)
  set newTagNameList to {}

  repeat with tagTag in tagList
    set tagName to name of tagTag
    if tagName is equal to "Now" then
      return
    end if
    copy tagName to the end of newTagNameList
  end repeat

  copy "Now" to the end of newTagNameList

  setTagList(todo, newTagNameList)
end addNowTag

on removeNowTag(todo)
  if todo is null
    return
  end if
  set tagList to getTagList(todo)
  set newTagNameList to {}
  set hasNowTag to false

  repeat with tagTag in tagList
    set tagName to name of tagTag
    if tagName is not equal to "Now" then
      copy tagName as string to the end of newTagNameList
    else
    set hasNowTag to true
    end if
  end repeat

  if hasNowTag is false
    return
  end if

  setTagList(todo, newTagNameList)
end removeNowTag

### Todo Misc Utils

on moveToList(todo, listName)
  tell application "Things3"
    move todo to list listName
  end tell
end moveToList

on getTodoByName(name, listName)
  tell application "Things3"
  set todo to to do named name of list listName
  end tell

  return todo
end getTodoByName

on getTodos(listName)
  set nowTodoName to ""

  tell application "Things3"
  set todos to to dos of list listName
  end tell

  set todoCount to count of todos
  set nowTodo to null
  set incompleteTodos to {}
  set completedTodos to {}

  repeat with n from 1 to todoCount
    set todo to item n of todos
    tell application "Things3"
    set todoCompleted to status of todo is not open
    end tell

    if todoCompleted is not true then
      tell application "Things3"
      set tagList to tags of todo
      end tell
      set hasNowTag to false

      repeat with tagTag in tagList
        set tagName to name of tagTag

        if tagName is equal to "Now" then
          # now todos
          if todoCompleted or listName is not equal to "Today" then
            removeNowTag(todo)
          else
            if nowTodo is not null
              removeNowTag(todo)
            else
              set nowTodo to todo
            end if
          end if
        end if
      end repeat
    end if
    if todo is not equal to nowTodo
      # not now todo
      if todoCompleted then
        copy todo to the end of completedTodos
      else
        copy todo to the end of incompleteTodos
      end if
    end if
  end repeat

  return { nowTodo, incompleteTodos, completedTodos }
end getTodos


on run argv
  set argCount to count of argv

  if argCount is greater than 0
    set f to POSIX file "/Users/tjmehta/Developer/scratch/log.log"
    write item 1 of argv & " " as string to f starting at eof
    if argCount is greater than 1
      write item 2 of argv & "\n" as string to f starting at eof
    end if
    if argCount is greater than 2
      write item 3 of argv & "\n" as string to f starting at eof
    end if
    if argCount is greater than 3
      write item 4 of argv & "\n" as string to f starting at eof
    end if

    # OPERATIONS: TODO
    if item 1 of argv is "complete"
      set todoName to item 2 of argv
      set todo to getTodoByName(todoName, item 3 of argv)

      tell application "Things3"
      set status of todo to completed
      end tell
      removeNowTag(todo)

      return
    end if
    if item 1 of argv is "delete"
      set todoName to item 2 of argv
      set todo to getTodoByName(todoName, item 3 of argv)

      removeNowTag(todo)
      tell application "Things3"
        delete todo
      end tell

      return
    end if
    if item 1 of argv is "add-now-tag"
      set todoName to item 2 of argv
      set todo to getTodoByName(todoName, item 3 of argv)
      set todoLists to getTodos("Today")
      set nowTodo to item 1 of todoLists

      if nowTodo is not null and name of nowTodo is equal to name of todo
        return
      end if

      removeNowTag(nowTodo)
      if item 3 of argv is not equal to "Today"
        moveToList(todo, "Today")
      end
      addNowTag(todo)
      return
    end if
    if item 1 of argv is "remove-now-tag"
      set todoName to item 2 of argv
      set todo to getTodoByName(todoName, item 3 of argv)

      removeNowTag(todo)
      return
    end if
    if item 1 of argv is "move-to"
      set todoName to item 2 of argv
      set todo to getTodoByName(todoName, item 3 of argv)

      if item 3 of argv is not equal to item 4 of argv
        moveToList(todo, item 4 of argv)
      end if
      return
    end if

    # COMMANDS: APP
    if item 1 of argv is "launch"
      tell application "Things3"
        activate
      end tell
      return
    end if
    if item 1 of argv is "new-todo"
      tell application "Things3"
        show quick entry panel
      end tell
      return
    end if
    if item 1 of argv is "log-completed"
      tell application "Things3"
        log completed now
      end tell
      return
    end if
    if item 1 of argv is "empty-trash"
      tell application "Things3"
        empty trash
      end tell
      return
    end if
  end if

  ######
  ### DISPLAY
  ######
  set filepath to path to me
  set filepathList to stringSplit(filepath as string, ":")
  set arg0 to "/" & listJoin(filepathList's (items 2 thru -1), "/")
  set logs to ""

  if argCount is greater than 0
    set arg1 to item 1 of argv
  else
    set arg1 to ""
  end if

  if application "Things3" is not running
    # THINGS IS NOT RUNNING
    set logs to logs & "‚òë" & "\n"
    set logs to logs & "---" & "\n"
    set logs to logs & "Things is not running" & "\n"
    set logs to logs & "Open Things | shell='" & arg0 & "' param1=launch terminal=false refresh=true"
  else
    # THINGS IS RUNNING
    set todoLists to getTodos("Today")
    set nowTodo to item 1 of todoLists
    set incompleteTodos to item 2 of todoLists
    set completedTodos to item 3 of todoLists
    set inboxTodoLists to getTodos("Inbox")
    set inboxTodos to item 2 of inboxTodoLists
    set inboxCompletedTodos to item 3 of inboxTodoLists

    ### MENUBAR ###

    if nowTodo is null
      set logs to logs & "‚òë" & "\n"
    else
      set logs to logs & "‚òê " & name of nowTodo & "\n"
    end if

    ### DROPDOWN ###

    set logs to logs & "---" & "\n"

    # Icons
    set deleteIcon to "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAG5lWElmTU0AKgAAAAgAAwESAAMAAAABAAEAAAExAAIAAAARAAAAModpAAQAAAABAAAARAAAAABBZG9iZSBJbWFnZVJlYWR5AAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAACj+zsWAAABy2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBJbWFnZVJlYWR5PC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgpRV3oSAAABGElEQVQ4Ee2UTW4CMQyFKexbCu2deg6uQdcVd+Gvf9tKHKEnYNM1azZI8H0ISxakMx1UdjzpaTKOY7/YSVqtKy5dgU4hwRO2AfyG68J8Nj3w8wzbcJknSuMRxi2cwn7J4WAz6Azq+3KwVX4emZ1AF7zBHjyGCd+hPmNokj9Bx1io8hzcoHMYiat2hdsp7jHFVl8Zd6G2nND/s5C3bBIThNK8i7OC37Iqtm5QS6OtEh6TOtzgIAN5HLbGX5v4AUNpKLfOjZsW2V0YgaztHbSBHsFI1Lh5Kv1MAXKjTBinpZFyL4gNUpVKc1B+9zB4KPcyKaQWcaVdUFVH50LAyZUuPUKelB84hCv4G3ygvuAGLmDtI4TPFf9YgR3aID79/qp4jQAAAABJRU5ErkJggg=="
    set completeIcon to "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAAAXNSR0IArs4c6QAAAG5lWElmTU0AKgAAAAgAAwESAAMAAAABAAEAAAExAAIAAAARAAAAModpAAQAAAABAAAARAAAAABBZG9iZSBJbWFnZVJlYWR5AAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAACj+zsWAAABy2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIj4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBJbWFnZVJlYWR5PC94bXA6Q3JlYXRvclRvb2w+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgpRV3oSAAABBElEQVQ4Ee2TIWtCURiGL4pMEWEwDcJAzIsmw/wDto3NZLX4Gww2uw61+A/sVsEiWB1YTFYZU4uKzucFL8gNXvScBcEXHu7h+J3Hl6PXce757xsIWviCCI42ZGEAO7CSCpY/GMGjFSOSHKxgC29gJU9Y1FJtW1aMR4lkkg4hcdwzfrxj2MASXv1sMQYaUIPQmeE0n01BbfXD+SbJxA/oQBMewJswG13QTA+i4JsAEx+wAB38Am/zMnv6n87gBS5KkelfcJurpZKBOWi/BFelwClXXmf9DH2QtANGb6ya61r2MAZJvyEFxvnE4DZfs84bG08Eaj6B6smetWUck9G9Wmtye6ID/C8yM5mJDIgAAAAASUVORK5CYII="
    set inboxIcon to "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAAFBlWElmTU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAO/B1EAAACTElEQVQ4Ee1TsW4TQRCdnb29852jBGPkIBPFsihANFQgGqQ0VAgJKfABEQ2fkZ4vSAUKpESiJDSREEipIhr6ECETYoJ1OI6x73aHWdtn9jhDR5eVTju78+btu9m3AGfjf3dAFA5YJ6w1vtwX0rstiKoApgAZb6DNGPT8fT3svWqvLX1wgQXi2tOvdzAqv8EgYlwh7dZyTAwRoONvH2Uludm6Vz/NAF4WZDOhqYPngznpHIMxh8z9D3ZmlV6TD6j1W/0LzHGQ8RSIETEAk4DWw8eUxtsmkLOJvzNdgMIP556x7Lt+qOYzUjsXiEmbeWEMi00+HT+62nXBs+LF5+0j8DxlkvScm0d3YWOJdB6IQJpg+Gdu1lqA6bBsQFAVN18gBiGrQAYGin64wL/GZNoCJduDAhdTbIWAEKSEMBWr5c2jXaike+5tZ8X1zdZyKuQVXt8S1h2kcyJzi6wIvQDQj55QVN6hWG2srO/kBFQ2Wsskg7eowtcimHtgeaXOqsdzkZhdLxBBKB/Y/EwoVg6uXS+7ZUGom/xXDRmUED018rKbt3GBWNidkcFYhpWCQptePMtyLGGCsVnJnzMKxJzLkxBJr5v2nRpWY7R9cdPBMRl3Y4aPBcEh8C3zC2FBxG3xFk+qC1sXt9rT56qJLiPKsSjLpxM2E+ZclLsUq0ALeom9+KEoRY2RqlKkUC2sTtXZgB+QFU2WNBkADU63hxC/dzHO//zevvTi85IBdYPI8M1Mhu2hvfmslzZWPqGmjj/svttfa/6cIM+mfAd+AcC6vbxdoG1hAAAAAElFTkSuQmCC"
    set todayIcon to "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAAFBlWElmTU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAO/B1EAAACA0lEQVQ4Ee1TTU8TURQ9b2g7nSluDMaEhbEYF2pioGiMAj+AsHPj3gU/wJJg4kKiCcGN/gfZsSH4B9hpkEZCQJdu2JCGjWnsfHX6OBc6ZabMOHWtL5nMffeec+7XDPD//O0Efu1i/ncDC8Py1DBA3YDtAbtQMFsOpq7NopXHM/IAEne7eGpauMvnll3Gs2E4ucJHG7CUgTp6SEPhRXMbo3nimcJ6GwUZwdUqnpdMTCKkFJ+yiTv2FSwe76MimKwEiRnLcki87zqYYJXTxRFc72qMlYooRQKaRieArxROQo1m2EWDnJ+uix+Vh9iKcImMzDJnVLBsmwxLhd0eLHrzKpUUS0ykMF4wMM4RTaJIv48PDPWFExWLTLuBNcvCstiQ8uTI+xLywud5eG9OYYldRIxoJcI+P/YDvHQ9vGaLFydNlFFNmbaL1XIN9bioEFOXZ9XwhlW85Xz/WKnv411lGq9EaPCkCvdAO0zbby1BpFeTycRfE/7YJVOYrVUNWVEkLcgYWnFhhoEbMa2EGYMm/DKC22eiguDHFnhoBT5/ZQqeJeAOOON7A6z+NVVYr7AYhTn5/MMQbuDgox7BjB9ilvY6fZ7E2NUTiqdq9DPEjaPPsJw9HHS+Y7O9j0fxmNjtb3gcHOCTu4dD+TsH45n3FVbsfMHNTMB5QDk7qAo2B/evh08B+WCSYldJvvMAAAAASUVORK5CYII="
    set upcomingIcon to "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAAFBlWElmTU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAO/B1EAAACp0lEQVQ4Ee2Uv08UQRTH33s7u3fLIQTvOALmDmKjIhATCjul0UISNTEk1nZGWxPL+yMMdHYWmPi70MRCRRujiUZzmmBC+KF48lN+Hnu7M8+ZPRZugVhpx0vmZt6873xm5s3bA9i3/50B3LnBRGN/k+vQVQI4DYANCJhi4JjMLNJN6m4REb+vKrydm3v4slYUA7+HXrujOXcnTfbAvKoMMvPnRrKHBGEMTRq7EHhFBXTdIn4qAOUGq3PZ2ccjEVwfbNvaM23dhHwhPCHCZSS8qZkag2BgUQt3QehEUrcSQMkDKFIadGWbBCBijiVyNoMzr7xhQlwGRvyt/IA1tGpRSvQmWgDM9joHb3zis3rTrhir1lHMgvS5SNKN9MKjqdrY38ZzzRfv6nhPrSZ24ijAqPSDFaiU+XgKhFxrLT15N52+dNSy/Nx63cHXtDjruo5zkolGW37dGwNgw4muE2J2gfUr64CjW4ETcuCDBKWMUro04a5SKTvTUQEYD5by8HZxsrlsYiZTGMOCvvce5qDPWssqAUdI2HkjqQ/8FlUnOr8cL4q5TINb8RPd9qHlzNZyiqPi3qaqwnb4WsRQltL3zLQUgS+By+XiGGcclg6oNdtP+NUluzG7Zzbh+mYoRDBtSX/GTCnPXUqCM9ULhxVMr1TKbE9mxerKpnyrbiI/BtYVFJiEKjJfVQE9Kbr8uvp2I046QZuSQc94R8o2qXAITizZyZYqCM2yoDqu/sYeDyVObZCSNuExhMI3KMGrSNzw48GoHptmbEO352bwoq9PiK+Qk4BF40cW5jJyGPrEfLZpWCCd0Ud+BorDiojie/UWUl4XUo9H+pP+eX8k0sTAZnIi39+U8hLXdOC8rsx0JNzZhwsRKxbip3UIhlpL8T+hnfp9/99n4A+FMeksKA2hgQAAAABJRU5ErkJggg=="
    set somedayIcon to "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAAFBlWElmTU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAO/B1EAAAB2UlEQVQ4Ee1TvU7cQBCe8a4tMAdpkNIgJERPRRmJghZqeroUdIgHSCp+SlpegI6KBomCBikFBW+AaJAQugvB3OHdnczYHp99d0hpKCIx0t387jfjb3YBPuW/ZQCbk1+e7a3GCZ1QoCQQVSkpUbtZrTZCHBvIc3+xtnG0o1Grhmg0bmm201lxXoBaPRtl2mSYtwah23txjSJoAUdogjER5wMQ6aQKoICS18alLs80YWEEOES/ut3sZ8BgGfufJYktENJt80Br4m+b+3dX57s3Bs18HnxRFxmej0BULUQReV6EBiKmYsqZK/VFt4CLBOHh3Jd02btyZOc9vGaDwF79DTaObGd6irdQ0pQkBp76v7f4/GmBwX9CWEu4OHMMKguUmfr9/PEtuMX0vpemX3upT2emudmBLFdq5DcYOPBE7y+v1YEdEg4Q56yxP14WZp/hAdFAxgC47oubMzxhoEnWJCrqa4bCLSQsM4nZ1rshafmiUFBcR4cdKmuc4yLBB5BRZT0RQi58i93CqRyNtQeesDzBxGotAq5ohS1dBYnjXKPdsM5JvpSxiYnfn60eSQ1a1Opo4qhdanl5ozIOTHT8/Cf7Hjy/vtHqCb68Ou/DXfYG1xPSn6EPZOAvfu2n8pRVKagAAAAASUVORK5CYII="
    set anytimeIcon to "iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAAFBlWElmTU0AKgAAAAgAAgESAAMAAAABAAEAAIdpAAQAAAABAAAAJgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAFqADAAQAAAABAAAAFgAAAAAO/B1EAAACyklEQVQ4Ee2TTUhUURSAz733/YyjqZi0iWzTpoVo2ahDREYtgn6gTbQazBz8oXFRilFhSkjRj0b+zmBNtpMKpKgoWohQ+UthELUJgiCkMEJ9743z7r3d96YbPjFrE228m3Pv+fnO4dxzAFbPv+4A+psEgdj1PaDgvcAQ55w9nAhHhv4UtyJ4y43OoIpQAxB8EPt04sBYwrKBsUFms8sTlXVjv0uwLDgQay9ERD3BCTlMfLouqgTgPMVACBDGQC3LBJsNMJu3TVZF3ixN4AEXRaN+jBOtSFPC2OdLd2FMQAXMPYvgzttNYFpzQO0eP55pGjrabKUcAbC8OJIkk2kCEsC6nu6iHJCEOg7OffFbqLCmZQhlgTmbozku8ngqlsqSvs4KUEk90tTN6CdI/Jprdt9CxykDlrRf84XkxfFwZEDGSukBl7W3ZxuZagW16V34/O2rkre2lhMlQnQ9L1VpCk5N6wOirM221ZiqGesZVQ5la1mxp6HQvAR7WpHMzKQI8WLFp02SjevOc4Li/hmrgM8Zp5hpTnHLekUN46RKZwvNBfOOqtGrHOsTGOOtMD0tma70VCwtwZvdO7mCm0XvNonR6jW+zF2bamhwqynr6sqw/FAPhFQCh3fig8+NlNc8l7FSesBF0Su5ipbWginuf1lZMxaI9x5QCDQxxnI548Oiv0hMwg5AMA1J1jJyrPbxtr6O7YqCj2QklLPPqqq+S7CnFQBrDMQhwRT+qPRWzwBK2u9fhqpLxNieIQTnIIyygNuNI6FqsTj4Y2m8+x7B6D7jaF7dkPg1ag7cU7HMFox35IsFaRQTvFs4DLLEQutouO6TYy+6Hc1TGW0CTPYhzp4wii6NVlS/lbFSLguWxmB/TzEgcloscjHjfMoZYowgXzTkBaX4wmh5eFL6LpUrgqVzSX/XLgJkvxg2scH2g/Hy48PStir/Xwd+AFo+ENapB/y3AAAAAElFTkSuQmCC"

    # Now
    if nowTodo is not null
      set todoName to name of nowTodo
      set logs to logs & "‚òê " & todoName & " #Now | shell='" & arg0 & "' param1=remove-now-tag param2='" & todoName & "' param3=Today terminal=false refresh=true" & "\n"
      set logs to logs & "-- Complete | image='" & completeIcon & "' shell='" & arg0 & "' param1=complete param2='" & todoName & "' param3=Today terminal=false refresh=true" & "\n"
    end if

    if count of incompleteTodos is greater than 0
      set logs to logs & "Today" & "\n"
      repeat with todo in incompleteTodos
        set todoName to name of todo
        set logs to logs & "‚òê " & todoName & "| shell='" & arg0 & "' param1=add-now-tag param2='" & todoName & "' param3=Today terminal=false refresh=true" & "\n"
        set logs to logs & "--  Complete | image='" & completeIcon & "' shell='" & arg0 & "' param1=complete param2='" & todoName & "' param3=Today terminal=false refresh=true" & "\n"
        set logs to logs & "--  Inbox | image='"    & inboxIcon    & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Today param4=Inbox terminal=false refresh=true" & "\n"
        set logs to logs & "--  Upcoming | image='" & upcomingIcon & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Today param4=Upcoming terminal=false refresh=true" & "\n"
        set logs to logs & "--  Anytime | image='"  & anytimeIcon  & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Today param4=Anytime terminal=false refresh=true" & "\n"
        set logs to logs & "--  Someday | image='"  & somedayIcon  & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Today param4=Someday terminal=false refresh=true" & "\n"
        set logs to logs & "--  Delete | image='"   & deleteIcon   & "' shell='" & arg0 & "' param1=delete param2='"   & todoName & "' param3=Today terminal=false refresh=true" & "\n"
        -- set logs to logs & "-- Anytime | shell='" & arg0 & "' param1=move-to param2='" & todoName & "' param3=Today param4=Someday terminal=false refresh=true" & "\n"
        -- set logs to logs & "-- Someday | shell='" & arg0 & "' param1=move-to param2='" & todoName & "' param3=Today param4=Someday terminal=false refresh=true" & "\n"
      end repeat
    end if

    if count of inboxTodos is greater than 0
      set logs to logs & "Inbox" & "\n"
      repeat with todo in inboxTodos
        set todoName to name of todo
        set logs to logs & "‚òê " & todoName & "| shell='" & arg0 & "' param1=add-now-tag param2='" & todoName & "' param3=Inbox terminal=false refresh=true" & "\n"
        set logs to logs & "--  Today | image='"    & todayIcon    & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Inbox param4=Today terminal=false refresh=true" & "\n"
        set logs to logs & "--  Upcoming | image='" & upcomingIcon & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Inbox param4=Upcoming terminal=false refresh=true" & "\n"
        set logs to logs & "--  Anytime | image='"  & anytimeIcon  & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Inbox param4=Anytime terminal=false refresh=true" & "\n"
        set logs to logs & "--  Someday | image='"  & somedayIcon  & "' shell='" & arg0 & "' param1=move-to param2='"  & todoName & "' param3=Inbox param4=Someday terminal=false refresh=true" & "\n"
        set logs to logs & "--  Delete | image='"   & deleteIcon   & "' shell='" & arg0 & "' param1=delete param2='"   & todoName & "' param3=Inbox terminal=false refresh=true" & "\n"
        set logs to logs & "--  Complete | image='" & completeIcon & "' shell='" & arg0 & "' param1=complete param2='" & todoName & "' param3=Inbox terminal=false refresh=true" & "\n"
      end repeat
    end if

    if count of completedTodos is greater than 0 or count of inboxCompletedTodos is greater than 0
      set logs to logs & "Completed" & "\n"
    end if
    if count of completedTodos is greater than 0
      repeat with todo in completedTodos
        set todoName to name of todo
        set logs to logs & "‚òë " & todoName & " | color=#666666 shell='" & arg0 & " terminal=false refresh=true'\n"
        set logs to logs & "-- Delete | shell='" & arg0 & "' param1=delete param2='" & todoName & "' param3=Today terminal=false refresh=true" & "\n"
      end repeat
    end if
    if count of inboxCompletedTodos is greater than 0
      repeat with todo in inboxCompletedTodos
        set todoName to name of todo
        set logs to logs & "‚òë " & todoName & " | color=#666666 shell='" & arg0 & " terminal=false refresh=true'\n"
        set logs to logs & "-- Delete | shell='" & arg0 & "' param1=delete param2='" & todoName & "' param3=Inbox terminal=false refresh=true" & "\n"
      end repeat
    end if
    if count of completedTodos is greater than 0 or count of inboxCompletedTodos is greater than 0
      set logs to logs & "Log Completed | color=#333333 shell='" & arg0 & "' param1=log-completed terminal=false refresh=true" & "\n"
    end if

    set logs to logs & "---" & "\n"

    set logs to logs & "New Todo | shell='" & arg0 & "' param1=new-todo terminal=false refresh=true" & "\n"
    set logs to logs & "Open Things | shell='" & arg0 & "' param1=launch terminal=false"
  end if

  ### PRINT STDOUT ###
  copy logs to stdout
end run
