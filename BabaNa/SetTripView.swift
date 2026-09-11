import SwiftUI

struct SetTripView: View {
    @EnvironmentObject var appState: AppState

    let destination: Destination

    @State private var selectedDistance: Double = 1000
    @State private var showCustomDistance = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(BabaNaTheme.green)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Destination")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(destination.name)
                            .font(.headline)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Reminder distance")
                        .font(.headline)

                    Text("Choose how early you want to be reminded.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    distanceButton(title: "500 meters", subtitle: "Closer reminder", meters: 500)
                    Divider().padding(.leading, 48)
                    distanceButton(title: "1 kilometer", subtitle: "Recommended", meters: 1000)
                    Divider().padding(.leading, 48)
                    distanceButton(title: "2 kilometers", subtitle: "Earlier reminder", meters: 2000)
                    Divider().padding(.leading, 48)

                    Button {
                        showCustomDistance = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(BabaNaTheme.green)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Custom distance")
                                    .foregroundStyle(.primary)
                                    .font(.subheadline.weight(.semibold))

                                Text("Set your own range")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(15)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                NavigationLink {
                    ActiveTripView()
                } label: {
                    Text("Start Trip")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(BabaNaTheme.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    appState.selectedDestination = destination
                    appState.selectedReminderDistance = selectedDistance
                    appState.startTrip()
                })
                .padding(.top, 4)
            }
            .padding(18)
        }
        .background(BabaNaTheme.background)
        .navigationTitle("Set Trip")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomDistance) {
            CustomDistanceView(distance: $selectedDistance)
        }
    }

    private func distanceButton(title: String, subtitle: String, meters: Double) -> some View {
        Button {
            selectedDistance = meters
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedDistance == meters ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedDistance == meters ? BabaNaTheme.green : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(15)
        }
        .buttonStyle(.plain)
    }
}

struct CustomDistanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var distance: Double

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "bell.and.waves.left.and.right.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(BabaNaTheme.green)

                Text("Choose your distance")
                    .font(.title2.bold())

                Text(distanceText)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(BabaNaTheme.green)

                Slider(value: $distance, in: 200...5000, step: 100)
                    .tint(BabaNaTheme.green)
                    .padding(.horizontal, 8)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Use This Distance")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(BabaNaTheme.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(22)
            .background(BabaNaTheme.background)
            .navigationTitle("Custom Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var distanceText: String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}
