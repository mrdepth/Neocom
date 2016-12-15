//
//  NCTableViewHeaderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCTableViewHeaderCell: UITableViewCell, NCExpandable {
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var expandIcon: UIImageView?
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	func setExpanded(_ expanded: Bool, animated: Bool) {
		expandIcon?.image = UIImage(named: expanded ? "collapse" : "expand")
	}

}
