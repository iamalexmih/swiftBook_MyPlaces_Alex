//
//  NewPlacesController.swift
//  swiftBook_MyPlaces_Alex
//
//  Created by Алексей Попроцкий on 11.07.2022.
//

import UIKit

class NewPlacesController: UITableViewController {
    
    var currentPlace: Place!
    var imageIsChanged = false
    
    @IBOutlet weak var imageNewPlace: UIImageView!
    @IBOutlet weak var saveButtonNewPlace: UIBarButtonItem!
    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var textFieldLocation: UITextField!
    @IBOutlet weak var textFieldType: UITextField!
    @IBOutlet weak var ratingControllOutlet: RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1)) //width = ширина равна ширине tableView
        
        saveButtonNewPlace.isEnabled = false
        textFieldName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        setupEditScreen()
    }

    @IBAction func buttonCancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupEditScreen() {
        if currentPlace != nil {
            setupNavigationBarForEditPlace()
            imageIsChanged = true //изображение не будет меняться, если мы редактируем запись.
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else { return }
            
            textFieldName.text = currentPlace?.name
            textFieldLocation.text = currentPlace?.location
            textFieldType.text = currentPlace?.type
            imageNewPlace.image = image
            imageNewPlace.contentMode = .scaleAspectFill
            ratingControllOutlet.rating = Int(currentPlace.rating)
        }
    }
    
    private func setupNavigationBarForEditPlace() {
        if let topItem = navigationController?.navigationBar.topItem {
            topItem.backButtonTitle = ""// убираем заголовок с кнопки назад, для красоты.
        }
        navigationItem.leftBarButtonItem = nil
        title = currentPlace?.name
        saveButtonNewPlace.isEnabled = true
    }
    
//MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        if indexPath.row == 0 {
            let iconCamera = #imageLiteral(resourceName: "camera")
            let iconPhoto = #imageLiteral(resourceName: "photo")
                                           
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let camera = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            camera.setValue(iconCamera, forKey: "image")
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            photo.setValue(iconPhoto, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")

            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            present(actionSheet, animated: true)
        } else {
            view.endEditing(true)
        }
    }
// MARK: - save Place
    func savePlace() {
        
        let image = imageIsChanged ? imageNewPlace.image : #imageLiteral(resourceName: "imagePlaceholder") //если изображение не было добавленно пользователем, то отобразить картина по умолчанию.
        let imageData = image?.pngData()
        
        let newPlace = Place(name: textFieldName.text!,
                             location: textFieldLocation.text,
                             type: textFieldType.text,
                             imageData: imageData,
                             rating: Double(ratingControllOutlet.rating))
        
        if currentPlace != nil { //если существует значение currentPlace, то обновляем это значение в realm.
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else { //если значение nil, то это новый объект и его надо добавить в базу realm.
            //save object newPlace in base Realm
            StorageManager.saveObject(newPlace)
        }
    }
    
//MARK: - Navigate Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
              let mapVC = segue.destination as? MapViewController
        else { return }
        
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapToNewViewControllerDelegate = self
        
        if identifier == "showPlaceMap" {
            mapVC.place.name = textFieldName.text!
            mapVC.place.location = textFieldLocation.text
            mapVC.place.type = textFieldType.text
            mapVC.place.imageData = imageNewPlace.image?.pngData()
        }

    }
    
    
}


//MARK: - Text field delegate
        
extension NewPlacesController: UITextFieldDelegate {
    
    //скрываем клаву при нажатии на Done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func textFieldChanged() {
        if textFieldName.text?.isEmpty == false {
            saveButtonNewPlace.isEnabled = true //если поле не пустое, то кнопка доступна.
        } else {
            saveButtonNewPlace.isEnabled = false
        }
    }
}

//MARK: - Work with image

extension NewPlacesController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageNewPlace.image = info[.editedImage] as? UIImage
        imageNewPlace.contentMode = .scaleAspectFill
        imageNewPlace.clipsToBounds = true
        
        imageIsChanged = true
        
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - Delegate
extension NewPlacesController: MapToNewViewControllerDelegate {
    
    func getAddress(_ address: String?) {
        textFieldLocation.text = address
    }

}
