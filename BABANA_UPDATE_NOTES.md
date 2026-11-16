# BabaNa — update notes

## Ano ang bago

- **Reminder card:** kalmadong green na itsura imbes na pulang emergency alert. Tuloy pa rin ang alarm hanggang i-tap ang "Okay, stop alarm".
- **Live Activity:** makikita sa Lock Screen at Dynamic Island ang destinasyon, distansya at progress habang may trip.
- **Widget Extension target** (`BabaNaWidgetsExtension`): kasama na sa Xcode project, hindi na kailangang gawin nang mano-mano.
- **Inayos ang mga folder** para hindi magkakahalo ang mga file.

## Ayos ng folders

```
BabaNa/                     ← app target
  App/                      BabaNaApp, AppState, ContentView, MainTabView
  Models/                   Models, TripRules
  Services/                 Auth, Location, Notifications, Firestore, Storage,
                            TripMonitor, TripLiveActivityManager, DestinationSearch
  Views/
    Auth/                   Login, Register, Onboarding
    Home/                   Home, SearchDestination, MapDestinationPicker
    Trip/                   SetTrip, ActiveTrip, EmergencyAlertView (reminder card)
    Saved/                  SavedStops
    History/                Trips
    Settings/               Settings
    Components/             Theme (colors, buttons, cards)
  Resources/                Assets, BabaNaAlert.wav, GoogleService-Info.plist
Shared/                     TripActivityAttributes (gamit ng app AT widget)
BabaNaWidgets/              Lock Screen / Dynamic Island UI
Configuration/              Info.plist ng app at ng widget
```

Gumagamit ang Xcode project ng "synchronized folders", kaya kusang nakikita ni Xcode ang mga file sa loob ng mga folder na ito. Kapag nagdagdag ka ng bagong `.swift` file sa `BabaNa/Views/...`, kasama na ito agad sa app.

## Bago mag-Run

1. Buksan ang **`BabaNa.xcodeproj`**.
2. **Team:**
   - Sa **Simulator**, hayaan mo lang kahit "Unknown".
   - Sa **totoong iPhone**, piliin ang Team mo sa **Signing & Capabilities** ng **BabaNa** at ng **BabaNaWidgetsExtension**.
   - Kung "bundle identifier not available" ang lumabas, palitan ang `mseuf.BabaNa` ng sarili mo, halimbawa `com.pangalanmo.BabaNa`. Ang widget ay dapat `com.pangalanmo.BabaNa.BabaNaWidgets`.
3. **BabaNa** ang piliing scheme, tapos **⇧⌘K** (Clean) at **⌘R** (Run).

## Hindi pa nasubukan

Inihanda ang update na ito sa Windows, kaya **hindi pa ito na-build sa Xcode**. Kung may error, kunin ang eksaktong text sa Issue Navigator (⌘5).
