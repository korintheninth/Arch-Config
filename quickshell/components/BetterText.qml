import QtQuick
import "../themes"

Text {
    // Pixel fonts stay crisp only at small sizes; larger glyphs/icons need AA.
    // Listed families never use crisp mode, regardless of size.
    // Crisp for Latin text (incl. ö/é/ñ etc.) — CJK, emoji, and icons need AA.
    readonly property int crispMaxSize: 11
    readonly property var smoothFonts: ["Silkscreen", "Pixel Code Regular", "CozetteVector"]

    // Snapshot font inputs so hinting/renderType changes don't re-enter crisp.
    readonly property string crispFamily: font.family
    readonly property int crispPixelSize: font.pixelSize

    readonly property bool crisp: !isSmoothFont(crispFamily)
        && (crispPixelSize <= crispMaxSize || crispMaxSize == 0)
        && isLatinText(text)

    function faded(c, a) {
        return Styles.faded(c, a)
    }

    function isSmoothFont(family) {
        const f = (family || "").toLowerCase()
        for (let i = 0; i < smoothFonts.length; ++i) {
            if (f.indexOf(("" + smoothFonts[i]).toLowerCase()) !== -1)
                return true
        }
        return false
    }

    function isLatinCodepoint(cp) {
        // Basic Latin + Latin-1 + Extended-A/B (ö, ü, ß, ā, …)
        if (cp <= 0x024F)
            return true
        // Latin Extended Additional (ḱ, ẓ, …)
        if (cp >= 0x1E00 && cp <= 0x1EFF)
            return true
        return false
    }

    function isLatinText(s) {
        if (s === undefined || s === null)
            return true
        const str = "" + s
        for (let i = 0; i < str.length; ) {
            const cp = str.codePointAt(i)
            i += cp > 0xFFFF ? 2 : 1
            if (!isLatinCodepoint(cp))
                return false
        }
        return true
    }

    font.family: Styles.fontFamily
    font.pixelSize: Styles.pixelSize
    renderType: crisp ? Text.NativeRendering : Text.QtRendering
    antialiasing: !crisp
    // Do not bind font.hintingPreference to crisp — writing font.* retriggers
    // bindings that read font and causes a loop.
}
