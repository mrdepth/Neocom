//
//  main.m
//  NCDatabase
//
//  Created by Артем Шиманский on 03.05.14.
//
//

#import "EVEDBAPI.h"
#import "NCDatabase.h"
#import "NSString+HTML.h"

#define NCDBCertMasteryLevelIconsStartID 1000000
#define NCDBCertCertificateDisplayNameTranslationColumnID 1000
#define NCDBCertCertificateDescriptionTranslationColumnID 1001
#define NCDBCertMasteryLevelDisplayNameTranslationColumnID 1002
#define NCDBInvControlTowerResourcePurposeDisplayNameTranslationColumnID 1003
#define NCDBRamAssemblyLineTypeDisplayNameTranslationColumnID 1004


int32_t lastUserDefinedIconID = 2000000;

NSDictionary* eveIcons;
NSDictionary* eveUnits;
NSDictionary* invTypes;
NSDictionary* invGroups;
NSDictionary* invCategories;
NSDictionary* invMetaGroups;
NSDictionary* invMetaTypes;
NSDictionary* invMarketGroups;
NSDictionary* dgmAttributeCategories;
NSDictionary* dgmAttributeTypes;
NSDictionary* dgmEffects;
NSDictionary* certCertificates;
NSDictionary* certMasteryLevels;
NSDictionary* certMasteries;
NSDictionary* invControlTowerResourcePurposes;
NSDictionary* mapRegions;
NSDictionary* mapConstellations;
NSDictionary* mapSolarSystems;
NSDictionary* staStations;
NSDictionary* ramActivities;
NSDictionary* ramAssemblyLineTypes;
NSDictionary* staStations;
NSDictionary* chrRaces;

NSMutableDictionary* baseTranslations;

static NSManagedObjectModel *managedObjectModel()
{
    static NSManagedObjectModel *model = nil;
    if (model != nil) {
        return model;
    }
    
	NSString *path = [[NSProcessInfo processInfo] arguments][0];
	path = [path stringByDeletingPathExtension];
    NSURL *modelURL = [NSURL fileURLWithPath:[path stringByAppendingPathExtension:@"momd"]];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return model;
}

static NSManagedObjectContext *managedObjectContext()
{
    static NSManagedObjectContext *context = nil;
    if (context != nil) {
        return context;
    }

    @autoreleasepool {
        context = [[NSManagedObjectContext alloc] init];
        
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel()];
        [context setPersistentStoreCoordinator:coordinator];
        
        NSString *STORE_TYPE = NSSQLiteStoreType;
        
        NSString *path = @"./NCDatabase";
        NSURL *url = [NSURL fileURLWithPath:[path stringByAppendingPathExtension:@"sqlite"]];
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        
        NSError *error;
        NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:STORE_TYPE
																configuration:nil
																		  URL:url
																	  options:@{NSSQLitePragmasOption:@{@"journal_mode": @"OFF"}}
																		error:&error];
        
        if (newStore == nil) {
            NSLog(@"Store Configuration Failure %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
        }
    }
    return context;
}

NSDictionary* convertEveIcons(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from eveIcons" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBEveIcon* eveIcon = [[EVEDBEveIcon alloc] initWithStatement:stmt];
		NSString* iconImageName = nil;
		if ([eveIcon.iconFile hasPrefix:@"res:/"])
			iconImageName = [NSString stringWithFormat:@"./Icons/%@", [eveIcon.iconFile lastPathComponent]];
		else
			iconImageName = [NSString stringWithFormat:@"./Icons/icon%@.png", eveIcon.iconFile];
		
		NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
		if (data) {
			NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
			icon.iconFile = eveIcon.iconFile;
			icon.image = imageRep;
			dictionary[@(eveIcon.iconID)] = icon;
		}
	}];
	
	for (int i = 0; i <= 5; i++) {
		NSString* iconImageName = [NSString stringWithFormat:@"./Icons/icon79_0%d", i + 1];
		NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
		if (data) {
			NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
			icon.iconFile = [iconImageName lastPathComponent];
			icon.image = imageRep;
			dictionary[@(NCDBCertMasteryLevelIconsStartID + i)] = icon;
		}
	}
	
	[database execSQLRequest:@"SELECT * FROM ramActivities" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBRamActivity* eveActivity = [[EVEDBRamActivity alloc] initWithStatement:stmt];
		if (eveActivity.iconNo) {
			__block EVEDBEveIcon* eveIcon = nil;
			[database execSQLRequest:[NSString stringWithFormat:@"select * from eveIcons where iconFile=\"%@\"", eveActivity.iconNo]
						 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
							 *needsMore = NO;
							 eveIcon = [[EVEDBEveIcon alloc] initWithStatement:stmt];
						 }];
			if (!eveIcon) {
				NCDBEveIcon* icon = dictionary[eveActivity.iconNo];
				if (!icon) {
					NSString* iconImageName = [NSString stringWithFormat:@"./Icons/icon%@.png", eveActivity.iconNo];
					
					NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
					if (data) {
						NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
						NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
						icon.iconFile = eveActivity.iconNo;
						icon.image = imageRep;
						dictionary[eveActivity.iconNo] = icon;
					}
				}
			}
		}
	}];
	
	[database execSQLRequest:@"SELECT * FROM npcGroup WHERE iconName IS NOT NULL GROUP BY iconName" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBNpcGroup* eveNpcGroup = [[EVEDBNpcGroup alloc] initWithStatement:stmt];
		NSString* iconImageName = [NSString stringWithFormat:@"./Factions/%@@2x.png", [eveNpcGroup.iconName stringByDeletingPathExtension]];
		
		NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
		if (data) {
			NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
			icon.iconFile = eveNpcGroup.iconName;
			icon.image = imageRep;
			dictionary[eveNpcGroup.iconName] = icon;
		}
	}];
	
	[database execSQLRequest:@"SELECT * FROM invTypes WHERE imageName IS NOT NULL GROUP BY imageName" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvType* eveType = [[EVEDBInvType alloc] initWithStatement:stmt];
		NSString* iconImageName = [NSString stringWithFormat:@"./Types/%@.png", eveType.imageName];
		NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
		if (data) {
			NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
			icon.iconFile = [NSString stringWithFormat:@"%@.png", eveType.imageName];
			icon.image = imageRep;
			dictionary[eveType.imageName] = icon;
		}
	}];
	
	return dictionary;
}

