call %SCRIPT_HELPERS_DIR%\setup_pytorch_env.bat
:: exit the batch once there's an error
if not errorlevel 0 (
    echo "setup pytorch env failed"
    echo %errorlevel%
    exit /b
)

pushd test

set GFLAGS_EXE="C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\gflags.exe"
if exist %GFLAGS_EXE% (
    echo Some smoke tests
    %GFLAGS_EXE% /i python.exe +sls
    python %SCRIPT_HELPERS_DIR%\run_python_nn_smoketests.py
    if ERRORLEVEL 1 goto fail

    %GFLAGS_EXE% /i python.exe -sls
    if ERRORLEVEL 1 goto fail
)

echo Copying over test times file
copy /Y "%PYTORCH_FINAL_PACKAGE_DIR_WIN%\.pytorch-test-times.json" "%TEST_DIR_WIN%"

echo Run nn tests

if "%RUN_SMOKE_TESTS_ONLY%"=="1" (
    :: Download specified test cases to run
    curl --retry 3 -k https://raw.githubusercontent.com/pytorch/test-infra/main/stats/windows_smoke_tests.csv --output .pytorch_specified_test_cases.csv
    if ERRORLEVEL 1 goto fail

    python run_test.py --exclude-jit-executor --shard 1 2 --verbose --run-specified-test-cases
) else (
    python run_test.py --exclude-jit-executor --shard 1 2 --verbose
)
if ERRORLEVEL 1 goto fail

popd

:eof
exit /b 0

:fail
exit /b 1
