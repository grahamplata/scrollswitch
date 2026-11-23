# ScrollSwitch

Menu bar toggle for natural scrolling. Left-click flips direction live via a
`CGEventTap` on scroll-wheel events; right-click quits.

Made because I want natural scrolling on the trackpad but reversed on my
mouse, and macOS only gives you one global setting for both. This toggles
manually rather than detecting the device, so swap it when you switch input.

## Build

```
make run
```

First launch asks for Accessibility and Input Monitoring access in System
Settings > Privacy & Security - required for the event tap to receive scroll
events. Ad-hoc code signing means rebuilding changes the app's signature, so
macOS will ask again; reset stale grants with:

```
tccutil reset Accessibility local.grahamplata.scrollswitch
tccutil reset ListenEvent local.grahamplata.scrollswitch
```
