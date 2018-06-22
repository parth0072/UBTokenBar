//
//  UBTokenBarRemovableCollectionViewCell.swift
//  UBTokenBar
//
//  Copyright (c) 2017 Uber Technologies, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

open class UBTokenBarRemovableCollectionViewCell: UBTokenBarCollectionViewCell {
    var title: String = "Token"
    var representedObject: Any?
    var titleLabel = UILabel(frame: CGRect.zero)
    var removeTokenButton = UIButton(type: .custom)
    var computedWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.translatesAutoresizingMaskIntoConstraints = false

        //Change to Biomark color
        self.contentView.backgroundColor = UIColor(red: 246.0/255.0, green: 248.0/255.0, blue: 249.0/255.0, alpha: 1)

        self.titleLabel.textColor = UIColor(red: 39.0/255.0, green: 56.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        self.titleLabel.font = UIFont.systemFont(ofSize: 12)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.titleLabel)

        if self.tokenBarIsRTL() {
            self.titleLabel.transform = CGAffineTransform(scaleX: -1, y: 1)
        }

        self.removeTokenButton.setTitle("x", for: .normal)
        self.removeTokenButton.titleLabel?.textAlignment = .center
        self.removeTokenButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        self.removeTokenButton.setTitleColor(UIColor(red: 132.0/255.0, green: 147.0/255.0, blue: 174.0/255.0, alpha: 1.0), for: .normal)
        self.removeTokenButton.addTarget(self, action: #selector(UBTokenBarRemovableCollectionViewCell.pressedRemoveButton(_:)), for: .touchUpInside)
        self.removeTokenButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(removeTokenButton)

        //Set cornerRadius
        self.contentView.layer.borderColor = UIColor(red: 224.0/255.0, green: 230.0/255.0, blue: 232.0/255.0, alpha: 1).cgColor
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.cornerRadius = 15.5
        self.contentView.layer.masksToBounds = true
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func maximumCellWidth() -> CGFloat {
        return 200
    }

    // Overridden UBTokenBarCollectionViewCell methods

    override func updateCellForToken(newToken: UBToken) {
        super.updateCellForToken(newToken: newToken)
        self.titleLabel.text = newToken.tokenTitle
        self.representedObject = newToken.representedObject
        self.computedWidth = 0
        updateConstraints()
    }

    // Remove button tap callback

    @objc func pressedRemoveButton(_ sender: UIButton!) {
        self.delegate?.tokenRemoveButtonTapped(token: self.token, cell: self)
    }

    // View managment code

    open override func updateConstraints() {
        let titleLabelLeadingConstraint = NSLayoutConstraint(item: self.titleLabel, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1, constant: 10)
        let titleLabelTrailingConstraint = NSLayoutConstraint(item: self.titleLabel, attribute: .trailing, relatedBy: .equal, toItem: self.removeTokenButton, attribute: .leading, multiplier: 1, constant: 0)
        let titleLabelTopConstraint = NSLayoutConstraint(item: self.titleLabel, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1, constant: 0)
        let titleLabelBottomConstraint = NSLayoutConstraint(item: self.titleLabel, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1, constant: 0)
        let titleLabelCenterYConstraint = NSLayoutConstraint(item: self.titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)

        self.contentView.addConstraints([titleLabelLeadingConstraint, titleLabelTrailingConstraint, titleLabelTopConstraint, titleLabelBottomConstraint, titleLabelCenterYConstraint])

        let removeTokenButtonWidthConstraint = NSLayoutConstraint(item: self.removeTokenButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 25)
        let removeTokenButtonTrailingConstraint = NSLayoutConstraint(item: self.removeTokenButton, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1, constant: 0)
        let removeTokenButtonCenterYConstraint = NSLayoutConstraint(item: self.removeTokenButton, attribute: .centerY, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1, constant: 0)
        let removeTokenButtonTopConstraint = NSLayoutConstraint(item: self.removeTokenButton, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1, constant: 0)
        let removeTokenButtonBottomConstraint = NSLayoutConstraint(item: self.removeTokenButton, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1, constant: 0)

        self.contentView.addConstraints([removeTokenButtonWidthConstraint, removeTokenButtonTrailingConstraint, removeTokenButtonCenterYConstraint, removeTokenButtonTopConstraint, removeTokenButtonBottomConstraint])

        super.updateConstraints()
    }

    override open func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let layoutAttributesCopy = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else {
            return layoutAttributes
        }
        if self.computedWidth == 0 {
            self.computedWidth = contentView.systemLayoutSizeFitting(CGSize(width: self.maximumCellWidth(), height: layoutAttributes.size.height)).width
            if self.computedWidth > self.maximumCellWidth() {
                self.computedWidth = self.maximumCellWidth()
            }
            var newFrame = layoutAttributes.frame
            newFrame.size.width = self.computedWidth
            layoutAttributesCopy.frame = newFrame
        }
        return layoutAttributesCopy
    }

    override open func prepareForReuse() {
        self.computedWidth = 0
        super.prepareForReuse()
    }
}
