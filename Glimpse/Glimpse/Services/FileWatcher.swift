import Foundation
import Combine

class FileWatcher: ObservableObject {
    @Published var lastUpdate: Date = Date()

    private var stream: FSEventStreamRef?
    private let path: String
    private var callback: (() -> Void)?

    init(path: String) {
        self.path = path
    }

    func start(onChange: @escaping () -> Void) {
        callback = onChange

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [path] as CFArray

        stream = FSEventStreamCreate(
            nil,
            { (_, info, numEvents, eventPaths, _, _) in
                guard let info = info else { return }
                let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
                DispatchQueue.main.async {
                    watcher.lastUpdate = Date()
                    watcher.callback?()
                }
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let stream = stream {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
            FSEventStreamStart(stream)
        }
    }

    func stop() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        stop()
    }
}
