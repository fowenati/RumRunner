import SwiftUI

struct PackageListView: View {
    @EnvironmentObject var packageListViewModel: PackageListViewModel
    @State private var showInstalledOnly = false
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List {
                    Toggle(isOn: $showInstalledOnly) {
                        Text("Show installed only")
                    }
                    
                    ForEach(filteredPackages) { package in
                        PackageView(package: package)
                            .environmentObject(PackageObservable(package: package))
                    }
                    
                    ForEach(filteredCasks) { cask in
                        CaskView(cask: cask)
                            .environmentObject(CaskObservable(cask: cask))
                    }
                }
                .frame(minWidth: 300)
                
                HStack {
                    Button(action: {
                        packageListViewModel.installSelectedPackagesAndCasks()
                    }) {
                        Text("Install")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!$packageListViewModel.canInstallPackages.wrappedValue)
                    .padding(.trailing)
                    Button(action: {
                        refreshPackages()
                    }) {
                        Text(isRefreshing ? "Refreshing..." : "Refresh Packages")
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(isRefreshing)
                }
                .padding(.vertical)
                
                
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Packages")
                        .font(.headline)
                }
            }
        }
        .onAppear {
            refreshPackages()
        }
    }
    
    private var filteredPackages: [Package] {
        if searchText.isEmpty {
            return packageListViewModel.packages.filter { !showInstalledOnly || $0.isSelected }
        } else {
            return packageListViewModel.packages.filter { package in
                let isSelected = !showInstalledOnly || package.isSelected
                let containsSearchText = package.name.localizedCaseInsensitiveContains(searchText)
                return isSelected && containsSearchText
            }
        }
    }
    
    private var filteredCasks: [Cask] {
        if searchText.isEmpty {
            return packageListViewModel.casks.filter { !showInstalledOnly || $0.isSelected }
        } else {
            return packageListViewModel.casks.filter { cask in
                let isSelected = !showInstalledOnly || cask.isSelected
                let containsSearchText = cask.name.localizedCaseInsensitiveContains(searchText)
                return isSelected && containsSearchText
            }
        }
    }
    
    private func refreshPackages() {
        isRefreshing = true
        packageListViewModel.getPackages()
        isRefreshing = false
    }
}


class PackageObservable: ObservableObject {
    @Published var package: Package
    
    init(package: Package) {
        self.package = package
    }
}

class CaskObservable: ObservableObject {
    @Published var cask: Cask
    
    init(cask: Cask) {
        self.cask = cask
    }
}

struct PackageView: View {
    @ObservedObject var packageObservable: PackageObservable
    
    init(package: Package) {
        self.packageObservable = PackageObservable(package: package)
    }
    
    var body: some View {
        Toggle(isOn: $packageObservable.package.isSelected) {
            Text(packageObservable.package.name)
        }
    }
}

struct CaskView: View {
    @ObservedObject var caskObservable: CaskObservable
    
    init(cask: Cask) {
        self.caskObservable = CaskObservable(cask: cask)
    }
    
    var body: some View {
        Toggle(isOn: $caskObservable.cask.isSelected) {
            Text(caskObservable.cask.name)
        }
    }
}

struct PackageListView_Previews: PreviewProvider {
    static var previews: some View {
        PackageListView()
            .environmentObject(PackageListViewModel())
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
