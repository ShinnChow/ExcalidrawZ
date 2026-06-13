//
//  FileCheckpointListView.swift
//  ExcalidrawZ
//
//  Created by Dove Zachary on 2023/8/6.
//

import SwiftUI
import ChocofordUI
import ChocofordEssentials

/// Inspector content that lists checkpoints for the currently active file.
/// Picks the right `FileCheckpointListView` overload based on the file type.
struct FileHistoryInspectorContent: View {
    @Environment(\.containerHorizontalSizeClass) private var containerHorizontalSizeClass

    @EnvironmentObject var fileState: FileState
    @EnvironmentObject var layoutState: LayoutState
    @EnvironmentObject var appPreference: AppPreference

    @ViewBuilder
    private func contentView(presentation: FileCheckpointListPresentation) -> some View {
        switch fileState.currentActiveFile {
            case .file(let file):
                FileCheckpointListView(file: file, presentation: presentation)
            case .localFile(let url):
                FileCheckpointListView(localFile: url, presentation: presentation)
            case .temporaryFile(let url):
                FileCheckpointListView(localFile: url, presentation: presentation)
            case .collaborationFile(let collaborationFile):
                FileCheckpointListView(file: collaborationFile, presentation: presentation)
            default:
                EmptyView()
        }
    }

    private var isCompactIOS: Bool {
#if os(iOS)
        containerHorizontalSizeClass == .compact
#else
        false
#endif
    }

    private var presentation: FileCheckpointListPresentation {
        isCompactIOS ? .compactNavigation : .inspectorList
    }

    private var usesInspectorToolbarChrome: Bool {
#if os(iOS)
        !isCompactIOS
#else
        appPreference.inspectorLayout == .sidebar
#endif
    }

    var body: some View {
        if usesInspectorToolbarChrome {
            contentView(presentation: presentation)
                .toolbar {
                    if layoutState.isInspectorPresented {
                        InspectorHeaderToolbar(
                            title: String(localizable: .checkpoints),
                            isInspectorPresented: layoutState.isInspectorPresented
                        )
                    }
                }
        } else {
            contentView(presentation: presentation)
        }
    }
}

enum FileCheckpointListPresentation {
    case inspectorList
    case compactNavigation
}

struct FileCheckpointListView<Checkpoint: FileCheckpointRepresentable>: View {
    @Environment(\.dismiss) private var dismiss

    @FetchRequest
    var fileCheckpoints: FetchedResults<Checkpoint>

    private let presentation: FileCheckpointListPresentation

    init(
        file: File,
        presentation: FileCheckpointListPresentation = .inspectorList
    ) where Checkpoint == FileCheckpoint {
        self.presentation = presentation
        self._fileCheckpoints = FetchRequest(
            sortDescriptors: [SortDescriptor(\.updatedAt, order: .reverse)],
            predicate: NSPredicate(format: "file == %@", file)
        )
    }

    init(
        file: CollaborationFile,
        presentation: FileCheckpointListPresentation = .inspectorList
    ) where Checkpoint == FileCheckpoint {
        self.presentation = presentation
        self._fileCheckpoints = FetchRequest(
            sortDescriptors: [SortDescriptor(\.updatedAt, order: .reverse)],
            predicate: NSPredicate(format: "collaborationFile == %@", file)
        )
    }

    init(
        localFile: URL,
        presentation: FileCheckpointListPresentation = .inspectorList
    ) where Checkpoint == LocalFileCheckpoint {
        self.presentation = presentation
        self._fileCheckpoints = FetchRequest(
            sortDescriptors: [SortDescriptor(\.updatedAt, order: .reverse)],
            predicate: NSPredicate(format: "url == %@", localFile as NSURL)
        )
    }
    
    @State private var selection: Checkpoint?
    
    var body: some View {
        switch presentation {
            case .compactNavigation:
#if os(iOS)
                compactNavigationContent()
#else
                inspectorListContent()
#endif
            case .inspectorList:
                inspectorListContent()
        }
    }

    @ViewBuilder
    private func checkpointRows() -> some View {
        ForEach(fileCheckpoints, id: \.objectID) { checkpoint in
            FileCheckpointRowView(checkpoint: checkpoint)
        }
    }

    @ViewBuilder
    private func inspectorListContent() -> some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            List {
                checkpointRows()
            }
            .scrollContentBackground(.hidden)
        } else {
            List {
                checkpointRows()
            }
        }
    }
    
#if os(iOS)

    @ViewBuilder
    private func compactNavigationContent() -> some View {
        NavigationStack {
            List(selection: $selection) {
                ForEach(fileCheckpoints) { checkpoint in
                    FileCheckpointRowView(checkpoint: checkpoint)
                }
            }
            .navigationTitle(String(localizable: .checkpoints))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarDoneButton {
                        dismiss()
                    }
                }
            }
        }
    }
#endif

}
