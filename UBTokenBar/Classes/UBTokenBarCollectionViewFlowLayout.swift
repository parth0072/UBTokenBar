//
//  UBTokenBarCollectionViewFlowLayout.swift
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

import Foundation
import UIKit

let searchIconDecorationCellType = "UBTokenBarCollectionViewFlowLayout.searchIconDecorationCellType"

open class UBTokenBarCollectionViewFlowLayout: UICollectionViewFlowLayout {
    fileprivate var contentSize = CGSize.zero

    public override init() {
        super.init()
        self.minimumInteritemSpacing = 5
        self.minimumLineSpacing = 5
        self.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        self.scrollDirection = .vertical
        self.estimatedItemSize = CGSize(width: 0, height: self.defaultItemHeight())
        self.register(UBTokenBarSearchIconDecorationViewCell.self, forDecorationViewOfKind: searchIconDecorationCellType)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func defaultItemHeight() -> CGFloat {
        return 26
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let currentItemAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }

        let sectionInset = self.sectionInset
        var currentItemRect = currentItemAttributes.frame

        // First item for the collectionView, do not try to use the previous index path to determine attributes
        if indexPath.item == 0 {
            currentItemRect.origin.x = sectionInset.left
            if let decorationLayoutAttributes = self.layoutAttributesForDecorationView(ofKind: searchIconDecorationCellType, at: IndexPath(item: 0, section: 0)) {
                currentItemRect.origin.x = decorationLayoutAttributes.frame.maxX + self.minimumInteritemSpacing
            }
            currentItemAttributes.frame = currentItemRect
            return currentItemAttributes
        }

        // Look at the previous index path item's attributes to determine this item's attributes
        let previousIndexPath = IndexPath(item: indexPath.item - 1, section: indexPath.section)

        guard let previousItemAttributes = self.layoutAttributesForItem(at: previousIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }

        guard let collectionView = self.collectionView else {
            return nil
        }

        let collectionViewBounds = collectionView.bounds
        let previousItemRect = previousItemAttributes.frame

        var remainingLineWidth = collectionViewBounds.width - self.sectionInset.left - self.sectionInset.right - self.minimumInteritemSpacing

        if currentItemRect.maxY == self.sectionInset.top {
            if let decorationLayoutAttributes = self.layoutAttributesForDecorationView(ofKind: searchIconDecorationCellType, at: IndexPath(item: 0, section: 0)) {
                remainingLineWidth = collectionViewBounds.width - self.sectionInset.left - self.sectionInset.right - decorationLayoutAttributes.size.width - self.minimumInteritemSpacing
            }
        }

        // Token should be on the same line as existing tokens
        if previousItemRect.maxX + self.minimumInteritemSpacing + currentItemRect.size.width < remainingLineWidth {
            currentItemRect.origin.x = previousItemRect.maxX + self.minimumInteritemSpacing
            currentItemRect.origin.y = previousItemRect.minY
            currentItemAttributes.frame = currentItemRect
            return currentItemAttributes
        }

        // Token exceeds the max length for the line, we need to create a new line of tokens
        currentItemRect.origin.x = sectionInset.left
        currentItemRect.origin.y = previousItemRect.maxY + self.minimumLineSpacing
        currentItemAttributes.frame = currentItemRect
        return currentItemAttributes
    }

    override open func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == searchIconDecorationCellType {
            let decorationLayoutAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
           // decorationLayoutAttributes.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            decorationLayoutAttributes.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            return decorationLayoutAttributes
        }
        return nil
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = self.collectionView else {
            return nil
        }

        var attributesCopy = [UICollectionViewLayoutAttributes]()

        if let inheritedLayoutAttributesForElementsInRect = super.layoutAttributesForElements(in: rect) {
            for layoutAttributesForItemsInRect in inheritedLayoutAttributesForElementsInRect {
                if let layoutAttributesForItem = self.layoutAttributesForItem(at: layoutAttributesForItemsInRect.indexPath) {
                    if layoutAttributesForItem.frame.intersects(rect) {
                        attributesCopy.append(layoutAttributesForItem)
                    }
                }
            }
        }

        // Initial call to layoutAttributesForElements returned nothing, lets add our text field cell attributes in this case
        if attributesCopy.count == 0 {
            if let initialTextFieldLayoutAttributes = self.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) {
                attributesCopy.append(initialTextFieldLayoutAttributes)
            }
        }

        if let textInputFieldLayoutAttributes = attributesCopy.last {
            if textInputFieldLayoutAttributes.representedElementCategory == .cell {
                textInputFieldLayoutAttributes.frame.size = CGSize(width: collectionView.bounds.size.width - textInputFieldLayoutAttributes.frame.minX - self.sectionInset.right, height: textInputFieldLayoutAttributes.size.height)
                contentSize = CGSize(width: collectionView.bounds.width, height: textInputFieldLayoutAttributes.frame.maxY + self.sectionInset.bottom)
            }
        }

        if let decorationLayoutAttributes = self.layoutAttributesForDecorationView(ofKind: searchIconDecorationCellType, at: IndexPath(item: 0, section: 0)) {
            attributesCopy.append(decorationLayoutAttributes)
        }
        
        return attributesCopy
    }

    override open var collectionViewContentSize: CGSize {
        return contentSize
    }
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
