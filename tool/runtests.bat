@ECHO OFF
SET __ARGS__=
SET __COV__=0
SET __COMMIT__=0

:parse
IF "%~1"=="" (
    GOTO endparse
) ELSE IF "%~1"=="/cov" (
    SET __COV__=1
) ELSE IF "%~1"=="--cov" (
    SET __COV__=1
) ELSE IF "%~1"=="/commit" (
    SET __COMMIT__=1
) ELSE IF "%~1"=="--commit" (
    SET __COMMIT__=1
) ELSE (
    SET __ARGS__=%__ARGS__% "%~1"
)
SHIFT
GOTO parse
:endparse

RMDIR .\test\coverage /S /Q
MKDIR .\test\coverage
CALL dart test -j 1 --coverage=.\test\coverage %__ARGS__%
SET __ERRLVL__=%ERRORLEVEL%
IF %__ERRLVL__% NEQ 0 (
    ECHO Tests failed with exit code = %__ERRLVL__%
    EXIT /B %__ERRLVL__%
)
IF "%__COV__%" == "1" (
    CALL dart run coverage:format_coverage --packages=.dart_tool\package_config.json --report-on=lib --lcov -o .\test\coverage\lcov.info -i .\test\coverage
    RMDIR .\coverage /s /q
    java -jar .\tool\jgenhtml\jgenhtml-1.6.jar .\test\coverage\lcov.info --output-directory .\coverage  
    CALL dart run .\tool\xtractcov\main.dart

    IF "%__COMMIT__%" == "1" (
        git config --global user.name 'd-markey'
        git config --global user.email 'd-markey@users.noreply.github.com'
        git add ./coverage
        git add ./coverage.json
        git commit -am "Automated test coverage report"
        git push
    )
)