NSDictionary* convertEveUnits(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from eveUnits" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBEveUnit* eveUnit = [[EVEDBEveUnit alloc] initWithStatement:stmt];
		NCDBEveUnit* unit = [NSEntityDescription insertNewObjectForEntityForName:@"EveUnit" inManagedObjectContext:context];
		unit.unitID = eveUnit.unitID;
		dictionary[@(unit.unitID)] = unit;
		
		NCDBTrnTranslation* displayNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		displayNameTranslation.keyID = eveUnit.unitID;
		displayNameTranslation.columnID = 58;
		displayNameTranslation.text = eveUnit.displayName;
	}];
	
	return dictionary;
}

NSDictionary* convertInvTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from invTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvType* eveType = [[EVEDBInvType alloc] initWithStatement:stmt];
		NCDBEveIcon* icon = eveType.imageName ? dictionary[eveType.imageName] : nil;
		
		NCDBInvType* type = [NSEntityDescription insertNewObjectForEntityForName:@"InvType" inManagedObjectContext:context];
		type.typeID = eveType.typeID;
		type.typeName = eveType.typeName;
		type.basePrice = eveType.basePrice;
		type.capacity = eveType.capacity;
		type.mass = eveType.mass;
		type.portionSize = eveType.portionSize;
		type.published = eveType.published;
		type.radius = eveType.radius;
		type.volume = eveType.volume;
		type.group = invGroups[@(eveType.groupID)];
		type.marketGroup = eveType.marketGroupID ? invMarketGroups[@(eveType.marketGroupID)] : nil;
		type.race = eveType.raceID ? chrRaces[@(eveType.raceID)] : nil;
		
		if (icon)
			type.icon = icon;
		else {
			if (eveType.iconID > 0) {
				type.icon = eveIcons[@(eveType.iconID)];
			}
		}
		
		dictionary[@(eveType.typeID)] = type;
		
		NSString* s = [[eveType.description stringByRemovingHTMLTags] stringByReplacingHTMLEscapes];
		NSMutableString* description = [NSMutableString stringWithString:s ? s : @""];
		[description replaceOccurrencesOfString:@"\\r" withString:@"" options:0 range:NSMakeRange(0, description.length)];
		[description replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, description.length)];
		[description replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, description.length)];
		
		if (eveType.traitsString.length > 0) {
			[description appendFormat:@"\n%@", eveType.traitsString];
		}
		
		NCDBTrnTranslation* typeNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		typeNameTranslation.keyID = type.typeID;
		typeNameTranslation.columnID = 8;
		typeNameTranslation.text = eveType.typeName;

		NCDBTrnTranslation* descriptionTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		descriptionTranslation.keyID = type.typeID;
		descriptionTranslation.columnID = 33;
		descriptionTranslation.text = description;
	}];
	
	return dictionary;
}

NSDictionary* convertInvCategories(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];

	[database execSQLRequest:@"select * from invCategories" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvCategory* eveCategory = [[EVEDBInvCategory alloc] initWithStatement:stmt];
		NCDBInvCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"InvCategory" inManagedObjectContext:context];
		category.categoryID = eveCategory.categoryID;
		category.icon = eveCategory.iconID ? eveIcons[@(eveCategory.iconID)] : nil;
		
		dictionary[@(category.categoryID)] = category;
		
		NCDBTrnTranslation* categoryNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		categoryNameTranslation.keyID = eveCategory.categoryID;
		categoryNameTranslation.columnID = 6;
		categoryNameTranslation.text = eveCategory.categoryName;
	}];
	
	return dictionary;
}

