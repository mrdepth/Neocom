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

@property (nonatomic, readonly, retain) EVEDBInvType* type;

//CoreData
@property (nonatomic, retain) NSString * fitName;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic) eufe::TypeID typeID;
@property (nonatomic, retain) NSString * typeName;
@property (nonatomic, retain) NSString * url;

- (void) save;
- (void) load;
- (void) unload;

@end
