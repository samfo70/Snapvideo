//
//  VideoEditorViewController.swift
//  Snapvideo
//
//  Created by Anastasia Petrova on 02/02/2020.
//  Copyright © 2020 Anastasia Petrova. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

final class VideoEditorViewController: UIViewController {
    var videoFileAsset: AVAsset {
        didSet {
            videoViewController.asset = videoFileAsset
            generatePreviewImages()
        }
    }
    
    let looksPanel = UIView()
    let exportPanel = UIView()
    
    var topExportPanelConstraint = NSLayoutConstraint()
    var topLooksConstraint = NSLayoutConstraint()
    var topToolsConstraint = NSLayoutConstraint()
    
    //child view controllers
    let videoViewController: VideoViewController
    let looksViewController: LooksViewController
    let toolsViewController: ToolsViewController
    
    let tabBar = TabBar(items: "LOOKS", "TOOLS", "EXPORT")
    var selectedFilter: AnyFilter = AnyFilter(PassthroughFilter())
    var selectedFilterIndex: Int
    var pendingFilterIndex: Int?
    let coverView = UIView()

    var cancelButton = LooksViewButton(imageName: "cancel-solid")
    var doneButton = LooksViewButton(imageName: "done-solid")
    //TODO: extract to own View Controller
    var saveCopyButton = SaveCopyVideoButton()
    var shareButton = SaveCopyVideoButton()

    var spacerHeight = CGFloat()
    let shareStackView = UIStackView()
    let saveCopyStackView = UIStackView()
    let itemSize = CGSize(width: 60, height: 76)
    var previouslySelectedIndex: Int?
    
    var isLooksButtonSelected: Bool = false {
        didSet {
            if isLooksButtonSelected {
                openLooks()
            } else {
                closeLooks()
            }
        }
    }
    
    var isExportButtonSelected: Bool = false {
        didSet {
            if isExportButtonSelected {
                openExportMenu()
            } else {
                closeExportMenu()
            }
        }
    }
    
    var isToolsButtonSelected: Bool = false {
        didSet {
            if isToolsButtonSelected {
                openTools()
            } else {
                closeTools()
            }
        }
    }
    
    var isExportViewShown: Bool = true {
        didSet {
            if isExportButtonSelected &&  isExportButtonSelected != isExportViewShown {
                isExportButtonSelected = isExportViewShown
                tabBar.selectedItem = nil
                previouslySelectedIndex = nil
            }
        }
    }
    
    var isToolsViewShown: Bool = true {
        didSet {
            if isToolsButtonSelected &&  isToolsButtonSelected != isToolsViewShown {
                isToolsButtonSelected = isToolsViewShown
                tabBar.selectedItem = nil
                previouslySelectedIndex = nil
            }
        }
    }
    
    var previewImage: UIImage? {
        didSet {
            looksViewController.dataSource.image = previewImage
        }
    }
    
    var trackDuration: Float {
        guard let trackDuration = videoViewController.player.currentItem?.asset.duration else {
            return 0
        }
        return Float(CMTimeGetSeconds(trackDuration))
    }
    

