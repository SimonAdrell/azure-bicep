module app 'modules/appService.bicep' = {
  name: 'pomodoroAppService'
  params: {
    location: 'westeurope'
    environmentType: 'nonprod'
    appServiceAppName: 'pomodoro-app-service'
    repoURL: 'https://github.com/SimonAdrell/pomodoroTimer.git'
  }
}
