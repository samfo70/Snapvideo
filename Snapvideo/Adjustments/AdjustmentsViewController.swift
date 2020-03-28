//
//  ToolEditingViewController.swift
//  Snapvideo
//
//  Created by Anastasia Petrova on 13/02/2020.
//  Copyright © 2020 Anastasia Petrova. All rights reserved.
//

import UIKit
import AVFoundation

final class AdjustmentsViewController: UIViewController {
    let asset: AVAsset
    let videoViewController: VideoViewController
    let listView: ParameterListView
    let tabBar = TabBar(items: "✕", "✓")
    let sliderView = AdjustmentSliderView(name: "Brightness", value: -50)
    lazy var resumeImageView = UIImageView(image: UIImage(named: "playCircle")?.withRenderingMode(.alwaysTemplate))
    
    var previousTranslationY: CGFloat = 0
    
    lazy var panGestureRecognizer = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePanGesture)
    )
    
    var trackDuration: Float {
        guard let trackDuration = videoViewController.player.currentItem?.asset.duration else {
            return 0
        }
        return Float(CMTimeGetSeconds(trackDuration))
    }
    
    init(url: URL, tool: AnyTool) {
        asset = AVAsset(url: url)
        videoViewController = VideoViewController(asset: asset)
        listView = ParameterListView(parameters: [
            ParameterListView.Parameter(name: "Brightness", value: "10"),
            ParameterListView.Parameter(name: "Contrast", value: "25"),
            ParameterListView.Parameter(name: "Saturation", value: "40"),
            ParameterListView.Parameter(name: "Ambience", value: "23"),
            ParameterListView.Parameter(name: "Highlight", value: "10"),
            ParameterListView.Parameter(name: "Shadows", value: "3"),
            ParameterListView.Parameter(name: "Warms", value: "5"),
        ]) { _ in }
//        listView.backgroundColor = .red
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(videoViewController.view)
        view.addSubview(sliderView)
        view.addSubview(listView)
        view.addSubview(tabBar)
        
        setUpVideoViewController()
        setUpSliderView()
        setUpParameterListView()
        setUpTabBar()
        setUpPanGestureRecognizer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setUpSliderView() {
        sliderView.translatesAutoresizingMaskIntoConstraints = false 
        NSLayoutConstraint.activate([
            sliderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            sliderView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            sliderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    }
    
    private func setUpParameterListView() {
        listView.isHidden = true
        listView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            listView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            listView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    private func setUpTabBar() {
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.setContentHuggingPriority(.required, for: .vertical)
        tabBar.setContentCompressionResistancePriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setUpVideoViewController() {
        videoViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate ([
            videoViewController.view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            videoViewController.view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            videoViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            videoViewController.view.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        ])
    }
    
    private func setUpPanGestureRecognizer() {
        videoViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: videoViewController.view)
        let deltaY = previousTranslationY - translation.y
        previousTranslationY = translation.y
        listView.translateY(deltaY)
        switch recognizer.state {
        case .began:
            listView.setHiddenAnimated(false, duration: 0.3)
        case .ended:
            listView.setHiddenAnimated(true, duration: 0.2)
            previousTranslationY = 0
        default: break
        }
    }
}

extension AdjustmentsViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }
}