NSDictionary* convertInvGroups(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from invGroups" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvGroup* eveGroup = [[EVEDBInvGroup alloc] initWithStatement:stmt];
		NCDBInvGroup* group = [NSEntityDescription insertNewObjectForEntityForName:@"InvGroup" inManagedObjectContext:context];
		group.groupID = eveGroup.groupID;
		group.category = invCategories[@(eveGroup.categoryID)];
		group.icon = eveGroup.iconID ? eveIcons[@(eveGroup.iconID)] : nil;
		
		dictionary[@(group.groupID)] = group;
		
		NCDBTrnTranslation* groupNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		groupNameTranslation.keyID = eveGroup.groupID;
		groupNameTranslation.columnID = 7;
		groupNameTranslation.text = eveGroup.groupName;

	}];

	return dictionary;
}

NSDictionary* convertInvMetaGroups(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from invMetaGroups" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvMetaGroup* eveMetaGroup = [[EVEDBInvMetaGroup alloc] initWithStatement:stmt];
		NCDBInvMetaGroup* metaGroup = [NSEntityDescription insertNewObjectForEntityForName:@"InvMetaGroup" inManagedObjectContext:context];
		metaGroup.metaGroupID = eveMetaGroup.metaGroupID;
		metaGroup.icon = eveMetaGroup.iconID ? eveIcons[@(eveMetaGroup.iconID)] : nil;
		
		dictionary[@(metaGroup.metaGroupID)] = metaGroup;
		
		NCDBTrnTranslation* metaGroupNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		metaGroupNameTranslation.keyID = eveMetaGroup.metaGroupID;
		metaGroupNameTranslation.columnID = 34;
		metaGroupNameTranslation.text = eveMetaGroup.metaGroupName;
	}];
	
	return dictionary;
}

NSDictionary* convertInvMetaTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from invMetaTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvMetaType* eveMetaType = [[EVEDBInvMetaType alloc] initWithStatement:stmt];
		NCDBInvMetaType* metaType = [NSEntityDescription insertNewObjectForEntityForName:@"InvMetaType" inManagedObjectContext:context];
		metaType.type = invTypes[@(eveMetaType.typeID)];
		metaType.parentType = eveMetaType.parentTypeID ? invTypes[@(eveMetaType.parentTypeID)] : nil;
		metaType.metaGroup = invMetaGroups[@(eveMetaType.metaGroupID)];
		dictionary[@(eveMetaType.typeID)] = metaType;
	}];
	
	return dictionary;
}

NSDictionary* convertInvMarketGroups(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	NSMutableDictionary* eveMarketGroups = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from invMarketGroups" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvMarketGroup* eveMarketGroup = [[EVEDBInvMarketGroup alloc] initWithStatement:stmt];
		NCDBInvMarketGroup* marketGroup = [NSEntityDescription insertNewObjectForEntityForName:@"InvMarketGroup" inManagedObjectContext:context];
		marketGroup.marketGroupID = eveMarketGroup.marketGroupID;
		marketGroup.icon = eveMarketGroup.iconID ? eveIcons[@(eveMarketGroup.iconID)] : nil;
		
		dictionary[@(marketGroup.marketGroupID)] = marketGroup;
		eveMarketGroups[@(marketGroup.marketGroupID)] = eveMarketGroup;
		
		NCDBTrnTranslation* marketGroupNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		marketGroupNameTranslation.keyID = eveMarketGroup.marketGroupID;
		marketGroupNameTranslation.columnID = 36;
		marketGroupNameTranslation.text = eveMarketGroup.marketGroupName;
	}];
	[dictionary enumerateKeysAndObjectsUsingBlock:^(id key, NCDBInvMarketGroup* obj, BOOL *stop) {
		EVEDBInvMarketGroup* eveMarketGroup = eveMarketGroups[@(obj.marketGroupID)];
		obj.parentGroup = eveMarketGroup.parentGroupID ? dictionary[@(eveMarketGroup.parentGroupID)] : nil;
	}];
	
	return dictionary;
}

NSDictionary* convertDgmAttributeCategories(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from dgmAttributeCategories" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBDgmAttributeCategory* eveAttributeCategory = [[EVEDBDgmAttributeCategory alloc] initWithStatement:stmt];
		NCDBDgmAttributeCategory* attributeCategory = [NSEntityDescription insertNewObjectForEntityForName:@"DgmAttributeCategory" inManagedObjectContext:context];
		attributeCategory.categoryID = eveAttributeCategory.categoryID;
		attributeCategory.categoryName = eveAttributeCategory.categoryName;
		dictionary[@(attributeCategory.categoryID)] = attributeCategory;
	}];
	
	return dictionary;
}

