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
#import "NSMutableString+HTML.h"
#import <dgmpp/dgmpp.h>
#import <objc/runtime.h>

#define NCDBExpansion @"Mosaic"

#define NCDBCertMasteryLevelIconsStartID 1000000
#define NCDBCertCertificateDisplayNameTranslationColumnID 1000
#define NCDBCertCertificateDescriptionTranslationColumnID 1001
#define NCDBCertMasteryLevelDisplayNameTranslationColumnID 1002
#define NCDBInvControlTowerResourcePurposeDisplayNameTranslationColumnID 1003
#define NCDBRamAssemblyLineTypeDisplayNameTranslationColumnID 1004

#define NCDBMetaGroupAttributeID 1692
#define NCDBMetaLevelAttributeID 633

typedef enum : uint32_t {
	/* Typeface info (lower 16 bits of UIFontDescriptorSymbolicTraits ) */
	UIFontDescriptorTraitItalic = 1u << 0,
	UIFontDescriptorTraitBold = 1u << 1,
	UIFontDescriptorTraitExpanded = 1u << 5,
	UIFontDescriptorTraitCondensed = 1u << 6,
	UIFontDescriptorTraitMonoSpace = 1u << 10,
	UIFontDescriptorTraitVertical = 1u << 11,
	UIFontDescriptorTraitUIOptimized = 1u << 12,
	UIFontDescriptorTraitTightLeading = 1u << 15,
	UIFontDescriptorTraitLooseLeading = 1u << 16,
	
	/* Font appearance info (upper 16 bits of UIFontDescriptorSymbolicTraits */
	UIFontDescriptorClassMask = 0xF0000000,
	
	UIFontDescriptorClassUnknown = 0u << 28,
	UIFontDescriptorClassOldStyleSerifs = 1u << 28,
	UIFontDescriptorClassTransitionalSerifs = 2u << 28,
	UIFontDescriptorClassModernSerifs = 3u << 28,
	UIFontDescriptorClassClarendonSerifs = 4u << 28,
	UIFontDescriptorClassSlabSerifs = 5u << 28,
	UIFontDescriptorClassFreeformSerifs = 7u << 28,
	UIFontDescriptorClassSansSerif = 8u << 28,
	UIFontDescriptorClassOrnamentals = 9u << 28,
	UIFontDescriptorClassScripts = 10u << 28,
	UIFontDescriptorClassSymbolic = 12u << 28
	
} UIFontDescriptorSymbolicTraits;

NSString* databasePath;
NSString* evedbPath;
NSString* iconsPath;
NSString* typesPath;
NSString* factionsPath;


@interface NSColor(NCDatabase)

+ (instancetype) colorWithString:(NSString*) string;
+ (instancetype) colorWithUInteger:(NSUInteger) rgba;
@end


@implementation NSColor(NCDatabase)

+ (instancetype) colorWithString:(NSString*) string {
	unsigned int rgba;
	if ([[NSScanner scannerWithString:string] scanHexInt:&rgba]) {
		return [self colorWithUInteger:rgba];
	}
	else {
		NSString* key = [string capitalizedString];
		for (NSColorList* colorList in [NSColorList availableColorLists]) {
			NSColor* color = [colorList colorWithKey:key];
			if (color)
				return color;
		}
	}
	return nil;
}

