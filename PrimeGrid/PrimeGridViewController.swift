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

typealias NumberData = (number: Int, isPrime: Bool, isMersennePrime: Bool)

class PrimeGridViewController: UIViewController, UICollectionViewDataSource, GridLayoutDelegate {
    static let NumberCellReuseIdentifier = "NumberCellReuseIdentifier"

    @IBOutlet weak var statusBarBackground: UIView!
    @IBOutlet weak var statusBarBackgroundHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var gridLayout: GridLayout!

    let useSections = false
    let data: Array<Array<NumberData>> = [
        [
            (1, false, false),
            (2, true, false),
            (3, true, true),
            (4, false, false),
            (5, true, false),
            (6, false, false),
            (7, true, true),
            (8, false, false),
            (9, false, false),
            (10, false, false),
        ],
        [
            (11, true, false),
            (12, false, false),
            (13, true, false),
            (14, false, false),
            (15, false, false),
            (16, false, false),
            (17, true, false),
            (18, false, false),
            (19, true, false),
            (20, false, false),
        ],
        [
            (21, false, false),
            (22, false, false),
            (23, true, false),
            (24, false, false),
            (25, false, false),
            (26, false, false),
            (27, false, false),
            (28, false, false),
            (29, true, false),
            (30, false, false),
        ],
        [
            (31, true, true),
            (32, false, false),
            (33, false, false),
            (34, false, false),
            (35, false, false),
            (36, false, false),
            (37, true, false),
            (38, false, false),
            (39, false, false),
            (40, false, false),
        ],
        [
            (41, true, false),
            (42, false, false),
            (43, true, false),
            (44, false, false),
            (45, false, false),
            (46, false, false),
            (47, true, false),
            (48, false, false),
            (49, false, false),
            (50, false, false),
        ],
        [
            (51, false, false),
            (52, false, false),
            (53, true, false),
            (54, false, false),
            (55, false, false),
            (56, false, false),
            (57, false, false),
            (58, false, false),
            (59, true, false),
            (60, false, false),
        ],
        [
            (61, true, false),
            (62, false, false),
            (63, false, false),
            (64, false, false),
            (65, false, false),
            (66, false, false),
            (67, true, false),
            (68, false, false),
            (69, false, false),
            (70, false, false),
        ],
        [
            (71, true, false),
            (72, false, false),
            (73, true, false),
            (74, false, false),
            (75, false, false),
            (76, false, false),
            (77, false, false),
            (78, false, false),
            (79, true, false),
            (80, false, false),
        ],
        [
            (81, false, false),
            (82, false, false),
            (83, true, false),
            (84, false, false),
            (85, false, false),
            (86, false, false),
            (87, false, false),
            (88, false, false),
            (89, true, false),
            (90, false, false),
        ],
        [
            (91, false, false),
            (92, false, false),
            (93, false, false),
            (94, false, false),
            (95, false, false),
            (96, false, false),
            (97, true, false),
            (98, false, false),
            (99, false, false),
            (100, false, false),
        ],
    ]

    // MARK: - UIViewController

    override func viewDidLoad() {
        statusBarBackground.backgroundColor = .darkGray
        collectionView.backgroundColor = .darkGray
        collectionView.register(NumberCell.self,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: PrimeGridViewController.NumberCellReuseIdentifier) // Reusing the cell as a header, shhhh...
        collectionView.register(NumberCell.self, forCellWithReuseIdentifier: PrimeGridViewController.NumberCellReuseIdentifier)
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionView.contentOffset = CGPoint(x: -10, y: -10)

        gridLayout.delegate = self
        gridLayout.itemSpacing = 10
        gridLayout.fixedDivisionCount = 4
        gridLayout.scrollDirection = .vertical
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        statusBarBackgroundHeightConstraint.constant = topLayoutGuide.length
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return useSections ? data.count : 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return useSections ? data[section].count : data.reduce(0) { $0 + $1.count }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let numberCell = collectionView.dequeueReusableCell(withReuseIdentifier: PrimeGridViewController.NumberCellReuseIdentifier, for: indexPath) as! NumberCell
        let cellNumberData = numberData(forItemAt: indexPath)
        numberCell.numberLabel.text = String(cellNumberData.number)
        numberCell.numberLabel.font = font(forNumberData: cellNumberData)
        numberCell.numberLabel.sizeToFit()

        return numberCell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let numberHeaderCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PrimeGridViewController.NumberCellReuseIdentifier, for: indexPath) as! NumberCell
        let firstNumberData = data[indexPath.section].first!
        let lastNumberData = data[indexPath.section].last!
        numberHeaderCell.contentView.backgroundColor = .lightGray
        numberHeaderCell.numberLabel.textColor = .black
        numberHeaderCell.numberLabel.text = "\(firstNumberData.number) ... \(lastNumberData.number)"
        numberHeaderCell.numberLabel.font = UIFont.boldSystemFont(ofSize: 36)
        numberHeaderCell.numberLabel.sizeToFit()
        numberHeaderCell.numberLabel.transform = gridLayout.scrollDirection == .vertical ? .identity : CGAffineTransform(rotationAngle: .pi / -2)

        return numberHeaderCell
    }

    // MARK: - PrimeGridDelegate

    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        return scale(forNumberData: numberData(forItemAt: indexPath))
    }

    func itemFlexibleDimension(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, fixedDimension: CGFloat) -> CGFloat {
        return 0.8 * fixedDimension
    }

    func headerFlexibleDimension(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, fixedDimension: CGFloat) -> CGFloat {
        return useSections ? 60 : 0
    }

    // MARK: - Private

    private func numberData(forItemAt indexPath: IndexPath) -> NumberData {
        if useSections {
            return data[indexPath.section][indexPath.row]
        } else {
            let section = indexPath.row / 10
            let row = indexPath.row % 10
            return data[section][row]
        }
    }

    private func font(forNumberData numberData: NumberData) -> UIFont {
        switch numberData {
        case (_, true, true):
            return UIFont.boldSystemFont(ofSize: 108)
        case (_, true, false):
            return UIFont.boldSystemFont(ofSize: 72)
        default:
            return UIFont.boldSystemFont(ofSize: 36)
        }
    }

    private func scale(forNumberData numberData: NumberData) -> UInt {
        switch numberData {
        case (_, true, true):
            return 3
        case (_, true, false):
            return 2
        default:
            return 1
        }
    }
}

