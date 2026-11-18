@echo off
rem Shows household budget leftovers (Groceries, Eating Out, allowances).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0expense-log.ps1" -Action leftovers
