//
//  ItemInfo.mm
//  EVEUniverse
//
//  Created by Mr. Depth on 12/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ItemInfo.h"

@interface ItemInfo()
@property (nonatomic, readwrite, assign) eufe::Item* item;

- (void) clear;

@end

class ItemInfoContext : public eufe::Item::Context
{
public:
	ItemInfoContext(ItemInfo* itemInfo) : itemInfo_(itemInfo) {}
	
	virtual ~ItemInfoContext()
	{
		[itemInfo_ clear];
		itemInfo_ = nil;
	}
	
	ItemInfo* getItemInfo() const {return itemInfo_;}
private:
	ItemInfo* itemInfo_;
};

@implementation ItemInfo

+ (id) itemInfoWithItem:(eufe::Item*) aItem error:(NSError **)errorPtr {
	const eufe::Item::Context* context = aItem->getContext();
	if (context == NULL)
	{
		ItemInfo* itemInfo = [[ItemInfo alloc] initWithItem:aItem error:errorPtr];
		ItemInfoContext* context = new ItemInfoContext(itemInfo);
		aItem->setContext(context);
		return itemInfo;
	}
	else
		return dynamic_cast<const ItemInfoContext*>(context)->getItemInfo();
}

- (id) initWithItem:(eufe::Item*) item error:(NSError **)errorPtr {
	if (self = [super initWithTypeID:item->getTypeID() error:errorPtr]) {
		self.item = item;
	}
	return self;
}

- (void) updateAttributes {
	const eufe::AttributesMap &attributesMap = self.item->getAttributes();
	NSMutableDictionary* attributes = self.attributesDictionary;
	eufe::AttributesMap::const_iterator i, end = attributesMap.end();
	for (i = attributesMap.begin(); i != end; i++) {
		NSString* key = [NSString stringWithFormat:@"%d", i->first];
		float value = i->second->getValue();
		EVEDBDgmTypeAttribute* attribute = [attributes valueForKey:key];
		attribute.value = value;
	}
}

#pragma mark - Private

- (void) clear {
	self.item = NULL;
}

@end