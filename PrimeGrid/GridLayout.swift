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
    func itemLongitudinalDimension(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, transverseDimension: CGFloat) -> CGFloat
    func headerLongitudinalDimension(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, transverseDimension: CGFloat) -> CGFloat
}

extension GridLayoutDelegate {
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        return 1
    }

    func itemLongitudinalDimension(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, transverseDimension: CGFloat) -> CGFloat {
        return transverseDimension
    }

    func headerLongitudinalDimension(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, transverseDimension: CGFloat) -> CGFloat {
        return 0
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
    private var itemTransverseDimension: CGFloat = 0
    private var itemLongitudinalDimension: CGFloat = 0

    private var sectionedItemGrid: Array<Array<Array<Bool>>> = []
    private var headerAttributesCache: Array<UICollectionViewLayoutAttributes> = []
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

        var additionalSectionSpacing: CGFloat = 0
        let headerLongitudinalDimension = (delegate ?? self).headerLongitudinalDimension(inCollectionView: collectionView, withLayout: self, transverseDimension: transverseDimension)

        itemTransverseDimension = (transverseDimension - (CGFloat(transverseItemsCount) * itemSpacing) + itemSpacing) / CGFloat(transverseItemsCount)
        itemLongitudinalDimension = (delegate ?? self).itemLongitudinalDimension(inCollectionView: collectionView, withLayout: self, transverseDimension: itemTransverseDimension)

        for section in 0 ..< collectionView.numberOfSections {
            let itemCount = collectionView.numberOfItems(inSection: section)

            // Calculate header attributes
            if headerLongitudinalDimension > 0.0 && itemCount > 0 {
                if headerAttributesCache.count > 0 {
                    additionalSectionSpacing += itemSpacing
                }

                let frame: CGRect
                if scrollDirection == .vertical {
                    frame = CGRect(x: 0, y: additionalSectionSpacing, width: transverseDimension, height: headerLongitudinalDimension)
                } else {
                    frame = CGRect(x: additionalSectionSpacing, y: 0, width: headerLongitudinalDimension, height: transverseDimension)
                }
                let headerLayoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: IndexPath(item: 0, section: section))
                headerLayoutAttributes.frame = frame

                headerAttributesCache.append(headerLayoutAttributes)
                additionalSectionSpacing += headerLongitudinalDimension + itemSpacing
            }

            // Calculate item attributes
            let sectionOffset = additionalSectionSpacing
            sectionedItemGrid.append([])

            var longitude = 0, transverse = 0
            for item in 0 ..< itemCount {
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
                let itemAttributes = layoutAttributes(for: itemIndexPath, at: itemFrame, with: sectionOffset)

                itemAttributesCache.append(itemAttributes)

                // Update variable dimension
                if scrollDirection == .vertical {
                    if itemAttributes.frame.maxY > contentHeight {
                        contentHeight = itemAttributes.frame.maxY
                    }
                    if itemAttributes.frame.maxY > additionalSectionSpacing {
                        additionalSectionSpacing = itemAttributes.frame.maxY
                    }
                } else {
                    // .horizontal
                    if itemAttributes.frame.maxX > contentWidth {
                        contentWidth = itemAttributes.frame.maxX
                    }
                    if itemAttributes.frame.maxX > additionalSectionSpacing {
                        additionalSectionSpacing = itemAttributes.frame.maxX
                    }
                }

                if (didFitInOriginalFrame) {
                    transverse += 1
                }
            }
        }
        sectionedItemGrid = [] // Only used during prepare, free up some memory
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let headerAttributes = headerAttributesCache.filter {
            $0.frame.intersects(rect)
        }
        let itemAttributes = itemAttributesCache.filter {
            $0.frame.intersects(rect)
        }

        return headerAttributes + itemAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributesCache.first {
            $0.indexPath == indexPath
        }
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard elementKind == UICollectionElementKindSectionHeader else { return nil }

        return headerAttributesCache.first {
            $0.indexPath == indexPath
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if scrollDirection == .vertical, let oldWidth = collectionView?.bounds.width {
            return oldWidth != newBounds.width
        } else if scrollDirection == .horizontal, let oldHeight = collectionView?.bounds.height {
            return oldHeight != newBounds.height
        }

        return false
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        itemAttributesCache = []
        headerAttributesCache = []
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

    private func layoutAttributes(for indexPath: IndexPath, at itemFrame: ItemFrame, with sectionOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let transverseOffset = CGFloat(itemFrame.transverse) * (itemSpacing + itemTransverseDimension)
        let longitudinalOffset = CGFloat(itemFrame.longitude) * (itemSpacing + itemLongitudinalDimension) + sectionOffset
        let itemScaledTransverseDimension = itemTransverseDimension + (CGFloat(itemFrame.scale) * (itemSpacing + itemTransverseDimension))
        let itemScaledLongitudinalDimension = itemLongitudinalDimension + (CGFloat(itemFrame.scale) * (itemSpacing + itemLongitudinalDimension))

        if scrollDirection == .vertical {
            layoutAttributes.frame = CGRect(x: transverseOffset, y: longitudinalOffset, width: itemScaledTransverseDimension, height: itemScaledLongitudinalDimension)
        } else {
            layoutAttributes.frame = CGRect(x: longitudinalOffset, y: transverseOffset, width: itemScaledLongitudinalDimension, height: itemScaledTransverseDimension)
        }

        return layoutAttributes
    }
}
