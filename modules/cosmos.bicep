@description('Cosmos DB account name')
param accountName string = 'cosmos-${uniqueString(resourceGroup().id)}'

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The name for the database')
param databaseName string

@description('The name for the containers')
param containerNames array = [
  'Users'
  'Settings'
]

param keyVaultName string

resource account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: toLower(accountName)
  location: location
  properties: {
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: account
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 1000
    }
  }
}

// resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = [
//   for name in containerNames: {
//     parent: database
//     name: name
//     properties: {
//       resource: {
//         id: name
//         partitionKey: {
//           paths: [
//             '/partitionKey'
//           ]
//         }
//         indexingPolicy: {
//           indexingMode: 'consistent'
//           includedPaths: [
//             {
//               path: '/*'
//             }
//           ]
//           excludedPaths: [
//             {
//               path: '/_etag/?'
//             }
//           ]
//         }
//       }
//     }
//   }
// ]

@description('Principal ID of the managed identity')
param principalId string

var roleDefId = guid('sql-role-definition-', principalId, account.id)
var roleDefName = 'Custom Read/Write role'

resource roleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-06-15' = {
  parent: account
  name: roleDefId
  properties: {
    roleName: roleDefName
    type: 'CustomRole'
    assignableScopes: [
      account.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
        ]
      }
    ]
  }
}

var roleAssignId = guid(roleDefId, principalId, account.id)

resource roleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-06-15' = {
  parent: account
  name: roleAssignId
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: principalId
    scope: account.id
  }
}

output endpoint string = account.properties.documentEndpoint

module setKey 'setSecret.bicep' = {
  name: 'setKeySecret'
  params: {
    keyVaultName: keyVaultName
    secretName: 'cosmosKey'
    secretValue: account.properties.documentEndpoint
  }
}
