select sql || ";" from sqlite_master where tbl_name IN (
"crtCategories",
"crtCertificates",
"crtClasses",
"crtRecommendations",
"crtRelationships",
"dgmAttributeCategories",
"dgmAttributeTypes",
"dgmEffects",
"dgmTypeAttributes",
"dgmTypeEffects",
"eveIcons",
"eveUnits",
"invCategories",
"invControlTowerResourcePurposes",
"invControlTowerResources",
"invGroups",
"invMarketGroups",
"invMetaGroups",
"invMetaTypes",
"invTypes",
"mapConstellations",
"mapDenormalize",
"mapRegions",
"mapSolarSystems",
"ramActivities",
"staStations");