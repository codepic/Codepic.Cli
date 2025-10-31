module resourceAbbreviations './resourceAbbreviations.bicep' = {
  name: 'resourceAbbreviations'
}

output abbreviations object = resourceAbbreviations.outputs.abbreviations
