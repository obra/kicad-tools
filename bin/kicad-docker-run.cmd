@echo off
REM Docker config

if %DOCKER_CMD_PATH%=="" set DOCKER_CMD_PATH=docker
if %DOCKER_CONTAINER%=="" set DOCKER_CONTAINER=kicad-automation

set DOCKER_RUN=%DOCKER_CMD_PATH% run --rm -it %DOCKER_VOLUMES% %DOCKER_CONTAINER% %*

%DOCKER_RUN%
