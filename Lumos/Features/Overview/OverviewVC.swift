//
//  OverviewVC.swift
//  Lumos
//
//  Created by Christoph Pageler on 09.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import UIKit


class OverviewVC: UIViewController {

    @IBOutlet weak var collectionViewImages: UICollectionView!
    private var refreshControl: UIRefreshControl?

    var images: [ImageDTO] = []
    var cameraVC: CameraVC?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "overview_title".localized()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(actionRefreshControlValueChanged), for: .valueChanged)
        self.refreshControl = refreshControl
        collectionViewImages.addSubview(refreshControl)

        let flowLayout = collectionViewImages.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout?.sectionHeadersPinToVisibleBounds = true

        NotificationCenter.default.addObserver(forName: HTTPService.didUpdateUploadsNotification,
                                               object: nil, queue: nil)
        { notification in
            DispatchQueue.main.async {
                self.collectionViewImages.reloadSections(IndexSet(integer: 0))
            }
        }

        updateImages()
    }

    private func updateImages() {
        HTTPService.shared.getAllImages { images in
            self.images = images ?? []
            self.collectionViewImages.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction func actionPhotoRollTouchUpInside(_ sender: UIBarButtonItem) {
        let cameraVC = CameraVC()
        self.cameraVC = cameraVC
        cameraVC.chooseImageFromGallery(on: self)
    }

    @objc private func actionRefreshControlValueChanged() {
        refreshControl?.beginRefreshing()
        updateImages()
    }

}


extension OverviewVC: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                       withReuseIdentifier: "OverviewUploadCollectionReusableView",
                                                                       for: indexPath) as! OverviewUploadCollectionReusableView
            return view
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionViewImages.dequeueReusableCell(withReuseIdentifier: "OverviewImageCollectionViewCell", for: indexPath) as! OverviewImageCollectionViewCell
        let image = images[indexPath.row]

        if let base64Data = image.data?.data(using: .utf8),
            let decodedImageData = Data(base64Encoded: base64Data, options: .ignoreUnknownCharacters) {
            let uiimage = UIImage(data: decodedImageData)
            cell.imageViewImage.image = uiimage
        }

        return cell
    }

}


extension OverviewVC: UICollectionViewDelegate {

}


extension OverviewVC: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let insets = self.collectionView(collectionView,
                                         layout: collectionViewLayout,
                                         insetForSectionAt: indexPath.section)
        let interitemSpacing = self.collectionView(collectionView,
                                                   layout: collectionViewLayout,
                                                   minimumInteritemSpacingForSectionAt: indexPath.section)
        let numberOfItemsPerRow = 3
        let insetsForWidth = (insets.left + insets.right)
        let spacingBetweenItems = CGFloat(numberOfItemsPerRow - 1) * interitemSpacing
        let availableWidth = collectionView.frame.size.width - (insetsForWidth + spacingBetweenItems)
        let width = availableWidth / CGFloat(numberOfItemsPerRow)
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        let isUploading = HTTPService.shared.imageUploads.count > 0
        if isUploading {
            return CGSize(width: collectionView.frame.size.width, height: 50)
        } else {
            return CGSize.zero
        }
    }

}
