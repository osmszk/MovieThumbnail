//
//  ThumbnailViewController.swift
//  MovieThumbnail
//
//  Created by 鈴木治 on 2019/08/28.
//  Copyright © 2019 Osamu Suzuki. All rights reserved.
//

import UIKit
import Photos

class ThumbnailViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private var videos: [AVPlayerItem] = []
    private let imageManager = PHImageManager()
    private var status = PHPhotoLibrary.authorizationStatus(){
        didSet{
            if status == .authorized {
                loadVideos()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch self.status {
        case .authorized:
            self.loadVideos()

        default:
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(ThumbnailViewController.checkState),
                                                   name:  UIApplication.didBecomeActiveNotification,
                                                   object: nil)

        }
    }

    @objc func checkState() {
        self.status = PHPhotoLibrary.authorizationStatus()
    }

    private func loadVideos() {
        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        activityIndicator.center = self.view.center
        activityIndicator.backgroundColor = UIColor.black
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        //メディアタイプをビデオに絞って取得
        let assets:PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: nil)
        //取得したアセットを変換
        assets.enumerateObjects({(obj, index, stop) -> Void in
            //PHImageManagerを使ってplayerItemに
            self.imageManager.requestPlayerItem(forVideo: assets[index], options: nil, resultHandler: {(playerItem, info) -> Void in
                //配列に追加
                guard let playerItem = playerItem else {
                    print("Not found playerItem")
                    return
                }
                self.videos.append(playerItem)

                //最後の処理が終わったらメインスレッドでコレクションビューをリロード
                if index == assets.count - 1 {
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        //インジケータ消す
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                    }
                }
            })
        })
    }
}

extension ThumbnailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "thumbnailCell", for: indexPath) as? ThumbnailCell else {
            return UICollectionViewCell()
        }

        let item  = videos[indexPath.row]
        //動画から画像を切り出し
        let asset1:AVAsset = item.asset
        let gene = AVAssetImageGenerator(asset:asset1)
        gene.maximumSize = CGSize(width:self.view.frame.size.width/4, height:self.view.frame.size.width/4)
        do {
            let capImg = try gene.copyCGImage(at: asset1.duration, actualTime: nil)
            cell.thumbnailImageView.image = UIImage.init(cgImage: capImg)
        } catch {
            print(error)
            return UICollectionViewCell()
        }

        return cell
    }
}