NSDictionary* convertDgmAttributeTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from dgmAttributeTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBDgmAttributeType* eveAttributeType = [[EVEDBDgmAttributeType alloc] initWithStatement:stmt];
		NCDBDgmAttributeType* attributeType = [NSEntityDescription insertNewObjectForEntityForName:@"DgmAttributeType" inManagedObjectContext:context];
		attributeType.attributeID = eveAttributeType.attributeID;
		attributeType.attributeName = eveAttributeType.attributeName;
		attributeType.published = eveAttributeType.published;
		attributeType.attributeCategory = eveAttributeType.categoryID ? dgmAttributeCategories[@(eveAttributeType.categoryID)] : nil;
		attributeType.icon = eveAttributeType.iconID ? eveIcons[@(eveAttributeType.iconID)] : nil;
		attributeType.unit = eveAttributeType.unitID ? eveUnits[@(eveAttributeType.unitID)] : nil;
		dictionary[@(attributeType.attributeID)] = attributeType;
		
		NCDBTrnTranslation* displayNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		displayNameTranslation.keyID = eveAttributeType.attributeID;
		displayNameTranslation.columnID = 59;
		displayNameTranslation.text = eveAttributeType.displayName;

	}];
	
	return dictionary;
}

NSMutableArray* convertDgmTypeAttributes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableArray* array = [NSMutableArray new];
	
	[database execSQLRequest:@"select * from dgmTypeAttributes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBDgmTypeAttribute* eveTypeAttribute = [[EVEDBDgmTypeAttribute alloc] initWithStatement:stmt];
		NCDBDgmTypeAttribute* typeAttribute = [NSEntityDescription insertNewObjectForEntityForName:@"DgmTypeAttribute" inManagedObjectContext:context];
		typeAttribute.value = eveTypeAttribute.value;
		typeAttribute.attributeType = dgmAttributeTypes[@(eveTypeAttribute.attributeID)];
		typeAttribute.type = invTypes[@(eveTypeAttribute.typeID)];
		[array addObject:typeAttribute];
	}];
	
	return array;
}

NSDictionary* convertDgmEffects(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from dgmEffects" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBDgmEffect* eveEffect = [[EVEDBDgmEffect alloc] initWithStatement:stmt];
		NCDBDgmEffect* effect = [NSEntityDescription insertNewObjectForEntityForName:@"DgmEffect" inManagedObjectContext:context];
		effect.effectID = eveEffect.effectID;
		dictionary[@(effect.effectID)] = effect;
	}];
	
	return dictionary;
}

void convertDgmTypeEffects(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"select * from dgmTypeEffects" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBDgmTypeEffect* eveTypeEffect = [[EVEDBDgmTypeEffect alloc] initWithStatement:stmt];
		NCDBDgmEffect* effect = dgmEffects[@(eveTypeEffect.effectID)];
		[effect addTypesObject:invTypes[@(eveTypeEffect.typeID)]];
	}];
}

NSDictionary* convertCertCertificates(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from certCerts" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBCertCertificate* eveCertificate = [[EVEDBCertCertificate alloc] initWithStatement:stmt];
		NCDBCertCertificate* certificate = [NSEntityDescription insertNewObjectForEntityForName:@"CertCertificate" inManagedObjectContext:context];
		certificate.certificateID = eveCertificate.certificateID;
		dictionary[@(certificate.certificateID)] = certificate;
		
		NCDBTrnTranslation* displayNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		displayNameTranslation.keyID = eveCertificate.certificateID;
		displayNameTranslation.columnID = NCDBCertCertificateDisplayNameTranslationColumnID;
		displayNameTranslation.text = eveCertificate.name;

		NCDBTrnTranslation* descriptionTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		descriptionTranslation.keyID = eveCertificate.certificateID;
		descriptionTranslation.columnID = NCDBCertCertificateDescriptionTranslationColumnID;
		descriptionTranslation.text = eveCertificate.description;
	}];
	
	return dictionary;
}

NSDictionary* convertCertMasteryLevels(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM certSkills group by certLevelInt" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBCertSkill* eveCertSkill = [[EVEDBCertSkill alloc] initWithStatement:stmt];
		NCDBCertMasteryLevel* masteryLevel = [NSEntityDescription insertNewObjectForEntityForName:@"CertMasteryLevel" inManagedObjectContext:context];
		masteryLevel.level = eveCertSkill.certificateLevel;
		masteryLevel.claimedIcon = eveIcons[@(NCDBCertMasteryLevelIconsStartID + masteryLevel.level)];
		masteryLevel.unclaimedIcon = eveIcons[@(NCDBCertMasteryLevelIconsStartID)];
		dictionary[@(masteryLevel.level)] = masteryLevel;

		NCDBTrnTranslation* displayNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		displayNameTranslation.keyID = masteryLevel.level;
		displayNameTranslation.columnID = NCDBCertMasteryLevelDisplayNameTranslationColumnID;
		displayNameTranslation.text = eveCertSkill.certificateLevelText;
	}];
	
	return dictionary;
}

