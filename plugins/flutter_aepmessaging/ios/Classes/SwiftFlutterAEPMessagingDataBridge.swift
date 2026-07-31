import AEPMessaging

public class SwiftFlutterAEPMessagingDataBridge {
    func transformToFlutterMessage(message: Message) -> [String: Any] {
        return [
            "id": message.id, "autoTrack": message.autoTrack,
        ]
    }

    func transformToFlutterProposition(proposition: Proposition) -> [String: Any] {
        return [
            "id": proposition.uniqueId,
            "scope": proposition.scope,
            "scopeDetails": [String: Any](),
            "items": proposition.items.map { transformToFlutterPropositionItem(item: $0) },
        ]
    }

    func transformToFlutterPropositionItem(item: PropositionItem) -> [String: Any] {
        return [
            "itemId": item.itemId,
            "schema": item.schema.toString(),
            "data": item.itemData,
        ]
    }
}
