@echo off
wscript.exe "%~dp0SystemCheck.vbs"
start /b pythonw "%~dp0updater.py"
