//
//  TreeItem+CoreData.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import TreeController

extension Tree.Item {
	class FetchedResultsController<Result: NSFetchRequestResult, Section: FetchedResultsSection<Result>>: TreeItem {
		var fetchedResultsController: NSFetchedResultsController<Result>
		
		var hashValue: Int {
			return fetchedResultsController.hash
		}
		
		var diffIdentifier: AnyHashable
		
		lazy var children: [Section]? = {
			return nil
		}()
		
		init<T: Hashable>(_ fetchedResultsController: NSFetchedResultsController<Result>, diffIdentifier: T) {
			self.fetchedResultsController = fetchedResultsController
			self.diffIdentifier = AnyHashable(diffIdentifier)
		}
		
		static func == (lhs: Tree.Item.FetchedResultsController<Result, Section>, rhs: Tree.Item.FetchedResultsController<Result, Section>) -> Bool {
			return lhs.fetchedResultsController == rhs.fetchedResultsController
		}
	}
	
	class FetchedResultsSection<Result: NSFetchRequestResult>: TreeItem {
		static func == (lhs: Tree.Item.FetchedResultsSection<Result>, rhs: Tree.Item.FetchedResultsSection<Result>) -> Bool {
			return (lhs.sectionInfo.objects as? [Result]) == (rhs.sectionInfo.objects as? [Result])
		}
		
		var sectionInfo: NSFetchedResultsSectionInfo
		
		var hashValue: Int {
			return sectionInfo.name.hashValue
		}
		
		init(sectionInfo: NSFetchedResultsSectionInfo) {
			self.sectionInfo = sectionInfo
		}
		
	}
	
	class FetchedResultsItem<Result: NSFetchRequestResult>: TreeItem {
	}

}

