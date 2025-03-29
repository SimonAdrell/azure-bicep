param location string
param appServiceAppName string
param keyVaultName string

@allowed([
  'nonprod'
  'prod'
])
param environmentType string

var appServicePlanName = 'pomodoro-launch-plan'
var appServicePlanSkuName = (environmentType == 'prod') ? 'P2v3' : 'F1'

@description('The URL for the GitHub repository that contains the project to deploy.')
param repoURL string

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
}

resource appServiceApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceAppName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'keyVault'
          value: keyVaultName
        }
      ]
    }
  }
}

resource sourceControl 'Microsoft.Web/sites/sourcecontrols@2023-01-01' = {
  parent: appServiceApp
  name: 'web'
  properties: {
    repoUrl: repoURL
    branch: 'main'
    isManualIntegration: false
  }
}

output principalId string = appServiceApp.identity.principalId
