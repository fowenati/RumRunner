import SwiftUI
import Combine

class PackageListViewModel: ObservableObject {
    @Published var packages = [Package]()
    @Published var casks = [Cask]()
    @Published var canInstallPackages = false
    @Published var packagesInstalled: [Package] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        getPackages()
        getCasks()
    }

    internal func getPackages() {
        let url = URL(string: "https://formulae.brew.sh/api/formula.json")!
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Package].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Failed to fetch packages: \(error)")
                }
            }, receiveValue: { [weak self] packages in
                self?.packages = packages
            })
            .store(in: &cancellables)
    }

    internal func getCasks() {
        let url = URL(string: "https://formulae.brew.sh/api/cask.json")!
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Cask].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Failed to fetch casks: \(error)")
                }
            }, receiveValue: { [weak self] casks in
                self?.casks = casks
            })
            .store(in: &cancellables)
    }

    func installSelectedPackagesAndCasks() {
        let selectedPackages = packages.filter { $0.isSelected }
        let selectedCasks = casks.filter { $0.isSelected }

        let packageInstallCommands = selectedPackages.map { "brew install \($0.name)" }
        let caskInstallCommands = selectedCasks.map { "brew install --cask \($0.name)" }

        let allCommands = packageInstallCommands + caskInstallCommands

        guard !allCommands.isEmpty else {
            print("No packages or casks selected to install.")
            return
        }

        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.launchPath = "/bin/bash"
            process.arguments = ["-c", allCommands.joined(separator: " && ")]

            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            let errorPipe = Pipe()
            process.standardError = errorPipe

            process.launch()
            process.waitUntilExit()

            let status = process.terminationStatus

            if status == 0 {
                DispatchQueue.main.async {
                    self.refreshPackages()
                }
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8)
                DispatchQueue.main.async {
                    print("Error: \(errorOutput ?? "")")
                }
            }

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8)

            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8)

            DispatchQueue.main.async {
                if let output = output {
                    print("Output: \(output)")
                }

                if let errorOutput = errorOutput, !errorOutput.isEmpty {
                    print("Error: \(errorOutput)")
                }
            }
        }
    }


    private func refreshPackages(completion: (() -> Void)? = nil) {
        
        let packagesURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
        let casksURL = URL(string: "https://formulae.brew.sh/api/cask.json")!
        
        URLSession.shared.dataTaskPublisher(for: packagesURL)
            .map { $0.data }
            .decode(type: [Package].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] packages -> AnyPublisher<[Cask], Error> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                self.packages = packages
                return URLSession.shared.dataTaskPublisher(for: casksURL)
                    .map { $0.data }
                    .decode(type: [Cask].self, decoder: JSONDecoder())
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Failed to fetch casks: \(error)")
                }
            }, receiveValue: { [weak self] casks in
                guard let self = self else { return }
                self.casks = casks
                completion?()
            })
            .store(in: &cancellables)
        
    }

    func getPackagesInstalled(completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let task = Process()
            let pipe = Pipe()
            
            task.executableURL = URL(fileURLWithPath: "/usr/local/bin/brew")
            task.arguments = ["list", "--json=v2"]
            task.standardOutput = pipe
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let decoder = JSONDecoder()
                let installedPackages = try decoder.decode([Package].self, from: data)
                
                DispatchQueue.main.async {
                    self.packagesInstalled = installedPackages
                    completion?()
                }
            } catch {
                print("Failed to fetch installed packages: \(error)")
            }
        }
    }
}

class PackageViewModel: ObservableObject, Identifiable {
    let name: String
    @Published var isSelected: Bool = false
    
    init(package: Package) {
        self.name = package.name
    }
}

class CaskViewModel: ObservableObject, Identifiable {
    let name: String
    @Published var isSelected: Bool = false
    
    init(cask: Cask) {
        self.name = cask.name
    }
}
