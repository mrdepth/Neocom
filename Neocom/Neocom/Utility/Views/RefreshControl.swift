//
//  RefreshControl.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct RefreshControl: UIViewRepresentable {
    @Binding var isRefreshing: Bool
    var title: String?
    var onRefresh: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = ZeroView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }
    
    class Coordinator: NSObject {
        var isRefreshing: Binding<Bool>
        var onRefresh: () -> Void
        var refreshControl: UIRefreshControl? {
            didSet {
                guard oldValue != refreshControl else {return}
                oldValue?.removeTarget(self, action: #selector(Coordinator.onValueChanged), for: .valueChanged)
                refreshControl?.addTarget(self, action: #selector(Coordinator.onValueChanged), for: .valueChanged)
            }
        }
        
        init(isRefreshing: Binding<Bool>, onRefresh: @escaping () -> Void) {
            self.isRefreshing = isRefreshing
            self.onRefresh = onRefresh
            super.init()
        }
        
        @objc func onValueChanged(_ sender: UIRefreshControl) {
            if sender.isRefreshing && !isRefreshing.wrappedValue {
                onRefresh()
                if !isRefreshing.wrappedValue {
                    sender.endRefreshing()
                }
            }
        }
        
        deinit {
            refreshControl?.removeTarget(self, action: #selector(Coordinator.onValueChanged), for: .valueChanged)
        }
    }

    
    func makeCoordinator() -> Coordinator {
        Coordinator(isRefreshing: $isRefreshing, onRefresh: onRefresh)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.isRefreshing = $isRefreshing
        context.coordinator.onRefresh = onRefresh
        
        func findChild(in view: UIView) -> UITableView? {
            if let tableView = view as? UITableView {
                return tableView
            }
            return view.subviews.lazy.map{findChild(in: $0)}.first{$0 != nil} ?? nil
        }
        
        func upwardSearch(from view: UIView) -> UITableView? {
            guard let s = view.superview else {return nil}
            guard let i = s.subviews.firstIndex(of: view) else {return nil}
            if let tableView = s.subviews[0..<i].lazy.map({findChild(in: $0)}).first(where: {$0 != nil}) ?? nil {
                return tableView
            }
            else {
                return upwardSearch(from: s)
            }
        }
        
        DispatchQueue.main.async {
            guard let tableView = upwardSearch(from: uiView) else {return}
            let refreshControl = tableView.refreshControl ?? {
                let refreshControl = UIRefreshControl()
                context.coordinator.refreshControl = refreshControl
                tableView.refreshControl = refreshControl
                return refreshControl
            }()
            refreshControl.attributedTitle = self.title.map{NSAttributedString(string: $0)}
            if !self.isRefreshing && refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        }
        
    }
}

extension View {
    func onRefresh(isRefreshing: Binding<Bool>, title: String? = nil, onRefresh: @escaping () -> Void) -> some View {
        self.overlay(RefreshControl(isRefreshing: isRefreshing, title: title, onRefresh: onRefresh))
    }
}

class ZeroView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
}

struct RefreshControlTest: View {
    @State private var isRefreshing = false
    var body: some View {
        List {
            Text("Text")
        }
        .onRefresh(isRefreshing: $isRefreshing, title: nil) {
            self.isRefreshing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isRefreshing = false
            }
        }
    }
}

struct RefreshControl_Previews: PreviewProvider {
    static var previews: some View {
        RefreshControlTest()
    }
}
