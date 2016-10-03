//
//  PrimeGrid.swift
//  PrimeGrid
//
//  Created by Sean Swezey on 9/29/16.
//  Copyright © 2016 stable/kernel. All rights reserved.
//

import UIKit

protocol GridLayoutDelegate: class {
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt
}

extension GridLayoutDelegate {
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        return 1
    }
}

class GridLayout: UICollectionViewLayout, GridLayoutDelegate {
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    var scrollDirection: UICollectionViewScrollDirection = .vertical
    var itemSpacing: CGFloat = 0
    var transverseItemsCount: UInt {
        get {
            return UInt(intTransverseItemsCount)
        }
        set {
            intTransverseItemsCount = newValue == 0 ? 1 : Int(newValue)
        }
    }

    weak var delegate: GridLayoutDelegate?

    private var intTransverseItemsCount = 1
    private var contentWidth: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var itemDimension: CGFloat = 0

    private var sectionedItemGrid: Array<Array<Array<Bool>>> = []
    private var itemAttributesCache: Array<UICollectionViewLayoutAttributes> = []

    private typealias ItemFrame = (section: Int, longitude: Int, transverse: Int, scale: Int)

    // MARK: - UICollectionView Layout

    override func prepare() {
        guard let collectionView = collectionView else { return }

        let transverseDimension: CGFloat
        if scrollDirection == .vertical {
            transverseDimension = collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right)
            contentWidth = transverseDimension
        } else {
            transverseDimension = collectionView.frame.height - (collectionView.contentInset.top + collectionView.contentInset.bottom)
            contentHeight = transverseDimension
        }

        itemDimension = (transverseDimension - (CGFloat(transverseItemsCount) * itemSpacing) + itemSpacing) / CGFloat(transverseItemsCount)

        for section in 0 ..< collectionView.numberOfSections {
            sectionedItemGrid.append([])

            var longitude = 0, transverse = 0
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                if transverse == intTransverseItemsCount {
                    // Reached end of row in .vertical or column in .horizontal
                    transverse = 0
                    longitude += 1
                }

                let itemIndexPath = IndexPath(item: item, section: section)
                let itemScale = indexableScale(forItemAt: itemIndexPath)
                let intendedFrame = ItemFrame(section, longitude, transverse, itemScale)
                let (itemFrame, didFitInOriginalFrame) = nextAvailableFrame(startingAt: intendedFrame)

                reserveItemGrid(frame: itemFrame)
                let itemAttributes = layoutAttributes(for: itemIndexPath, at: itemFrame)

                itemAttributesCache.append(itemAttributes)

                // Update variable dimension
                if scrollDirection == .vertical && itemAttributes.frame.maxY > contentHeight {
                    contentHeight = itemAttributes.frame.maxY
                } else if itemAttributes.frame.maxX > contentWidth {
                    contentWidth = itemAttributes.frame.maxX
                }

                if (didFitInOriginalFrame) {
                    transverse += 1
                }
            }
        }
        sectionedItemGrid = [] // Only used during prepare, free up some memory
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return itemAttributesCache.filter {
            $0.frame.intersects(rect)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributesCache.first {
            $0.indexPath == indexPath
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if scrollDirection == .vertical,
            let oldWidth = collectionView?.bounds.width
        {
            return oldWidth != newBounds.width
        } else if scrollDirection == .horizontal,
            let oldHeight = collectionView?.bounds.height
        {
            return oldHeight != newBounds.height
        }

        return false
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        itemAttributesCache = []
        contentWidth = 0
        contentHeight = 0
    }

    // MARK: - Private

    private func indexableScale(forItemAt indexPath: IndexPath) -> Int {
        var itemScale = (delegate ?? self).scaleForItem(inCollectionView: collectionView!, withLayout: self, atIndexPath: indexPath)
        if itemScale > transverseItemsCount {
            itemScale = transverseItemsCount
        }
        return Int(itemScale - 1) // Using with indices, want 0-based
    }

    private func nextAvailableFrame(startingAt originalFrame: ItemFrame) -> (frame: ItemFrame, fitInOriginalFrame: Bool) {
        var longitude = originalFrame.longitude, transverse = originalFrame.transverse
        var newFrame = ItemFrame(originalFrame.section, longitude, transverse, originalFrame.scale)
        while !isSpaceAvailable(for: newFrame) {
            transverse += 1

            // Reached end of transverse, restart on next longitude
            if transverse == intTransverseItemsCount || transverse + originalFrame.scale == intTransverseItemsCount {
                transverse = 0
                longitude += 1
            }

            newFrame = ItemFrame(originalFrame.section, longitude, transverse, originalFrame.scale)
        }

        return (newFrame, longitude == originalFrame.longitude && transverse == originalFrame.transverse)
    }

    private func isSpaceAvailable(for frame: ItemFrame) -> Bool {
        for longitude in frame.longitude ... frame.longitude + frame.scale {
            // Ensure we won't get off the end of the array
            while sectionedItemGrid[frame.section].count <= longitude {
                sectionedItemGrid[frame.section].append(Array(repeating: false, count: intTransverseItemsCount))
            }

            for transverse in frame.transverse ... frame.transverse + frame.scale {
                if transverse >= intTransverseItemsCount || sectionedItemGrid[frame.section][longitude][transverse] {
                    return false
                }
            }
        }

        return true
    }

    private func reserveItemGrid(frame: ItemFrame) {
        for longitude in frame.longitude ... frame.longitude + frame.scale {
            for transverse in frame.transverse ... frame.transverse + frame.scale {
                sectionedItemGrid[frame.section][longitude][transverse] = true
            }
        }
    }

    private func layoutAttributes(for indexPath: IndexPath, at itemFrame: ItemFrame) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let transverseOffset = CGFloat(itemFrame.transverse) * (itemSpacing + itemDimension)
        let longitudinalOffset = CGFloat(itemFrame.longitude) * (itemSpacing + itemDimension)
        let itemScaledDimension = itemDimension + (CGFloat(itemFrame.scale) * (itemSpacing + itemDimension))

        if scrollDirection == .vertical {
            layoutAttributes.frame = CGRect(x: transverseOffset, y: longitudinalOffset, width: itemScaledDimension, height: itemScaledDimension)
        } else {
            layoutAttributes.frame = CGRect(x: longitudinalOffset, y: transverseOffset, width: itemScaledDimension, height: itemScaledDimension)
        }

        return layoutAttributes
    }
}
