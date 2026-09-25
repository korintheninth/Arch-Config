import QtQuick
import "../../components"
import "../../themes"

BetterText {
    // "muted" for secondary text, "text" for primary.
    property string role: "muted"
    readonly property var s: role === "text"
        ? Styles.wallpaperGallery.preview.text
        : Styles.wallpaperGallery.preview.muted

    color: s.color
    font.family: s.font.family
    font.pixelSize: s.font.pixelSize
}
