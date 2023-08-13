# Chocolatey

## Troubleshooting: Running Scripts is Disabled

You might encounter the following error:

> *C:\temp\.\Script.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at https://go.microsoft.com/fwlink/?LinkID=135170*

Run the following to solve this problem:

```
Set-ExecutionPolicy RemoteSigned
```
