//
//  NumberCell.swift
//  PrimeGridLayout
//
//  Created by Sean Swezey on 9/29/16.
//  Copyright © 2016 stable/kernel. All rights reserved.
//

import UIKit

class NumberCell: UICollectionViewCell {
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    let numberLabel: UILabel

    override init(frame: CGRect) {
        numberLabel = UILabel()

        super.init(frame: frame)

        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        numberLabel = UILabel()

        super.init(coder: aDecoder)

        setUpView()
    }

    override func prepareForReuse() {
        numberLabel.text = nil
    }

    private func setUpView() {
        contentView.backgroundColor = .black

        numberLabel.translatesAutoresizingMaskIntoConstraints = false

        numberLabel.textColor = .white
        contentView.addSubview(numberLabel)

        numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }
}
