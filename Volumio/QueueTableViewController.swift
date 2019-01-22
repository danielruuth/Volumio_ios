//
//  QueueTableViewController.swift
//  Volumio
//
//  Created by Federico Sintucci on 03/10/16.
//  Copyright © 2016 Federico Sintucci. All rights reserved.
//

import UIKit

/**
 Controller for queue table view. Inherits automatic connection handling from `VolumioTableViewController`.
 */
class QueueTableViewController: VolumioTableViewController, QueueActionsDelegate {

    var headerView: QueueActions?

    var tracksList: [TrackObject] = []

    var queuePointer: Int = 0

    var currentTrack: TrackObject?

    // MARK: - View Callbacks

    override func viewDidLoad() {
        super.viewDidLoad()

        localize()

        tableView.tableFooterView = UIView(frame: CGRect.zero)

        self.refreshControl?.addTarget(self,
            action: #selector(handleRefresh),
            for: UIControl.Event.valueChanged
        )

        let frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 56.0)
        headerView = QueueActions(frame: frame)
        headerView?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerObserver(forName: .currentQueue) { (notification) in
            self.clearAllNotice()

            guard let tracks = notification.object as? [TrackObject]
                else { return }
            self.update(tracks: tracks)
        }

        registerObserver(forName: .currentTrack) { (notification) in
            guard let track = notification.object as? TrackObject
                else { return }
            self.getCurrent(track)
        }
        registerObserver(forName: .removedfromQueue) { _ in
            self.noticeRemovedItem(delayed: 0.5)

            VolumioIOManager.shared.getQueue()
        }

        pleaseWait()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        clearAllNotice()
    }

    // MARK: - View Update

    func update(tracks: [TrackObject]? = nil) {
        if let tracks = tracks {
            tracksList = tracks
        }
        tableView.reloadData()
    }

    func noticeRemovedItem(delayed time: Double? = nil) {
        notice(localizedRemovedNotice, delayed: time)
    }

    // MARK: -

    func getCurrent(_ track: TrackObject) {
        if let position = track.position {
            currentTrack = track

            queuePointer = position

            headerView?.update(for: track)
        }
        VolumioIOManager.shared.getQueue()
    }

    // MARK: - Volumio Events

    override func volumioWillConnect() {
        pleaseWait()

        super.volumioWillConnect()
    }

    override func volumioDidConnect() {
        super.volumioDidConnect()

        VolumioIOManager.shared.getQueue()
    }

    override func volumioDidDisconnect() {
        clearAllNotice()

        super.volumioDidDisconnect()

        update(tracks: [])
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return tracksList.count
    }

    override func tableView(_ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let anyCell = tableView.dequeueReusableCell(withIdentifier: "track", for: indexPath)
        guard let cell = anyCell as? QueueTableViewCell
            else { fatalError() }

        let track = tracksList[indexPath.row]

        cell.trackTitle.text = track.localizedTitle
        cell.trackArtist.text = track.localizedArtistAndAlbum
        cell.trackImage.setAlbumArt(for: track)

        cell.trackPosition.text = "\(indexPath.row + 1)"

        if indexPath.row == queuePointer {
            cell.trackPlaying.isHidden = false
            cell.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        } else {
            cell.trackPlaying.isHidden = true
            cell.backgroundColor = UIColor.white
        }

        return cell
    }

    override func tableView(_ tableView: UITableView,
        canEditRowAt indexPath: IndexPath
    ) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            VolumioIOManager.shared.removeFromQueue(position: indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VolumioIOManager.shared.playTrack(position: indexPath.row)
        VolumioIOManager.shared.getState()
    }

    override func tableView(_ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        VolumioIOManager.shared.sortQueue(
            from: sourceIndexPath.row,
            to:destinationIndexPath.row
        )
    }

    override func tableView(_ tableView: UITableView,
        canMoveRowAt indexPath: IndexPath
    ) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 54.0
    }

    @IBAction func editRowOrder(_ sender: UIBarButtonItem) {
        self.isEditing = !self.isEditing
    }

    override func tableView(_ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        return headerView
    }

    override func tableView(_ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 56.0
    }

	@objc func handleRefresh(refreshControl: UIRefreshControl) {
        VolumioIOManager.shared.getQueue()
        refreshControl.endRefreshing()
    }

    // MARK: - QueueActionsDelegate

    func didRepeat() {
        if let track = currentTrack, let repetition = track.repetition {
            switch repetition {
            case 0: VolumioIOManager.shared.toggleRepeat(value: 1)
            default: VolumioIOManager.shared.toggleRepeat(value: 0)
            }
        } else {
            VolumioIOManager.shared.toggleRepeat(value: 1)
        }
    }

    func didShuffle() {
        if let track = currentTrack, let shuffle = track.shuffle {
            switch shuffle {
            case 0: VolumioIOManager.shared.toggleRandom(value: 1)
            default: VolumioIOManager.shared.toggleRandom(value: 0)
            }
        } else {
            VolumioIOManager.shared.toggleRandom(value: 1)
        }
    }

    func didConsume() {
        if let track = currentTrack, let consume = track.consume {
            switch consume {
            case 0: VolumioIOManager.shared.toggleConsume(value: 1)
            default: VolumioIOManager.shared.toggleConsume(value: 0)
            }
        } else {
            VolumioIOManager.shared.toggleConsume(value: 1)
        }
    }

    func didClear() {
        VolumioIOManager.shared.clearQueue()
    }

}

// MARK: - Localization

extension QueueTableViewController {

    fileprivate func localize() {
        navigationItem.title = NSLocalizedString("QUEUE",
            comment: "queue view title"
        )
    }

    fileprivate var localizedRemovedNotice: String {
        return NSLocalizedString("QUEUE_REMOVED_ITEM",
            comment: "removed item from queue"
        )
    }

}
