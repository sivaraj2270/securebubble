@echo off
cd /d C:\Users\kavit\AndroidStudioProjects\securebubble_pro
py -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
