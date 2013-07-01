//
//  APIKey.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "EVEOnlineAPI.h"

@interface APIKey : NSManagedObject

@property (nonatomic, strong) EVEAPIKeyInfo *apiKeyInfo;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSMutableArray *assignedCharacters;

//CoreData
@property (nonatomic) int32_t keyID;
@property (nonatomic, strong) NSString * vCode;


@end
