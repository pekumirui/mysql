param location string = resourceGroup().location
param StorageAcountName string = 'stockdbmount'
param StorageAccountSKU string ='Standard_LRS'

var userAssignedIdentityName = 'configDeployer'
var roleAssignmentName = guid(resourceGroup().id, 'contributor')
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: 'mysqlapp'
  location: location
  properties: {
    containers: [
      {
        name: 'mysqlapp'
        properties: {
          image: 'pekumirui/mysql'
          ports: [
            {
              port: 3306
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          volumeMounts: [
            {
            name: 'initdata'
            mountPath: '/docker-entrypoint-initdb.d'            
            }
            {
              name: 'sqldata'
              mountPath: '/var/lib/mysql'
            }
          ]
          environmentVariables:[
            {
              name:'MYSQL_ROOT_PASSWORD'
              value:'6539Eryu'
            }
          ]
        }
      }
    ]
    restartPolicy: 'OnFailure'
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'TCP'
          port: 3306
        }
      ]
      dnsNameLabel: 'mysql-demo'
    }
    volumes: [
      {
        name: 'initdata'
        azureFile: {
            shareName: initdata.name
            storageAccountName: mysqlstorage.name
            storageAccountKey: mysqlstorage.listKeys().keys[0].value
        }
      }
      {
        name: 'sqldata'
        azureFile: {
            shareName: sqldata.name
            storageAccountName: mysqlstorage.name
            storageAccountKey: mysqlstorage.listKeys().keys[0].value
        }
      }
    ]
  }
  dependsOn: [
    uploadinitsqlfile
  ]
}
resource mysqlstorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAcountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: StorageAccountSKU
  }
}

resource fileservice 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  name: 'default'
  parent: mysqlstorage
}

resource initdata 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: 'sql'
  parent: fileservice
}

resource sqldata 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: 'data'
  parent: fileservice
}


resource uploadinitsqlfile 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'uploadinitsqlfile'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.40.0'
    timeout: 'PT30M'
    arguments: '\'foo\' \'bar\''
    environmentVariables: [
      {
        name: 'storageAccountKey'
        value: mysqlstorage.listKeys().keys[0].value
      }
      {
        name: 'storageAccountName'
        secureValue: mysqlstorage.name
      }
      {
        name: 'sharename'
        secureValue: initdata.name
      }
      {
        name: 'filepath'
        secureValue: './DB/test.sql'
      }
    ]
    scriptContent: 'az storage file upload --account-key $storageAccountKey --account-name $storageAccountName --share-name $sharename --source $filepath'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    roleAssignment
  ]
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