+ (instancetype) colorWithUInteger:(NSUInteger) argb {
	float components[4];
	for (int i = 3; i > 0; i--) {
		components[i - 1] = (argb & 0xff) / 255.0;
		argb >>= 8;
	}
	components[3] = (argb & 0xff) / 255.0;
	return [NSColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
}

@end


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
NSDictionary* indBlueprintTypes;
NSDictionary* indActivities;
NSDictionary* indProducts;

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
	//NSManagedObjectModel* storageModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"NCStorage.momd"]]];
	//model = [NSManagedObjectModel modelByMergingModels:@[storageModel, model]];
	//return storageModel;
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
        
        NSURL *url = [NSURL fileURLWithPath:databasePath];
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

static NSAttributedString* attributedStringFromHTMLString(NSString* html) {
	if (!html)
		return [[NSAttributedString alloc] initWithString:@"" attributes:nil];
	NSMutableString* mHtml = [html mutableCopy];
	[mHtml replaceOccurrencesOfString:@"<br>" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, mHtml.length)];
	[mHtml replaceOccurrencesOfString:@"<p>" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, mHtml.length)];
	
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:mHtml attributes:nil];

	
	NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:@"<(a[^>]*href|url)=[\"']?(.*?)[\"']?>(.*?)<\\/(a|url)>"
																				   options:NSRegularExpressionCaseInsensitive
																				  error:nil];
	
	NSTextCheckingResult* result;
	while ((result = [expression firstMatchInString:s.string options:0 range:NSMakeRange(0, s.length)]) != nil) {
		NSMutableAttributedString* replace = [[s attributedSubstringFromRange:[result rangeAtIndex:3]] mutableCopy];
		[replace addAttribute:@"NSURL" value:[NSURL URLWithString:[[s.string substringWithRange:[result rangeAtIndex:2]] stringByReplacingOccurrencesOfString:@" " withString:@""]] range:NSMakeRange(0, replace.length)];
		[s replaceCharactersInRange:[result rangeAtIndex:0] withAttributedString:replace];
	}
	
	expression = [NSRegularExpression regularExpressionWithPattern:@"<b[^>]*>(.*?)</b>"
														   options:NSRegularExpressionCaseInsensitive
															 error:nil];
	
	while ((result = [expression firstMatchInString:s.string options:0 range:NSMakeRange(0, s.length)]) != nil) {
		NSMutableAttributedString* replace = [[s attributedSubstringFromRange:[result rangeAtIndex:1]] mutableCopy];
		[replace addAttribute:@"UIFontDescriptorSymbolicTraits" value:@(UIFontDescriptorTraitBold) range:NSMakeRange(0, replace.length)];
		[s replaceCharactersInRange:[result rangeAtIndex:0] withAttributedString:replace];
	}
	
	expression = [NSRegularExpression regularExpressionWithPattern:@"<i[^>]*>(.*?)</i>"
														   options:NSRegularExpressionCaseInsensitive
															 error:nil];
	
	while ((result = [expression firstMatchInString:s.string options:0 range:NSMakeRange(0, s.length)]) != nil) {
		NSMutableAttributedString* replace = [[s attributedSubstringFromRange:[result rangeAtIndex:1]] mutableCopy];
		[replace addAttribute:@"UIFontDescriptorSymbolicTraits" value:@(UIFontDescriptorTraitItalic) range:NSMakeRange(0, replace.length)];
		[s replaceCharactersInRange:[result rangeAtIndex:0] withAttributedString:replace];
	}

	expression = [NSRegularExpression regularExpressionWithPattern:@"<u[^>]*>(.*?)</u>"
														   options:NSRegularExpressionCaseInsensitive
															 error:nil];
	
	while ((result = [expression firstMatchInString:s.string options:0 range:NSMakeRange(0, s.length)]) != nil) {
		NSMutableAttributedString* replace = [[s attributedSubstringFromRange:[result rangeAtIndex:1]] mutableCopy];
		[replace addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, replace.length)];
		[s replaceCharactersInRange:[result rangeAtIndex:0] withAttributedString:replace];
	}
	
	expression = [NSRegularExpression regularExpressionWithPattern:@"<(color|font)[^>]*=[\"']?(.*?)[\"']?\\s*?>(.*?)</(color|font)>"
														   options:NSRegularExpressionCaseInsensitive
															 error:nil];
	
	while ((result = [expression firstMatchInString:s.string options:0 range:NSMakeRange(0, s.length)]) != nil) {
		NSString* colorString = [s.string substringWithRange:[result rangeAtIndex:2]];
		NSColor* color = [NSColor colorWithString:colorString];
		
		NSMutableAttributedString* replace = [[s attributedSubstringFromRange:[result rangeAtIndex:3]] mutableCopy];
		if (color)
			[replace addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, replace.length)];
		[s replaceCharactersInRange:[result rangeAtIndex:0] withAttributedString:replace];
	}

	expression = [NSRegularExpression regularExpressionWithPattern:@"</?.*?>"
														   options:NSRegularExpressionCaseInsensitive
															 error:nil];
	
	while ((result = [expression firstMatchInString:s.string options:0 range:NSMakeRange(0, s.length)]) != nil)
		[s replaceCharactersInRange:result.range withAttributedString:[[NSAttributedString alloc] initWithString:@"" attributes:nil]];
	
	[s.mutableString unescapeHTML];

	return s;
}

