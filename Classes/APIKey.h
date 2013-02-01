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

@property (nonatomic, retain) EVEAPIKeyInfo *apiKeyInfo;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSMutableArray *assignedCharacters;

//CoreData
@property (nonatomic) int32_t keyID;
@property (nonatomic, retain) NSString * vCode;


@end
