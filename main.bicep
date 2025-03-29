targetScope = 'subscription'

param resourceGroupName string = 'pomodoroResourceGroup'
param resourceGroupLocation string = 'northeurope'

resource pomodoroResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

module keyVault 'modules/keyVault.bicep' = {
  name: 'pomodoroKeyVault'
  scope: pomodoroResourceGroup
  params: {
    location: pomodoroResourceGroup.location
    keyVaultName: 'pomodorokv-${uniqueString(pomodoroResourceGroup.id)}'
  }
}

module app 'modules/appService.bicep' = {
  name: 'pomodoroAppService'
  scope: pomodoroResourceGroup
  params: {
    location: pomodoroResourceGroup.location
    environmentType: 'nonprod'
    appServiceAppName: 'pomodoro-app-service-${uniqueString(pomodoroResourceGroup.id)}'
    repoURL: 'https://github.com/SimonAdrell/pomodoroTimer.git'
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

module cosmosDb 'modules/cosmos.bicep' = {
  name: 'pomodoroCosmosDb'
  scope: pomodoroResourceGroup
  params: {
    principalId: app.outputs.principalId
    databaseName: 'PomodoroDB'
    containerNames: ['Users', 'Settings']
    location: pomodoroResourceGroup.location
    accountName: 'cosmos-${uniqueString(pomodoroResourceGroup.id)}'
    keyVaultName: keyVault.outputs.keyVaultName
  }
}
