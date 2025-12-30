//
//  ReelsViewController.swift
//  TheHotelMedia
//
//  Created by Auto on 26/02/25.
//

import UIKit
import AVFoundation

// MARK: - Reel Model
struct Reel {
    let id: String
    let url: URL
    let thumbnailURL: URL?
    let views: Int?
    let postData: PostData? // Full post data for details
}

// MARK: - Delegate Protocol
protocol ReelCellDelegate: AnyObject {
    func didTapLike(postID: String, isLiked: Bool)
    func didTapComment(postID: String)
    func didTapShare(postID: String)
    func didTapBookmark(postID: String, isSaved: Bool)
    func didTapViewComments(postID: String)
    func didTapProfile(postID: String, userID: String)
}

// MARK: - Video Cell
final class ReelCollectionViewCell: UICollectionViewCell {
    static let reuseId = "ReelCollectionViewCell"
    
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?
    private var playerItem: AVPlayerItem?
    
    private let thumbnailImageView = UIImageView()
    private let viewsContainer = UIStackView()
    private let viewsLabel = UILabel()
    private let eyeImageView = UIImageView()
    
    // Mute/unmute feedback icon
    private let muteFeedbackImageView = UIImageView()
    
    // Post details UI
    private let rightActionsStack = UIStackView() // Like, comment, share, bookmark buttons
    private let bottomInfoView = UIView()
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let locationTimeLabel = UILabel()
    private let captionLabel = UILabel()
    private let viewCommentsButton = UIButton(type: .system)
    private let timeLabel = UILabel()
    
    // Action buttons
    private let likeButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let bookmarkButton = UIButton(type: .system)
    
    // Count labels
    private let likesLabel = UILabel()
    private let commentsLabel = UILabel()
    private let sharesLabel = UILabel()
    
    // Current post data
    private var currentPostID: String?
    private var currentPost: PostData?
    weak var delegate: ReelCellDelegate?
    
    var isMuted: Bool = false {
        didSet {
            player?.isMuted = isMuted
        }
    }
    
