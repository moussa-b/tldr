import receive_sharing_intent

/// Receives the link shared from the Reddit app and opens TL;DR+ directly
/// (spec ticket #5). The Flutter side reads it via receive_sharing_intent.
class ShareViewController: RSIShareViewController {
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