NSDictionary* convertEveIcons(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"select * from eveIcons" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBEveIcon* eveIcon = [[EVEDBEveIcon alloc] initWithStatement:stmt];
		NSString* iconImageName = nil;
		if ([eveIcon.iconFile hasPrefix:@"res:/"])
			iconImageName = [NSString stringWithFormat:@"%@/%@", iconsPath, [eveIcon.iconFile lastPathComponent]];
		else
			iconImageName = [NSString stringWithFormat:@"%@/icon%@.png", iconsPath, eveIcon.iconFile];
		
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
	
	for (NSString* iconNo in @[@"09_07", @"105_32", @"50_13", @"38_193", @"38_194", @"38_195", @"38_174", @"17_04", @"74_14", @"79_01", @"23_03", @"18_02", @"33_02"]) {
		__block EVEDBEveIcon* eveIcon = nil;
		[database execSQLRequest:[NSString stringWithFormat:@"select * from eveIcons where iconFile=\"%@\"", iconNo]
					 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
						 *needsMore = NO;
						 eveIcon = [[EVEDBEveIcon alloc] initWithStatement:stmt];
					 }];
		if (!eveIcon) {
			NCDBEveIcon* icon = dictionary[iconNo];
			if (!icon) {
				NSString* iconImageName = [NSString stringWithFormat:@"%@/icon%@.png", iconsPath, iconNo];
				
				NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
				if (data) {
					NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
					NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
					icon.iconFile = iconNo;
					icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
					icon.image.image = imageRep;
					dictionary[iconNo] = icon;
				}
				else {
					NSLog(@"Unable to load icon %@", iconNo);
				}
			}
		}
	}
	
	for (int i = 0; i <= 5; i++) {
		NSString* iconImageName = [NSString stringWithFormat:@"%@/icon79_0%d.png", iconsPath, i + 1];
		NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
		if (data) {
			NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
			icon.iconFile = [NSString stringWithFormat:@"79_0%d", i + 1];
			icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
			icon.image.image = imageRep;
			dictionary[@(NCDBCertMasteryLevelIconsStartID + i)] = icon;
		}
		else
			NSLog(@"Unable to load icon %@", iconImageName);
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
					NSString* iconImageName = [NSString stringWithFormat:@"%@/icon%@.png", iconsPath, eveActivity.iconNo];
					
					NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
					if (data) {
						NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
						NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
						icon.iconFile = eveActivity.iconNo;
						icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
						icon.image.image = imageRep;
						dictionary[eveActivity.iconNo] = icon;
					}
					NSLog(@"Unable to load icon %@", eveActivity.iconNo);
				}
			}
		}
	}];
	
	[database execSQLRequest:@"SELECT * FROM npcGroup WHERE iconName IS NOT NULL GROUP BY iconName" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBNpcGroup* eveNpcGroup = [[EVEDBNpcGroup alloc] initWithStatement:stmt];
		NSString* iconImageName = [NSString stringWithFormat:@"%@/%@@2x.png", factionsPath, [eveNpcGroup.iconName stringByDeletingPathExtension]];
		
		NSData* data = [[NSData alloc] initWithContentsOfFile:iconImageName];
		if (data) {
			NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:data];
			NCDBEveIcon* icon = [NSEntityDescription insertNewObjectForEntityForName:@"EveIcon" inManagedObjectContext:context];
			icon.iconFile = eveNpcGroup.iconName;
			icon.image = [NSEntityDescription insertNewObjectForEntityForName:@"EveIconImage" inManagedObjectContext:context];
			icon.image.image = imageRep;
			dictionary[eveNpcGroup.iconName] = icon;
		}
		else
			NSLog(@"Unable to load icon %@", eveNpcGroup.iconName);
	}];
	
	[database execSQLRequest:@"SELECT * FROM invTypes WHERE imageName IS NOT NULL GROUP BY imageName" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvType* eveType = [[EVEDBInvType alloc] initWithStatement:stmt];
		NSString* iconImageName = [NSString stringWithFormat:@"%@/%@.png", typesPath, eveType.imageName];
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
	
	NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:@"\\\\u(.{4})"
																				options:NSRegularExpressionCaseInsensitive
									   
																				  error:nil];

	[database execSQLRequest:@"select * from invTypes" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvType* eveType = [[EVEDBInvType alloc] initWithStatement:stmt];
		if (!eveType.typeName)
			return;
		NCDBEveIcon* icon = eveType.imageName ? eveIcons[eveType.imageName] : nil;
		
		NCDBInvType* type = [NSEntityDescription insertNewObjectForEntityForName:@"InvType" inManagedObjectContext:context];
		type.typeID = eveType.typeID;
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
		
		NSMutableString* typeName = [NSMutableString stringWithString:eveType.typeName];
		NSMutableDictionary* ranges = [NSMutableDictionary new];
		for (NSTextCheckingResult* m in [expression matchesInString:typeName options:0 range:NSMakeRange(0, typeName.length)]) {
			NSString* s2 = [typeName substringWithRange:[m rangeAtIndex:1]];
			NSScanner* scanner = [NSScanner scannerWithString:s2];
			unsigned int i;
			unichar *u = (unichar*) &i;
			[scanner scanHexInt:&i];
			NSString* s3 = [NSString stringWithCharacters:u length:1];
			ranges[@([m rangeAtIndex:0].location)] = @{@"string": s3, @"range":[NSValue valueWithRange:[m rangeAtIndex:0]]};
		}
		for (NSString* key in [[[ranges allKeys] sortedArrayUsingSelector:@selector(compare:)] reverseObjectEnumerator]) {
			NSDictionary* obj = ranges[key];
			NSRange range = [obj[@"range"] rangeValue];
			NSString* string = obj[@"string"];
			[typeName replaceCharactersInRange:range withString:string];
		}

		type.typeName = typeName;

		
		if (icon)
			type.icon = icon;
		else {
			if (eveType.iconID > 0) {
				type.icon = eveIcons[@(eveType.iconID)];
			}
		}
		
		dictionary[@(eveType.typeID)] = type;
		
		NSMutableString* description = [eveType.description mutableCopy];
		//[description replaceOccurrencesOfString:@"\\r" withString:@"" options:0 range:NSMakeRange(0, description.length)];
		//[description replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, description.length)];
		//[description replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, description.length)];
		
		if (eveType.traitsString.length > 0) {
			if (description)
				[description appendFormat:@"\n%@", eveType.traitsString];
			else
				description = [eveType.traitsString mutableCopy];
		}
		
		type.typeDescription = [NSEntityDescription insertNewObjectForEntityForName:@"TxtDescription" inManagedObjectContext:context];
		type.typeDescription.text = attributedStringFromHTMLString(description);
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
		if (invTypes[@(eveTypeAttribute.typeID)]) {
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
		}
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
		NCDBInvType* type = invTypes[@(eveTypeEffect.typeID)];
		if (type)
			[effect addTypesObject:type];
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
		certificate.certificateDescription.text = attributedStringFromHTMLString(eveCertificate.description);
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

/*void convertInvBlueprintTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
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
}*/

/*void convertInvTypeMaterials(NSManagedObjectContext* context, EVEDBDatabase* database) {
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
}*/

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

/*void convertRamTypeRequirements(NSManagedObjectContext* context, EVEDBDatabase* database) {
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
}*/

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

NSDictionary* convertIndustryBlueprints(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM industryBlueprints" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBIndustryBlueprint* eveBlueprint = [[EVEDBIndustryBlueprint alloc] initWithStatement:stmt];
		NCDBIndBlueprintType* blueprintType = [NSEntityDescription insertNewObjectForEntityForName:@"IndBlueprintType" inManagedObjectContext:context];
		blueprintType.type = invTypes[@(eveBlueprint.typeID)];
		blueprintType.maxProductionLimit = eveBlueprint.maxProductionLimit;
		dictionary[@(eveBlueprint.typeID)] = blueprintType;
	}];
	
	return dictionary;
}

