@echo off
REM Script para gerar o parser ANTLR4 para Dart

REM Define o caminho para o JAR local
set LOCAL_JAR=%~dp0antlr-4.13.2-complete.jar

REM Verifica se o JAR local existe
IF EXIST "%LOCAL_JAR%" (
    echo Usando ANTLR JAR local: %LOCAL_JAR%
    java -jar "%LOCAL_JAR%" -Dlanguage=Dart -visitor -o lib/src/generated lib/src/grammar/CSubset.g4
    goto :end
)

REM Verifica se a variável ANTLR_JAR está definida
IF DEFINED ANTLR_JAR (
    echo Usando ANTLR_JAR definido em: %ANTLR_JAR%
    java -jar "%ANTLR_JAR%" -Dlanguage=Dart -visitor -o lib/src/generated lib/src/grammar/CSubset.g4
    goto :end
)

REM Tenta usar o comando do sistema (pode falhar se for versão antiga)
WHERE antlr4 >nul 2>nul
IF %ERRORLEVEL% EQU 0 (
    echo Usando comando 'antlr4' do PATH...
    antlr4 -Dlanguage=Dart -visitor -o lib/src/generated lib/src/grammar/CSubset.g4
    goto :end
)

REM Se falhar, avisa o usuário
echo [ERRO] Nao foi possivel encontrar o ANTLR4 compativel.
echo O script tentou procurar em: %LOCAL_JAR%
echo Por favor, certifique-se de que o arquivo antlr-4.13.2-complete.jar esteja na pasta tool/
exit /b 1

:end
echo Geracao concluida com sucesso!
