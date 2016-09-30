//
//  PrimeGridLayout.swift
//  PrimeGridLayout
//
//  Created by Sean Swezey on 9/29/16.
//  Copyright © 2016 stable/kernel. All rights reserved.
//

import UIKit

protocol PrimeGridLayoutDelegate: class {
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt
}

extension PrimeGridLayoutDelegate {
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        return 1
    }
}

class PrimeGridLayout: UICollectionViewLayout, PrimeGridLayoutDelegate {
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    var scrollDirection: UICollectionViewScrollDirection = .vertical
    var transverseItemsCount: UInt = 1
    var itemSpacing: CGFloat = 0

    weak var delegate: PrimeGridLayoutDelegate?

    private var contentWidth: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var itemDimension: CGFloat = 0

    private var sectionedItemGrid: Array<Array<Array<Bool>>> = []
    private var itemAttributesCache: Array<UICollectionViewLayoutAttributes> = []

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

        sectionedItemGrid = []
        let sectionCount = collectionView.numberOfSections
        for sectionIndex in 0 ..< sectionCount {
            sectionedItemGrid.append([])
            var sectionTransverseIndex: UInt = 0, sectionLongitudinalIndex: UInt = 0
            for itemIndex in 0 ..< collectionView.numberOfItems(inSection: sectionIndex) {
                if sectionTransverseIndex == transverseItemsCount {
                    // Reached end of row in .vertical or column in .horizontal
                    sectionTransverseIndex = 0
                    sectionLongitudinalIndex += 1
                }

                let (itemFits, layoutAttributes) = attributes(forTransverseIndex: sectionTransverseIndex, longitudinalIndex: sectionLongitudinalIndex, indexPath: IndexPath(item: itemIndex, section: sectionIndex))
                itemAttributesCache.append(layoutAttributes)
                if (itemFits) {
                    sectionTransverseIndex += 1
                }

                if scrollDirection == .vertical && layoutAttributes.frame.maxY > contentHeight {
                    contentHeight = layoutAttributes.frame.maxY
                } else if layoutAttributes.frame.maxX > contentWidth {
                    contentWidth = layoutAttributes.frame.maxX
                }
            }
        }
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

    override func invalidateLayout() {
        super.invalidateLayout()

        itemAttributesCache = []
        contentWidth = 0
        contentHeight = 0
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let oldWidth = collectionView?.bounds.width {
            return oldWidth != newBounds.width
        }

        return false
    }

    // MARK: - Private

    private func attributes(forTransverseIndex transverseIndex: UInt, longitudinalIndex: UInt, indexPath: IndexPath) -> (itemFitsAtGivenLocation: Bool, attributes: UICollectionViewLayoutAttributes) {
        let itemScale: UInt = {
            var itemScale = (delegate ?? self).scaleForItem(inCollectionView: collectionView!, withLayout: self, atIndexPath: indexPath)
            if itemScale > transverseItemsCount {
                itemScale = transverseItemsCount
            }
            return itemScale - 1 // Using with indices, want 0-based
        }()

        // Find a location for the item
        ensureGridSize(forSection: indexPath.section, longitudinalIndex: longitudinalIndex + itemScale)

        var walkingTransverseIndex = transverseIndex, walkingLongitudinalIndex = longitudinalIndex
        while !isSpaceAvailable(inSection: indexPath.section, atLongitudinalIndex: walkingLongitudinalIndex, transverseIndex: walkingTransverseIndex, itemScale: itemScale) {
            walkingTransverseIndex += 1

            if walkingTransverseIndex == transverseItemsCount || walkingTransverseIndex + itemScale == self.transverseItemsCount {
                walkingTransverseIndex = 0
                walkingLongitudinalIndex += 1

                ensureGridSize(forSection: indexPath.section, longitudinalIndex: walkingLongitudinalIndex + itemScale)
            }
        }

        // Should have enough room for item now in grid
        // Mark occupying locations in item grid
        for occupyingLongitudinalIndex in walkingLongitudinalIndex ... walkingLongitudinalIndex + itemScale {
            for occupyingTransverseIndex in walkingTransverseIndex ... walkingTransverseIndex + itemScale {
                sectionedItemGrid[indexPath.section][Int(occupyingLongitudinalIndex)][Int(occupyingTransverseIndex)] = true
            }
        }

        // Create frame for item
        let transverseOffset = CGFloat(walkingTransverseIndex) * (itemSpacing + itemDimension)
        let longitudinalOffset = CGFloat(walkingLongitudinalIndex) * (itemSpacing + itemDimension)
        let itemScaledDimension = itemDimension + (CGFloat(itemScale) * (itemSpacing + itemDimension))
        let frame: CGRect
        if scrollDirection == .vertical {
            frame = CGRect(x: transverseOffset, y: longitudinalOffset, width: itemScaledDimension, height: itemScaledDimension)
        } else {
            frame = CGRect(x: longitudinalOffset, y: transverseOffset, width: itemScaledDimension, height: itemScaledDimension)
        }

        // Create attributes
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        layoutAttributes.frame = frame

        return (walkingTransverseIndex == transverseIndex && walkingLongitudinalIndex == longitudinalIndex, layoutAttributes)
    }

    private func ensureGridSize(forSection section: Int, longitudinalIndex: UInt) {
        while UInt(sectionedItemGrid[section].count) <= longitudinalIndex {
            let transverseOccupiedArray = Array<Bool>(repeating: false, count: Int(transverseItemsCount))
            sectionedItemGrid[section].append(transverseOccupiedArray)
        }
    }

    private func isSpaceAvailable(inSection section: Int, atLongitudinalIndex longitudinalIndex: UInt, transverseIndex: UInt, itemScale: UInt) -> Bool {
        for longIndex in longitudinalIndex ... longitudinalIndex + itemScale {
            for tranIndex in transverseIndex ... transverseIndex + itemScale {
                if tranIndex >= transverseItemsCount || sectionedItemGrid[section][Int(longIndex)][Int(tranIndex)] {
                    return false
                }
            }
        }

        return true
    }
}