NSDictionary* convertIndustryActivity(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM industryActivity" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBIndustryActivity* eveActivity = [[EVEDBIndustryActivity alloc] initWithStatement:stmt];
		NCDBIndActivity* activity = [NSEntityDescription insertNewObjectForEntityForName:@"IndActivity" inManagedObjectContext:context];
		activity.time = eveActivity.time;
		activity.activity = ramActivities[@(eveActivity.activityID)];
		activity.blueprintType = indBlueprintTypes[@(eveActivity.typeID)];
		dictionary[[NSString stringWithFormat:@"%d.%d", eveActivity.typeID, eveActivity.activityID]] = activity;
	}];
	
	return dictionary;
}

void convertIndustryActivityMaterials(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM industryActivityMaterials" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBIndustryActivityMaterial* eveActivityMaterial = [[EVEDBIndustryActivityMaterial alloc] initWithStatement:stmt];
		NCDBIndRequiredMaterial* requiredMaterial = [NSEntityDescription insertNewObjectForEntityForName:@"IndRequiredMaterial" inManagedObjectContext:context];
		requiredMaterial.materialType = invTypes[@(eveActivityMaterial.materialTypeID)];
		requiredMaterial.quantity = eveActivityMaterial.quantity;
		requiredMaterial.activity = indActivities[[NSString stringWithFormat:@"%d.%d", eveActivityMaterial.typeID, eveActivityMaterial.activityID]];
	}];
}

NSDictionary* convertIndustryActivityProducts(NSManagedObjectContext* context, EVEDBDatabase* database) {
	NSMutableDictionary* dictionary = [NSMutableDictionary new];
	
	[database execSQLRequest:@"SELECT * FROM industryActivityProducts" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBIndustryActivityProduct* eveProduct = [[EVEDBIndustryActivityProduct alloc] initWithStatement:stmt];
		NCDBIndProduct* product = [NSEntityDescription insertNewObjectForEntityForName:@"IndProduct" inManagedObjectContext:context];
		product.quantity = eveProduct.quantity;
		product.productType = invTypes[@(eveProduct.productTypeID)];
		product.activity = indActivities[[NSString stringWithFormat:@"%d.%d", eveProduct.typeID, eveProduct.activityID]];
		dictionary[[NSString stringWithFormat:@"%d.%d.%d", eveProduct.typeID, eveProduct.activityID, eveProduct.productTypeID]] = product;
	}];
	
	return dictionary;
}

void convertIndustryActivityProbabilities(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM industryActivityProbabilities" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBIndustryActivityProbability* eveActivityProbability = [[EVEDBIndustryActivityProbability alloc] initWithStatement:stmt];
		NCDBIndProduct* product = indProducts[[NSString stringWithFormat:@"%d.%d.%d", eveActivityProbability.typeID, eveActivityProbability.activityID, eveActivityProbability.productTypeID]];
		product.probability = eveActivityProbability.probability;
	}];
}

/*void convertIndustryActivityRaces(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM industryActivityRaces" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBIndustryActivityRace* eveActivityRace = [[EVEDBIndustryActivityRace alloc] initWithStatement:stmt];
		NCDBIndProduct* product = indProducts[[NSString stringWithFormat:@"%d.%d.%d", eveActivityRace.typeID, eveActivityRace.activityID, eveActivityRace.productTypeID]];
		product.race = chrRaces[@(eveActivityRace.raceID)];
	}];
}*/

void convertIndustryActivitySkills(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM industryActivitySkills" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBIndustryActivitySkill* eveActivitySkill = [[EVEDBIndustryActivitySkill alloc] initWithStatement:stmt];
		NCDBIndRequiredSkill* requiredSkill = [NSEntityDescription insertNewObjectForEntityForName:@"IndRequiredSkill" inManagedObjectContext:context];
		requiredSkill.skillLevel = eveActivitySkill.level;
		requiredSkill.activity = indActivities[[NSString stringWithFormat:@"%d.%d", eveActivitySkill.typeID, eveActivitySkill.activityID]];
		requiredSkill.skillType = invTypes[@(eveActivitySkill.skillID)];
	}];
}

typedef enum {
	SLOT_NONE = dgmpp::Module::SLOT_NONE,
	SLOT_HI,
	SLOT_MED,
	SLOT_LOW,
	SLOT_RIG,
	SLOT_SUBSYSTEM,
	SLOT_STARBASE_STRUCTURE,
	SLOT_MODE,
	SLOT_CHARGE,
	SLOT_DRONE,
	SLOT_IMPLANT,
	SLOT_BOOSTER,
	SLOT_SHIP,
	SLOT_CONTROL_TOWER,
	SLOT_SPACE_STRUCTURE,
	SLOT_STRUCTURE_RIG,
	SLOT_STRUCTURE_SERVICE,
	SLOT_STRUCTURE_DRONE
} Slot;

