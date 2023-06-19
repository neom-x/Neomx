//
// Copyright 2023 New Vector Ltd
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

import SwiftUI

extension View {
    /// Disable the interactive dismiss while the search is on.
    /// - Note: the modifier needs to be called before the `searchable` modifier to work properly
    func disableInteractiveDismissOnSearch() -> some View {
        modifier(InteractiveDismissSearchModifier())
    }
    
    /// Dismiss search when the view is disappearing. It helps to restore correct state on pop into a NavigationStack
    /// - Note: the modifier needs to be called before the `searchable` modifier to work properly
    func dismissSearchOnDisappear() -> some View {
        modifier(DismissSearchOnDisappear())
    }
}

private struct InteractiveDismissSearchModifier: ViewModifier {
    @Environment(\.isSearching) private var isSearching
    
    func body(content: Content) -> some View {
        if isSearching {
            content.interactiveDismissDisabled()
        } else {
            content
        }
    }
}

private struct DismissSearchOnDisappear: ViewModifier {
    @Environment(\.isSearching) private var isSearching
    @Environment(\.dismissSearch) private var dismissSearch
    
    func body(content: Content) -> some View {
        content
            .onDisappear {
                if isSearching {
                    dismissSearch()
                }
            }
    }
}