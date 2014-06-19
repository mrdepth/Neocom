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
#include "eufe.h"
#import <objc/runtime.h>

#define NCDBCertMasteryLevelIconsStartID 1000000
#define NCDBCertCertificateDisplayNameTranslationColumnID 1000
#define NCDBCertCertificateDescriptionTranslationColumnID 1001
#define NCDBCertMasteryLevelDisplayNameTranslationColumnID 1002
#define NCDBInvControlTowerResourcePurposeDisplayNameTranslationColumnID 1003
#define NCDBRamAssemblyLineTypeDisplayNameTranslationColumnID 1004

#define NCDBMetaGroupAttributeID 1692
#define NCDBMetaLevelAttributeID 633

@interface EVEDBInvMarketGroup (NCDatabaseTypePickerViewController)
@property (nonatomic, strong, readonly) NSMutableArray* subgroups;
@end

@implementation EVEDBInvMarketGroup (NCItemsViewController)

- (NSMutableArray*) subgroups {
	NSMutableArray* subgroups = objc_getAssociatedObject(self, (const void*) @"subgroups");
	if (!subgroups) {
		subgroups = [NSMutableArray new];
		objc_setAssociatedObject(self, (const void*) @"subgroups", subgroups, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return subgroups;
}

@end


int32_t lastUserDefinedIconID = 2000000;

NSDictionary* eveIcons;
NSDictionary* eveUnits;
NSDictionary* invTypes;
NSDictionary* invGroups;
NSDictionary* invCategories;
NSDictionary* invMetaGroups;
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
NSDictionary* chrRaces;

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
			icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
			icon.image.image = imageRep;
			dictionary[@(eveIcon.iconID)] = icon;
		}
	}];
	
	for (int i = 0; i <= 5; i++) {
		NSString* iconImageName = [NSString stringWithFormat:@"./Icons/icon79_0%d.png", i + 1];
		NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
		if (data) {
			NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
			icon.iconFile = [NSString stringWithFormat:@"79_0%d", i + 1];
			icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
			icon.image.image = imageRep;
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
						icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
						icon.image.image = imageRep;
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
			icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
			icon.image.image = imageRep;
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
			icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
			icon.image.image = imageRep;
			dictionary[eveType.imageName] = icon;
		}
	}];
	
	for (NSString* iconNo in @[@"09_07", @"105_32", @"50_13", @"38_193", @"38_194", @"38_195", @"38_174"]) {
		__block EVEDBEveIcon* eveIcon = nil;
		[database execSQLRequest:[NSString stringWithFormat:@"select * from eveIcons where iconFile=\"%@\"", iconNo]
					 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
						 *needsMore = NO;
						 eveIcon = [[EVEDBEveIcon alloc] initWithStatement:stmt];
					 }];
		if (!eveIcon) {
			NCDBEveIcon* icon = dictionary[iconNo];
			if (!icon) {
				NSString* iconImageName = [NSString stringWithFormat:@"./Icons/icon%@.png", iconNo];
				
				NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
				if (data) {
					NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
					NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
					icon.iconFile = iconNo;
					icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
					icon.image.image = imageRep;
					dictionary[iconNo] = icon;
				}
			}
		}
	}
	return dictionary;
}

NSDictionary* convertEveUnits(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from eveUnits" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBEveUnit* eveUnit = [[EVEDBEveUnit alloc] initWithStatement:stmt];
		NCDBEveUnit* unit = [NSEntityDescription insertNewObjectForEntityForName:@"EveUnit" inManagedObjectContext:context];
		unit.unitID = eveUnit.unitID;
		unit.displayName = eveUnit.displayName;
		dictionary[@(unit.unitID)] = unit;
	}];
	
	return dictionary;
}

