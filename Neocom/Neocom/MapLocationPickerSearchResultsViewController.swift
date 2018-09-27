//
//  MapLocationPickerSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MapLocationPickerSearchResultsViewController: TreeViewController<MapLocationPickerSearchResultsPresenter, MapLocationPickerSearchResultsViewController.Input>, TreeView {
	struct Input {
		var mode: MapLocationPickerViewController.Mode
		var region: SDEMapRegion?
	}
}

