/// Defines how pagination data should be sent in API requests.
///
/// - [queryParams]: Sends pagination values (like page number, limit)
///   as URL query parameters.
/// - [payload]: Sends pagination values inside the request body (payload).
enum PaginationPayloadMode {
  queryParams,
  payload,
}
