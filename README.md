# win-ssh-setup
Script to install OpenSSH, enable the service, add ssh user, setting privileges and hide it from Windows login



#### Fully automated installation via CMD

``` Remote source
powershell -Command "& {Start-Process powershell -ArgumentList \"-NoProfile -ExecutionPolicy Bypass -Command `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/nyok1912/win-ssh-setup/main/setup.ps1'))).Invoke('myUser', 'myPassword');`]\" -Verb RunAs}"
```


* Just download and run [setup.bat](https://raw.githack.com/nyok1912/win-ssh-setup/main/setup.bat) then answer the prompts when given


``` Local setup.bat
setup.bat user myUser pass myPassword
```


## Wizard installation via POWERSHELL

```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-Expression "& { $(Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/nyok1912/win-ssh-setup/main/setup.ps1') }"
```

## Fully automated installation via POWERSHELL passing user and password inline

#### powershell as current user (With privilege scale trick)

```
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/nyok1912/win-ssh-setup/main/setup.ps1'))).Invoke('myUser', 'myPassword');`]" -Verb RunAs
```

#### powershell running as administrator
```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/nyok1912/win-ssh-setup/main/setup.ps1'))).Invoke('myUser', 'myPassword');
```
