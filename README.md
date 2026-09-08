# HelloWorld

My first repo

Just learning how to use Git and Swift

## TruckRoute

A dead-simple iOS app for scheduling and routing a week of trucking loads.
Open `TruckRoute.xcodeproj` in Xcode 16 or later and run on iOS 17+.

### What it does

- **Loads tab** — add, edit and delete loads. Each one is a pickup address, a
  drop-off address, a pickup date/time, an optional delivery deadline, and a
  reference plus notes. Everything is stored on the device with SwiftData; there
  is no server and no account.
- **Route tab** — turns the week's loads into an ordered run. Addresses are
  geocoded once and cached, loads are grouped by pickup day, and within each day
  the next stop is whichever remaining pickup is closest to where the truck
  currently sits. Each leg is then measured with MapKit for real drive time and
  distance, drawn on a map, and every stop has a button to hand off to Apple
  Maps for turn-by-turn.
- **Settings tab** — your yard address. Every route starts there.

### Scope

One truck, one route, ordered by nearest-neighbor — not a full optimizer. No
multiple drivers, no GPS tracking, no hours-of-service rules, no traffic-aware
re-routing, no backend sync.

Loads whose addresses can't be found are listed under "Left out" on the route
rather than silently dropped.
