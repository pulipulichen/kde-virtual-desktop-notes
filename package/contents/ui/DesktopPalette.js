.pragma library

// Material 3-inspired container / on-container tonal pairs.
// All eight pairs exceed WCAG AAA (7:1) contrast for normal text.
var presets = [
    { name: "Blue",   foreground: "#0B2545", background: "#D3E3FD" },
    { name: "Teal",   foreground: "#003731", background: "#B2F5EA" },
    { name: "Purple", foreground: "#35165A", background: "#E9DDFF" },
    { name: "Rose",   foreground: "#5B1131", background: "#FFD9E2" },
    { name: "Amber",  foreground: "#4B2800", background: "#FFE0B2" },
    { name: "Green",  foreground: "#183B1E", background: "#CDECCB" },
    { name: "Cyan",   foreground: "#003641", background: "#B9EAF5" },
    { name: "Indigo", foreground: "#1E2855", background: "#DEE1FF" }
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
