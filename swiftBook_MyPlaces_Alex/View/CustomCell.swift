//
//  CustomCell.swift
//  swiftBook_MyPlaces_Alex
//
//  Created by Алексей Попроцкий on 10.07.2022.
//

import UIKit

class CustomCell: UITableViewCell {

    @IBOutlet weak var imagePreviewPlace: UIImageView! {
        didSet {
            imagePreviewPlace.layer.cornerRadius = imagePreviewPlace.frame.size.height / 2
            imagePreviewPlace.clipsToBounds = true
        }
    }
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var labelTypePlace: UILabel!
    
    
    @IBOutlet var starsCollection: [UIImageView]!
    
}
