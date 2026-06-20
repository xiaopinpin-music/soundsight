# SoundSight

SoundSight is an accessibility-focused macOS companion for blind and visually impaired users. Its purpose is to help users understand, navigate, and control application interfaces that do not expose sufficient information to VoiceOver.

## Why SoundSight exists

Many professional macOS applications, audio tools, plug-ins, and hardware control panels still use custom graphical interfaces that VoiceOver cannot interpret properly.

Instead of meaningful control names, values, and states, blind users may encounter:

- unnamed buttons;
- silent controls;
- unknown groups;
- sliders without descriptions;
- repeated navigation sounds with no useful information.

For blind users, this is not merely an inconvenience. It can remove independent access to professional software and hardware that they have already purchased and rely upon.

Apple provides accessibility technologies for macOS applications, but some developers still do not provide a complete or reliable VoiceOver experience. SoundSight is being created to help bridge that gap without modifying or damaging VoiceOver.

## First study case

The first application being studied is:

- PreSonus Universal Control;
- Revelator io24;
- the current Fender and PreSonus ecosystem.

Universal Control is essential for configuring supported PreSonus audio hardware. However, important controls may be difficult or impossible to identify and operate independently with VoiceOver.

SoundSight will begin by investigating exactly what Universal Control exposes through the macOS Accessibility API.

Where usable accessibility information exists, SoundSight will organise, label, and present it clearly.

Where information is missing, later stages may use:

- verified control mappings;
- screen analysis;
- OCR;
- control positions;
- carefully controlled interaction methods.

## Initial goals

The first development milestones are:

1. Detect when Universal Control is running.
2. Announce that interface scanning has started.
3. Inspect the application's accessibility structure.
4. Identify buttons, sliders, switches, tabs, values, positions, and available actions.
5. Present the results through a native VoiceOver-friendly interface.
6. Allow verified mappings to be saved locally.
7. Use saved mappings to provide practical control of Universal Control.
8. Allow mappings to be deleted when they are no longer needed.

## Intended experience

When Universal Control is opened, SoundSight should eventually announce:

> Universal Control detected. Scanning interface.

After analysing the interface:

> Scan complete. Would you like to save this mapping?

When a verified mapping is loaded, VoiceOver should be able to identify controls meaningfully, for example:

> Mic 1 Gain, 42 per cent, slider.

> Phantom Power, on, checkbox.

> Headphone Level, 55 per cent, slider.

## Design principles

SoundSight must:

- work alongside VoiceOver rather than replace or modify it;
- use native macOS accessibility technologies wherever possible;
- remain fully keyboard accessible;
- provide clear and consistent control names;
- expose control values and on/off states accurately;
- keep saved mappings small, local, removable, and understandable;
- avoid changing hardware settings unexpectedly;
- begin with one real application and one real device;
- expand only after the first study case is reliable.

## Development strategy

SoundSight will not attempt to solve every inaccessible macOS application immediately.

Development begins with:

- one application: PreSonus Universal Control;
- one device: Revelator io24;
- one blind user's real workflow;
- one control at a time.

The first technical target is to inspect and control:

1. one slider;
2. one on/off control;
3. one tab or page.

Once those three control types work reliably, SoundSight can progressively map the rest of Universal Control.

## Long-term direction

After Universal Control has been studied successfully, SoundSight may later support other inaccessible:

- audio interface control applications;
- standalone audio utilities;
- Audio Unit plug-ins;
- virtual instruments;
- mixing and mastering tools.

Future expansion will be based on real accessibility problems experienced by blind users.

## Status

Early development prototype.

Current technology:

- Swift;
- AppKit;
- macOS;
- macOS Accessibility API;
- native VoiceOver-compatible interface.

Current target:

- PreSonus Universal Control;
- Revelator io24.

## Creator

Created by Xiao Pinpin, a blind musician, producer, and macOS VoiceOver user.

SoundSight is built from direct experience of inaccessible professional audio software and from the need for independent access to tools that blind users already own and use.