NSDictionary* convertCertMasteries(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[certCertificates enumerateKeysAndObjectsUsingBlock:^(id key, NCDBCertCertificate* certificate, BOOL *stop) {
		[certMasteryLevels enumerateKeysAndObjectsUsingBlock:^(id key, NCDBCertMasteryLevel* level, BOOL *stop) {
			NCDBCertMastery* mastery = [NSEntityDescription insertNewObjectForEntityForName:@"CertMastery" inManagedObjectContext:context];
			mastery.certificate = certificate;
			mastery.level = level;
			dictionary[[NSString stringWithFormat:@"%d.%d", certificate.certificateID, level.level]] = mastery;
		}];
	}];
	
	[database execSQLRequest:@"SELECT * FROM certMasteries" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBCertMastery* eveCertMastery = [[EVEDBCertMastery alloc] initWithStatement:stmt];
		NCDBCertMastery* mastery = dictionary[[NSString stringWithFormat:@"%d.%d", eveCertMastery.certificateID, eveCertMastery.masteryLevel]];
		[mastery addTypesObject:invTypes[@(eveCertMastery.typeID)]];
	}];
	
	return dictionary;
}

void convertCertSkills(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM certSkills" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBCertSkill* eveCertSkill = [[EVEDBCertSkill alloc] initWithStatement:stmt];
		NCDBCertMastery* mastery = certMasteries[[NSString stringWithFormat:@"%d.%d", eveCertSkill.certificateID, eveCertSkill.certificateLevel]];
		NCDBCertSkill* skill = [NSEntityDescription insertNewObjectForEntityForName:@"CertSkill" inManagedObjectContext:context];
		skill.skillLevel = eveCertSkill.skillLevel;
		skill.type = invTypes[@(eveCertSkill.skillID)];
		skill.mastery = mastery;
	}];
}

void convertInvBlueprintTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM invBlueprintTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvBlueprintType* eveBlueprintType = [[EVEDBInvBlueprintType alloc] initWithStatement:stmt];
		NCDBInvBlueprintType* blueprintType = [NSEntityDescription insertNewObjectForEntityForName:@"InvBlueprintType" inManagedObjectContext:context];
		blueprintType.materialModifier = eveBlueprintType.materialModifier;
		blueprintType.maxProductionLimit = eveBlueprintType.maxProductionLimit;
		blueprintType.productionTime = eveBlueprintType.productionTime;
		blueprintType.productivityModifier = eveBlueprintType.productivityModifier;
		blueprintType.researchCopyTime = eveBlueprintType.researchCopyTime;
		blueprintType.researchMaterialTime = eveBlueprintType.researchMaterialTime;
		blueprintType.researchProductivityTime = eveBlueprintType.researchProductivityTime;
		blueprintType.researchTechTime = eveBlueprintType.researchTechTime;
		blueprintType.techLevel = eveBlueprintType.techLevel;
		blueprintType.wasteFactor = eveBlueprintType.wasteFactor;
		blueprintType.blueprintType = invTypes[@(eveBlueprintType.blueprintTypeID)];
		blueprintType.productType = invTypes[@(eveBlueprintType.productTypeID)];
	}];
}

void convertInvTypeMaterials(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM invTypeMaterials" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvTypeMaterial* eveTypeMaterial = [[EVEDBInvTypeMaterial alloc] initWithStatement:stmt];
		NCDBInvType* product = invTypes[@(eveTypeMaterial.typeID)];
		if (product.blueprint) {
			NCDBInvTypeMaterial* typeMaterial = [NSEntityDescription insertNewObjectForEntityForName:@"InvTypeMaterial" inManagedObjectContext:context];
			
			typeMaterial.blueprintType = product.blueprint;
			typeMaterial.materialType = invTypes[@(eveTypeMaterial.materialTypeID)];
			typeMaterial.quantity = eveTypeMaterial.quantity;
		}
	}];
}

NSDictionary* convertInvControlTowerResourcePurposes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM invControlTowerResourcePurposes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvControlTowerResourcePurpose* eveControlTowerResourcePurposes = [[EVEDBInvControlTowerResourcePurpose alloc] initWithStatement:stmt];
		NCDBInvControlTowerResourcePurpose* controlTowerResourcePurposes = [NSEntityDescription insertNewObjectForEntityForName:@"InvControlTowerResourcePurpose" inManagedObjectContext:context];
		controlTowerResourcePurposes.purposeID = eveControlTowerResourcePurposes.purposeID;
		dictionary[@(controlTowerResourcePurposes.purposeID)] = controlTowerResourcePurposes;
		
		NCDBTrnTranslation* displayNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		displayNameTranslation.keyID = eveControlTowerResourcePurposes.purposeID;
		displayNameTranslation.columnID = NCDBInvControlTowerResourcePurposeDisplayNameTranslationColumnID;
		displayNameTranslation.text = eveControlTowerResourcePurposes.purposeText;
	}];
	
	return dictionary;
}

