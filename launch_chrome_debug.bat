@echo off
echo ===================================================
echo Starting Chrome with Remote Debugging for BloxChain
echo Debug Port: 9222
echo Profile Dir: c:\Users\Admin\Desktop\Game\chrome_profile_bloxchain
echo ===================================================
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir="c:\Users\Admin\Desktop\Game\chrome_profile_bloxchain" --no-first-run --no-default-browser-check "https://play.google.com/console"