void convertDgmppItems(NSManagedObjectContext* context, EVEDBDatabase* database) {
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
	
	NSArray* (^getMarketGroups)(NSArray*, NSSet*) = ^(NSArray* conditions, NSSet* conditionsTables) {
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
		NSMutableArray* allConditions = marketGroupID > 0 ? [[NSMutableArray alloc] initWithObjects:[NSString stringWithFormat:@"invTypes.marketGroupID = %d", marketGroupID], @"invTypes.published = 1", nil] : [NSMutableArray new];
		
		[fromTables unionSet:getConditionsTables(conditions)];
		[allConditions addObjectsFromArray:conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invTypes.* FROM invTypes \
							 WHERE invTypes.typeID IN \
							 (SELECT invTypes.typeID FROM %@ WHERE %@) GROUP BY invTypes.typeID",
							 [[fromTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		return request;
	};
	
	float (^getAttributeValue)(NCDBInvType*, int32_t) = ^(NCDBInvType* type, int32_t attributeID) {
		return [(NCDBDgmTypeAttribute*) [[type.attributes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"attributeType.attributeID==%d", attributeID]] anyObject] value];
	};
	
	void (^loadDetails)(NCDBDgmppItem*) = ^(NCDBDgmppItem* item) {
		NCDBDgmppItemGroup* group = [item.groups anyObject];
		switch (group.category.category) {
			case SLOT_HI:
			case SLOT_MED:
			case SLOT_LOW:
			case SLOT_RIG:
			case SLOT_STARBASE_STRUCTURE: {
				item.requirements = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemRequirements" inManagedObjectContext:context];
				item.requirements.powerGrid = getAttributeValue(item.type, 30);
				item.requirements.cpu = getAttributeValue(item.type, 50);
				item.requirements.calibration = getAttributeValue(item.type, 1153);
				break;
			}
			case SLOT_CHARGE:
			case SLOT_DRONE: {
				item.damage = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemDamage" inManagedObjectContext:context];
				float multiplier = MAX(getAttributeValue(item.type, 64), getAttributeValue(item.type, 212));
				multiplier = MAX(multiplier, 1);
				item.damage.emAmount = getAttributeValue(item.type, 114) * multiplier;
				item.damage.kineticAmount = getAttributeValue(item.type, 117) * multiplier;
				item.damage.thermalAmount = getAttributeValue(item.type, 118) * multiplier;
				item.damage.explosiveAmount = getAttributeValue(item.type, 116) * multiplier;
				break;
			}
			case SLOT_SHIP: {
				item.shipResources = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemShipResources" inManagedObjectContext:context];
				item.shipResources.hiSlots = getAttributeValue(item.type, 14);
				item.shipResources.medSlots = getAttributeValue(item.type, 13);
				item.shipResources.lowSlots = getAttributeValue(item.type, 12);
				item.shipResources.rigSlots = getAttributeValue(item.type, 1137);
				item.shipResources.turrets = getAttributeValue(item.type, 102);
				item.shipResources.launchers = getAttributeValue(item.type, 101);
				break;
			}
			case SLOT_SPACE_STRUCTURE: {
				item.spaceStructureResources = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemSpaceStructureResources" inManagedObjectContext:context];
				item.spaceStructureResources.hiSlots = getAttributeValue(item.type, 14);
				item.spaceStructureResources.medSlots = getAttributeValue(item.type, 13);
				item.spaceStructureResources.lowSlots = getAttributeValue(item.type, 12);
				item.spaceStructureResources.rigSlots = getAttributeValue(item.type, 1137);
				item.spaceStructureResources.serviceSlots = getAttributeValue(item.type, 2056);
				item.spaceStructureResources.turrets = getAttributeValue(item.type, 102);
				item.spaceStructureResources.launchers = getAttributeValue(item.type, 101);
				break;
			}
			default:
				break;
		}
	};

	__weak __block void (^weakRecursiveFind)(EVEDBInvMarketGroup*, NCDBDgmppItemCategory*, NCDBDgmppItemGroup*, NSArray*, NSSet*);
	void (^recursiveFind)(EVEDBInvMarketGroup*, NCDBDgmppItemCategory*, NCDBDgmppItemGroup*, NSArray*, NSSet*) = ^(EVEDBInvMarketGroup* marketGroup, NCDBDgmppItemCategory* category, NCDBDgmppItemGroup* itemGroup, NSArray* conditions, NSSet* conditionsTables) {
		if (marketGroup.subgroups.count == 1) {
			weakRecursiveFind(marketGroup.subgroups[0], category, itemGroup, conditions, conditionsTables);
		}
		else {
			
			if (marketGroup.subgroups.count > 1) {
				for (EVEDBInvMarketGroup* group in marketGroup.subgroups) {
					NCDBInvMarketGroup* invMarketGroup = invMarketGroups[@(group.marketGroupID)];
					NCDBDgmppItemGroup* subGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
					subGroup.category = category;
					subGroup.parentGroup = itemGroup;
					subGroup.groupName = group.marketGroupName;
					subGroup.icon = invMarketGroup.icon;

					weakRecursiveFind(group, category, subGroup, conditions, conditionsTables);
				}
			}
			else {
				NSString* request = getRequest(conditions, marketGroup.marketGroupID);
				[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
					NCDBInvType* invType = invTypes[@(type.typeID)];
					if (invType) {
						if (!invType.dgmppItem) {
							invType.dgmppItem = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItem" inManagedObjectContext:context];
							[itemGroup addItemsObject:invType.dgmppItem];
							loadDetails(invType.dgmppItem);
						}
						else
							[itemGroup addItemsObject:invType.dgmppItem];
					}
				}];
			}
		}
	};
	
	weakRecursiveFind = recursiveFind;
	
	void (^process)(NSArray*, NCDBDgmppItemCategory*, NSString*) = ^(NSArray* conditions, NCDBDgmppItemCategory* category, NSString* title) {
		NCDBDgmppItemGroup* parentGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
		parentGroup.category = category;
		parentGroup.parentGroup = nil;
		parentGroup.groupName = title;
		parentGroup.icon = nil;

		NSSet* conditionsTables = getConditionsTables(conditions);
		NSArray* groups = getMarketGroups(conditions, conditionsTables);
		for (EVEDBInvMarketGroup* group in groups) {
			NCDBDgmppItemGroup* itemGroup;
			if (groups.count > 1) {
				NCDBInvMarketGroup* invMarketGroup = invMarketGroups[@(group.marketGroupID)];
				itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
				itemGroup.category = category;
				itemGroup.parentGroup = parentGroup;
				itemGroup.groupName = group.marketGroupName;
				itemGroup.icon = invMarketGroup.icon;
			}
			else
				itemGroup = parentGroup;

			recursiveFind(group, category, itemGroup, conditions, conditionsTables);
		}
	};
	
	void (^chargeProcess)(NSArray*, NCDBDgmppItemCategory*) = ^(NSArray* conditions, NCDBDgmppItemCategory* category) {
		NSSet* conditionsTables = getConditionsTables(conditions);
		NSMutableSet* allTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invTypes.published=1", nil];
		
		[allTables unionSet:conditionsTables];
		[allConditions addObjectsFromArray:conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invTypes.* FROM %@ WHERE %@",
							 [[allTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
		NCDBDgmppItemGroup* itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
		itemGroup.category = category;
		itemGroup.parentGroup = nil;
		itemGroup.groupName = @"Ammo";
		itemGroup.icon = nil;
		
		[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
			EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
			NCDBInvType* invType = invTypes[@(type.typeID)];
			if (invType) {
				if (!invType.dgmppItem) {
					invType.dgmppItem = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItem" inManagedObjectContext:context];
					[itemGroup addItemsObject:invType.dgmppItem];
					loadDetails(invType.dgmppItem);
				}
				else
					[itemGroup addItemsObject:invType.dgmppItem];
			}
		}];

	};
	void (^structureProcess)(NSArray*, NCDBDgmppItemCategory*, NSString*) = ^(NSArray* conditions, NCDBDgmppItemCategory* category, NSString* title) {
		NSSet* conditionsTables = getConditionsTables(conditions);
		NSMutableSet* allTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [conditions mutableCopy];
		
		[allTables unionSet:conditionsTables];
		[allConditions addObjectsFromArray:conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invTypes.* FROM %@ WHERE %@",
							 [[allTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
		NCDBDgmppItemGroup* itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
		itemGroup.category = category;
		itemGroup.parentGroup = nil;
		itemGroup.groupName = title;
		itemGroup.icon = nil;
		
		[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
			EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
			NCDBInvType* invType = invTypes[@(type.typeID)];
			if (invType) {
				if (!invType.dgmppItem) {
					invType.dgmppItem = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItem" inManagedObjectContext:context];
					[itemGroup addItemsObject:invType.dgmppItem];
					loadDetails(invType.dgmppItem);
				}
				else
					[itemGroup addItemsObject:invType.dgmppItem];
			}
		}];
	};
	
	void (^structureDroneProcess)(NSArray*, NCDBDgmppItemCategory*, NSString*) = ^(NSArray* conditions, NCDBDgmppItemCategory* category, NSString* title) {
		NSSet* conditionsTables = getConditionsTables(conditions);
		NSMutableSet* allTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [conditions mutableCopy];
		
		[allTables unionSet:conditionsTables];
		[allConditions addObjectsFromArray:conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invTypes.* FROM %@ WHERE %@",
							 [[allTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
		NCDBDgmppItemGroup* rootGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
		rootGroup.category = category;
		rootGroup.parentGroup = nil;
		rootGroup.groupName = title;
		rootGroup.icon = nil;
		
		NSMutableDictionary* groups = [NSMutableDictionary new];
		
		[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
			EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
			NCDBInvType* invType = invTypes[@(type.typeID)];
			if (invType) {
				NCDBInvGroup* invGroup = invType.group;
				NCDBDgmppItemGroup* itemGroup = groups[@(invGroup.groupID)];
				if (!itemGroup) {
					groups[@(invGroup.groupID)] = itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
					itemGroup.category = category;
					itemGroup.parentGroup = rootGroup;
					itemGroup.groupName = invGroup.groupName;
					itemGroup.icon = invGroup.icon;
				}
				
				if (!invType.dgmppItem) {
					invType.dgmppItem = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItem" inManagedObjectContext:context];
					[itemGroup addItemsObject:invType.dgmppItem];
					loadDetails(invType.dgmppItem);
				}
				else
					[itemGroup addItemsObject:invType.dgmppItem];
			}
		}];
	};
	
	NCDBDgmppItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_HI;
	category.subcategory = dgmpp::MODULE_CATEGORY_ID;
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 12", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 7"], category, @"Hi Slot");

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_MED;
	category.subcategory = dgmpp::MODULE_CATEGORY_ID;
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 13", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 7"], category, @"Med Slot");

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_LOW;
	category.subcategory = dgmpp::MODULE_CATEGORY_ID;
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 11", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 7"], category, @"Low Slot");
	
	
	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_HI;
	category.subcategory = dgmpp::STRUCTURE_MODULE_CATEGORY_ID;
	//structureProcess(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 12", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Hi Slot");
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 12", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Hi Slot");

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_MED;
	category.subcategory = dgmpp::STRUCTURE_MODULE_CATEGORY_ID;
	//structureProcess(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 13", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Med Slot");
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 13", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Med Slot");
	
	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_LOW;
	category.subcategory = dgmpp::STRUCTURE_MODULE_CATEGORY_ID;
	//structureProcess(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 11", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Low Slot");
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 11", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Low Slot");

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_STRUCTURE_SERVICE;
	category.subcategory = dgmpp::STRUCTURE_MODULE_CATEGORY_ID;
	//structureProcess(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 6306", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Service Slot");
	process(@[@"dgmTypeEffects.typeID = invTypes.typeID", @"dgmTypeEffects.effectID = 6306", @"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 66"], category, @"Service Slot");

	
	
	[database execSQLRequest:@"select value from dgmTypeAttributes as a, dgmTypeEffects as b, invTypes as c, invGroups as d where b.effectID = 2663 AND attributeID=1547 AND a.typeID=b.typeID AND b.typeID=c.typeID AND c.groupID = d.groupID AND d.categoryID = 7 group by value;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t value = sqlite3_column_int(stmt, 0);
					 NCDBDgmppItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_RIG;
					 category.subcategory = value;
					 process(@[@"dgmTypeEffects.typeID = invTypes.typeID",
							   @"dgmTypeEffects.effectID = 2663",
							   @"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 1547",
							   @"invGroups.groupID = invTypes.groupID",
							   @"invGroups.categoryID = 7",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", value]], category, @"Rig Slot");
				 }];

	[database execSQLRequest:@"select value from dgmTypeAttributes as a, dgmTypeEffects as b, invTypes as c, invGroups as d where b.effectID = 2663 AND attributeID=1547 AND a.typeID=b.typeID AND b.typeID=c.typeID AND c.groupID = d.groupID AND d.categoryID = 66 group by value;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t value = sqlite3_column_int(stmt, 0);
					 NCDBDgmppItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_STRUCTURE_RIG;
					 category.subcategory = value;
					 structureProcess(@[@"dgmTypeEffects.typeID = invTypes.typeID",
							   @"dgmTypeEffects.effectID = 2663",
							   @"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 1547",
							   @"invGroups.groupID = invTypes.groupID",
							   @"invGroups.categoryID = 66",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", value]], category, @"Rig Slot");
				 }];

	[database execSQLRequest:@"select raceID from invTypes as a, dgmTypeEffects as b where b.effectID = 3772 AND a.typeID=b.typeID group by raceID;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t raceID = sqlite3_column_int(stmt, 0);
					 NCDBDgmppItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_SUBSYSTEM;
					 category.subcategory = dgmpp::MODULE_CATEGORY_ID;
					 category.race = chrRaces[@(raceID)];
					 process(@[@"dgmTypeEffects.typeID = invTypes.typeID",
							   @"dgmTypeEffects.effectID = 3772",
							   [NSString stringWithFormat:@"invTypes.raceID=%d", raceID]], category, @"Subsystems");
				 }];

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_SHIP;
	process(@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"], category, @"Ships");

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_DRONE;
	category.subcategory = dgmpp::DRONE_CATEGORY_ID;
	process(@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 18"], category, @"Drones");
	
	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_DRONE;
	category.subcategory = dgmpp::FIGHTER_CATEGORY_ID;
	//structureDroneProcess(@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 87"], category, @"Drones");
	process(@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 87"], category, @"Drones");

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_CONTROL_TOWER;
	process(@[@"invTypes.marketGroupID = 478"], category, @"Control Towers");

	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_STARBASE_STRUCTURE;
	process(@[@"invTypes.groupID <> 365",
			  @"invTypes.groupID = invGroups.groupID",
			  @"invGroups.categoryID = 23"], category, @"Structures");
	
	
	category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
	category.category = SLOT_SPACE_STRUCTURE;
	process(@[@"invTypes.marketGroupID = invMarketGroups.marketGroupID",
			  @"invMarketGroups.parentGroupID = 2199"], category, @"Structures");

	[database execSQLRequest:@"SELECT typeID FROM dgmTypeAttributes WHERE attributeID=10000"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t typeID = sqlite3_column_int(stmt, 0);
					 NCDBDgmppItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_MODE;
					 category.subcategory = typeID;
					 
					 NCDBDgmppItemGroup* itemGroup = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemGroup" inManagedObjectContext:context];
					 itemGroup.category = category;
					 itemGroup.parentGroup = nil;
					 itemGroup.groupName = @"Tactical Mode";
					 itemGroup.icon = nil;

					 
					 [database execSQLRequest:[NSString stringWithFormat:@"SELECT a.typeID FROM dgmTypeEffects AS a, dgmTypeAttributes AS b WHERE effectID=%d AND attributeID=1302 AND a.typeID=b.typeID AND value=%d;", dgmpp::TACTICAL_MODE_EFFECT_ID, typeID]
								  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
									  int32_t typeID = sqlite3_column_int(stmt, 0);
									  NCDBInvType* invType = invTypes[@(typeID)];
									  if (invType) {
										  if (!invType.dgmppItem) {
											  invType.dgmppItem = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItem" inManagedObjectContext:context];
											  [itemGroup addItemsObject:invType.dgmppItem];
											  loadDetails(invType.dgmppItem);
										  }
										  else
											  [itemGroup addItemsObject:invType.dgmppItem];
									  }
								  }];
				 }];

	
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
						 
						 NCDBDgmppItemCategory* category = chargeCategories[key];
						 if (!category) {
							 chargeCategories[key] = category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
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
						 invType.dgmppItem.charge = category;
					 }
				 }];
	
	[database execSQLRequest:@"select value from dgmTypeAttributes as a, invTypes as b where attributeID=331 and a.typeID=b.typeID and b.published = 1 group by value;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t slot = sqlite3_column_int(stmt, 0);
					 NCDBDgmppItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_IMPLANT;
					 category.subcategory = slot;
					 process(@[@"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 331",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", slot]], category, @"Implants");
				 }];
	[database execSQLRequest:@"select value from dgmTypeAttributes as a, invTypes as b where attributeID=1087 and a.typeID=b.typeID and b.published = 1 group by value;"
				 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
					 int32_t slot = sqlite3_column_int(stmt, 0);
					 NCDBDgmppItemCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppItemCategory" inManagedObjectContext:context];
					 category.category = SLOT_BOOSTER;
					 category.subcategory = slot;
					 process(@[@"dgmTypeAttributes.typeID = invTypes.typeID",
							   @"dgmTypeAttributes.attributeID = 1087",
							   [NSString stringWithFormat:@"dgmTypeAttributes.value = %d", slot]], category, @"Boosters");
				 }];
}

