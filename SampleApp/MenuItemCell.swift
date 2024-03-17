//
//  MenuItemTableViewCell.swift
//  SampleApp
//
//  Created by Ayush on 15/03/24.
//

import UIKit

class MenuItemCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func update(item: MenuItem) {
        titleLabel.text = item.title
        descriptionLabel.text = item.description
    }
}
