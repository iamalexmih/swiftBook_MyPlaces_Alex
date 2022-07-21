//
//  RatingControl.swift
//  swiftBook_MyPlaces_Alex
//
//  Created by Алексей Попроцкий on 14.07.2022.
//

import UIKit

@IBDesignable class RatingControl: UIStackView {

    // MARK: Properties
    
    var rating = 0 {
        didSet {
            updateButtonSelectionState()
        }
    }
    private var ratingButtons = [UIButton]()
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        didSet {
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }
    
    // MARK: Initialisation
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    //MARK: Button Action
    
    @objc func ratingButtonTapped(button: UIButton) {
        
        
        // Define the star index in the array
        guard let index = ratingButtons.firstIndex(of: button) else { return }
        
        // Calculate rating
        let selectRating = index + 1
        
        if selectRating == rating { // Reset the rating if you click on the previously set rating
            rating = 0
        } else {
            rating = selectRating
        }
    }
    
    // MARK: Privane Methods
    
    private func setupButtons() {
        
        //Delete old button. And then create new button
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        
        ratingButtons.removeAll()
        
        // Load button image
        let bundle = Bundle(for: type(of: self)) // определяет местоположение ресурсов в каталоге assets. Подставляем в качестве параметра свой собственный класс = self. Чтоб помочь xcode срендерить звезды для сториборда, надо явно указать к ним путь.
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)

        
        for item in 0..<starCount { // 5 button = 5 stars
            
            // Create button
            let button = UIButton()
            
            //Set the button image
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)

            button.setImage(highlightedStar, for: .highlighted)
            button.setImage(highlightedStar, for: [.highlighted, .selected])

            
            
            // Add Constrains
            button.translatesAutoresizingMaskIntoConstraints = false // Disabled auto generate constrains
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true // isActive = activate constrains.
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            
            //Setup the button action
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add the button to the Stack View
            addArrangedSubview(button)
            
            // Add the new button on the rating button array
            ratingButtons.append(button)
            
        }
    }
    
    private func updateButtonSelectionState() { // read in Obsidian.
        for (index, button) in ratingButtons.enumerated() {
            //print("index = \(index), raring = \(rating)")
            button.isSelected = index < rating
            //print("button.isSelected = \(button.isSelected)")
        }
    }
    
    
}
 