NSDictionary* convertInvTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from invTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvType* eveType = [[EVEDBInvType alloc] initWithStatement:stmt];
		NCDBEveIcon* icon = eveType.imageName ? eveIcons[eveType.imageName] : nil;
		
		NCDBInvType* type = [NSEntityDescription insertNewObjectForEntityForName:@"InvType" inManagedObjectContext:context];
		type.typeID = eveType.typeID;
		type.typeName = eveType.typeName;
		type.basePrice = eveType.basePrice;
		type.capacity = eveType.capacity;
		type.mass = eveType.mass;
		type.portionSize = eveType.portionSize;
		type.published = eveType.published != NO;
		type.radius = eveType.radius;
		type.volume = eveType.volume;
		type.group = invGroups[@(eveType.groupID)];
		type.marketGroup = eveType.marketGroupID ? invMarketGroups[@(eveType.marketGroupID)] : nil;
		type.race = eveType.raceID ? chrRaces[@(eveType.raceID)] : nil;
		type.metaGroup = invMetaGroups[@(-1)];
		
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
		
		type.typeDescription = [NSEntityDescription insertNewObjectForEntityForName:@"TxtDescription" inManagedObjectContext:context];
		type.typeDescription.text = description;
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
		category.categoryName = eveCategory.categoryName;
		category.published = eveCategory.published != NO;
		dictionary[@(category.categoryID)] = category;
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
		group.groupName = eveGroup.groupName;
		group.published = eveGroup.published != NO;
		dictionary[@(group.groupID)] = group;

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
		metaGroup.metaGroupName = eveMetaGroup.metaGroupName;
		dictionary[@(metaGroup.metaGroupID)] = metaGroup;
	}];

	NCDBInvMetaGroup* metaGroup = [NSEntityDescription insertNewObjectForEntityForName:@"InvMetaGroup" inManagedObjectContext:context];
	metaGroup.metaGroupID = -1;
	metaGroup.icon = nil;
	metaGroup.metaGroupName = @"";
	dictionary[@(metaGroup.metaGroupID)] = metaGroup;

	return dictionary;
}

void convertInvMetaTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"select * from invMetaTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvMetaType* eveMetaType = [[EVEDBInvMetaType alloc] initWithStatement:stmt];
		NCDBInvType* type = invTypes[@(eveMetaType.typeID)];
		NCDBInvType* parentType = eveMetaType.parentTypeID ? invTypes[@(eveMetaType.parentTypeID)] : nil;
		if (parentType)
			type.parentType = parentType;
		type.metaGroup = invMetaGroups[@(eveMetaType.metaGroupID)];
	}];
}

NSDictionary* convertInvMarketGroups(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	NSMutableDictionary* eveMarketGroups = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from invMarketGroups" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvMarketGroup* eveMarketGroup = [[EVEDBInvMarketGroup alloc] initWithStatement:stmt];
		NCDBInvMarketGroup* marketGroup = [NSEntityDescription insertNewObjectForEntityForName:@"InvMarketGroup" inManagedObjectContext:context];
		marketGroup.marketGroupID = eveMarketGroup.marketGroupID;
		marketGroup.icon = eveMarketGroup.iconID ? eveIcons[@(eveMarketGroup.iconID)] : nil;
		marketGroup.marketGroupName = eveMarketGroup.marketGroupName;
		dictionary[@(marketGroup.marketGroupID)] = marketGroup;
		eveMarketGroups[@(marketGroup.marketGroupID)] = eveMarketGroup;
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
		attributeType.displayName = eveAttributeType.displayName;
		dictionary[@(attributeType.attributeID)] = attributeType;
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
		if (eveTypeAttribute.attributeID == NCDBMetaGroupAttributeID) {
			NCDBInvMetaGroup* metaGroup = invMetaGroups[@((int32_t) eveTypeAttribute.value)];
			//assert(!typeAttribute.type.metaGroup || typeAttribute.type.metaGroup.metaGroupID == metaGroup.metaGroupID);
			if (metaGroup)
				typeAttribute.type.metaGroup = metaGroup;
		}
		else if (eveTypeAttribute.attributeID == NCDBMetaLevelAttributeID) {
			typeAttribute.type.metaLevel = typeAttribute.value;
		}
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
		certificate.certificateName = eveCertificate.name;
		certificate.group = invGroups[@(eveCertificate.groupID)];
		dictionary[@(certificate.certificateID)] = certificate;
		
		certificate.certificateDescription = [NSEntityDescription insertNewObjectForEntityForName:@"TxtDescription" inManagedObjectContext:context];
		certificate.certificateDescription.text = eveCertificate.description;
	}];
	
	return dictionary;
}

NSDictionary* convertCertMasteryLevels(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM certSkills group by certLevelInt" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBCertSkill* eveCertSkill = [[EVEDBCertSkill alloc] initWithStatement:stmt];
		NCDBCertMasteryLevel* masteryLevel = [NSEntityDescription insertNewObjectForEntityForName:@"CertMasteryLevel" inManagedObjectContext:context];
		masteryLevel.level = eveCertSkill.certificateLevel;
		masteryLevel.icon = eveIcons[@(NCDBCertMasteryLevelIconsStartID + masteryLevel.level + 1)];
		masteryLevel.displayName = eveCertSkill.certificateLevelText;
		dictionary[@(masteryLevel.level)] = masteryLevel;
	}];
	
	return dictionary;
}