void convertInvControlTowerResources(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM invControlTowerResources" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvControlTowerResource* eveControlTowerResource = [[EVEDBInvControlTowerResource alloc] initWithStatement:stmt];
		NCDBInvType* controlTowerType = invTypes[@(eveControlTowerResource.controlTowerTypeID)];
		NCDBInvControlTower* controlTower = controlTowerType.controlTower;
		if (!controlTower) {
			controlTower = [NSEntityDescription insertNewObjectForEntityForName:@"InvControlTower" inManagedObjectContext:context];
			controlTower.type = controlTowerType;
		}
		NCDBInvControlTowerResource* controlTowerResource = [NSEntityDescription insertNewObjectForEntityForName:@"InvControlTowerResource" inManagedObjectContext:context];
		controlTowerResource.resourceType = invTypes[@(eveControlTowerResource.resourceTypeID)];
		controlTowerResource.controlTower = controlTower;
		controlTowerResource.factionID = eveControlTowerResource.factionID;
		controlTowerResource.minSecurityLevel = eveControlTowerResource.minSecurityLevel;
		controlTowerResource.quantity = eveControlTowerResource.quantity;
		controlTowerResource.wormholeClassID = eveControlTowerResource.wormholeClassID;
		controlTowerResource.purpose = invControlTowerResourcePurposes[@(eveControlTowerResource.purposeID)];
	}];
}

NSDictionary* convertMapRegions(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM mapRegions" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBMapRegion* eveRegion = [[EVEDBMapRegion alloc] initWithStatement:stmt];
		NCDBMapRegion* region = [NSEntityDescription insertNewObjectForEntityForName:@"MapRegion" inManagedObjectContext:context];
		region.regionID = eveRegion.regionID;
		region.regionName = eveRegion.regionName;
		dictionary[@(region.regionID)] = region;
	}];
	
	return dictionary;
}

NSDictionary* convertMapConstellations(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM mapConstellations" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBMapConstellation* eveConstellation = [[EVEDBMapConstellation alloc] initWithStatement:stmt];
		NCDBMapConstellation* constellation = [NSEntityDescription insertNewObjectForEntityForName:@"MapConstellation" inManagedObjectContext:context];
		constellation.constellationID = eveConstellation.constellationID;
		constellation.constellationName = eveConstellation.constellationName;
		constellation.factionID = eveConstellation.factionID;
		constellation.region = mapRegions[@(eveConstellation.regionID)];
		dictionary[@(constellation.constellationID)] = constellation;
	}];
	
	return dictionary;
}

NSDictionary* convertMapSolarSystems(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM mapSolarSystems" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBMapSolarSystem* eveSolarSystem = [[EVEDBMapSolarSystem alloc] initWithStatement:stmt];
		NCDBMapSolarSystem* solarSystem = [NSEntityDescription insertNewObjectForEntityForName:@"MapSolarSystem" inManagedObjectContext:context];
		solarSystem.security = eveSolarSystem.security;
		solarSystem.solarSystemID = eveSolarSystem.solarSystemID;
		solarSystem.solarSystemName = eveSolarSystem.solarSystemName;
		solarSystem.constellation = mapConstellations[@(eveSolarSystem.constellationID)];
		dictionary[@(solarSystem.solarSystemID)] = solarSystem;
	}];
	
	return dictionary;
}


void convertMapDenormalize(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM mapDenormalize where groupID = 15 and itemID NOT IN (SELECT stationID FROM staStations);" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBMapDenormalize* eveDenormalize = [[EVEDBMapDenormalize alloc] initWithStatement:stmt];
		NCDBMapDenormalize* denormalize = [NSEntityDescription insertNewObjectForEntityForName:@"MapDenormalize" inManagedObjectContext:context];
		denormalize.itemID = eveDenormalize.itemID;
		denormalize.itemName = eveDenormalize.itemName;
		denormalize.security = eveDenormalize.security;
		denormalize.region = eveDenormalize.regionID ? mapRegions[@(eveDenormalize.regionID)] : nil;
		denormalize.constellation = eveDenormalize.constellationID ? mapConstellations[@(eveDenormalize.constellationID)] : nil;
		denormalize.solarSystem = eveDenormalize.solarSystemID ? mapSolarSystems[@(eveDenormalize.solarSystemID)] : nil;
		denormalize.type = invTypes[@(eveDenormalize.typeID)];
	}];
}

void convertNpcGroup(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	NSMutableDictionary* eveNpcGroups = [NSMutableDictionary new];
	[database execSQLRequest:@"SELECT * FROM npcGroup" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBNpcGroup* eveNpcGroup = [[EVEDBNpcGroup alloc] initWithStatement:stmt];
		NCDBNpcGroup* npcGroup = [NSEntityDescription insertNewObjectForEntityForName:@"NpcGroup" inManagedObjectContext:context];
		npcGroup.npcGroupName = eveNpcGroup.npcGroupName;
		npcGroup.group = invGroups[@(eveNpcGroup.groupID)];
		npcGroup.icon = eveNpcGroup.iconName ? eveIcons[eveNpcGroup.iconName] : nil;
		
		dictionary[@(eveNpcGroup.npcGroupID)] = npcGroup;
		eveNpcGroups[@(eveNpcGroup.npcGroupID)] = eveNpcGroup;
	}];
	
	[dictionary enumerateKeysAndObjectsUsingBlock:^(id key, NCDBNpcGroup* npcGroup, BOOL *stop) {
		EVEDBNpcGroup* eveNpcGroup = eveNpcGroups[key];
		npcGroup.parentNpcGroup = eveNpcGroup.parentNpcGroupID ? dictionary[@(eveNpcGroup.parentNpcGroupID)] : nil;
	}];
}

