@description('Strongly typed map of Azure region names to CAF geo codes for naming consistency.')
type RegionAbbreviations = {
  @description('Australia Central (Canberra, Australia); paired with Australia Central 2.')
  australiacentral: string
  @description('Australia Central 2 (Canberra, Australia); paired with Australia Central.')
  australiacentral2: string
  @description('Australia East (New South Wales, Australia); paired with Australia Southeast.')
  australiaeast: string
  @description('Australia Southeast (Victoria, Australia); paired with Australia East.')
  australiasoutheast: string
  @description('Austria East (Vienna, Austria); standalone region for Austria.')
  austriaeast: string
  @description('Brazil South (São Paulo State, Brazil); paired with South Central US.')
  brazilsouth: string
  @description('Brazil US (reserved access); companion region for Brazil-based resiliency scenarios.')
  brazilus: string
  @description('Brazil Southeast (Rio, Brazil); paired with Brazil South.')
  brazilsoutheast: string
  @description('Belgium Central (Brussels, Belgium); standalone region for Belgium.')
  belgiumcentral: string
  @description('Central US EUAP (limited-access Early Update Access Program in Iowa, United States).')
  centraluseuap: string
  @description('Canada Central (Toronto, Canada); paired with Canada East.')
  canadacentral: string
  @description('Canada East (Quebec, Canada); paired with Canada Central.')
  canadaeast: string
  @description('Central US (Iowa, United States); paired with East US 2.')
  centralus: string
  @description('Central US Stage (Iowa, United States); staging environment aligned with Central US.')
  centralusstage: string
  @description('Chile Central (Santiago, Chile); standalone region for Chile.')
  chilecentral: string
  @description('East Asia (Hong Kong SAR); paired with Southeast Asia.')
  eastasia: string
  @description('East Asia Stage (Hong Kong SAR); staging environment aligned with East Asia.')
  eastasiastage: string
  @description('East US 2 EUAP (limited-access Early Update Access Program in Virginia, United States).')
  eastus2euap: string
  @description('Spain Central (Madrid, Spain); standalone region for Iberia workloads.')
  spaincentral: string
  @description('East US (Virginia, United States); paired with West US.')
  eastus: string
  @description('East US 2 (Virginia, United States); paired with Central US.')
  eastus2: string
  @description('East US Stage (Virginia, United States); staging environment aligned with East US.')
  eastusstage: string
  @description('East US 2 Stage (Virginia, United States); staging environment aligned with East US 2.')
  eastus2stage: string
  @description('East US STG (Virginia, United States); staging environment aligned with East US.')
  eastusstg: string
  @description('France Central (Paris, France); paired with France South.')
  francecentral: string
  @description('France South (Marseille, France); paired with France Central.')
  francesouth: string
  @description('Germany North (Berlin, Germany); paired with Germany West Central.')
  germanynorth: string
  @description('Germany West Central (Frankfurt, Germany); paired with Germany North.')
  germanywestcentral: string
  @description('Central India (Pune, India); paired with South India.')
  centralindia: string
  @description('Indonesia Central (Jakarta, Indonesia); standalone region for Indonesia.')
  indonesiacentral: string
  @description('South India (Chennai, India); paired with Central India.')
  southindia: string
  @description('West India (Mumbai, India); paired with South India for resiliency.')
  westindia: string
  @description('Israel Central (Israel); standalone region for local residency.')
  israelcentral: string
  @description('Italy North (Milan, Italy); standalone region for Italy.')
  italynorth: string
  @description('Japan East (Tokyo/Saitama, Japan); paired with Japan West.')
  japaneast: string
  @description('Japan West (Osaka, Japan); paired with Japan East.')
  japanwest: string
  @description('Jio India Central (Indian partner region); supports private connectivity workloads.')
  jioindiacentral: string
  @description('Jio India West (Indian partner region); supports private connectivity workloads.')
  jioindiawest: string
  @description('Korea Central (Seoul, Korea); paired with Korea South.')
  koreacentral: string
  @description('Korea South (Busan, Korea); paired with Korea Central.')
  koreasouth: string
  @description('Malaysia West (Kuala Lumpur, Malaysia); standalone region for Malaysia.')
  malaysiawest: string
  @description('Mexico Central (Querétaro, Mexico); standalone region for Mexico.')
  mexicocentral: string
  @description('North Central US (Illinois, United States); paired with South Central US.')
  northcentralus: string
  @description('North Central US Stage (Illinois, United States); staging environment aligned with North Central US.')
  northcentralusstage: string
  @description('North Europe (Ireland); paired with West Europe.')
  northeurope: string
  @description('Norway East (Norway); paired with Norway West.')
  norwayeast: string
  @description('Norway West (Norway); paired with Norway East.')
  norwaywest: string
  @description('New Zealand North (Auckland, New Zealand); standalone region for New Zealand.')
  newzealandnorth: string
  @description('Poland Central (Warsaw, Poland); standalone region for Poland.')
  polandcentral: string
  @description('Qatar Central (Doha, Qatar); standalone region for Qatar.')
  qatarcentral: string
  @description('South Africa North (Johannesburg, South Africa); paired with South Africa West.')
  southafricanorth: string
  @description('South Africa West (Cape Town, South Africa); paired with South Africa North.')
  southafricawest: string
  @description('South Central US (Texas, United States); paired with North Central US.')
  southcentralus: string
  @description('South Central US Stage (Texas, United States); staging environment aligned with South Central US.')
  southcentralusstage: string
  @description('South Central US STG (Texas, United States); staging environment aligned with South Central US.')
  southcentralusstg: string
  @description('Sweden Central (Gävle, Sweden); paired with Sweden South.')
  swedencentral: string
  @description('Sweden South (Sweden); paired with Sweden Central.')
  swedensouth: string
  @description('Southeast Asia (Singapore); paired with East Asia.')
  southeastasia: string
  @description('Southeast Asia Stage (Singapore); staging environment aligned with Southeast Asia.')
  southeastasiastage: string
  @description('Switzerland North (Zurich, Switzerland); paired with Switzerland West.')
  switzerlandnorth: string
  @description('Switzerland West (Geneva, Switzerland); paired with Switzerland North.')
  switzerlandwest: string
  @description('UAE Central (Abu Dhabi, United Arab Emirates); paired with UAE North.')
  uaecentral: string
  @description('UAE North (Dubai, United Arab Emirates); paired with UAE Central.')
  uaenorth: string
  @description('UK South (London, United Kingdom); paired with UK West.')
  uksouth: string
  @description('UK West (Cardiff, United Kingdom); paired with UK South.')
  ukwest: string
  @description('West Central US (Wyoming, United States); paired with West US 2.')
  westcentralus: string
  @description('West US Stage (California, United States); staging environment aligned with West US.')
  westusstage: string
  @description('West Europe (Netherlands); paired with North Europe.')
  westeurope: string
  @description('West US (California, United States); paired with East US.')
  westus: string
  @description('West US 2 (Washington, United States); paired with West Central US.')
  westus2: string
  @description('West US 2 Stage (Washington, United States); staging environment aligned with West US 2.')
  westus2stage: string
  @description('West US 3 (Phoenix, United States); paired with East US.')
  westus3: string
  @description('USDoD Central (reserved U.S. Department of Defense region in the United States).')
  usdodcentral: string
  @description('USDoD East (reserved U.S. Department of Defense region in the United States).')
  usdodeast: string
  @description('USGov Arizona (Azure Government region located in Arizona, United States).')
  usgovarizona: string
  @description('USGov Iowa (Azure Government region located in Iowa, United States).')
  usgoviowa: string
  @description('USGov Texas (Azure Government region located in Texas, United States).')
  usgovtexas: string
  @description('USGov Virginia (Azure Government region located in Virginia, United States).')
  usgovvirginia: string
  @description('USNat East (restricted national cloud region for the United States, East).')
  usnateast: string
  @description('USNat West (restricted national cloud region for the United States, West).')
  usnatwest: string
  @description('USSec East (restricted secure national cloud region for the United States, East).')
  usseceast: string
  @description('USSec West (restricted secure national cloud region for the United States, West).')
  ussecwest: string
  @description('China North (Beijing, operated by 21Vianet); paired with China North 2.')
  chinanorth: string
  @description('China North 2 (Beijing, operated by 21Vianet); paired with China East 2.')
  chinanorth2: string
  @description('China North 3 (Beijing, operated by 21Vianet); additional capacity for northern China.')
  chinanorth3: string
  @description('China East (Shanghai, operated by 21Vianet); paired with China East 2.')
  chinaeast: string
  @description('China East 2 (Shanghai, operated by 21Vianet); paired with China North 2.')
  chinaeast2: string
  @description('China East 3 (Shanghai, operated by 21Vianet); additional capacity for eastern China.')
  chinaeast3: string
  @description('Germany Central (legacy sovereign cloud region); operated for specific compliance scenarios.')
  germanycentral: string
  @description('Germany North East (legacy sovereign cloud region); operated for specific compliance scenarios.')
  germanynortheast: string
  @description('Asia Pacific geography scope (logical region grouping used for staging and global services).')
  asiapacific: string
  @description('Global geography scope (logical region grouping used for global services).')
  global: string
  @description('Taiwan (Taipei, Taiwan); logical geography entry for services with Taiwan scope.')
  taiwan: string
  @description('United States geography scope aggregating US regions.')
  unitedstates: string
  @description('United States EUAP (Early Update Access Program geography scope for US canary deployments).')
  unitedstateseuap: string
}

