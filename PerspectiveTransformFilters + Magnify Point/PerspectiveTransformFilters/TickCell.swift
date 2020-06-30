//
//  NumberCell.swift
//  PerspectiveTransformFilters
//
//  Created by Onur Işık on 29.06.2020.
//  Copyright © 2020 Coder ACJHP. All rights reserved.
//

import UIKit

class TickCell: UICollectionViewCell {
    
    public enum TickSize: String {
        case Small, Big
    }
    
    public var degree: Int = -30
    public var tickSize: TickSize = .Small {
        didSet {
            if tickSize == .Small {
                tickSizeHeight = self.bounds.height - 20
                tickSizeWidth = 0.75
            } else {
                tickSizeHeight = self.bounds.height - 17
                tickSizeWidth = 1.0
            }
            addTickView()
        }
    }
    private var tickView: UIView?
    private lazy var tickSizeWidth: CGFloat = 1.0
    private lazy var tickSizeHeight: CGFloat = 0.75
    
    override func awakeFromNib() {
        super.awakeFromNib()        
    }
    
    private func addTickView() {
        
        let frame = CGRect(x: (self.bounds.width / 2) - (tickSizeWidth / 2),
                           y: (self.bounds.height / 2) - (self.tickSizeHeight / 2),
                           width: tickSizeWidth, height: self.tickSizeHeight)
        
        if tickView == nil {
            tickView = UIView(frame: frame)
            tickView!.backgroundColor = .white
            addSubview(tickView!)
        } else {
            tickView?.frame = frame
        }
    }
    
    override func prepareForReuse() {
        tickView?.frame = .zero
        super.prepareForReuse()
    }
}

