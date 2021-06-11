//
//  SearchController2.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

extension View {
    func search<T: View>(@ViewBuilder _ content: @escaping (AnyPublisher<String?, Never>) -> T) -> some View {
        self.background(SearchControllerView(content))
    }
}

fileprivate struct SearchControllerView<Content: View>: UIViewControllerRepresentable {
    var content: (AnyPublisher<String?, Never>) -> Content
    init(@ViewBuilder _ content: @escaping (AnyPublisher<String?, Never>) -> Content) {
        self.content = content
    }
    
    func makeUIViewController(context: Context) -> SearchController2<Content> {
        SearchController2(content)
    }
    
    func updateUIViewController(_ uiViewController: SearchController2<Content>, context: Context) {
        uiViewController.content = content
    }
    
    static func dismantleUIViewController(_ uiViewController: SearchController2<Content>, coordinator: ()) {
        uiViewController.searchResultsController = nil
    }
}

fileprivate class SearchController2<Content: View>: UIViewController, UISearchResultsUpdating {
    var content: (AnyPublisher<String?, Never>) -> Content {
        didSet {
            searchResultsController?.rootView = content(subject.eraseToAnyPublisher())
        }
    }
    private var subject = PassthroughSubject<String?, Never>()
    
    init(_ content: @escaping (AnyPublisher<String?, Never>) -> Content) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var searchResultsController: UIHostingController<Content>?
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard let parent = parent, parent.navigationItem.searchController == nil else {return}
        if searchResultsController == nil {
            searchResultsController = SearchHostingController(rootView: content(subject.eraseToAnyPublisher()))
        }
        let searchController = UISearchController(searchResultsController: searchResultsController!)
        searchController.searchResultsUpdater = self
        parent.navigationItem.searchController = searchController
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        subject.send(searchController.searchBar.text)
    }
}

fileprivate class SearchHostingController<Content: View>: UIHostingController<Content> {
    override var navigationController: UINavigationController? {
        parent?.presentingViewController?.navigationController
    }
}


struct SearchController2_Previews: PreviewProvider {
    static var previews: some View {
        SearchControllerView { _ in
            EmptyView()
        }
    }
}
