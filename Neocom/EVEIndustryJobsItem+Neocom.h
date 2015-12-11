//
//  EVEIndustryJobsItem+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 20.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <EVEAPI/EVEAPI.h>
#import "NCLocationsManager.h"

@class NCDBRamActivity;
@class NCDBInvType;
@interface EVEIndustryJobsItem (Neocom)
@property (nonatomic, strong) NCLocationsManagerItem* blueprintLocation;
@property (nonatomic, strong) NCLocationsManagerItem* outputLocation;
//@property (nonatomic, strong) NSString* installerName;
//@property (nonatomic, strong) NCDBRamActivity* activity;
//@property (nonatomic, strong) NCDBInvType* blueprintType;
//@property (nonatomic, strong) NCDBInvType* productType;

- (NSString*) localizedStateWithCurrentDate:(NSDate*) date;
@end
