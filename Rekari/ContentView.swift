//
//  ContentView.swift
//  Rekari
//
//  Created by development on 2024/06/15.
//

import SwiftUI
import Combine

struct SearchResult: Codable, Identifiable {
    let id: String
    let title: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
    }
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        let titles = try container.decode([String].self, forKey: .title)
        title = titles.joined(separator: ", ")
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    private var cancellables = Set<AnyCancellable>()
    
    func search(query: String) {
        let urlString: String
        if !query.isEmpty {
            let allowedCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) else {
                return
            }
            urlString = "https://g4bvjgz8cj.execute-api.ap-northeast-1.amazonaws.com/Prod/search?q=\(encodedQuery)"
        } else {
            urlString = "https://g4bvjgz8cj.execute-api.ap-northeast-1.amazonaws.com/Prod/all"
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [SearchResult].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error fetching data: \(error)")
                }
            }, receiveValue: { [weak self] results in
                self?.searchResults = results
            })
            .store(in: &cancellables)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var url = "https://www.nicovideo.jp/"
    
    var body: some View {
        HStack {
            VStack {
                TextField("Search", text: $searchText,  onCommit: {
                    viewModel.search(query: searchText)
                })
                .padding(7)
                .background(Color(.systemGray))
                .cornerRadius(8)
                .padding(.horizontal, 10)
                List(viewModel.searchResults) { result in
                    VStack(alignment: .leading) {
                        Text(result.title)
                            .font(.headline)
                            .onTapGesture {
                                                            // Set the URL based on the selected result's ID
                                                            url = "https://www.nicovideo.jp/watch_tmp/\(result.id)"
                            }
                    }
                    .padding(.vertical, 8) // オプション: 行の上下にパディングを追加
                    Divider() // 区切り線を追加
                }
            }.frame(maxWidth: 300)
            WebView(url: url).frame(maxWidth: .infinity)
        }.onAppear {
            viewModel.search(query: "") // 初回表示時に全結果を取得
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
