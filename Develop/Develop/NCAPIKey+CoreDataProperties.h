//
//  NCAPIKey+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAPIKey+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCAPIKey (CoreDataProperties)

+ (NSFetchRequest<NCAPIKey *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *apiKeyInfo;
@property (nonatomic) int32_t keyID;
@property (nullable, nonatomic, copy) NSString *vCode;
@property (nullable, nonatomic, retain) NSSet<NCAccount *> *accounts;

@end

@interface NCAPIKey (CoreDataGeneratedAccessors)

- (void)addAccountsObject:(NCAccount *)value;
- (void)removeAccountsObject:(NCAccount *)value;
- (void)addAccounts:(NSSet<NCAccount *> *)values;
- (void)removeAccounts:(NSSet<NCAccount *> *)values;

@end

NS_ASSUME_NONNULL_END
