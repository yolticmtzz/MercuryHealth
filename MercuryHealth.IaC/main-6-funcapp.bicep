// The following will create an Azure Function app on
// a consumption plan, along with a storage account

param location string = resourceGroup().location
param functionRuntime string = 'dotnet'
param functionExtensionVersion string = '~4'

//param appNamePrefix string = uniqueString(resourceGroup().id)
//param workspaceResourceId string
param functionAppName string
param functionAppServiceName string
param appInsightsInstrumentationKey string
//var appInsightsName = '${appNamePrefix}-appinsights'
param defaultTags object

// remove dashes for storage account name
//var storageAccountName = format('{0}sta', replace(appNamePrefix, '-', ''))
//var storageAccountName = replace(appNamePrefix, '-', '')
var storageAccountName = uniqueString(resourceGroup().id)

// var appTags = {
//   AppID: 'myfunc'
//   AppName: 'My Function App'
// }

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    accessTier: 'Hot'
  }
}
// resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
//   name: storageAccountName
//   location: location
//   tags: defaultTags
//   sku: {
//     name: 'Standard_LRS'
//   }
//   kind: 'StorageV2'
//   properties: {
//     supportsHttpsTrafficOnly: true
//     encryption: {
//       services: {
//         file: {
//           keyType: 'Account'
//           enabled: true
//         }
//         blob: {
//           keyType: 'Account'
//           enabled: true
//         }
//       }
//       keySource: 'Microsoft.Storage'
//     }
//     accessTier: 'Hot'
//   }
// }

// Blob Services for Storage Account
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// App Service
resource appService 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: functionAppServiceName
  location: location
  kind: 'functionapp'
  tags: defaultTags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2021-01-15' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  tags: defaultTags
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${functionAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${functionAppName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
    ]
    serverFarmId: appService.id
    reserved: false
    isXenon: false
    hyperV: false
    siteConfig: {
      appSettings: [
        {
          name: 'ApimSubscriptionKey'
          value: 'e2d1cf7c5b0.........TBD'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsInstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: functionExtensionVersion
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
  }
}

// Function App Config
resource functionAppConfig 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: functionApp
  name: 'web'
  properties: {
    numberOfWorkers: -1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    phpVersion: '5.6'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$${functionAppName}'
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    cors: {
      allowedOrigins: [
        'https://functions.azure.com'
        'https://functions-staging.azure.com'
        'https://functions-next.azure.com'
      ]
      supportCredentials: false
    }
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    ftpsState: 'AllAllowed'
    preWarmedInstanceCount: 0
  }
}

// Function App Binding
resource functionAppBinding 'Microsoft.Web/sites/hostNameBindings@2021-01-15' = {
  parent: functionApp
  name: '${functionApp.name}.azurewebsites.net'
  properties: {
    siteName: functionApp.name
    hostNameType: 'Verified'
  }
}
