.pragma library

// Material 3-inspired container / on-container tonal pairs.
// All sixteen pairs exceed 9:1 WCAG contrast for normal text.
// Desktops 1–8 retain distinct defaults; desktop 8 uses green for LINE.
var presets = [
    { name: "Blue", foreground: "#0B2545", background: "#D3E3FD" },
    { name: "Teal", foreground: "#003731", background: "#B2F5EA" },
    { name: "Purple", foreground: "#35165A", background: "#E9DDFF" },
    { name: "Rose", foreground: "#5B1131", background: "#FFD9E2" },
    { name: "Amber", foreground: "#4B2800", background: "#FFE0B2" },
    { name: "Indigo", foreground: "#1E2855", background: "#DEE1FF" },
    { name: "Cyan", foreground: "#003641", background: "#B9EAF5" },
    { name: "Green", foreground: "#183B1E", background: "#CDECCB" },
    { name: "Slate", foreground: "#1C2935", background: "#DFE5EB" },
    { name: "Coral", foreground: "#5E2319", background: "#FFDDD5" },
    { name: "Sky", foreground: "#0A3552", background: "#D6EFFE" },
    { name: "Lime", foreground: "#263800", background: "#E3F6BD" },
    { name: "Mint", foreground: "#074233", background: "#D2F6E4" },
    { name: "Peach", foreground: "#532C13", background: "#FFE5CF" },
    { name: "Lavender", foreground: "#38265F", background: "#E8E1FA" },
    { name: "Sand", foreground: "#4E3719", background: "#F8E8CC" }

]

function forIndex(index) {
    var number = Number(index)
    if (!isFinite(number) || number < 0)
        number = 0
    return presets[Math.floor(number) % presets.length]
}

function isHexColor(value) {
    return typeof value === "string" && /^#[0-9a-fA-F]{6}$/.test(value)
}

function indexOfPair(foreground, background) {
    if (!isHexColor(foreground) || !isHexColor(background))
        return -1
    for (var i = 0; i < presets.length; i++) {
        if (presets[i].foreground === foreground.toUpperCase()
                && presets[i].background === background.toUpperCase())
            return i
    }
    return -1
}

function luminance(hex) {
    if (!isHexColor(hex))
        return NaN
    var channels = []
    for (var i = 1; i <= 5; i += 2) {
        var value = parseInt(hex.substr(i, 2), 16) / 255
        channels.push(value <= 0.04045 ? value / 12.92
                                         : Math.pow((value + 0.055) / 1.055, 2.4))
    }
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
}

function contrastRatio(foreground, background) {
    if (!isHexColor(foreground) || !isHexColor(background))
        return 0
    var a = luminance(foreground)
    var b = luminance(background)
    return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
}

// Existing title / note overrides continue to take precedence.
// Otherwise, both text roles share the customizable foreground.
function roleColor(entry, role, preset) {
    if (entry && isHexColor(entry[role]))
        return entry[role]
    if (role === "title" || role === "note" || role === "foreground") {
        if (entry && isHexColor(entry.foreground))
            return entry.foreground
        return preset.foreground
    }
    return preset.background
}