NSDictionary* convertRamActivities(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM ramActivities" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBRamActivity* eveActivity = [[EVEDBRamActivity alloc] initWithStatement:stmt];
		NCDBRamActivity* activity = [NSEntityDescription insertNewObjectForEntityForName:@"RamActivity" inManagedObjectContext:context];
		activity.activityID = eveActivity.activityID;
		activity.published = eveActivity.published;

		if (eveActivity.iconNo) {
			__block EVEDBEveIcon* eveIcon = nil;
			[database execSQLRequest:[NSString stringWithFormat:@"select * from eveIcons where iconFile=\"%@\"", eveActivity.iconNo]
						 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
							 *needsMore = NO;
							 eveIcon = [[EVEDBEveIcon alloc] initWithStatement:stmt];
						 }];
			if (eveIcon)
				activity.icon = eveIcons[@(eveIcon.iconID)];
			if (!activity.icon)
				activity.icon = eveIcons[eveActivity.iconNo];
		}

		dictionary[@(activity.activityID)] = activity;
		
		NCDBTrnTranslation* displayNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		displayNameTranslation.keyID = eveActivity.activityID;
		displayNameTranslation.columnID = 100;
		displayNameTranslation.text = eveActivity.activityName;
	}];
	
	return dictionary;
}

NSDictionary* convertRamAssemblyLineTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM ramAssemblyLineTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBRamAssemblyLineType* eveAssemblyLineType = [[EVEDBRamAssemblyLineType alloc] initWithStatement:stmt];
		NCDBRamAssemblyLineType* assemblyLineType = [NSEntityDescription insertNewObjectForEntityForName:@"RamAssemblyLineType" inManagedObjectContext:context];
		assemblyLineType.assemblyLineTypeID = eveAssemblyLineType.assemblyLineTypeID;
		assemblyLineType.baseTimeMultiplier = eveAssemblyLineType.baseTimeMultiplier;
		assemblyLineType.baseMaterialMultiplier = eveAssemblyLineType.baseMaterialMultiplier;
		assemblyLineType.volume = eveAssemblyLineType.volume;
		assemblyLineType.minCostPerHour = eveAssemblyLineType.minCostPerHour;
		assemblyLineType.activity = ramActivities[@(eveAssemblyLineType.activityID)];
		dictionary[@(assemblyLineType.assemblyLineTypeID)] = assemblyLineType;

		NCDBTrnTranslation* displayNameTranslation = [NSEntityDescription insertNewObjectForEntityForName:@"TrnTranslation" inManagedObjectContext:context];
		displayNameTranslation.keyID = eveAssemblyLineType.assemblyLineTypeID;
		displayNameTranslation.columnID = NCDBRamAssemblyLineTypeDisplayNameTranslationColumnID;
		displayNameTranslation.text = eveAssemblyLineType.assemblyLineTypeName;
	}];
	
	return dictionary;
}

void convertRamInstallationTypeContents(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM ramInstallationTypeContents" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBRamInstallationTypeContent* eveInstallationTypeContent = [[EVEDBRamInstallationTypeContent alloc] initWithStatement:stmt];
		NCDBRamInstallationTypeContent* installationTypeContent = [NSEntityDescription insertNewObjectForEntityForName:@"RamInstallationTypeContent" inManagedObjectContext:context];
		installationTypeContent.quantity = eveInstallationTypeContent.quantity;
		installationTypeContent.assemblyLineType = ramAssemblyLineTypes[@(eveInstallationTypeContent.assemblyLineTypeID)];
		installationTypeContent.installationType = invTypes[@(eveInstallationTypeContent.installationTypeID)];
	}];
}

void convertRamTypeRequirements(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM ramTypeRequirements" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBRamTypeRequirement* eveTypeRequirement = [[EVEDBRamTypeRequirement alloc] initWithStatement:stmt];
		NCDBRamTypeRequirement* typeRequirement = [NSEntityDescription insertNewObjectForEntityForName:@"RamTypeRequirement" inManagedObjectContext:context];
		typeRequirement.quantity = eveTypeRequirement.quantity;
		typeRequirement.damagePerJob = eveTypeRequirement.damagePerJob;
		typeRequirement.recycle = eveTypeRequirement.recycle;
		typeRequirement.type = invTypes[@(eveTypeRequirement.typeID)];
		typeRequirement.requiredType = invTypes[@(eveTypeRequirement.requiredTypeID)];
		typeRequirement.activity = ramActivities[@(eveTypeRequirement.activityID)];
	}];
}

NSDictionary* convertStaStations(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM staStations" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBStaStation* eveStation = [[EVEDBStaStation alloc] initWithStatement:stmt];
		NCDBStaStation* station = [NSEntityDescription insertNewObjectForEntityForName:@"StaStation" inManagedObjectContext:context];
		station.stationID = eveStation.stationID;
		station.security = eveStation.security;
		station.stationName = eveStation.stationName;
		station.stationType = invTypes[@(eveStation.stationTypeID)];
		station.solarSystem = mapSolarSystems[@(eveStation.solarSystemID)];
		dictionary[@(station.stationID)] = station;
	}];
	
	return dictionary;
}