NSDictionary* convertCertMasteries(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	NSArray* levels = [[certMasteryLevels allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"level" ascending:YES]]];
	[certCertificates enumerateKeysAndObjectsUsingBlock:^(id key, NCDBCertCertificate* certificate, BOOL *stop) {
		for (NCDBCertMasteryLevel* level in levels) {
			NCDBCertMastery* mastery = [NSEntityDescription insertNewObjectForEntityForName:@"CertMastery" inManagedObjectContext:context];
			mastery.certificate = certificate;
			mastery.level = level;
			dictionary[[NSString stringWithFormat:@"%d.%d", certificate.certificateID, level.level]] = mastery;
		};
	}];
	
	[database execSQLRequest:@"SELECT * FROM certMasteries" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBCertMastery* eveCertMastery = [[EVEDBCertMastery alloc] initWithStatement:stmt];
		NCDBCertCertificate* certificate = certCertificates[@(eveCertMastery.certificateID)];
		[certificate addTypesObject:invTypes[@(eveCertMastery.typeID)]];
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
		controlTowerResourcePurposes.purposeText = eveControlTowerResourcePurposes.purposeText;
		dictionary[@(controlTowerResourcePurposes.purposeID)] = controlTowerResourcePurposes;
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
		region.factionID = eveRegion.factionID;
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
		solarSystem.factionID = eveSolarSystem.factionID;
		dictionary[@(solarSystem.solarSystemID)] = solarSystem;
	}];
	
	return dictionary;
}


void convertMapDenormalize(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM mapDenormalize where groupID IN (8, 15) and itemID NOT IN (SELECT stationID FROM staStations);" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
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
		activity.activityName = eveActivity.activityName;

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
		assemblyLineType.assemblyLineTypeName = eveAssemblyLineType.assemblyLineTypeName;
		dictionary[@(assemblyLineType.assemblyLineTypeID)] = assemblyLineType;
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
		race.raceName = eveRace.raceName;
		dictionary[@(race.raceID)] = race;
	}];
	
	return dictionary;
}

void convertRequiredSkills(NSManagedObjectContext* context) {
	static int32_t requirementID[] = {182, 183, 184, 1285, 1289, 1290};
	static int32_t skillLevelID[] = {277, 278, 279, 1286, 1287, 1288};

	[invTypes enumerateKeysAndObjectsUsingBlock:^(id key, NCDBInvType* type, BOOL *stop) {
		NSMutableDictionary* attributes = [NSMutableDictionary new];
		for (NCDBDgmTypeAttribute* attribute in type.attributes) {
			for (int i = 0; i < 6; i++) {
				if (attribute.attributeType.attributeID == requirementID[i]) {
					attributes[@(requirementID[i])] = attribute;
				}
				if (attribute.attributeType.attributeID == skillLevelID[i]) {
					attributes[@(skillLevelID[i])] = attribute;
				}
			}
		}
		for (int i = 0; i < 6; i++) {
			NCDBDgmTypeAttribute* typeID = attributes[@(requirementID[i])];
			NCDBDgmTypeAttribute* level = attributes[@(skillLevelID[i])];
			if (typeID && level && ((int32_t) typeID.value) != type.typeID) {
				NCDBInvType* skillType = invTypes[@((int32_t) typeID.value)];
				if (skillType) {
					NCDBInvTypeRequiredSkill* requiredSkill = [NSEntityDescription insertNewObjectForEntityForName:@"InvTypeRequiredSkill" inManagedObjectContext:context];
					requiredSkill.skillType = skillType;
					requiredSkill.type = type;
					requiredSkill.skillLevel = level.value;
				}
			}
		}
	}];
}

typedef enum {
	SLOT_NONE = eufe::Module::SLOT_NONE,
	SLOT_HI,
	SLOT_MED,
	SLOT_LOW,
	SLOT_RIG,
	SLOT_SUBSYSTEM,
	SLOT_STRUCTURE,
	SLOT_CHARGE,
	SLOT_DRONE,
	SLOT_IMPLANT,
	SLOT_BOOSTER,
	SLOT_SHIP,
	SLOT_CONTROL_TOWER
} Slot;

