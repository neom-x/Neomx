//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

typealias RoomDetailsScreenViewModelType = StateStoreViewModel<RoomDetailsScreenViewState, RoomDetailsScreenViewAction>

class RoomDetailsScreenViewModel: RoomDetailsScreenViewModelType, RoomDetailsScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private var members: [RoomMemberProxyProtocol] = [] {
        didSet {
            state.members = members.map { RoomMemberDetails(withProxy: $0) }
            if roomProxy.isDirect, roomProxy.isEncrypted, members.count == 2 {
                dmRecipient = members.first(where: { !$0.isAccountOwner })
            } else {
                dmRecipient = nil
            }
        }
    }

    private var dmRecipient: RoomMemberProxyProtocol? {
        didSet {
            if let dmRecipient {
                state.dmRecipient = RoomMemberDetails(withProxy: dmRecipient)
            } else {
                state.dmRecipient = nil
            }
        }
    }
    
    var callback: ((RoomDetailsScreenViewModelAction) -> Void)?

    init(roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: .init(roomId: roomProxy.id,
                                           canonicalAlias: roomProxy.canonicalAlias,
                                           isEncrypted: roomProxy.isEncrypted,
                                           isDirect: roomProxy.isDirect,
                                           title: roomProxy.displayName ?? roomProxy.name ?? "Unknown Room",
                                           topic: roomProxy.topic,
                                           avatarURL: roomProxy.avatarURL,
                                           permalink: roomProxy.permalink,
                                           bindings: .init()),
                   imageProvider: mediaProvider)

        roomProxy.membersPublisher.sink { [weak self] members in
            self?.members = members
        }
        .store(in: &cancellables)

        Task {
            await roomProxy.updateMembers()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDetailsScreenViewAction) {
        switch viewAction {
        case .processTapPeople:
            callback?(.requestMemberDetailsPresentation(members))
        case .processTapLeave:
            guard members.count > 1 else {
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(state: .empty)
                return
            }
            state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(state: roomProxy.isPublic ? .public : .private)
        case .confirmLeave:
            Task { await leaveRoom() }
        case .processTapIgnore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .ignore)
        case .processTapUnignore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .unignore)
        case .ignoreConfirmed:
            Task { await ignore() }
        case .unignoreConfirmed:
            Task { await unignore() }
        }
    }
    
    // MARK: - Private

    private static let leaveRoomLoadingID = "LeaveRoomLoading"

    private func leaveRoom() async {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLoading, persistent: true))
        let result = await roomProxy.leaveRoom()
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
        switch result {
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
        case .success:
            callback?(.leftRoom)
        }
    }

    private func ignore() async {
        state.isProcessingIgnoreRequest = true
        let result = await dmRecipient?.ignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.dmRecipient?.isIgnored = true
        case .failure, .none:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }

    private func unignore() async {
        state.isProcessingIgnoreRequest = true
        let result = await dmRecipient?.unignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.dmRecipient?.isIgnored = false
        case .failure, .none:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }
}