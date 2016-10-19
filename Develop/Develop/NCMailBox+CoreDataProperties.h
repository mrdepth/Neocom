//
//  NCMailBox+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCMailBox+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCMailBox (CoreDataProperties)

+ (NSFetchRequest<NCMailBox *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *readedMessagesIDs;
@property (nullable, nonatomic, copy) NSDate *updateDate;
@property (nullable, nonatomic, retain) NCAccount *account;

@end

NS_ASSUME_NONNULL_END
