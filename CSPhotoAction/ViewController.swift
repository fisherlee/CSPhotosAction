//
//  ViewController.swift
//  PhotoAction
//
//  Created by liwei on 2017/2/6.
//  Copyright © 2017年 liwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var albumListButton: UIButton!
    @IBOutlet weak var photosListButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // #MARK - action
    @IBAction func albumListAction() -> Void {
        let albumController = CSAssetViewController(layoutStyle: .album)
        let navigationController = UINavigationController(rootViewController: albumController)
        self.present(navigationController, animated: true, completion: nil)
        
        albumController.callBackPhotos = { (photos)->Void in
            print("photos = \(photos)")
        }
    }
    
    @IBAction func photosListAction() -> Void {
        let photosController = CSAssetViewController(layoutStyle: .photos)
        photosController.showBackBarButton = false
        let navigationController = UINavigationController(rootViewController: photosController)
        self.present(navigationController, animated: true, completion: nil)
        
        photosController.callBackPhotos = { (photos)->Void in
            print("photos = \(photos)")
        }
    }

}