    private var isManuallyPaused: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupViews()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupViews() {
        // Thumbnail
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Mute/unmute feedback icon
        muteFeedbackImageView.contentMode = .scaleAspectFit
        muteFeedbackImageView.alpha = 0.0
        muteFeedbackImageView.tintColor = .white
        contentView.addSubview(muteFeedbackImageView)
        muteFeedbackImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Views container
        viewsContainer.axis = .horizontal
        viewsContainer.spacing = 4
        viewsContainer.alignment = .center
        viewsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        viewsContainer.layer.cornerRadius = 10
        viewsContainer.clipsToBounds = true
        viewsContainer.isLayoutMarginsRelativeArrangement = true
        viewsContainer.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        
        // Eye icon
        eyeImageView.image = UIImage(named: "eye2")
        eyeImageView.contentMode = .scaleAspectFit
        eyeImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            eyeImageView.widthAnchor.constraint(equalToConstant: 12),
            eyeImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // Views label
        viewsLabel.textColor = .white
        viewsLabel.font = UIFont.systemFont(ofSize: 9)
        viewsLabel.numberOfLines = 1
        
        viewsContainer.addArrangedSubview(eyeImageView)
        viewsContainer.addArrangedSubview(viewsLabel)
        
        contentView.addSubview(viewsContainer)
        viewsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Right side action buttons
        setupRightActions()
        
        // Bottom info view
        setupBottomInfo()
        
        // Add gesture recognizers for tap (mute/unmute) and long press (pause/play)
        setupGestures()
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            viewsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            viewsContainer.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            rightActionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rightActionsStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            bottomInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomInfoView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            
            muteFeedbackImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            muteFeedbackImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            muteFeedbackImageView.widthAnchor.constraint(equalToConstant: 80),
            muteFeedbackImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupRightActions() {
        rightActionsStack.axis = .vertical
        rightActionsStack.spacing = 20
        rightActionsStack.alignment = .center
        contentView.addSubview(rightActionsStack)
        rightActionsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Like button
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .white
        likeButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        rightActionsStack.addArrangedSubview(likeButton)
        
        likesLabel.textColor = .white
        likesLabel.font = .systemFont(ofSize: 12)
        likesLabel.textAlignment = .center
        rightActionsStack.addArrangedSubview(likesLabel)
        
        // Comment button
        commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        commentButton.tintColor = .white
        commentButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        commentButton.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        rightActionsStack.addArrangedSubview(commentButton)
        
        commentsLabel.textColor = .white
        commentsLabel.font = .systemFont(ofSize: 12)
        commentsLabel.textAlignment = .center
        rightActionsStack.addArrangedSubview(commentsLabel)
        
        // Share button
        shareButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        shareButton.tintColor = .white
        shareButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        rightActionsStack.addArrangedSubview(shareButton)
        
        sharesLabel.textColor = .white
        sharesLabel.font = .systemFont(ofSize: 12)
        sharesLabel.textAlignment = .center
        rightActionsStack.addArrangedSubview(sharesLabel)
        
        // Bookmark button
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = .white
        bookmarkButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        rightActionsStack.addArrangedSubview(bookmarkButton)
    }
    
    @objc private func likeButtonTapped() {
        guard let postID = currentPostID else { return }
        let isLiked = currentPost?.likedByMe ?? false
        delegate?.didTapLike(postID: postID, isLiked: isLiked)
    }
    
    @objc private func commentButtonTapped() {
        guard let postID = currentPostID else { return }
        delegate?.didTapComment(postID: postID)
    }
    
    @objc private func shareButtonTapped() {
        guard let postID = currentPostID else { return }
        delegate?.didTapShare(postID: postID)
    }
    
    @objc private func bookmarkButtonTapped() {
        guard let postID = currentPostID else { return }
        let isSaved = currentPost?.savedByMe ?? false
        delegate?.didTapBookmark(postID: postID, isSaved: isSaved)
    }
    
    @objc private func viewCommentsButtonTapped() {
        guard let postID = currentPostID else { return }
        delegate?.didTapViewComments(postID: postID)
    }
    
    @objc private func profileTapped() {
        guard
            let postID = currentPostID,
            let userID = currentPost?.postedBy?.id,
            !userID.isEmpty
        else { return }
        delegate?.didTapProfile(postID: postID, userID: userID)
    }
    
    private func setupGestures() {
        // Tap gesture for mute/unmute
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        contentView.addGestureRecognizer(tapGesture)
        
        // Long press gesture for pause/play
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.1
        longPressGesture.delegate = self
        contentView.addGestureRecognizer(longPressGesture)
        
        // Make tap gesture require long press to fail so they don't conflict
        tapGesture.require(toFail: longPressGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        // Toggle mute/unmute
        isMuted.toggle()
        
        // Show feedback icon
        showMuteFeedbackIcon(muted: isMuted)
        
        // Update audio session based on mute state
        do {
            if isMuted {
                try AVAudioSession.sharedInstance().setCategory(.soloAmbient)
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            }
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    private func showMuteFeedbackIcon(muted: Bool) {
        // Set the appropriate icon
        let iconName = muted ? "Mute" : "Unmute"
        muteFeedbackImageView.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
        
        // Animate in
        UIView.animate(withDuration: 0.2, animations: {
            self.muteFeedbackImageView.alpha = 1.0
            self.muteFeedbackImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            // Animate out
            UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
                self.muteFeedbackImageView.alpha = 0.0
                self.muteFeedbackImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: { _ in
                self.muteFeedbackImageView.transform = .identity
            })
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // Pause video when long press starts
            if player?.rate != 0 {
                player?.pause()
                isManuallyPaused = true
            }
        case .ended, .cancelled:
            // Resume video when long press ends
            if isManuallyPaused {
                player?.play()
                isManuallyPaused = false
            }
        default:
            break
        }
    }
    
    private func setupBottomInfo() {
        bottomInfoView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        contentView.addSubview(bottomInfoView)
        bottomInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemGreen.cgColor
        profileImageView.isUserInteractionEnabled = true
        bottomInfoView.addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(profileTapGesture)
        
        // Username
        usernameLabel.textColor = .white
        usernameLabel.font = .boldSystemFont(ofSize: 14)
        usernameLabel.isUserInteractionEnabled = true
        bottomInfoView.addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        usernameLabel.addGestureRecognizer(usernameTapGesture)
        
        // Location and time
        locationTimeLabel.textColor = .white.withAlphaComponent(0.8)
        locationTimeLabel.font = .systemFont(ofSize: 12)
        bottomInfoView.addSubview(locationTimeLabel)
        locationTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Caption
        captionLabel.textColor = .white
        captionLabel.font = .systemFont(ofSize: 14)
        captionLabel.numberOfLines = 3
        bottomInfoView.addSubview(captionLabel)
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // View comments button
        viewCommentsButton.setTitleColor(.white.withAlphaComponent(0.8), for: .normal)
        viewCommentsButton.titleLabel?.font = .systemFont(ofSize: 12)
        viewCommentsButton.addTarget(self, action: #selector(viewCommentsButtonTapped), for: .touchUpInside)
        bottomInfoView.addSubview(viewCommentsButton)
        viewCommentsButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Time label
        timeLabel.textColor = .white.withAlphaComponent(0.6)
        timeLabel.font = .systemFont(ofSize: 11)
        bottomInfoView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: bottomInfoView.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: bottomInfoView.topAnchor, constant: 12),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            usernameLabel.topAnchor.constraint(equalTo: bottomInfoView.topAnchor, constant: 12),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: bottomInfoView.trailingAnchor, constant: -16),
            
            locationTimeLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            locationTimeLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            
            captionLabel.leadingAnchor.constraint(equalTo: bottomInfoView.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: bottomInfoView.trailingAnchor, constant: -16),
            captionLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            
            viewCommentsButton.leadingAnchor.constraint(equalTo: bottomInfoView.leadingAnchor, constant: 16),
            viewCommentsButton.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 4),
            
            timeLabel.leadingAnchor.constraint(equalTo: bottomInfoView.leadingAnchor, constant: 16),
            timeLabel.topAnchor.constraint(equalTo: viewCommentsButton.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: bottomInfoView.bottomAnchor, constant: -12)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stop()
        playerLayer?.removeFromSuperlayer()
        player = nil
        looper = nil
        playerItem = nil
        thumbnailImageView.image = nil
        thumbnailImageView.isHidden = false // Reset thumbnail visibility
        viewsLabel.text = nil
        viewsContainer.isHidden = true
        
        // Clear post details
        profileImageView.image = nil
        usernameLabel.text = nil
        locationTimeLabel.text = nil
        captionLabel.text = nil
        viewCommentsButton.setTitle(nil, for: .normal)
        timeLabel.text = nil
        likesLabel.text = nil
        commentsLabel.text = nil
        sharesLabel.text = nil
        
        // Reset gesture states
        isManuallyPaused = false
        
        // Reset feedback icon
        muteFeedbackImageView.alpha = 0.0
        muteFeedbackImageView.transform = .identity
    }
    
    func configure(with reel: Reel, shouldAutoplay: Bool = false, isMuted: Bool = false, delegate: ReelCellDelegate?) {
        self.isMuted = isMuted
        self.delegate = delegate
        
        // Store current post data
        currentPost = reel.postData
        currentPostID = reel.postData?.id
        
        // Load thumbnail
        if let thumbnailURL = reel.thumbnailURL {
            loadThumbnail(from: thumbnailURL)
        }
        
        // Set views
        if let views = reel.views {
            viewsLabel.text = formatViews(views)
            viewsContainer.isHidden = false
        } else {
            viewsContainer.isHidden = true
        }
        
        // Configure post details
        if let postData = reel.postData {
            configurePostDetails(postData)
        }
        
        // Reset thumbnail visibility
        thumbnailImageView.isHidden = false
        
        let asset = AVAsset(url: reel.url)
        let item = AVPlayerItem(asset: asset)
        self.playerItem = item
        
        // AVQueuePlayer + AVPlayerLooper for smooth looping
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = isMuted
        self.player = queuePlayer
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        
        let pl = AVPlayerLayer(player: queuePlayer)
        pl.videoGravity = .resizeAspectFill
        pl.frame = contentView.bounds
        contentView.layer.insertSublayer(pl, at: 1) // Above thumbnail
        self.playerLayer = pl
        
        pl.needsDisplayOnBoundsChange = true
        
        // Observe when ready to play
        item.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        
        // Check if already ready
        if item.status == .readyToPlay {
            DispatchQueue.main.async { [weak self] in
                self?.thumbnailImageView.isHidden = true
            }
        }
        
        if shouldAutoplay {
            play()
        }
    }
    
    func updatePostData(_ post: PostData) {
        currentPost = post
        configurePostDetails(post)
    }
    
    private func configurePostDetails(_ post: PostData) {
        // Profile image - handle both individual and business accounts
        var profilePicURL: String?
        if post.postedBy?.accountType == "business" {
            profilePicURL = post.postedBy?.businessProfileRef?.profilePic?.small
        } else {
            profilePicURL = post.postedBy?.profilePic?.small
        }
        
        if let profilePicURL = profilePicURL,
           let url = URL(string: profilePicURL) {
            loadImage(from: url, into: profileImageView)
        }
        
        // Username - handle both individual and business accounts
        if post.postedBy?.accountType == "business" {
            usernameLabel.text = post.postedBy?.businessProfileRef?.name ?? post.postedBy?.name ?? post.postedBy?.username ?? ""
        } else {
            usernameLabel.text = post.postedBy?.name ?? post.postedBy?.username ?? ""
        }
        
        // Location and time
        var locationTimeText = ""
        if let location = post.location?.placeName {
            locationTimeText = location
        }
        if let createdAt = post.createdAt {
            let timeAgo = DateManager.getPostedAgoTime(date: createdAt, language: .english)
            if !locationTimeText.isEmpty {
                locationTimeText += " • \(timeAgo)"
            } else {
                locationTimeText = timeAgo
            }
        }
        locationTimeLabel.text = locationTimeText
        
        // Caption
        captionLabel.text = post.content ?? ""
        
        // View comments button
        let commentsCount = post.comments ?? 0
        if commentsCount > 0 {
            viewCommentsButton.setTitle("View all \(commentsCount) comments", for: .normal)
        } else {
            viewCommentsButton.setTitle(nil, for: .normal)
        }
        
        // Time label
        if let createdAt = post.createdAt {
            timeLabel.text = DateManager.getPostedAgoTime(date: createdAt, language: .english).uppercased()
        }
        
        // Likes count
        let likesCount = post.likes ?? 0
        likesLabel.text = formatNumber(likesCount)
        likeButton.setImage(UIImage(systemName: post.likedByMe == true ? "heart.fill" : "heart"), for: .normal)
        likeButton.tintColor = post.likedByMe == true ? .systemRed : .white
        
        // Comments count
        commentsLabel.text = formatNumber(commentsCount)
        
        // Shares count
        let sharesCount = post.shared ?? 0
        sharesLabel.text = formatNumber(sharesCount)
        
        // Bookmark state
        bookmarkButton.setImage(UIImage(systemName: post.savedByMe == true ? "bookmark.fill" : "bookmark"), for: .normal)
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000_000 {
            return String(format: "%.1fB", Double(number) / 1_000_000_000)
        } else if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
    
    private func loadThumbnail(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.thumbnailImageView.image = image
            }
        }.resume()
    }
    
    private func formatViews(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.1fB", Double(count) / 1_000_000_000)
        } else if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "status", let item = object as? AVPlayerItem else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                self.thumbnailImageView.isHidden = true
            }
            // On error or unknown status, keep thumbnail visible
        }
    }
    
    func play() {
        guard !isManuallyPaused else { return }
        player?.play()
        player?.isMuted = isMuted
    }
    
    func pause() {
        player?.pause()
        isManuallyPaused = false // Reset manual pause flag when externally paused
    }
    
    func stop() {
        pause()
        isManuallyPaused = false
        if let item = playerItem {
            item.removeObserver(self, forKeyPath: "status", context: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }
}

// MARK: - ViewController
final class ReelsViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var reels: [Reel] = []
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private var initialReelID: String?
    private var isMuted: Bool = false
    
    var onLoadMore: (() -> Void)?
    var onVideoChanged: ((Int) -> Void)?
    var onLike: ((String, Bool) -> Void)?
    var onComment: ((String) -> Void)?
    var onShare: ((String) -> Void)?
    var onBookmark: ((String, Bool) -> Void)?
    var onProfileTapped: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCollectionView()
        configureDataSource()
        
        // Apply snapshot if reels were set before viewDidLoad
        if !reels.isEmpty {
            applySnapshot()
            
            // Scroll to initial reel if needed
            if let initialID = initialReelID,
               let index = reels.firstIndex(where: { $0.id == initialID }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let indexPath = IndexPath(item: index, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                    self.playVisibleCellIfNeeded()
                }
            } else if !reels.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.playVisibleCellIfNeeded()
                }
            }
        }
    }
    
    private var hasScrolledToInitial: Bool = false
    
    func setReels(_ newReels: [Reel], initialID: String? = nil) {
        let oldReels = self.reels
        let reelsChanged = oldReels.map { $0.id } != newReels.map { $0.id }
        self.reels = newReels
        
        // Only apply snapshot if dataSource is ready
        guard dataSource != nil else {
            // Will be applied in viewDidLoad
            if let initialID = initialID {
                self.initialReelID = initialID
            }
            return
        }
        
        // Get current visible index before any updates
        let currentVisibleIndexPath = collectionView.indexPathsForVisibleItems.first
        
        // Update visible cells if post data changed (but reels structure is the same)
        if !reelsChanged, let visibleIndexPath = currentVisibleIndexPath,
           visibleIndexPath.item < newReels.count,
           let cell = collectionView.cellForItem(at: visibleIndexPath) as? ReelCollectionViewCell {
            let newReel = newReels[visibleIndexPath.item]
            if let oldReel = oldReels.first(where: { $0.id == newReel.id }),
               let oldPostID = oldReel.postData?.id,
               let newPostID = newReel.postData?.id,
               oldPostID == newPostID,
               let newPostData = newReel.postData {
                // Post data changed, just update the cell without applying snapshot
                cell.updatePostData(newPostData)
                return // Don't apply snapshot or scroll if only post data changed
            }
        }
        
        // Only apply snapshot if reels structure changed
        if reelsChanged {
            applySnapshot()
        }
        
        // Scroll to initial reel only if we haven't scrolled to it yet and initialID is provided
        if let initialID = initialID, !hasScrolledToInitial,
           let index = reels.firstIndex(where: { $0.id == initialID }) {
            hasScrolledToInitial = true
            self.initialReelID = initialID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard self.collectionView != nil else { return }
                let indexPath = IndexPath(item: index, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                self.playVisibleCellIfNeeded()
            }
        } else if reelsChanged && !reels.isEmpty {
            // If reels changed but no initial ID, just play visible cell
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playVisibleCellIfNeeded()
            }
        }
    }
    
    func setMuted(_ muted: Bool) {
        self.isMuted = muted
        // Update all visible cells
        guard let collectionView = collectionView else { return }
        for cell in collectionView.visibleCells {
            if let reelCell = cell as? ReelCollectionViewCell {
                reelCell.isMuted = muted
            }
        }
    }
    
    private func configureCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ReelCollectionViewCell.self, forCellWithReuseIdentifier: ReelCollectionViewCell.reuseId)
        collectionView.isPagingEnabled = true // Important -> one video at a time
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure item size equals view bounds so each cell covers full screen
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.itemSize = collectionView.bounds.size
        }
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, String>(collectionView: collectionView) { [weak self] (cv, indexPath, id) -> UICollectionViewCell? in
            guard let cell = cv.dequeueReusableCell(withReuseIdentifier: ReelCollectionViewCell.reuseId, for: indexPath) as? ReelCollectionViewCell,
                  let reel = self?.reels.first(where: { $0.id == id }) else {
                return nil
            }
            
            // Autoplay only for the initially visible cell
            let initiallyVisible = (indexPath.row == 0 && cv.indexPathsForVisibleItems.contains(indexPath))
            cell.configure(with: reel, shouldAutoplay: initiallyVisible, isMuted: self?.isMuted ?? false, delegate: self)
            return cell
        }
    }
    
    private func applySnapshot(animatingDifferences: Bool = false) {
        guard let dataSource = dataSource else { return }
        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(reels.map { $0.id }, toSection: 0)
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }
    
    // Plays the visible cell and pauses others
    private func playVisibleCellIfNeeded() {
        guard let collectionView = collectionView else { return }
        
        for cell in collectionView.visibleCells {
            if let reelCell = cell as? ReelCollectionViewCell {
                reelCell.play()
            }
        }
        
        // Pause cells not visible
        for case let cell as ReelCollectionViewCell in collectionView.subviews.compactMap({ $0 as? ReelCollectionViewCell }) {
            if !collectionView.visibleCells.contains(cell) {
                cell.pause()
            }
        }
        
        // Notify about current video index
        if let visibleIndexPath = collectionView.indexPathsForVisibleItems.first {
            onVideoChanged?(visibleIndexPath.item)
            
            // Load more if at the end
            if visibleIndexPath.item == reels.count - 1 {
                onLoadMore?()
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ReelsViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Called when paging finished; play the visible cell and pause others
        playVisibleCellIfNeeded()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            playVisibleCellIfNeeded()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let reelCell = cell as? ReelCollectionViewCell {
            reelCell.play()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let reelCell = cell as? ReelCollectionViewCell {
            reelCell.pause()
        }
    }
}

// MARK: - ReelCellDelegate
extension ReelsViewController: ReelCellDelegate {
    func didTapLike(postID: String, isLiked: Bool) {
        onLike?(postID, isLiked)
    }
    
    func didTapComment(postID: String) {
        onComment?(postID)
    }
    
    func didTapShare(postID: String) {
        onShare?(postID)
    }
    
    func didTapBookmark(postID: String, isSaved: Bool) {
        onBookmark?(postID, isSaved)
    }
    
    func didTapViewComments(postID: String) {
        onComment?(postID)
    }
    
    func didTapProfile(postID: String, userID: String) {
        onProfileTapped?(userID)
    }
    
    func updatePostInReel(postID: String, updatedPost: PostData) {
        // Update the reel's post data
        if let index = reels.firstIndex(where: { $0.postData?.id == postID }) {
            var updatedReel = reels[index]
            var updatedPostData = updatedPost
            // Keep the video URL from the original reel
            reels[index] = Reel(
                id: updatedReel.id,
                url: updatedReel.url,
                thumbnailURL: updatedReel.thumbnailURL,
                views: updatedReel.views,
                postData: updatedPostData
            )
            
            // Update the visible cell if it's showing this post
            if let visibleIndexPath = collectionView.indexPathsForVisibleItems.first,
               visibleIndexPath.item == index,
               let cell = collectionView.cellForItem(at: visibleIndexPath) as? ReelCollectionViewCell {
                cell.updatePostData(updatedPostData)
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ReelCollectionViewCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't handle gestures if touching buttons or interactive elements
        let touchPoint = touch.location(in: contentView)
        
        // Check if touch is in the right actions stack area (buttons)
        let rightActionsFrame = rightActionsStack.frame
        if rightActionsFrame.contains(touchPoint) {
            return false
        }
        
        // Check if touch is in the bottom info view area (profile, username, etc.)
        let bottomInfoFrame = bottomInfoView.frame
        if bottomInfoFrame.contains(touchPoint) {
            // Allow tap on profile image and username, but not on the whole bottom area
            let profileFrame = profileImageView.frame
            let usernameFrame = usernameLabel.frame
            let viewCommentsFrame = viewCommentsButton.frame
            
            if profileFrame.contains(touchPoint) || usernameFrame.contains(touchPoint) {
                return false // Let the profile tap gesture handle it
            }
            
            // Allow gestures in bottom area but not on interactive elements
            if viewCommentsFrame.contains(touchPoint) {
                return false
            }
        }
        
        // Check if touch is in the views container area
        let viewsFrame = viewsContainer.frame
        if viewsFrame.contains(touchPoint) {
            return false
        }
        
        return true
    }
}