var regionAbbreviations = {
  australiacentral: 'acl'
  australiacentral2: 'acl2'
  australiaeast: 'ae'
  australiasoutheast: 'ase'
  austriaeast: 'ate'
  brazilsouth: 'brs'
  brazilus: 'bru'
  brazilsoutheast: 'bse'
  belgiumcentral: 'bec'
  centraluseuap: 'ccy'
  canadacentral: 'cnc'
  canadaeast: 'cne'
  centralus: 'cus'
  centralusstage: 'cust'
  chilecentral: 'clc'
  eastasia: 'ea'
  eastasiastage: 'easg'
  eastus2euap: 'ecy'
  spaincentral: 'esc'
  eastus: 'eus'
  eastus2: 'eus2'
  eastusstage: 'eust'
  eastus2stage: 'e2st'
  eastusstg: 'eusg'
  francecentral: 'frc'
  francesouth: 'frs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  centralindia: 'inc'
  indonesiacentral: 'idc'
  southindia: 'ins'
  westindia: 'inw'
  israelcentral: 'ilc'
  italynorth: 'itn'
  japaneast: 'jpe'
  japanwest: 'jpw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'krc'
  koreasouth: 'krs'
  malaysiawest: 'myw'
  mexicocentral: 'mxc'
  northcentralus: 'ncus'
  northcentralusstage: 'ncst'
  northeurope: 'ne'
  norwayeast: 'nwe'
  norwaywest: 'nww'
  newzealandnorth: 'nzn'
  polandcentral: 'plc'
  qatarcentral: 'qac'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scus'
  southcentralusstage: 'scst'
  southcentralusstg: 'scsg'
  swedencentral: 'sdc'
  swedensouth: 'sds'
  southeastasia: 'sea'
  southeastasiastage: 'seag'
  switzerlandnorth: 'szn'
  switzerlandwest: 'szw'
  uaecentral: 'uac'
  uaenorth: 'uan'
  uksouth: 'uks'
  ukwest: 'ukw'
  westcentralus: 'wcus'
  westeurope: 'we'
  westus: 'wus'
  westusstage: 'wust'
  westus2: 'wus2'
  westus2stage: 'w2st'
  westus3: 'wus3'
  usdodcentral: 'udc'
  usdodeast: 'ude'
  usgovarizona: 'uga'
  usgoviowa: 'ugi'
  usgovtexas: 'ugt'
  usgovvirginia: 'ugv'
  usnateast: 'exe'
  usnatwest: 'exw'
  usseceast: 'rxe'
  ussecwest: 'rxw'
  chinanorth: 'bjb'
  chinanorth2: 'bjb2'
  chinanorth3: 'bjb3'
  chinaeast: 'sha'
  chinaeast2: 'sha2'
  chinaeast3: 'sha3'
  germanycentral: 'gec'
  germanynortheast: 'gne'
  asiapacific: 'apac'
  global: 'gbl'
  taiwan: 'twn'
  unitedstates: 'usa'
  unitedstateseuap: 'usae'
}

output abbreviations RegionAbbreviations = regionAbbreviations
