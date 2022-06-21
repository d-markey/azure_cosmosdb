@ECHO OFF
SET __ARGS__=
SET __COV__=1
SET __COMMIT__=0

:parse
IF "%~1"=="" GOTO endparse
IF "%~1"=="/nocov" (
    set __COV__=0
) ELSE IF "%~1"=="--nocov" (
    set __COV__=0
) ELSE IF "%~1"=="-nc" (
    set __COV__=0
) ELSE IF "%~1"=="/nc" (
    set __COV__=0
IF "%~1"=="/commit" (
    set __COMMIT__=1
) ELSE IF "%~1"=="--commit" (
    set __COMMIT__=1
) ELSE IF "%~1"=="-c" (
    set __COMMIT__=1
) ELSE IF "%~1"=="/c" (
    set __COMMIT__=1
) ELSE (
    set __ARGS__=%__ARGS__% "%~1"
)
SHIFT
GOTO parse
:endparse

rmdir .\test\coverage /s /q
mkdir .\test\coverage
CALL dart run test --coverage=.\test\coverage %__ARGS__%
IF "%__COV__%" == "1" (
    CALL dart run coverage:format_coverage --packages=.dart_tool\package_config.json --report-on=lib --lcov -o .\test\coverage\lcov.info -i .\test\coverage
    rmdir .\coverage /s /q
    java -jar .\tool\jgenhtml\jgenhtml-1.5.jar .\test\coverage\lcov.info --output-directory .\coverage  
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
