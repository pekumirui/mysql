param location string = resourceGroup().location

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
              memoryInGB: 4
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
            shareName: 'sql'
            storageAccountName: 'stockdbmount'
            storageAccountKey: 'vBogSp/mPLEUO2JBzOCpaUE3/cTDLnujEXHZGbGG8FYeNQ/74a3uxX9ANlyDuISmtAM4vUq6Craq+AStGSHA7A=='
        }
      }
      {
        name: 'sqldata'
        azureFile: {
            shareName: 'data'
            storageAccountName: 'stockdbmount'
            storageAccountKey: 'vBogSp/mPLEUO2JBzOCpaUE3/cTDLnujEXHZGbGG8FYeNQ/74a3uxX9ANlyDuISmtAM4vUq6Craq+AStGSHA7A=='
        }
      }
    ]
  }
}