    init(url: URL, selectedFilterIndex: Int, filters: [AnyFilter], tools: [ToolEnum]) {
        videoFileAsset = AVAsset(url: url)
        self.selectedFilterIndex = selectedFilterIndex
        videoViewController = VideoViewController(asset: videoFileAsset)
        toolsViewController = ToolsViewController(tools: tools)
        looksViewController = LooksViewController(
            itemSize: itemSize,
            selectedFilterIndex: selectedFilterIndex,
            filters: filters
        )
        
        super.init(nibName: nil, bundle: nil)
        addChild(looksViewController)
        looksViewController.didMove(toParent: self)
        looksViewController.didSelectLook = { [weak self] newIndex, previousIndex in
            guard let self = self else { return }
            let hasChangedSelectedFilter = newIndex != self.selectedFilterIndex
            self.videoViewController.playerView.filter = filters[newIndex]
            self.videoViewController.backgroundVideoView.filter = filters[newIndex] + AnyFilter(BlurFilter(blurRadius: 100))
            self.doneButton.isEnabled = hasChangedSelectedFilter
            self.tabBar.isHidden = hasChangedSelectedFilter
            guard newIndex != previousIndex && hasChangedSelectedFilter else { return }
            self.selectedFilter = filters[newIndex]
            self.pendingFilterIndex = newIndex
        }
        toolsViewController.didSelectToolCallback = { [weak self] index in
            self?.presentAdjustmentsScreen(url: url, tool: tools[index])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        generatePreviewImages()
        
        view.addSubview(videoViewController.view)
        view.addSubview(looksPanel)
        view.addSubview(toolsViewController.view)
        view.addSubview(exportPanel)
        view.addSubview(tabBar)
        
        setUpVideoViewController()
        setUpLooksView()
        setUpCancelButton()
        setUpDoneButton()
        setUpToolsView()
        setUpExportView()
        setUpShareStackView()
        setUpSaveCopyStackView()
        setUpShareButton()
        setUpSaveCopyButton()
        setUpTabBar()
    }
    
    private func generatePreviewImages() {
        AssetImageGenerator.getThumbnailImageFromVideoAsset(
            asset: videoFileAsset,
            maximumSize: itemSize.applying(.init(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)),
            completion: { [weak self] image in
                DispatchQueue.main.async {
                    self?.previewImage = image
                }
            }
        )
    }
    
    private func setUpTabBar() {
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.isTranslucent = false
        tabBar.setContentHuggingPriority(.required, for: .vertical)
        tabBar.setContentCompressionResistancePriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func setUpVideoViewController() {
        videoViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate ([
            videoViewController.view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            videoViewController.view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            videoViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            tabBar.topAnchor.constraint(greaterThanOrEqualTo: videoViewController.view.bottomAnchor)
        ])
    }
   
    func setUpLooksView() {
        looksPanel.translatesAutoresizingMaskIntoConstraints = false
        looksPanel.backgroundColor = .white
        topLooksConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: looksPanel.topAnchor, constant: -view.safeAreaInsets.bottom)
        let looksViewHeight: CGFloat = 100.0
        let bottomConstraint = looksPanel.topAnchor.constraint(equalTo: videoViewController.view.bottomAnchor)
        bottomConstraint.priority = .defaultLow
        NSLayoutConstraint.activate ([
            looksPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            looksPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            looksPanel.heightAnchor.constraint(equalTo: tabBar.heightAnchor, constant: looksViewHeight),
            bottomConstraint,
            topLooksConstraint
        ])
        let buttonsStackView = UIStackView()
        buttonsStackView.addArrangedSubview(cancelButton)
        buttonsStackView.addArrangedSubview(doneButton)
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillEqually
        
        let collectionStackView = UIStackView()
        collectionStackView.translatesAutoresizingMaskIntoConstraints = false
        collectionStackView.axis = .vertical
        
        looksPanel.addSubview(collectionStackView)
        collectionStackView.addArrangedSubview(looksViewController.view)
        
        let line = UIView()
        line.backgroundColor = .darkGray
        collectionStackView.addArrangedSubview(line)
        
        let spacer = UIView()
        spacer.backgroundColor = .white
        collectionStackView.addArrangedSubview(spacer)
        collectionStackView.addArrangedSubview(buttonsStackView)
        
        NSLayoutConstraint.activate ([
            collectionStackView.trailingAnchor.constraint(equalTo: looksPanel.trailingAnchor),
            collectionStackView.leadingAnchor.constraint(equalTo: looksPanel.leadingAnchor),
            collectionStackView.topAnchor.constraint(equalTo: looksPanel.topAnchor),
            collectionStackView.bottomAnchor.constraint(equalTo: looksPanel.bottomAnchor),
            looksViewController.view.heightAnchor.constraint(equalToConstant: looksViewHeight),
            line.heightAnchor.constraint(equalToConstant: 0.4)
        ])
    }
    
    func setUpToolsView() {
        toolsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        topToolsConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolsViewController.view.topAnchor)
        
        NSLayoutConstraint.activate ([
            toolsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolsViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            topToolsConstraint
        ])
    }
    
    func setUpExportView() {
        exportPanel.translatesAutoresizingMaskIntoConstraints = false
        exportPanel.backgroundColor = .white
        topExportPanelConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: exportPanel.topAnchor, constant: -view.safeAreaInsets.bottom)
        
        NSLayoutConstraint.activate ([
            exportPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            exportPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            exportPanel.heightAnchor.constraint(equalToConstant: 100),
            topExportPanelConstraint
        ])
        
        let exportStackView = UIStackView()
        exportStackView.translatesAutoresizingMaskIntoConstraints = false
        exportStackView.axis = .vertical
        exportStackView.distribution = .fillEqually
        exportPanel.addSubview(exportStackView)
        
