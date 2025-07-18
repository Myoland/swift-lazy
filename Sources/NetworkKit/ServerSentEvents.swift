//
//  ServerSentEvent.swift
//  dify-forward
//
//  Created by AFuture on 2025/4/5.
//
import Foundation
import RegexBuilder
import AsyncAlgorithms
import LazyKit
import OSLog
import SynchronizationKit


public struct ServerSentEvent: Sendable {
    public let id: String?
    public let event: String
    public let data: String
    public let retry: Int?
}

public extension ServerSentEvent {
    static let MIME_String: String = "text/event-stream"
    
    static let encoding: String.Encoding = .utf8
}


/// A Interpreter for processing server-sent-events
///
/// The Interpreter will process as [specification](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation) descried.
public final class ServerSentEventsInterpreter: Sendable {

    private let clientLastEventId: LazyLockedValue<String?> = .init(nil)
    public let logger: Logger = .init(subsystem: "me.afuture.server.sse", category: "interpreter")

    public func process(buffer: Data) -> [ServerSentEvent] {
        // Streams must be decoded using the UTF-8 decode algorithm.
        let raw = String(data: buffer, encoding: ServerSentEvent.encoding)
        logger.debug("[*] \(raw ?? "nil")")

        guard let raw, !raw.isEmpty else {
            return []
        }

        let lines = raw.split(separator: Self.lineRegex, omittingEmptySubsequences: false)

        var events: [ServerSentEvent] = []
        var fields: [String: String] = [:]

        for line in lines {
            if line == "" {
                if let event = buildEvent(fields) {
                    events.append(event)
                }
                fields = [:]
            }

            if line.starts(with: ":") {
                continue
            }

            if line.contains(":") {
                let keyValuePair = line.split(separator: #/: ?/#, maxSplits: 1)
                guard let keyView = keyValuePair.first else {
                    continue
                }
                let valueView = keyValuePair.last ?? ""

                let key = String(keyView)
                let value = String(valueView)

                switch key {
                case "event":
                    fields["event"] = value
                case "id" where !value.isEmpty:
                    fields["id"] = value
                case "retry":
                    // TODO: Support retry logic
                    break
                case "data":
                    fields["data"] = (fields["data"] ?? "").appending(value + "\n")
                default:
                    break
                }

            } else {
                let key = String(line)
                fields[key] = ""
            }
        }

        logger.debug("[*] \(events)")
        // NOTICE: If the file ends in the middle of an event, before the final empty line,
        //         the incomplete event is not dispatched.
        return events
    }

    public func buildEvent(_ fields: [String: String]) -> ServerSentEvent? {
        let eventType = fields["event"] ?? "message"

        guard var data = fields["data"], !data.isEmpty else {
            return nil
        }

        if data.hasSuffix("\n") {
            data.removeLast()
        }

        let id = clientLastEventId.withLock { $0 }

        let event = ServerSentEvent(id: id, event: eventType, data: data, retry: nil)

        clientLastEventId.withLock { theID in
            theID = fields["id"] ?? theID
        }

        return event
    }
}

extension ServerSentEventsInterpreter {

    static let lineCharacters = ["\r\n", "\n", "\r"]
    nonisolated(unsafe) static let lineRegex: any RegexComponent = Regex {
        ChoiceOf {
            "\r\n"
            "\n"
            "\r"
        }
    }
}

// Rewrite using state machine.
// The current implement is for convenience.
public final class AsyncServerSentEventsInterpreter: AsyncSequence, Sendable {

    let stream: AnyAsyncSequence<Data>
    public init(stream: AnyAsyncSequence<Data>) {
        self.stream = stream
    }

    public func makeAsyncIterator() -> AnyAsyncSequence<ServerSentEvent>.AsyncIterator {
        let interpreter = ServerSentEventsInterpreter()

        return AnyAsyncSequence(stream.map {
            interpreter.process(buffer: $0)
        }.flatMap { $0.async }).makeAsyncIterator()
    }
}

extension AsyncSequence where Self: Sendable, Self.Element == Data {
    public func mapToServerSentEvert() -> AsyncServerSentEventsInterpreter {
        AsyncServerSentEventsInterpreter(stream: .init(self))
    }
}
