# monarch_command

Monarch Command – mobile control interface for Monarch Core.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running on web

When running with `flutter run -d chrome` (or from the IDE), you may see:

- `Failed to set DevTools server address: ext.flutter.activeDevToolsServerAddress: (-32601) Unknown method`
- `Failed to set vm service URI: ext.flutter.connectedVmServiceUri: (-32601) Unknown method`

These come from the Flutter/IDE tooling; the web runtime does not support those VM service extension methods. They are harmless and can be ignored. Only DevTools deep links in error output are affected.
