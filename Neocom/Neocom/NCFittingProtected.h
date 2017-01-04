//
//  NCFittingProtected.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#ifndef NCFittingProtected_h
#define NCFittingProtected_h

#import <Dgmpp/Dgmpp.h>
#import "NCFittingItem.h"
#import "NCFittingAttribute.h"
#import "NCFittingCharacter.h"
#import "NCFittingGang.h"

@interface NCFittingItem() {
@public
	std::shared_ptr<dgmpp::Item> _item;
	NCFittingAttributes* _attributes;
}
- (nonnull instancetype) initWithItem:(std::shared_ptr<dgmpp::Item> const&) item;
@end

@interface NCFittingAttribute()
- (nonnull instancetype) initWithAttribute:(std::shared_ptr<dgmpp::Attribute> const&) attribute;
@end


#endif /* NCFittingProtected_h */
