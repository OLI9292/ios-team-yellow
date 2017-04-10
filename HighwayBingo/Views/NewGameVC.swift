///
/// NewGameVC.swift
///

import Then
import UIKit

protocol InviteFriendDelegate: class {
    func invite(_ friend: FacebookUser)
}

class NewGameVC: UIViewController, UITableViewDelegate, UITableViewDataSource, InviteFriendDelegate {
    
    let inviteButton = UIButton()
    let inviteLabel = UILabel()
    let search = UITextField()
    let friendsTableView = UITableView()
    let friendsToInviteStackView = UIStackView()
    
    var facebookFriends = [FacebookUser]()
    let firebaseManager = FirebaseManager.shared
    var friendsMatchingSearch = [FacebookUser]()
    var friendsToInvite = [FacebookUser]() {
        didSet {
            addFriendToStackView()
        }
    }
    
    var views: [UIView] {
        return [friendsTableView, friendsToInviteStackView, inviteButton, inviteLabel, search]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        FacebookManager.getFriends() { self.facebookFriends = $0 }
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.title = "New Game"
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        fixTableViewInsets()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsTableView.delegate = self
        friendsTableView.dataSource = self

        views.forEach(view.addSubview)
        views.forEach { $0.freeConstraints() }
        
        _ = inviteLabel.then {
            $0.text = "Invite Friends"
            // Anchors
            $0.leftAnchor.constraint(equalTo: margin.leftAnchor).isActive = true
            $0.topAnchor.constraint(equalTo: margin.topAnchor, constant: screen.height * 0.35).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 20).isActive = true
        }
        
        _ = friendsTableView.then {
            $0.register(FacebookFriendCell.self, forCellReuseIdentifier: FacebookFriendCell.reuseID)
            $0.separatorColor = .white
            // Anchors
            $0.topAnchor.constraint(equalTo: search.bottomAnchor, constant: 20).isActive = true
            $0.leadingAnchor.constraint(equalTo: margin.leadingAnchor).isActive = true
            $0.widthAnchor.constraint(equalTo: search.widthAnchor).isActive = true
            $0.bottomAnchor.constraint(equalTo: margin.bottomAnchor).isActive = true
        }
        
        _ = friendsToInviteStackView.then {
            $0.axis = .horizontal
            $0.distribution = .equalSpacing
            $0.alignment = .center
            $0.spacing = 20
            // Anchors
            $0.leftAnchor.constraint(equalTo: margin.leftAnchor).isActive = true
            $0.topAnchor.constraint(equalTo: inviteLabel.bottomAnchor, constant: 10).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
        
        _ = search.then {
            $0.placeholder = "Search"
            $0.underline()
            // Sends alert when changed
            $0.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            // Anchors
            $0.leftAnchor.constraint(equalTo: margin.leftAnchor).isActive = true
            $0.topAnchor.constraint(equalTo: friendsToInviteStackView.bottomAnchor, constant: 10).isActive = true
            $0.widthAnchor.constraint(equalTo: margin.widthAnchor, multiplier: 0.45).isActive = true
        }
        
        _ = inviteButton.then {
            $0.setTitle("Send", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.backgroundColor = .blue
            // Create Game and send Invitations when touched
            $0.addTarget(self, action: #selector(self.createGameAndSendInvitations(_:)), for: UIControlEvents.touchUpInside)
            // Anchors
            $0.rightAnchor.constraint(equalTo: margin.rightAnchor).isActive = true
            $0.bottomAnchor.constraint(equalTo: search.bottomAnchor).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 30).isActive = true
            $0.widthAnchor.constraint(equalTo: margin.widthAnchor, multiplier: 0.45).isActive = true
        }
    }
    
    func addFriendToStackView() {
        guard let friend = friendsToInvite.last else { return }
        
        let friendImageView = UIImageView()
        let friendView = UIView()
        
        [friendImageView, friendView].forEach { $0.freeConstraints() }
        
        let _ = friendView.then {
            $0.heightAnchor.constraint(equalToConstant: 60).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 40).isActive = true
        }
        
        if let url = friend.imageUrl {
            let _ = friendImageView.then {
                $0.kfSetPlayerImage(with: url, diameter: 40)
                friendView.addSubview($0)
                // Anchors
                $0.widthAnchor.constraint(equalToConstant: 40).isActive = true
                $0.heightAnchor.constraint(equalToConstant: 40).isActive = true
                $0.centerXAnchor.constraint(equalTo: friendView.centerXAnchor).isActive = true
                $0.centerYAnchor.constraint(equalTo: friendView.centerYAnchor).isActive = true
            }
        }
        
        friendsToInviteStackView.addArrangedSubview(friendView)
    }
    
    func createGameAndSendInvitations(_ sender: UIButton!) {
        disableButton(sender)
        let boardType = BoardType.Highway
        let gameId = FirebaseManager.shared.createGame(boardType, participants: friendsToInvite)
        let from = DataStore.shared.currentUser.kindName
        FirebaseManager.shared.sendInvitations(to: friendsToInvite, from: from, for: gameId, boardType: boardType)
    }
    
    func disableButton(_ sender: UIButton) {
        sender.isEnabled = false
        sender.backgroundColor = .black
        sender.setTitle("Sent", for: .disabled)
    }
    
    // Called from FacebookFriendCell.swift
    //
    func invite(_ friend: FacebookUser) {
        friendsToInvite.append(friend)
        reloadFriendsTableView()
    }
    
    func textFieldChanged(_: UITextField) {
        reloadFriendsTableView()
    }
}


private typealias FriendsTableView = NewGameVC
extension FriendsTableView {
    
    func reloadFriendsTableView() {
        guard let searchText = search.text else { return }
        friendsMatchingSearch = facebookFriends.filter { $0.name.contains(searchText) && !friendsToInvite.contains($0) }
        friendsTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsMatchingSearch.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "facebookFriend", for: indexPath) as! FacebookFriendCell
        cell.selectionStyle = .none
        cell.delegate = self
        cell.friend = friendsMatchingSearch[indexPath.row]
        return cell
    }
    
    func fixTableViewInsets() {
        let zContentInsets = UIEdgeInsets.zero
        friendsTableView.contentInset = zContentInsets
        friendsTableView.scrollIndicatorInsets = zContentInsets
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
