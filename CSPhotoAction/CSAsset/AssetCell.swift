/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    AssetCell is a basic UICollectionViewCell sublass to display a photo.
*/

import UIKit

class AssetCell: UICollectionViewCell {
    
    var assetIdentifier: String = ""
    
    var imageView: UIImageView!
    var titleView: UIView!
    var titleLabel: UILabel!
    
    var effectView: UIVisualEffectView!
    var selectImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        titleView = UIView(frame: CGRect(x: 0, y: frame.size.height-30, width: frame.size.width, height: 30))
        titleView.backgroundColor = UIColor.lightGray
        titleView.alpha = 0.5
        titleView.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        imageView.addSubview(titleView)
        
        titleLabel = UILabel(frame: CGRect(x: 0, y: frame.size.height-30, width: frame.size.width, height: 30))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = UIColor.black
        imageView.addSubview(titleLabel)
        
        
        backgroundView = imageView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil;
        titleLabel.text = "";
        assetIdentifier = ""
    }
    
    func setBrulView(select: Bool) -> Void {
        if select == true {
            if effectView == nil {
                let blur = UIBlurEffect(style: .extraLight)
                effectView = UIVisualEffectView(effect: blur)
            }
            effectView.alpha = 0.5
            effectView.frame = imageView.bounds
            effectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            imageView.addSubview(effectView)
            
            if selectImageView == nil {
                selectImageView = UIImageView(image: UIImage.init(named: "cs_check"))
            }
            selectImageView.frame = CGRect(x: frame.size.height-30, y: frame.size.height-30, width: 25, height: 25)
            selectImageView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
            imageView.addSubview(selectImageView)
        }else {
            for iv in imageView.subviews {
                if iv.isKind(of: UIVisualEffectView.classForCoder()) {
                    iv.removeFromSuperview()
                }
                if iv.isKind(of: UIImageView.classForCoder()) {
                    iv.removeFromSuperview()
                }
            }
        }

    }
}
