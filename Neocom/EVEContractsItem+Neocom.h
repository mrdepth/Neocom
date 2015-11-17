//
//  EVEContractsItem+Neocom.h
//  Neocom
//
//  Created by Shimanski Artem on 19.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <EVEAPI/EVEAPI.h>
#import "NCLocationsManager.h"

@interface EVEContractsItem (Neocom)
@property (nonatomic, strong) NCLocationsManagerItem* startStation;
@property (nonatomic, strong) NCLocationsManagerItem* endStation;
@property (nonatomic, strong) NSString* issuerName;
@property (nonatomic, strong) NSString* issuerCorpName;
@property (nonatomic, strong) NSString* assigneeName;
@property (nonatomic, strong) NSString* acceptorName;
@property (nonatomic, strong) NSString* forCorpName;
@end