        NSLayoutConstraint.activate ([
            exportStackView.trailingAnchor.constraint(equalTo: exportPanel.trailingAnchor),
            exportStackView.leadingAnchor.constraint(equalTo: exportPanel.leadingAnchor),
            exportStackView.topAnchor.constraint(equalTo: exportPanel.topAnchor),
            exportStackView.bottomAnchor.constraint(equalTo: exportPanel.bottomAnchor)
        ])
        shareStackView.translatesAutoresizingMaskIntoConstraints = false
        shareStackView.axis = .horizontal
        saveCopyStackView.translatesAutoresizingMaskIntoConstraints = false
        saveCopyStackView.axis = .horizontal
        exportStackView.addArrangedSubview(shareStackView)
        exportStackView.addArrangedSubview(saveCopyStackView)
    }
    
    func setUpCancelButton() {
        cancelButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        NSLayoutConstraint.activate ([
            cancelButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        cancelButton.addTarget(self, action: #selector(self.discardLooks), for: .touchUpInside)
    }
    
    func setUpDoneButton() {
        doneButton.isEnabled = false
        doneButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        NSLayoutConstraint.activate ([
            doneButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        doneButton.addTarget(self, action: #selector(self.saveFilter), for: .touchUpInside)
    }
    
    func setUpShareStackView() {
        shareStackView.spacing = 16
        shareStackView.alignment = .center
        let imageView = ExportImageView(systemName: "square.and.arrow.up")
        let leftSpacer = UIView()
        let rightSpacer = UIView()
        let labelsStackView = UIStackView()
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        
        shareStackView.addArrangedSubview(leftSpacer)
        shareStackView.addArrangedSubview(imageView)
        shareStackView.addArrangedSubview(labelsStackView)
        shareStackView.addArrangedSubview(rightSpacer)
        shareStackView.setCustomSpacing(0, after: leftSpacer)
        shareStackView.setCustomSpacing(0, after: labelsStackView)
        
        NSLayoutConstraint.activate ([
            leftSpacer.widthAnchor.constraint(equalToConstant: 16),
            rightSpacer.widthAnchor.constraint(equalTo: leftSpacer.widthAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        let header = HeaderExportLabel()
        header.text = "Share"
        
        let body = BodyExportLabel()
        body.text = "Posts video to social media sites or sends it via email or SMS."

        labelsStackView.addArrangedSubview(header)
        labelsStackView.addArrangedSubview(body)
        labelsStackView.layoutMargins = .init(top: 8, left: 0, bottom: 8, right: 0)
        labelsStackView.isLayoutMarginsRelativeArrangement = true
    }
        
    func setUpSaveCopyStackView() {
        saveCopyStackView.spacing = 16
        saveCopyStackView.alignment = .center
        let imageView = ExportImageView(systemName: "doc.on.doc")
        let leftSpacer = UIView()
        let rightSpacer = UIView()
        let labelsStackView = UIStackView()
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        
        saveCopyStackView.addArrangedSubview(leftSpacer)
        saveCopyStackView.addArrangedSubview(imageView)
        saveCopyStackView.addArrangedSubview(labelsStackView)
        saveCopyStackView.addArrangedSubview(rightSpacer)
        
        saveCopyStackView.setCustomSpacing(0, after: leftSpacer)
        saveCopyStackView.setCustomSpacing(0, after: labelsStackView)
        
        NSLayoutConstraint.activate ([
            leftSpacer.widthAnchor.constraint(equalToConstant: 16),
            rightSpacer.widthAnchor.constraint(equalTo: leftSpacer.widthAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        let header = HeaderExportLabel()
        header.text = "Save a copy"
        
        let body = BodyExportLabel()
        body.text = "Creates a copy with changes that you can not undo."
        
        labelsStackView.addArrangedSubview(header)
        labelsStackView.addArrangedSubview(body)
        labelsStackView.layoutMargins = .init(top: 8, left: 0, bottom: 8, right: 0)
        labelsStackView.isLayoutMarginsRelativeArrangement = true
    }
    
    func setUpSaveCopyButton() {
        saveCopyButton.translatesAutoresizingMaskIntoConstraints = false
        saveCopyButton.addTarget(self, action: #selector(self.saveVideoCopy), for: .touchUpInside)
        saveCopyStackView.addSubview(saveCopyButton)
        NSLayoutConstraint.activate ([
            saveCopyButton.trailingAnchor.constraint(equalTo: saveCopyStackView.trailingAnchor),
            saveCopyButton.leadingAnchor.constraint(equalTo: saveCopyStackView.leadingAnchor),
            saveCopyButton.topAnchor.constraint(equalTo: saveCopyStackView.topAnchor),
            saveCopyButton.bottomAnchor.constraint(equalTo: saveCopyStackView.bottomAnchor)
        ])
    }
    
    func setUpShareButton() {
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(self.openActivityView), for: .touchUpInside)
        shareStackView.addSubview(shareButton)
        NSLayoutConstraint.activate ([
            shareButton.trailingAnchor.constraint(equalTo: shareStackView.trailingAnchor),
            shareButton.leadingAnchor.constraint(equalTo: shareStackView.leadingAnchor),
            shareButton.topAnchor.constraint(equalTo: shareStackView.topAnchor),
            shareButton.bottomAnchor.constraint(equalTo: shareStackView.bottomAnchor)
        ])
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
   
    public func openLooks() {
        self.view.layoutIfNeeded()
        topLooksConstraint.constant = looksViewController.view.frame.height + tabBar.frame.height + 0.3
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    public func closeLooks() {
        self.view.layoutIfNeeded()
        topLooksConstraint.constant = -view.safeAreaInsets.bottom
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    public func openExportMenu() {
        self.view.layoutIfNeeded()
        isExportViewShown = true
        topExportPanelConstraint.constant = exportPanel.frame.height + tabBar.frame.height
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    public func closeExportMenu() {
        self.view.layoutIfNeeded()
        topExportPanelConstraint.constant = -self.view.safeAreaInsets.bottom
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    public func openTools() {
        self.view.layoutIfNeeded()
        isToolsViewShown = true
        topToolsConstraint.constant = toolsViewController.view.frame.height + tabBar.frame.height
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    public func closeTools() {
        self.view.layoutIfNeeded()
        topToolsConstraint.constant = -self.view.safeAreaInsets.bottom
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func presentAdjustmentsScreen(url: URL, tool: ToolEnum) {
        switch tool {
        case let .vignette(tool),
             let .blur(tool):
            let vc = AdjustmentsViewController(url: url, tool: tool) { [weak self] url in
                guard let self = self, let url = url else { return }
                self.videoFileAsset = AVAsset(url: url)
            }
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overCurrentContext
            present(vc, animated: true, completion: nil)
            isToolsViewShown = false
        case let .colourCorrection(tool):
            let vc = AdjustmentsViewController(url: url, tool: tool) { [weak self] url in
                guard let self = self, let url = url else { return }
                self.videoFileAsset = AVAsset(url: url)
            }
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overCurrentContext
            present(vc, animated: true, completion: nil)
            isToolsViewShown = false
        }
    }
    
    private func resetToDefaultFilter() {
        pendingFilterIndex = nil
        looksViewController.deselectFilter()
    }
    
    @objc func openActivityView() {
        self.isExportViewShown = false
        self.videoViewController.isActivityIndicatorVisible = true
        
        guard let playerItem = videoViewController.player.currentItem else { return }
        
        VideoEditor.composeVideo(
            choosenFilter: looksViewController.selectedFilter,
            asset: playerItem.asset
        ) { url in
            DispatchQueue.main.async {
                self.videoViewController.isActivityIndicatorVisible = false
                guard let fileURL = url as NSURL? else { return }
                
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                activityVC.setValue("Video", forKey: "subject")
                activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact]
                self.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    @objc func discardLooks() {
        resetToDefaultFilter()
    }
    
    @objc func saveFilter() {
        view.layoutIfNeeded()
        tabBar.isHidden = false
        topLooksConstraint.constant = 146
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        if let pendingFilterIndex = looksViewController.currentlySelectedFilterIndex {
            selectedFilterIndex = pendingFilterIndex
            looksViewController.initiallySelectedFilterIndex = pendingFilterIndex
        }
        looksViewController.currentlySelectedFilterIndex = nil
        pendingFilterIndex = nil
    }
    
    @objc func saveVideoCopy() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    self?.saveVideoToPhotos()
                }
            default:
                //TODO: properly handle this. Show error, send to settings, etc.
                print("Photos permissions not granted.")
                return
            }
        }
    }
    
    func saveVideoToPhotos() {
        isExportViewShown = false
        videoViewController.isActivityIndicatorVisible = true
        guard let playerItem = videoViewController.player.currentItem else { return }
        VideoEditor.saveEditedVideo(
            choosenFilter: looksViewController.selectedFilter,
            asset: playerItem.asset
        ) {
            DispatchQueue.main.async {
                self.videoViewController.isActivityIndicatorVisible = false
            }
        }
    }    
}

extension VideoEditorViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let selectedIndex = tabBar.items?.firstIndex(of: item) else { return }
        
        isLooksButtonSelected = selectedIndex == 0 && previouslySelectedIndex != selectedIndex
        
        isExportButtonSelected = selectedIndex == 2 && previouslySelectedIndex != selectedIndex
        
        isToolsButtonSelected = selectedIndex == 1 && previouslySelectedIndex != selectedIndex
        
        if previouslySelectedIndex == selectedIndex {
            previouslySelectedIndex = nil
        } else {
            previouslySelectedIndex = selectedIndex
        }
    }
}
