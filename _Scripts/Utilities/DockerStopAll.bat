@ECHO OFF
FOR /f "tokens=*" %%i IN ('docker ps -q -as') DO docker rm -f %%i