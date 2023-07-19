import SwiftUI
import Combine

class PackageListViewModel: ObservableObject {
    @Published var packages = [Package]()
    @Published var casks = [Cask]()
    @Published var canInstallPackages = false
    
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

        let packageInstallCommand = selectedPackages.map { "brew install \($0.name)" }.joined(separator: " && ")
        let caskInstallCommand = selectedCasks.map { "brew install --cask \($0.name)" }.joined(separator: " && ")

        let finalCommand = packageInstallCommand + " && " + caskInstallCommand

        // Execute the final command here
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.launchPath = "/bin/zsh"
            process.arguments = ["-c", finalCommand]

            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            let errorPipe = Pipe()
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Error occurred while installing packages: \(error.localizedDescription)")
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
