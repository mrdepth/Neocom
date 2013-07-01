//
//  Fit.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 28.01.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "eufe.h"
#import "EVEDBAPI.h"

@interface Fit : NSManagedObject

@property (nonatomic, readonly, strong) EVEDBInvType* type;

//CoreData
@property (nonatomic, strong) NSString * fitName;
@property (nonatomic, strong) NSString * imageName;
@property (nonatomic) eufe::TypeID typeID;
@property (nonatomic, strong) NSString * typeName;
@property (nonatomic, strong) NSString * url;

- (void) save;
- (void) load;
- (void) unload;

@end
