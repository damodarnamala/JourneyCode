//
//  ViewController.swift
//  CleanCodeApp
//
//  Created by Damodar Namala on 21/05/24.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func showPostsView() {
        let vc =  PostsView.build()
        self.present(vc, animated: true)
    }
}

// Define ViewState Enum
enum ViewState<T> {
    case none
    case loading
    case finished(T)
    case error(Error)
}

// Property Wrapper for ViewState
@propertyWrapper
struct StateWrapper<T> {
    private var state: ViewState<T>
    
    var wrappedValue: ViewState<T> {
        get { state }
        set { state = newValue }
    }
    
    init(wrappedValue: ViewState<T>) {
        self.state = wrappedValue
    }
}

// Protocol for UseCase
protocol UseCase {
    associatedtype Input
    associatedtype Output
    func transform(_ input: Input, output: @escaping (Output) -> Void)
}

// PostsUseCase Implementation
struct PostsUseCase: UseCase {
    enum PostRequest {
        case getPost
        case sendPost(String)
    }
    
    enum PostResponse {
        case getPostResponse(String)
        case sendPostResponse(String)
    }
    
    typealias Input = PostRequest
    typealias Output = PostResponse
    
    func transform(_ input: PostRequest, output: @escaping (PostResponse) -> Void) {
        switch input {
        case .getPost:
            output(.getPostResponse("Get Post Response"))
        case .sendPost(let string):
            output(.sendPostResponse(string))
        }
    }
}

// PostsViewModel Implementation
class PostsViewModel<U: UseCase> where U.Input == PostsUseCase.PostRequest, U.Output == PostsUseCase.PostResponse {
    
    struct Output {
        var getPostResponseState = PublishRelay<ViewState<String>>()
        var sendPostResponseState = PublishRelay<ViewState<Int>>()
    }
    
    struct Configuration {
        var postUseCase: U
    }
    
    var configuration: Configuration
    let output = Output()
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    func request(_ input: PostsUseCase.PostRequest) {
        switch input {
        case .getPost:
            self.output.getPostResponseState.accept(.loading)
            handleRequest(input: input,
                          stateRelay: output.getPostResponseState,
                          responseHandler: handleResponse)
        case .sendPost:
            self.output.sendPostResponseState.accept(.loading)
            handleRequest(input: input,
                          stateRelay: output.sendPostResponseState,
                          responseHandler: handleResponse)
        }
    }
    
    private func handleRequest<T>(input: PostsUseCase.PostRequest,
                                  stateRelay: PublishRelay<ViewState<T>>,
                                  responseHandler: @escaping (PostsUseCase.PostResponse) -> Void) {
        stateRelay.accept(.loading)
        configuration.postUseCase.transform(input) { response in
            responseHandler(response)
        }
    }
    
    private func handleResponse(_ response: PostsUseCase.PostResponse) {
        switch response {
        case .getPostResponse(let string):
            output.getPostResponseState.accept(.finished(string))
        case .sendPostResponse(let string):
            output.sendPostResponseState.accept(.finished(10))
        }
    }
}

// PostsViewController Implementation
class PostsViewController: UIViewController {
    
    var viewModel: PostsViewModel<PostsUseCase>
    var bag = DisposeBag()
    
    init(viewModel: PostsViewModel<PostsUseCase>) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init failed")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        setupBindings()
        viewModel.request(.getPost)
    }
    
    private func setupBindings() {
        viewModel.output.sendPostResponseState
            .subscribe(onNext: { [weak self] state in
                self?.handleResponseState(state)
            })
            .disposed(by: bag)
        
        viewModel.output.getPostResponseState
            .subscribe(onNext: { [weak self] state in
                self?.handleResponseState(state)
            })
            .disposed(by: bag)
    }
    
    private func handleResponseState<T>(_ state: ViewState<T>) {
        switch state {
        case .none:
            // Handle none state if needed
            break
        case .loading:
            // Handle loading state if needed
            print("Loading")
            break
        case .finished(let response):
            // Display the finished response
            print("Finished response: \(response)")
        case .error(let error):
            // Display error message if needed
            print("Error: \(error)")
        }
    }
    
    enum ResponseType {
        case getPost
        case sendPost
    }
}


// PostsView Extension and Builder
extension PostsView {
    struct Configuration {
        var postUseCase: any UseCase = PostsUseCase()
        var router = Router()
        var strings = Strings()
        var design = Design()
    }
    
    struct Router { }
    struct Strings { }
    struct Design { }
}

struct PostsView {
    static func build() -> PostsViewController {
        let postsUseCase = PostsUseCase()
        let configuration = PostsViewModel<PostsUseCase>.Configuration(postUseCase: postsUseCase)
        let viewModel = PostsViewModel(configuration: configuration)
        return PostsViewController(viewModel: viewModel)
    }
}
