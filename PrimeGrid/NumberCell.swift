// MIT License
//
// Copyright (c) 2016 stable|kernel
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
        contentView.backgroundColor = .black
        numberLabel.textColor = .white
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
