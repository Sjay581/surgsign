import Foundation
import MultipeerConnectivity
import Observation
import UIKit
import os

// MARK: - Multipeer Service

/// Manages device-to-device data transfer using the Multipeer Connectivity
/// framework for proximity-based shift handoff.
///
/// Usage:
/// - **Sender** calls `startAdvertising(data:)` to advertise availability and
///   wait for an incoming connection.
/// - **Receiver** calls `startBrowsing()` to discover nearby senders, then
///   `connect(to:)` to establish a session.
/// - Once connected, data flows automatically from sender to receiver.
///
/// Observed via the `@Observable` macro (requires iOS 17+).
@Observable
final class MultipeerService: NSObject, @unchecked Sendable {

    // MARK: - Constants

    /// Bonjour service type (max 15 ASCII characters, lowercase + hyphens).
    let serviceType = "surgsign-ho"

    // MARK: - Transfer State

    enum TransferState: Equatable {
        case idle
        case browsing
        case advertising
        case connecting(peerName: String)
        case connected(peerName: String)
        case receiving
        case completed(data: Data)
        case failed(message: String)

        static func == (lhs: TransferState, rhs: TransferState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.browsing, .browsing),
                 (.advertising, .advertising),
                 (.receiving, .receiving):
                return true
            case let (.connecting(a), .connecting(b)):
                return a == b
            case let (.connected(a), .connected(b)):
                return a == b
            case let (.completed(a), .completed(b)):
                return a == b
            case let (.failed(a), .failed(b)):
                return a == b
            default:
                return false
            }
        }
    }

    // MARK: - Published State

    private(set) var state: TransferState = .idle
    private(set) var discoveredPeers: [MCPeerID] = []

    // MARK: - Private Properties

    private let peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// Data the sender wants to transmit once a session is established.
    private var pendingData: Data?

    private let logger = Logger(subsystem: "com.surgsign", category: "MultipeerService")

    // MARK: - Init

    override init() {
        #if targetEnvironment(simulator)
        let deviceName = "Simulator"
        #else
        let deviceName = UIDevice.current.name
        #endif
        self.peerID = MCPeerID(displayName: deviceName)
        super.init()
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    /// Begin advertising this device as a sender with `data` to transmit.
    func startAdvertising(data: Data) {
        stop()
        pendingData = data

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let adv = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        self.advertiser = adv

        state = .advertising
        logger.info("Started advertising as \(self.peerID.displayName)")
    }

    /// Begin browsing for nearby advertisers (senders).
    func startBrowsing() {
        stop()

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let br = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        br.delegate = self
        br.startBrowsingForPeers()
        self.browser = br

        discoveredPeers = []
        state = .browsing
        logger.info("Started browsing for peers")
    }

    /// Invite a discovered peer to join the session.
    func connect(to peer: MCPeerID) {
        guard let session, let browser else {
            logger.warning("Cannot connect — session or browser is nil.")
            return
        }
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        state = .connecting(peerName: peer.displayName)
        logger.info("Invited peer: \(peer.displayName)")
    }

    /// Send data to all connected peers.
    func send(_ data: Data) {
        guard let session, !session.connectedPeers.isEmpty else {
            logger.warning("Cannot send — no connected peers.")
            return
        }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            logger.info("Sent \(data.count) bytes to \(session.connectedPeers.count) peer(s)")
        } catch {
            logger.error("Send failed: \(error.localizedDescription)")
            state = .failed(message: error.localizedDescription)
        }
    }

    /// Stop all advertising, browsing, and disconnect the session.
    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        browser?.stopBrowsingForPeers()
        browser = nil

        session?.disconnect()
        session = nil

        pendingData = nil
        discoveredPeers = []
        state = .idle
        logger.info("Stopped all multipeer services")
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID,
                 didChange newState: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch newState {
            case .notConnected:
                self.logger.info("Peer disconnected: \(peerID.displayName)")
                // Only transition to idle if we're not already in completed or failed state.
                switch self.state {
                case .completed, .failed:
                    break
                default:
                    self.state = .idle
                }
            case .connecting:
                self.logger.info("Connecting to: \(peerID.displayName)")
                self.state = .connecting(peerName: peerID.displayName)
            case .connected:
                self.logger.info("Connected to: \(peerID.displayName)")
                self.state = .connected(peerName: peerID.displayName)
                // If we're the advertiser (sender), transmit the pending data.
                if let data = self.pendingData {
                    self.send(data)
                    self.pendingData = nil
                }
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.logger.info("Received \(data.count) bytes from \(peerID.displayName)")
            self.state = .completed(data: data)
        }
    }

    // Unused but required delegate methods.

    func session(_ session: MCSession, didReceive stream: InputStream,
                 withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?,
                 withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logger.info("Received invitation from: \(peerID.displayName)")
        // Auto-accept. In production you might present a confirmation dialog.
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        logger.error("Advertising failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.state = .failed(message: error.localizedDescription)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        logger.info("Discovered peer: \(peerID.displayName)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !self.discoveredPeers.contains(where: { $0.displayName == peerID.displayName }) {
                self.discoveredPeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        logger.info("Lost peer: \(peerID.displayName)")
        DispatchQueue.main.async { [weak self] in
            self?.discoveredPeers.removeAll { $0.displayName == peerID.displayName }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        logger.error("Browsing failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.state = .failed(message: error.localizedDescription)
        }
    }
}
