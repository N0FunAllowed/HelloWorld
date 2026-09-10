# HelloWorld

My first repo

Just learning how to use Git and Swift

## TruckRoute

A dead-simple iOS app for scheduling and routing a week of trucking loads.
Needs Xcode 16 or later and targets iOS 17+.

### Running it

Either open `TruckRoute.xcodeproj` in Xcode and press Run, or from a terminal:

```sh
./run.sh                  # first available iPhone simulator
./run.sh "iPhone 17 Pro"  # or name one
```

The script builds, boots the simulator, installs and launches. No signing
setup is needed for the simulator. Running on a physical iPhone does need a
signing team and a bundle identifier of your own, set on the target's Signing
& Capabilities tab.

Set a home base address under Settings before planning a route — addresses are
geocoded against Apple's live service, so use real ones and expect about a
second per address.

### What it does

- **Addresses tab** — the address book. Yards, customers and docks are entered
  once, with notes for gate codes or dock hours. Typing an address searches
  Apple Maps, and picking a suggestion confirms it against a real location and
  keeps its coordinate, so it never has to be looked up again.
- **Loads tab** — add, edit and delete loads. Each one picks a pickup and a
  drop-off from the address book, plus a pickup date/time, an optional delivery
  deadline, what it pays, and a reference and notes. Everything is stored on the
  device with SwiftData; there is no server and no account.
- **Route tab** — turns the week's loads into an ordered run. Addresses are
  geocoded once and cached, loads are grouped by pickup day, and within each day
  the next stop is whichever remaining pickup is closest to where the truck
  currently sits. Each leg is then measured with MapKit for real drive time and
  distance, drawn on a map, and every stop has a button to hand off to Apple
  Maps for turn-by-turn. Empty legs — running to a pickup with nothing on —
  are marked as deadhead, and each load shows its rate per mile measured over
  loaded *and* empty miles, which is the number that decides whether a load was
  worth taking.
- **Settings tab** — which address is your yard. Every route starts there.

### Scope

One truck, one route, ordered by nearest-neighbor — not a full optimizer. No
multiple drivers, no GPS tracking, no hours-of-service rules, no traffic-aware
re-routing, no backend sync.

Loads whose addresses can't be found are listed under "Left out" on the route
rather than silently dropped.
