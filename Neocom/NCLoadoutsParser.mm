//
//  NCLoadoutsParser.m
//  Neocom
//
//  Created by Артем Шиманский on 24.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCLoadoutsParser.h"
#import "NCLoadout.h"
#import "NCDatabase.h"
#import "NCShipFit.h"

@interface NCLoadoutsParser()<NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableArray* loadouts;
@property (nonatomic, strong) NCLoadout* loadout;
@property (nonatomic, strong) NSMutableArray* hiSlots;
@property (nonatomic, strong) NSMutableArray* medSlots;
@property (nonatomic, strong) NSMutableArray* lowSlots;
@property (nonatomic, strong) NSMutableArray* rigSlots;
@property (nonatomic, strong) NSMutableArray* subsystems;
@property (nonatomic, strong) NSMutableArray* drones;
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext* databaseManagedObjectContext;

@end

@implementation NCLoadoutsParser

+ (NSArray*) parserEveXML:(NSString*) xml {
	NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithData:[xml dataUsingEncoding:NSUTF8StringEncoding]];
	NCLoadoutsParser* parser = [NCLoadoutsParser new];
	xmlParser.delegate = parser;
	[parser.databaseManagedObjectContext performBlockAndWait:^{
		[xmlParser parse];
	}];
	return parser.loadouts;
}

- (id) init {
	if (self = [super init]) {
		self.loadouts = [NSMutableArray new];
		self.storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
		self.databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
	}
	return self;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	if ([elementName compare:@"fitting" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		self.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout"
																	 inManagedObjectContext:self.storageManagedObjectContext]
						  insertIntoManagedObjectContext:nil];
		self.loadout.name = attributeDict[@"name"];
		self.hiSlots = [NSMutableArray new];
		self.medSlots = [NSMutableArray new];
		self.lowSlots = [NSMutableArray new];
		self.rigSlots = [NSMutableArray new];
		self.subsystems = [NSMutableArray new];
		self.drones = [NSMutableArray new];
	}
	else if ([elementName compare:@"shipType" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeName:attributeDict[@"value"]];
		if (type)
			self.loadout.typeID = type.typeID;
		else
			self.loadout = nil;
	}
	else if ([elementName compare:@"hardware" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeName:attributeDict[@"type"]];
		if (type) {
			NSString* slot = attributeDict[@"slot"];
			if ([slot hasPrefix:@"drone bay"]) {
				NCLoadoutDataShipDrone* drone = [NCLoadoutDataShipDrone new];
				drone.typeID = type.typeID;
				drone.count = [attributeDict[@"qty"] intValue];
				drone.active = true;
				[self.drones addObject:drone];
			}
			else {
				NCLoadoutDataShipModule* module = [NCLoadoutDataShipModule new];
				module.typeID = type.typeID;
				module.state = eufe::Module::STATE_ACTIVE;
				if ([slot hasPrefix:@"hi slot"])
					[self.hiSlots addObject:module];
				else if ([slot hasPrefix:@"med slot"])
					[self.medSlots addObject:module];
				else if ([slot hasPrefix:@"low slot"])
					[self.lowSlots addObject:module];
				else if ([slot hasPrefix:@"rig slot"])
					[self.rigSlots addObject:module];
				else if ([slot hasPrefix:@"subsystem slot"])
					[self.subsystems addObject:module];
			}
		}
	}

}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
	if ([elementName compare:@"fitting" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		if (self.loadout) {
			self.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:nil];
			self.loadout.data.loadout = self.loadout;
			NCLoadoutDataShip* ship = [NCLoadoutDataShip new];
			ship.hiSlots = self.hiSlots;
			ship.medSlots = self.medSlots;
			ship.lowSlots = self.lowSlots;
			ship.rigSlots = self.rigSlots;
			ship.subsystems = self.subsystems;
			ship.drones = self.drones;
			self.loadout.data.data = ship;
			[self.loadouts addObject:self.loadout];
		}
	}
}

@end
