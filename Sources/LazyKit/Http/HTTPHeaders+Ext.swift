import HTTPTypes


#if canImport(NIO)
import AsyncHTTPClient
import NIOHTTP1

extension  NIOHTTP1.HTTPHeaders {
    public subscript(field: HTTPTypes.HTTPField.Name) -> [String] {
        self[field.rawName]
    }
}

extension HttpClientAbstract.Response {
    public var contentLength: Int? {
        guard let value = self.headers[.contentLength].first else {
            return nil
        }
        return Int(value)
    }

    public var contentType: String? {
        self.headers[.contentType].first
    }
}

#endif
