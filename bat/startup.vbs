set ws=WScript.CreateObject("WScript.Shell")
ws.currentdirectory = "C:\Users\Think\AppData\Local\YOURDIR\"
ws.run "cmd /c app.exe -p hhhhh",vbhide