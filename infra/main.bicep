targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('Resource group name')
param resourceGroupName string = ''

@description('User\'s principal id')
param principalId string

@minLength(1)
@description('Primary location for all resources')
param location string

var abbrs = loadJsonContent('./abbreviations.json')
var uniqueSuffix = substring(uniqueString(subscription().id, environmentName), 1, 5)
@description('IP address to allow for Cognitive Service connection')
param ipAddress string = ''

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
  'SecurityControl': 'Ignore'
}

//OpenAI Module Parameters
@description('OpenAI resource name')
param openaiName string = ''

//Speech Module Parameters
@description('Speech service resource name')
param speechServiceName string = ''
//Face Module Parameters
@description('Face service resource name')
param faceServiceName string = ''
//Vision Module Parameters
@description('Vision service resource name')
param visionServiceName string = ''
@description('App Service resource name')
param appServiceName string = ''
@description('AppServerFarm service resource name')
param appServerFarmName string = ''

var names = {
  resourceGroupName: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  openaiName: !empty(openaiName) ? openaiName : '${abbrs.cognitiveServicesOpenAI}${environmentName}-${uniqueSuffix}'
  speechServiceName: !empty(speechServiceName) ? speechServiceName : '${abbrs.cognitiveServicesSpeech}${environmentName}-${uniqueSuffix}'
  faceServiceName: !empty(faceServiceName) ? faceServiceName : '${abbrs.cognitiveServicesFace}${environmentName}-${uniqueSuffix}'
  visionServiceName: !empty(visionServiceName) ? visionServiceName : '${abbrs.cognitiveServicesVision}${environmentName}-${uniqueSuffix}'
  appServiceName: !empty(appServiceName) ? appServiceName : '${abbrs.webSitesAppService}${environmentName}-${uniqueSuffix}'
  appServerFarmName: !empty(appServerFarmName) ? appServerFarmName :'${abbrs.webServerFarms}${environmentName}-${uniqueSuffix}'
}


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module m_vnet 'modules/vnet.bicep' = {
  name: 'deploy_vnet'
  scope: rg
  params: {
    location: location
    tags: tags
    appServiceName: names.appServiceName
  }
}



  

module m_openai 'modules/openai.bicep' = {
  name: 'deploy_openai'
  scope: rg
  params: {
    location: location
    principalId: principalId
    ipAddress: ipAddress
    openaiName: names.openaiName
    tags: tags
    appServiceName: names.appServiceName
  }
  dependsOn: [
    m_vnet
  ]
}


module m_speech 'modules/speech.bicep' = {
  name: 'deploy_speech'
  scope: rg
  params: {
    location: location
    principalId: principalId
    ipAddress: ipAddress
    speechServiceName: names.speechServiceName
    tags: tags
    appServiceName: names.appServiceName
  }
  dependsOn: [
    m_vnet
  ]
}


module m_face 'modules/face.bicep' = {
  name: 'deploy_face'
  scope: rg
  params: {
    location: location
    principalId: principalId
    ipAddress: ipAddress
    faceServiceName: names.faceServiceName
    tags: tags
    appServiceName: names.appServiceName
  }
  dependsOn: [
    m_vnet
  ]
}

module m_vision 'modules/vision.bicep' = {
  name: 'deploy_vision'
  scope: rg
  params: {
    location: location
    principalId: principalId
    ipAddress: ipAddress
    visionServiceName: names.visionServiceName
    tags: tags
    appServiceName: names.appServiceName
  }
  dependsOn: [
    m_vnet
  ]
}

module m_appService 'modules/webapp.bicep' = {
  name: 'deploy_appService'
  scope: rg
  params: {
    location: location
    appServiceName: names.appServiceName
    appServerFarmName: names.appServerFarmName
    tags: tags
    facekey: m_face.outputs.apikey
    faceendpoint: m_face.outputs.endpoint
    visionkey: m_vision.outputs.apikey
    visionendpoint: m_vision.outputs.endpoint
    speechkey: m_speech.outputs.apikey
    speechendpoint: m_speech.outputs.endpoint
    openaikey: m_openai.outputs.apikey
    openaiendpoint: m_openai.outputs.endpoint
  }
}



// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output SPEECH_SERVICE_ID string = m_speech.outputs.speechid
output FACE_SERVICE_ID string = m_face.outputs.faceid
output OPENAI_SERVICE_ID string = m_openai.outputs.openaiid
output AZURE_OPENAI_CHAT_DEPLOYMENT_NAME string = m_openai.outputs.deploymentName
output AZURE_OPENAI_ENDPOINT string = m_openai.outputs.endpoint
output VISION_ENDPOINT string = m_vision.outputs.endpoint
output FACE_ENDPOINT string = m_face.outputs.endpoint
output SPEECH_ENDPOINT string = m_speech.outputs.endpoint
