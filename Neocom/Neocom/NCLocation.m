//
//  NCLocation.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCLocation.h"
#import "NCDatabase.h"
#import "UIColor+NC.h"
@import EVEAPI;

@implementation NCLocation

- (instancetype) initWithStation:(NCDBStaStation*) station {
	if (!station)
		return nil;
	if (self = [self initWithSolarSystem:station.solarSystem]) {
		self.stationID = station.stationID;
		self.stationName = station.stationName;
	}
	return self;
}

- (instancetype) initWithSolarSystem:(NCDBMapSolarSystem*) solarSystem {
	if (!solarSystem)
		return nil;
	if (self = [super init]) {
		self.solarSystemID = solarSystem.solarSystemID;
		self.solarSystemName = solarSystem.solarSystemName;
		self.security = solarSystem.security;
	}
	return self;
}

- (instancetype) initWithMapDenormalize:(NCDBMapDenormalize*) mapDenormalize {
	if (!mapDenormalize)
		return nil;
	if (self = [self initWithSolarSystem:mapDenormalize.solarSystem]) {
		
	}
	return self;
}

- (instancetype) initWithConquerableStation:(EVEConquerableStationListItem*) conquerableStation {
	if (!conquerableStation)
		return nil;
	NCDBMapSolarSystem* solarSystem = NCDatabase.sharedDatabase.mapSolarSystems[conquerableStation.solarSystemID];
	if (self = [self initWithSolarSystem:solarSystem]) {
		self.stationID = conquerableStation.stationID;
		self.stationName = conquerableStation.stationName;
		self.corporationID = conquerableStation.corporationID;
		self.corporationName = conquerableStation.corporationName;
		
	}
	return self;
}

- (NSAttributedString*) displayName {
	NSMutableAttributedString* s = [NSMutableAttributedString new];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.1f ", self.security] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithSecurity:self.security]}]];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:self.solarSystemName attributes:nil]];
	if (self.stationName)
		[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" / %@", self.stationName] attributes:nil]];
	return s;
}

@end
