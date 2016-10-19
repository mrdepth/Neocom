//
//  NCMailBox+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCMailBox+CoreDataProperties.h"

@implementation NCMailBox (CoreDataProperties)

+ (NSFetchRequest<NCMailBox *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MailBox"];
}

@dynamic readedMessagesIDs;
@dynamic updateDate;
@dynamic account;

@end
