//
//  HomeTableViewCell.swift
//  Image To Text
//
//  Created by Sorfian on 12/05/23.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var inputLabel:UILabel! {
        didSet {
            inputLabel.numberOfLines = 0
            inputLabel.text = "Input:"
        }
    }
    
    @IBOutlet weak var inputValueLabel:UILabel! {
        didSet {
            inputValueLabel.numberOfLines = 0
            inputValueLabel.text = "1+2"
        }
    }
    
    @IBOutlet weak var resultLabel:UILabel! {
        didSet {
            resultLabel.numberOfLines = 0
            resultLabel.text = "Result:"
        }
    }
    
    @IBOutlet weak var resultValueLabel:UILabel! {
        didSet {
            resultValueLabel.numberOfLines = 0
            resultValueLabel.text = "3"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
