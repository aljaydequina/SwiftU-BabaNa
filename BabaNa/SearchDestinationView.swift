import SwiftUI

struct SearchDestinationView: View {
    @State private var searchText = ""

    private var filtered: [Destination] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Destination.samples
        }

        return Destination.samples.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "No destination found",
                    systemImage: "magnifyingglass",
                    description: Text("Try searching for another stop.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(filtered) { destination in
                        NavigationLink {
                            SetTripView(destination: destination)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BabaNaTheme.green)
                                    .frame(width: 36, height: 36)
                                    .background(BabaNaTheme.softGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(destination.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    Text(destination.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                } header: {
                    Text(searchText.isEmpty ? "Popular Stops" : "Search Results")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(BabaNaTheme.background)
        .navigationTitle("Choose Destination")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search destination")
    }
}