void convertDgmppHullTypes(NSManagedObjectContext* context) {
	NCDBInvMarketGroup* marketGroup = invMarketGroups[@(4)];
	__weak __block void (^weakAdd)(NCDBInvMarketGroup*, NSMutableArray*);
	void (^add)(NCDBInvMarketGroup*, NSMutableArray*) = ^(NCDBInvMarketGroup* marketGroup, NSMutableArray* types) {
		if (marketGroup.types.count > 0)
			[types addObjectsFromArray:marketGroup.types.allObjects];
		for (NCDBInvMarketGroup* subGroup in marketGroup.subGroups)
			weakAdd(subGroup, types);
	};
	weakAdd = add;
	
	for (NCDBInvMarketGroup* subGroup in marketGroup.subGroups) {
		NCDBDgmppHullType* hullType = [NSEntityDescription insertNewObjectForEntityForName:@"DgmppHullType" inManagedObjectContext:context];
		hullType.hullTypeName = subGroup.marketGroupName;
		
		NSMutableArray* types = [NSMutableArray new];
		add(subGroup, types);
		double signature = 0;
		for (NCDBInvType* type in types) {
			NCDBDgmTypeAttribute* attribute = [[type.attributes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"attributeType.attributeID==552"]] anyObject];
			signature += attribute.value;
			type.hullType = hullType;
		}
		signature /= types.count;
		signature = ceil(signature / 5) * 5;
		hullType.signature = signature;
	}
}

