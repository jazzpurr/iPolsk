# iPolsk
A customizable polska generator written in Swift for iOS using SwiftUI and CoreAudio.

My initial approach was to use markov chains to transition between note states and applying constraints to direct the output into a nice direction.
This sort of worked, but it sounded too incoherent. I came to a realization that repetition is to some extent important, and thus came about my second approach.

I'm representing the song as an array of bars, where each bar either contains a fixed pattern or a chord. A chord in turn consists of a set of patterns along with a base note. Finally, a pattern is a bar of notes, represented by scale offsets from the chord base note. Representing notes as scale indices rather than half notes allows for more intuitive browsing and editing of the data, and if you happen to want a diminished note somewhere that wouldn't be so hard to add.

My vision is that you should be able to interface with the song structure in each individual step, from bars to chords to patterns. To simplify the workflow and to make it more fun I've made some constraints as to what I think is important for a polska to have. (Emphasis on 1st and 7th subbeat, etc)

Playback happens in the form of a timer running on the common thread at a frequency of one subbeat per second. For music playback I'm using a Core Audio polyphonic MIDI synth with a public domain violin sound font made by Nando Florestan. There's also an AVPlayer playing a stomp sound on the 1 and 7

I then played around with tweaks and settings to make it sound even better, such as a second violin playing along automatically and leading notes to alleviate larger chord transitions.

A polska is a scandinavian dance music tradition btw, I chose it largerly for it's very rigid structure. Here's an example
https://www.youtube.com/watch?v=wVx5RJojwnA


Acknowledgements:
https://developer.apple.com/tutorials/app-dev-training/getting-started-with-scrumdinger
https://docs.swift.org/swift-book/LanguageGuide/MemorySafety.html
https://github.com/ivanvorobei/SwiftUI
https://pspdfkit.com/blog/2021/swiftui-in-production/
http://www.rockhoppertech.com/blog/multi-timbral-avaudiounitmidiinstrument/
http://dev.nando.audio/pages/soundfonts.html
https://hotpot.ai/free-icons?s=sfSymbols
https://appicon.co/