void convertEufeItems(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSSet* (^getConditionsTables)(NSArray*) = ^(NSArray* conditions) {
		NSMutableSet* conditionsTables = [NSMutableSet new];
		for (NSString* condition in conditions) {
			
			NSError* error = nil;
			NSRegularExpression* expression = [[NSRegularExpression alloc] initWithPattern:@"\\b([a-zA-Z]{1,}?)\\.[a-zA-Z]{1,}?\\b" options:NSRegularExpressionCaseInsensitive error:&error];
			[expression enumerateMatchesInString:condition
										 options:0
										   range:NSMakeRange(0, condition.length)
									  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
										  NSInteger n = [result numberOfRanges];
										  if (n == 2)
											  [conditionsTables addObject:[condition substringWithRange:[result rangeAtIndex:1]]];
									  }];
		}
		return conditionsTables;
	};
	
	NSArray* (^getGroups)(NSArray*, NSSet*) = ^(NSArray* conditions, NSSet* conditionsTables) {
		NSMutableSet* allTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invTypes.published=1", nil];
		
		[allTables unionSet:conditionsTables];
		[allConditions addObjectsFromArray:conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invMarketGroups.* FROM invMarketGroups WHERE marketGroupID IN \
							 (SELECT invTypes.marketGroupID FROM %@ WHERE %@ GROUP BY invTypes.marketGroupID)",
							 [[allTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
		NSMutableDictionary* marketGroupsMap = [NSMutableDictionary new];
		NSMutableArray* parentGroupIDs = [NSMutableArray new];
		NSMutableArray* lastGroups = [NSMutableArray new];
		
		[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
			EVEDBInvMarketGroup* marketGroup = [[EVEDBInvMarketGroup alloc] initWithStatement:stmt];
			marketGroupsMap[@(marketGroup.marketGroupID)] = marketGroup;
			if (marketGroup.parentGroupID)
				[parentGroupIDs addObject:[NSString stringWithFormat:@"%d", marketGroup.parentGroupID]];
		}];
		
		while (parentGroupIDs.count > 0) {
			request = [NSString stringWithFormat:@"SELECT * FROM invMarketGroups WHERE marketGroupID IN (%@) AND marketGroupID <> 1659 GROUP BY marketGroupID", [parentGroupIDs componentsJoinedByString:@","]];
			[parentGroupIDs removeAllObjects];
			
			[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
				EVEDBInvMarketGroup* marketGroup = [[EVEDBInvMarketGroup alloc] initWithStatement:stmt];
				marketGroupsMap[@(marketGroup.marketGroupID)] = marketGroup;
				
				if (marketGroup.parentGroupID && !marketGroupsMap[@(marketGroup.parentGroupID)])
					[parentGroupIDs addObject:[NSString stringWithFormat:@"%d", marketGroup.parentGroupID]];
			}];
		}
		
		[marketGroupsMap enumerateKeysAndObjectsUsingBlock:^(id key, EVEDBInvMarketGroup* marketGroup, BOOL *stop) {
			if (marketGroup.parentGroupID) {
				EVEDBInvMarketGroup* parentGroup = marketGroupsMap[@(marketGroup.parentGroupID)];
				[parentGroup.subgroups addObject:marketGroup];
			}
			else
				[lastGroups addObject:marketGroup];
		}];
		
		while(lastGroups.count == 1) {
			EVEDBInvMarketGroup* parentGroup = lastGroups[0];
			if (parentGroup.subgroups.count == 0)
				break;
			lastGroups = parentGroup.subgroups;
		}
		[marketGroupsMap enumerateKeysAndObjectsUsingBlock:^(id key, EVEDBInvMarketGroup* marketGroup, BOOL *stop) {
			[marketGroup.subgroups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]]];
		}];
		[lastGroups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]]];
		
		return lastGroups;
	};
	
	NSString* (^getRequest)(NSArray*, int32_t) = ^(NSArray* conditions, int32_t marketGroupID) {
		NSMutableSet* fromTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:[NSString stringWithFormat:@"invTypes.marketGroupID = %d", marketGroupID], @"invTypes.published = 1", nil];
		
		[fromTables unionSet:getConditionsTables(conditions)];
		[allConditions addObjectsFromArray:conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invTypes.* FROM invTypes \
							 WHERE invTypes.typeID IN \
							 (SELECT invTypes.typeID FROM %@ WHERE %@) GROUP BY invTypes.typeID",
							 [[fromTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		return request;
	};
	
	__weak __block void (^weakRecursiveFind)(EVEDBInvMarketGroup*, NCDBEufeItemCategory*, NCDBEufeItemGroup*, NSArray*, NSSet*);
	void (^recursiveFind)(EVEDBInvMarketGroup*, NCDBEufeItemCategory*, NCDBEufeItemGroup*, NSArray*, NSSet*) = ^(EVEDBInvMarketGroup* marketGroup, NCDBEufeItemCategory* category, NCDBEufeItemGroup* parentGroup, NSArray* conditions, NSSet* conditionsTables) {
		if (marketGroup.subgroups.count == 1) {
			NCDBEufeItemGroup* itemGroup = parentGroup;
			if (!itemGroup) {
				NCDBInvMarketGroup* invMarketGroup = invMarketGroups[@(marketGroup.marketGroupID)];
				
				itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemGroup" inManagedObjectContext:context];
				itemGroup.category = category;
				itemGroup.parentGroup = parentGroup;
				itemGroup.groupName = marketGroup.marketGroupName;
				itemGroup.icon = invMarketGroup.icon;
			}
			weakRecursiveFind(marketGroup.subgroups[0], category, itemGroup, conditions, conditionsTables);
		}
		else {
			NCDBInvMarketGroup* invMarketGroup = invMarketGroups[@(marketGroup.marketGroupID)];
			
			NCDBEufeItemGroup* itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemGroup" inManagedObjectContext:context];
			itemGroup.category = category;
			itemGroup.parentGroup = parentGroup;
			itemGroup.groupName = marketGroup.marketGroupName;
			itemGroup.icon = invMarketGroup.icon;

			if (marketGroup.subgroups.count > 1) {
				for (EVEDBInvMarketGroup* group in marketGroup.subgroups) {
					weakRecursiveFind(group, category, itemGroup, conditions, conditionsTables);
				}
			}
			else {
				NSString* request = getRequest(conditions, marketGroup.marketGroupID);
				[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
					NCDBInvType* invType = invTypes[@(type.typeID)];
					if (invType) {
						if (!invType.eufeItem)
							invType.eufeItem = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItem" inManagedObjectContext:context];
						[itemGroup addItemsObject:invType.eufeItem];
					}
				}];
			}
		}
	};
	
	weakRecursiveFind = recursiveFind;
	
	void (^process)(NSArray*, NCDBEufeItemCategory*) = ^(NSArray* conditions, NCDBEufeItemCategory* category) {
		NSSet* conditionsTables = getConditionsTables(conditions);
		NSArray* groups = getGroups(conditions, conditionsTables);
		for (EVEDBInvMarketGroup* group in groups) {
			recursiveFind(group, category, nil, conditions, conditionsTables);
		}
	};
	
	void (^chargeProcess)(NSArray*, NCDBEufeItemCategory*) = ^(NSArray* conditions, NCDBEufeItemCategory* category) {
		NSSet* conditionsTables = getConditionsTables(conditions);
		NSMutableSet* allTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invTypes.published=1", nil];
		
		[allTables unionSet:conditionsTables];
		[allConditions addObjectsFromArray:conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invTypes.* FROM %@ WHERE %@",
							 [[allTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
		NCDBEufeItemGroup* itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemGroup" inManagedObjectContext:context];
		itemGroup.category = category;
		itemGroup.parentGroup = nil;
		itemGroup.groupName = nil;
		itemGroup.icon = nil;
		
		[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
			EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
			NCDBInvType* invType = invTypes[@(type.typeID)];
			if (invType) {
				if (!invType.eufeItem)
					invType.eufeItem = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItem" inManagedObjectContext:context];
				[itemGroup addItemsObject:invType.eufeItem];
			}
		}];

	};
	
	NCDBEufeItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
	category.category = SLOT_HI;
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 12"], category);

	category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
	category.category = SLOT_MED;
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 13"], category);

	category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
	category.category = SLOT_LOW;
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 11"], category);
	
	[database execSQLRequest:@"select value from dgmTypeAttributes as a, dgmTypeEffects as b where b.effectID = 2663 AND attributeID=1547 AND a.typeID=b.typeID group by value;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t value = sqlite3_column_int(stmt, 0);
					 NCDBEufeItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_RIG;
					 category.subcategory = value;
					 process(@[@"dgmTypeEffects.typeID = invTypes.typeID",
							   @"dgmTypeEffects.effectID = 2663",
							   @"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 1547",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", value]], category);
				 }];

	[database execSQLRequest:@"select raceID from invTypes as a, dgmTypeEffects as b where b.effectID = 3772 AND a.typeID=b.typeID group by raceID;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t raceID = sqlite3_column_int(stmt, 0);
					 NCDBEufeItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_SUBSYSTEM;
					 category.race = chrRaces[@(raceID)];
					 process(@[@"dgmTypeEffects.typeID = invTypes.typeID",
							   @"dgmTypeEffects.effectID = 3772",
							   [NSString stringWithFormat:@"invTypes.raceID=%d", raceID]], category);
				 }];

	category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
	category.category = SLOT_SHIP;
	process(@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"], category);

	category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
	category.category = SLOT_DRONE;
	process(@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 18"], category);

	category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
	category.category = SLOT_CONTROL_TOWER;
	process(@[@"invTypes.marketGroupID = 478"], category);

	category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
	category.category = SLOT_STRUCTURE;
	process(@[@"invTypes.groupID <> 365",
			  @"invTypes.groupID = invGroups.groupID",
			  @"invGroups.categoryID = 23"], category);
	
	NSMutableDictionary* chargeCategories = [NSMutableDictionary new];
	[database execSQLRequest:@"SELECT b.* FROM dgmTypeAttributes as a, invTypes as b where a.attributeID in (604, 605, 606, 609, 610) and a.typeID=b.typeID group by a.typeID;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
					 EVEDBDgmTypeAttribute* chargeSizeAttribute = type.attributesDictionary[@128];
					 int32_t chargeSize = chargeSizeAttribute.value;
					 
					 NSMutableArray* groups = [NSMutableArray new];
					 for (NSNumber* attributeKey in @[@604, @605, @606, @609, @610]) {
						 EVEDBDgmTypeAttribute* attribute = type.attributesDictionary[attributeKey];
						 if (attribute) {
							 [groups addObject:@((int32_t) attribute.value)];
						 }
					 }
					 
					 if (groups.count > 0) {
						 NSString* key;
						 if (chargeSizeAttribute > 0)
							 key = [NSString stringWithFormat:@"%@.%d", [[groups sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","], (int32_t) chargeSize];
						 else
							 key = [NSString stringWithFormat:@"%@.%.2f", [[groups sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","], type.capacity];
						 
						 NCDBEufeItemCategory* category = chargeCategories[key];
						 if (!category) {
							 chargeCategories[key] = category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
							 category.category = SLOT_CHARGE;
							 category.subcategory = chargeSize;
							 
							 if (chargeSizeAttribute) {
								 chargeProcess(@[@"invTypes.typeID=dgmTypeAttributes.typeID",
												 @"dgmTypeAttributes.attributeID=128",
												 [NSString stringWithFormat:@"dgmTypeAttributes.value=%d", chargeSize],
												 [NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]]], category);
							 }
							 else {
								 chargeProcess(@[[NSString stringWithFormat:@"groupID IN (%@)", [groups componentsJoinedByString:@","]],
												 [NSString stringWithFormat:@"invTypes.volume <= %f", type.capacity]], category);
							 }
						 }
						 NCDBInvType* invType = invTypes[@(type.typeID)];
						 invType.eufeItem.charge = category;
					 }
				 }];
	
	[database execSQLRequest:@"select value from dgmTypeAttributes as a, invTypes as b where attributeID=331 and a.typeID=b.typeID and b.published = 1 group by value;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t slot = sqlite3_column_int(stmt, 0);
					 NCDBEufeItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_IMPLANT;
					 category.subcategory = slot;
					 process(@[@"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 331",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", slot]], category);
				 }];
	[database execSQLRequest:@"select value from dgmTypeAttributes as a, invTypes as b where attributeID=1087 and a.typeID=b.typeID and b.published = 1 group by value;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t slot = sqlite3_column_int(stmt, 0);
					 NCDBEufeItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"EufeItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_BOOSTER;
					 category.subcategory = slot;
					 process(@[@"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 1087",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", slot]], category);
				 }];
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
			convertInvMetaTypes(context, database);
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
//			convertMapDenormalize(context, database);
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
			NSLog(@"convertRequiredSkills");
			convertRequiredSkills(context);
			NSLog(@"convertEufeItems");
			convertEufeItems(context, database);
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