void convertWhTypes(NSManagedObjectContext* context, EVEDBDatabase* database) {
	[database execSQLRequest:@"SELECT * FROM invTypes where groupID = 988" resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
		EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
		
		EVEDBDgmTypeAttribute* targetSystemClass = type.attributesDictionary[@(1381)];
		EVEDBDgmTypeAttribute* maxStableTime = type.attributesDictionary[@(1382)];
		EVEDBDgmTypeAttribute* maxStableMass = type.attributesDictionary[@(1383)];
		EVEDBDgmTypeAttribute* maxRegeneration = type.attributesDictionary[@(1384)];
		EVEDBDgmTypeAttribute* maxJumpMass = type.attributesDictionary[@(1385)];

		NCDBWhType* wh = [NSEntityDescription insertNewObjectForEntityForName:@"WhType" inManagedObjectContext:context];
		wh.type = invTypes[@(type.typeID)];
		wh.targetSystemClass = targetSystemClass.value;
		wh.maxJumpMass = maxJumpMass.value;
		wh.maxRegeneration = maxRegeneration.value;
		wh.maxStableMass = maxStableMass.value;
		wh.maxStableTime = maxStableTime.value;
	}];
}

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		if (argc != 7)
			return 1;
		
		databasePath = [NSString stringWithUTF8String:argv[1]];
		evedbPath = [NSString stringWithUTF8String:argv[2]];
		iconsPath = [NSString stringWithUTF8String:argv[3]];
		typesPath = [NSString stringWithUTF8String:argv[4]];
		factionsPath = [NSString stringWithUTF8String:argv[5]];
		NSString* expansion = [NSString stringWithUTF8String:argv[6]];

		NSManagedObjectContext *context = managedObjectContext();
		EVEDBDatabase* database = [[EVEDBDatabase alloc] initWithDatabasePath:evedbPath];
		[EVEDBDatabase setSharedDatabase:database];
		
		@autoreleasepool {
			[database execSQLRequest:@"select version, build from version"
						 resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
							 const char* version = (const char*) sqlite3_column_text(stmt, 0);
							 int32_t build = sqlite3_column_int(stmt, 1);
							 NCDBVersion* dbVersion = [NSEntityDescription insertNewObjectForEntityForName:@"Version" inManagedObjectContext:context];
							 dbVersion.version = [NSString stringWithCString:version encoding:NSUTF8StringEncoding];
							 dbVersion.build = build;
							 dbVersion.expansion = expansion;
						 }];
			
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
//			NSLog(@"convertInvBlueprintTypes");
//			convertInvBlueprintTypes(context, database);
//			NSLog(@"convertInvTypeMaterials");
//			convertInvTypeMaterials(context, database);
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
//			NSLog(@"convertRamTypeRequirements");
//			convertRamTypeRequirements(context, database);
			NSLog(@"convertStaStations");
			staStations = convertStaStations(context, database);
			NSLog(@"convertRequiredSkills");
			convertRequiredSkills(context);
			NSLog(@"convertDgmppItems");
			convertDgmppItems(context, database);
			NSLog(@"convertDgmppHullTypes");
			convertDgmppHullTypes(context);
			NSLog(@"convertIndustryBlueprints");
			indBlueprintTypes = convertIndustryBlueprints(context, database);
			NSLog(@"convertIndustryActivity");
			indActivities = convertIndustryActivity(context, database);
			NSLog(@"convertIndustryActivityMaterials");
			convertIndustryActivityMaterials(context, database);
			NSLog(@"convertIndustryActivityProducts");
			indProducts = convertIndustryActivityProducts(context, database);
			NSLog(@"convertIndustryActivityProbabilities");
			convertIndustryActivityProbabilities(context, database);
//			NSLog(@"convertIndustryActivityRaces");
//			convertIndustryActivityRaces(context, database);
			NSLog(@"convertIndustryActivitySkills");
			convertIndustryActivitySkills(context, database);
			NSLog(@"convertWhTypes");
			convertWhTypes(context, database);
		}
		NSLog(@"Saving...");

		
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