NSDictionary* convertChrRaces(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM chrRaces" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBChrRace* eveRace = [[EVEDBChrRace alloc] initWithStatement:stmt];
		NCDBChrRace* race = [NSEntityDescription insertNewObjectForEntityForName:@"ChrRace" inManagedObjectContext:context];
		race.raceID = eveRace.raceID;
		race.icon = eveRace.iconID ? eveIcons[@(eveRace.iconID)] : nil;
		dictionary[@(race.raceID)] = race;
	}];
	
	return dictionary;
}

int main(int argc, const char * argv[])
{

	@autoreleasepool {
	    NSManagedObjectContext *context = managedObjectContext();

		EVEDBDatabase* database = [[EVEDBDatabase alloc] initWithDatabasePath:@"./evedb.sqlite"];
		[EVEDBDatabase setSharedDatabase:database];
		
		@autoreleasepool {
			NSLog(@"convertEveIcons");
			eveIcons = convertEveIcons(context, database);
			NSLog(@"convertChrRaces");
			chrRaces = convertChrRaces(context, database);
			NSLog(@"convertEveUnits");
			eveUnits = convertEveUnits(context, database);
			NSLog(@"convertInvCategories");
			invCategories = convertInvCategories(context, database);
			NSLog(@"convertInvGroups");
			invGroups = convertInvGroups(context, database);
			NSLog(@"convertInvMetaGroups");
			invMetaGroups = convertInvMetaGroups(context, database);
			NSLog(@"convertInvMarketGroups");
			invMarketGroups = convertInvMarketGroups(context, database);
			NSLog(@"convertInvTypes");
			invTypes = convertInvTypes(context, database);
			NSLog(@"convertInvMetaTypes");
			invMetaTypes = convertInvMetaTypes(context, database);
			NSLog(@"convertDgmAttributeCategories");
			dgmAttributeCategories = convertDgmAttributeCategories(context, database);
			NSLog(@"convertDgmAttributeTypes");
			dgmAttributeTypes = convertDgmAttributeTypes(context, database);
			NSLog(@"convertDgmTypeAttributes");
			convertDgmTypeAttributes(context, database);
			NSLog(@"convertDgmEffects");
			dgmEffects = convertDgmEffects(context, database);
			NSLog(@"convertDgmTypeEffects");
			convertDgmTypeEffects(context, database);
			NSLog(@"convertCertCertificates");
			certCertificates = convertCertCertificates(context, database);
			NSLog(@"convertCertMasteryLevels");
			certMasteryLevels = convertCertMasteryLevels(context, database);
			NSLog(@"convertCertMasteries");
			certMasteries = convertCertMasteries(context, database);
			NSLog(@"convertCertSkills");
			convertCertSkills(context, database);
			NSLog(@"convertInvBlueprintTypes");
			convertInvBlueprintTypes(context, database);
			NSLog(@"convertInvTypeMaterials");
			convertInvTypeMaterials(context, database);
			NSLog(@"convertInvControlTowerResourcePurposes");
			invControlTowerResourcePurposes = convertInvControlTowerResourcePurposes(context, database);
			NSLog(@"convertInvControlTowerResources");
			convertInvControlTowerResources(context, database);
			NSLog(@"convertMapRegions");
			mapRegions = convertMapRegions(context, database);
			NSLog(@"convertMapConstellations");
			mapConstellations = convertMapConstellations(context, database);
			NSLog(@"convertMapSolarSystems");
			mapSolarSystems = convertMapSolarSystems(context, database);
			NSLog(@"convertMapDenormalize");
			convertMapDenormalize(context, database);
			NSLog(@"convertNpcGroup");
			convertNpcGroup(context, database);
			NSLog(@"convertRamActivities");
			ramActivities = convertRamActivities(context, database);
			NSLog(@"convertRamAssemblyLineTypes");
			ramAssemblyLineTypes = convertRamAssemblyLineTypes(context, database);
			NSLog(@"convertRamInstallationTypeContents");
			convertRamInstallationTypeContents(context, database);
			NSLog(@"convertRamTypeRequirements");
			convertRamTypeRequirements(context, database);
			NSLog(@"convertStaStations");
			staStations = convertStaStations(context, database);
		}

		
	    // Custom code here...
	    // Save the managed object context
	    NSError *error = nil;
	    if (![context save:&error]) {
	        NSLog(@"Error while saving %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
	        exit(1);
	    }
		
/*		NSString *path = [[NSProcessInfo processInfo] arguments][0];
        path = [path stringByDeletingLastPathComponent];
        NSURL *url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"evedb.sqlite"]];
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];

		[context.persistentStoreCoordinator migratePersistentStore:context.persistentStoreCoordinator.persistentStores[0]
															 toURL:url
														   options:@{NSReadOnlyPersistentStoreOption: @(YES)}
														  withType:NSSQLiteStoreType
															 error:&error];
*/	}
    return 0;
}

