import HTTPTypes

/// An extension to provide convenience accessors for common HTTP header fields.
extension HTTPFields {
    /// The value of the `Content-Length` header, if present.
    public var contentLength: Int? {
        guard let value = self[.contentLength] else {
            return nil
        }
        return Int(value)
    }
    
    /// The value of the `Content-Type` header, if present.
    public var contentType: String? {
        self[.contentType]
    }
}
