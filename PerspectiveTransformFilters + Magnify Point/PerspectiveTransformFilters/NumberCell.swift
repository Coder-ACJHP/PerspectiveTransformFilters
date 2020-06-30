//
//  NumberCell.swift
//  PerspectiveTransformFilters
//
//  Created by Onur Işık on 29.06.2020.
//  Copyright © 2020 Coder ACJHP. All rights reserved.
//

import UIKit

class TickCell: UICollectionViewCell {
    
    public var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .red
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
