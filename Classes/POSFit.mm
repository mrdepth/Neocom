//
//  POSFit.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 28.01.13.
//
//

#import "POSFit.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "EVEOnlineAPI.h"
#import "EVEAssetListItem+AssetsViewController.h"
#import "EUStorage.h"
#import "ItemInfo.h"

@implementation POSFit

@synthesize controlTower = _controlTower;
@dynamic structures;

+ (id) posFitWithFitName:(NSString*) fitName controlTower:(eufe::ControlTower*) aControlTower {
	return [[[POSFit alloc] initWithFitName:fitName controlTower:aControlTower] autorelease];
}

+ (id) posFitWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine {
	return [[[POSFit alloc] initWithAsset:asset engine:engine] autorelease];
	
}

+ (NSArray*) allFits {
	EUStorage* storage = [EUStorage sharedStorage];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"POSFit" inManagedObjectContext:storage.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [storage.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	return fetchedObjects;
}

- (id) initWithFitName:(NSString*) aFitName controlTower:(eufe::ControlTower*) aControlTower {
	EUStorage* storage = [EUStorage sharedStorage];
	if (self = [super initWithEntity:[NSEntityDescription entityForName:@"POSFit" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:nil]) {
		self.fitName = aFitName;
		_controlTower = aControlTower;
		if (aControlTower) {
			ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:aControlTower error:nil];
			self.typeID = itemInfo.typeID;
			self.typeName = itemInfo.typeName;
			self.imageName = itemInfo.typeSmallImageName;
		}
	}
	return self;
}

- (id) initWithAsset:(EVEAssetListItem*) asset engine:(eufe::Engine*) engine {
	EUStorage* storage = [EUStorage sharedStorage];
	if (self = [super initWithEntity:[NSEntityDescription entityForName:@"POSFit" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:nil]) {
		_controlTower = engine->setControlTower(asset.typeID);
		self.fitName = asset.location.itemName ? asset.location.itemName : asset.type.typeName;
		if (_controlTower == NULL) {
			[self release];
			return nil;
		}
		else {
			ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:self.controlTower error:nil];
			self.typeID = itemInfo.typeID;
			self.typeName = itemInfo.typeName;
			self.imageName = itemInfo.typeSmallImageName;

			for (EVEAssetListItem* assetItem in asset.contents) {
				int amount = assetItem.quantity;
				if (amount < 1)
					amount = 1;
				EVEDBInvType* type = assetItem.type;
				if (type.group.category.categoryID == eufe::STRUCTURE_CATEGORY_ID && type.group.groupID != eufe::CONTROL_TOWER_GROUP_ID) {
					for (int i = 0; i < amount; i++)
						_controlTower->addStructure(type.typeID);
				}
			}
		}
	}
	return self;
}


- (void) dealloc {
	[super dealloc];
}

- (void) save {
	NSMutableDictionary* structuresDic = [NSMutableDictionary dictionary];
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:self.controlTower error:nil];

	if (self.typeID != itemInfo.typeID) {
		self.typeID = itemInfo.typeID;
		self.imageName = itemInfo.typeSmallImageName;
		self.typeName = itemInfo.typeName;
	}

	
	for (auto i : self.controlTower->getStructures()) {
		eufe::Charge* charge = i->getCharge();
		eufe::TypeID chargeID = charge ? charge->getTypeID() : 0;
		NSString* key = [NSString stringWithFormat:@"%d:%d:%d", i->getTypeID(), i->getState(), chargeID];
		NSMutableDictionary* dic = [structuresDic valueForKey:key];
		if (!dic) {
			dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(i->getTypeID()), @"typeID", @(i->getState()), @"state", @(structuresDic.count), @"order", @(1), @"count", @(chargeID), @"chargeTypeID", nil];
			[structuresDic setValue:dic forKey:key];
		}
		else
			[dic setValue:@([[dic valueForKey:@"count"] integerValue] + 1) forKey:@"count"];
	}
	
	NSMutableArray* structures = [NSMutableArray array];
	for (NSDictionary* dic in [[structuresDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]]) {
		NSString* record = [NSString stringWithFormat:@"%d:%d:%d:%d",
							[[dic valueForKey:@"typeID"] integerValue],
							[[dic valueForKey:@"count"] integerValue],
							[[dic valueForKey:@"state"] integerValue],
							[[dic valueForKey:@"chargeTypeID"] integerValue]];
		[structures addObject:record];
	}
	
	NSString* structuresString = [structures componentsJoinedByString:@";"];
	
	if (![self.structures isEqualToString:structuresString])
		self.structures = structuresString;

	EUStorage* storage = [EUStorage sharedStorage];
	
	if (![self managedObjectContext])
		[storage.managedObjectContext insertObject:self];
	[storage saveContext];
}

- (void) load {
	[self.managedObjectContext performBlockAndWait:^{
		for (NSString* row in [self.structures componentsSeparatedByString:@";"]) {
			NSArray* components = [row componentsSeparatedByString:@":"];
			NSInteger numberOfComponents = components.count;
			
			if (numberOfComponents >= 1) {
				eufe::TypeID typeID = [[components objectAtIndex:0] integerValue];
				if (typeID) {
					NSInteger count = numberOfComponents >= 2 ? [[components objectAtIndex:1] integerValue] : 1;
					eufe::Module::State state = numberOfComponents >= 3 ? (eufe::Module::State) [[components objectAtIndex:2] integerValue] : eufe::Module::STATE_ONLINE;
					NSInteger chargeTypeID = numberOfComponents >= 4 ? [[components objectAtIndex:3] integerValue] : 0;
					for (NSInteger i = 0; i < count; i++) {
						eufe::Structure* structure = self.controlTower->addStructure(typeID);
						if (!structure)
							break;
						structure->setState(state);
						if (chargeTypeID)
							structure->setCharge(chargeTypeID);
					}
				}
			}
		}
	}];
}

@end
