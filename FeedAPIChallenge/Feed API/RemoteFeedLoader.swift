//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }
			switch result {
			case let .success((data, response)):
				completion(FeedImageMapper.map(data: data, response: response))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
}

private struct FeedImageMapper {
	struct Root: Decodable {
		let items: [FeedImageDTO]
		struct FeedImageDTO: Decodable {
			let id: UUID
			let description: String?
			let location: String?
			let url: URL
			private enum CodingKeys: String, CodingKey {
				case id = "image_id"
				case description = "image_desc"
				case location = "image_loc"
				case url = "image_url"
			}
		}
	}

	static func map(data: Data, response: HTTPURLResponse) -> RemoteFeedLoader.Result {
		guard response.statusCode == 200 else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}

		do {
			let feedImageDTO = try JSONDecoder().decode(Root.self, from: data)
			let feedImages = feedImageDTO.items.map {
				FeedImage(
					id: $0.id,
					description: $0.description,
					location: $0.location,
					url: $0.url
				)
			}
			return .success(feedImages)
		} catch {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
	}
}
