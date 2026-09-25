// themes/Style.qml
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: styles

    readonly property color bgBase: Colors.color8
    readonly property color bgSecondary: Colors.color6
    readonly property color fgBase: Colors.color6
    readonly property color fgSecondary: Colors.color8
    readonly property string fontFamily: "Departure Mono"
    readonly property double pixelSize: 11

    // Prefer this over Item.opacity for muted text/glyphs.
    function faded(c, a) {
        const col = Qt.color(c)
        return Qt.rgba(col.r, col.g, col.b, col.a * a)
    }

    readonly property var topbar: ({

        "color": "transparent",
        "implicitHeight": 18,
        "background": {
            "color": bgBase,
            "border": {
                "width": 1,
                "color": fgBase,
            },
        },
        "margins": {
            "top": 0,
            "left": 2,
            "right": 2,
            "bottom": 0
        }
    })

    readonly property var clock: ({
        "color": "transparent",
        "radius": 0,
        "text": {
            "font": {
                "family": fontFamily,
                "bold": false
            },
            "color": fgBase
        },
        "indicator": {
            "size": 6,
            "spacing": 6,
            "color": fgBase
        }
    })

    readonly property var media: ({

        "titleMaxLength": 24,
        "artistMaxLength": 16,
        "albumMaxLength": 16,
        "color": "transparent",
        "radius": 0,
        "text": {
            "font": {
                "family": fontFamily,
                "bold": false
            },
            "color": fgBase
        },
        "oscilloscope": {
            "width": 96,
            "height": 16,
            "lineWidth": 1,
            "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.8),
            "background": "transparent",
            "anchors": {
                "leftMargin": 6
            }
        }
    })

    readonly property var mediaMenu: ({
        "menuWidth": 600,
        "menuHeight": 220,
        "controls": {
            "spacing": 40,
            "bottomOffset": 30
        },
        "button": {
            "size": 45,
            "radius": 25,
            "normalColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.0),
            "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
            "pressedColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.2),
            "iconSize": 16,
            "iconColor": fgBase,
            "iconHoverColor": fgBase,
            "iconPressedColor": fgBase,
            "shadow": {
                "color": Qt.rgba(0, 0, 0, 1),
                "opacity": 0.55,
                "blur": 0.5,
                "horizontalOffset": 0,
                "verticalOffset": 3,
                "pressedVerticalOffset": 1
            }
        },
        "background": {
            "color": bgBase,
            "radius": 10,
            "border": {
                "width": 1,
                "color": fgBase,
            },
        },
        "text": {
            "font": {
                "family": "Silkscreen",
                "pixelSize": 12,
                "bold": false
            },
            "color": fgBase,
            "anchors": {
                "leftMargin": 0,
                "bottomMargin": 5
            }
        },
        "cover": {
            "width": 96,
            "height": 96,
            "radius": 5,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "anchors": {
                "leftMargin": 20,
                "topMargin": 15
            },
            "mask": {
                "color": fgBase
            }
        },
        "oscilloscope": {
            "width": 600,
            "height": 65,
            "lineWidth": 2,
            "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.8),
            "background": "transparent"
        },
        "cava": {
            "width": 601,
            "height": 65,
            "bars": {
                "spacing": 1,
                "anchors": {
                    "bottomMargin": 0
                }
            },
            "barCount": 70,
            "barColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.8),
            "confPath": "wallpaper.conf"
        },
        "slider": {
            "radius": 2,
            "background": {
                "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1)
            },
            "bar": {
                "color": fgBase
            },
            "handle": {
                "color": fgBase
            }
        },
        "volumeSlider": {
            "implicitWidth": 6,
            "implicitHeight": 96,
            "anchors": {
                "leftMargin": 12,
                "topMargin": 0
            }
        },
        "seekSlider": {
            "implicitWidth": 560,
            "implicitHeight": 6,
            "anchors": {
                "bottomMargin": 60
            }
        },
        "ytmusic": {
            "width": 36,
            "height": 36,
            "anchors": {
                "bottomMargin": 0,
                "rightMargin": 0
            },
            "background": {
                "visible": false
            },
            "icon": {
                "width": 32,
                "height": 32,
                "color": fgBase
            }
        },
        "lyrics": {
            "height": 96,
            "spacing": 10,
            "padding": 0,
            "inactiveColor": faded(fgBase, 0.75),
            "activeColor": fgBase,
            "anchors": {
                "topMargin": 15,
                "rightMargin": 20
            },
            "font": {
                "family": "Silkscreen",
                "pixelSize": 12,
                "bold": false
            },
            "background": {
                "color": bgBase,
                "radius": 5,
                "visible": true,
                "opacity": 1,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            }
        }
    })

    readonly property var cava: ({
        "barColor": fgBase,
        "barWidth": 3,
        "anchors": {
            "leftMargin": 5,
        },
        "bars": {
            "spacing": 1,
            "anchors": {
                "bottomMargin": 10
            }
        }
    })

    readonly property var vectorscope: ({
        "bufferSize": 256,
        "displaySize": 512,
        "decay": 200,
        "intensity": 96,
        "gain": 1.0,
        "fps": 24,
        "lineWidth": 2,
        "color": Qt.rgba(bgSecondary.r, bgSecondary.g, bgSecondary.b, 1.0),
        "background": "transparent"
    })

    readonly property var oscilloscope: ({
        "bufferWidth": 600,
        "bufferHeight": 65,
        "displayWidth": 601,
        "displayHeight": 65,
        "periodMs": 30,
        "intensity": 255,
        "gain": 1.0,
        "fps": 24,
        "lineWidth": 1,
        "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.8),
        "background": "transparent"
    })

    readonly property var workspaces: ({
        "spacing": 0,
        "background": {
            "color": "transparent",
            "radius": 0
        },
        "button": {
            "width": 14,
            "radius": 0,
            "text": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                }
            },
            "checked": {
                "fill": fgBase,
                "text": bgBase
            },
            "unchecked": {
                "fill": "transparent",
                "text": fgBase
            }
        }
    })

    readonly property var tooltip: ({
        "delay": 400,
        "timeout": 5000,
        "background": {
            "color": bgBase,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "label": {
            "color": fgBase,
            "font": {
                "family": fontFamily,
            }
        },
        "anchor": {
            "margins": {
                "top": 15
            }
        }
    })

    readonly property var sound: ({
        "color": "transparent",
        "radius": 0,
        "icon": {
            "font": {
                "family": "Scientifica",
                "pixelSize": 10,
                "bold": false
            },
            "color": fgBase,
            "muted": "󰝟",
            "wired": ["", " ", ""],
            "bluetooth": [" ", " ", " "]
        },
        "text": {
            "font": {
                "family": fontFamily,
                "bold": false
            },
            "color": fgBase
        }
    })

    readonly property var battery: ({
        "color": "transparent",
        "radius": 0,
        "icon": {
            "font": {
                "family": "Scientifica",
                "bold": false
            },
            "color": fgBase,
            "charging": [" ", " ", " ", " ", " "],
            "discharging": ["", "", "", "", ""]
        },
        "text": {
            "font": {
                "family": fontFamily,
                "bold": false
            },
            "color": fgBase
        },
        "baseColor": fgBase,
        "warningColor": "#e6c200",
        "criticalColor": "#e54545"
    })

    readonly property var updates: ({
        "color": "transparent",
        "radius": 0,
        "icon": {
            "glyph": "",
            "font": {
                "family": "Scientifica",
                "bold": false
            },
            "color": fgBase
        },
        "text": {
            "font": {
                "family": fontFamily,
                "bold": false
            },
            "color": fgBase
        },
        "baseColor": fgBase,
        "warningColor": "#e6c200",
        "criticalColor": "#e54545"
    })

    readonly property var hwState: ({
        "spacing": 2,
        "barWidth": 5,
        "radius": 0,
        "baseColor": fgBase,
        "leftPadding": 5,
        "rightPadding": 10,
        "warningColor": "#e6c200",
        "criticalColor": "#e54545",
        "warningThreshold": 80,
        "criticalThreshold": 90
    })

    readonly property var hwMenu: ({
        "spacing": 5,
        "padding": 5,
        "background": {
            "color": bgBase,
            "radius": 14,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },

        // shared card style for every section rectangle
        "section": {
            "width": 250,
            "color": bgBase,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "header": {
                "color": fgBase,
                "spacing": 6,
                "anchors": {
                    "topMargin": 4,
                    "leftMargin": 10
                }
            }
        },

        // per-section sizing
        "disk": {
            "height": 45,
            "radius": 10
        },
        "gpu": {
            "height": 57,
            "radius": 10
        },
        "cpu": {
            "height": 116,
            "radius": 10
        },
        "mem": {
            "height": 116,
            "radius": 10
        },
        "powerProfiles": {
            "height": 35,
            "radius": 10,
            "text": {
                "checkedColor": fgSecondary,
                "normalColor": fgBase,
                "font": {
                    "family": "Scientifica",
                    "pixelSize": 16
                }
            }
        },
        "fanControl": {
            "height": 35,
            "radius": 10,
            "autoSwitchThreshold": 75,
            "text": {
                "checkedColor": fgSecondary,
                "normalColor": fgBase,
                "font": {
                    "family": fontFamily,
                    "pixelSize": 11
                }
            }
        },

        // temperature readouts in section headers
        "temps": {
            "baseColor": fgBase,
            "warningColor": "#e6c200",
            "criticalColor": "#e54545",
            "warningThreshold": 80,
            "criticalThreshold": 90
        },

        // HorizontalStatusBar (disk)
        "bar": {
            "width": 230,
            "height": 15,
            "radius": 3,
            "color": bgBase,
            "barColor": bgSecondary,
            "leftMargin": 5,
            "label": {
                "color": fgSecondary
            },
            "anchors": {
                "topMargin": 5,
                "leftMargin": 10,
                "bottomMargin": 7
            }
        },

        // UsageGraph (gpu, cpu, mem)
        "graph": {
            "width": 230,
            "height": 25,
            "radius": 4,
            "color": bgBase,
            "lineColor": fgBase,
            "fillColor": bgBase,
            "maxSamples": 60,
            "leftMargin": 5,
            "label": {
                "color": fgBase
            },
            "anchors": {
                "topMargin": 5,
                "leftMargin": 10,
                "bottomMargin": 7
            }
        },

        // top-process lists under cpu/mem graphs
        "processes": {
            "anchors": {
                "topMargin": 5,
                "leftMargin": 10,
                "rightMargin": 10,
                "bottomMargin": 4
            },
            "row": {
                "height": 18,
                "spacing": 8,
                "name": {
                    "color": fgBase
                },
                "usage": {
                    "color": fgBase
                }
            }
        },

        // shared button style for powerProfiles and fanControl rows
        "toggleButton": {
            "width": 75,
            "height": 20,
            "background": {
                "radius": 5,
                "checkedColor": bgSecondary,
                "normalColor": bgBase,
                "border": {
                    "width": 2,
                    "color": fgBase
                }
            }
        }
    })


    readonly property var notification: ({
        "color": bgBase,
        "radius": 5,
        "border": {
            "width": 1,
            "color": fgBase
        },
        "accentWidth": 3,
        "accentLeftMargin": 6,
        "padding": {
            "top": 6,
            "left": 15,
            "right": 16,
            "bottom": 6
        },
        "dismiss": {
            "topMargin": 2,
            "rightMargin": 6,
            "normalColor": fgBase,
            "hoverColor": "#e54545",
            "font": {
                "family": fontFamily,
                "pixelSize": 18
            }
        },
        "actionsRow": {
            "spacing": 8
        },
        "action": {
            "height": 18,
            "horizontalPadding": 10,
            "normalColor": bgSecondary,
            "hoverColor": bgBase,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "normalColor": fgSecondary,
                "hoverColor": fgBase,
                "font": {
                    "family": fontFamily,
                    "pixelSize": 11
                }
            }
        },
        "appName": {
            "color": fgBase,
            "font": {
                "family": fontFamily,
                "pixelSize": 11
            }
        },
        "summary": {
            "color": fgBase,
            "font": {
                "family": fontFamily,
                "bold": true
            }
        },
        "body": {
            "color": fgBase,
            "opacity": 0.65,
            "font": {
                "family": fontFamily,
                "pixelSize": 10
            }
        },
        "urgency": {
            "normal": fgBase,
            "critical": "#e54545"
        }
    })

    readonly property var centerMenu: ({
        "spacing": 5,
        "padding": 5,
        "background": {
            "color": bgBase,
            "radius": 14,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "header": {
            "text": {
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 16
                },
            },
            "button": {
                "color": fgBase,
                "hoverTextColor": fgBase
            },
        },
        "notifications": {
            "width": 320,
            "height": 280,
            "color": bgBase,
            "radius": 10,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "empty": {
                "color": fgBase,
                "opacity": 0.45
            }
        },
        "calendar": {
            "width": 320,
            "height": 310,
            "radius": 10,
            "color": bgBase,
            "spacing": 1,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 16
                }
            },
            "navButton": {
                "width": 70,
                "height": 30,
                "color": fgBase,
                "hoverColor": fgBase,
                "hoverTextColor": bgBase,
                "radius": 5
            },
            "selected": {
                "color": fgBase,
                "textColor": bgBase,
                "radius": 5
            },
            "today": {
                "borderColor": fgBase,
                "borderWidth": 2,
            },
            "outOfMonth": {
                "opacity": 0.35
            },
            "dayOfWeek": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": 12,
                },
                "opacity": 0.75,
                "color": fgBase
            },
            "highPriorityTextColor": bgBase
        },
        "upcoming": {
            "width": 320,
            "height": 160,
            "radius": 10,
            "color": bgBase,
            "daysAhead": 10,
            "rowSpacing": 4,
            "padding": 15,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "header": {
                "text": "Upcoming Tasks",
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 16
                }
            },
            "task": {
                "spacing": 8,
                "text": {
                    "color": fgBase,
                    "font": {
                        "family": fontFamily,
                        "pixelSize": 11
                    }
                },
                "days": {
                    "width": 60,
                    "color": fgBase,
                    "font": {
                        "family": fontFamily,
                        "pixelSize": 11
                    }
                }
            },
            "empty": {
                "text": "No upcoming tasks",
                "color": fgBase,
                "opacity": 0.45
            }
        },
        "middlePanel": {
            "height": 280,
            "width": 320,
            "spacing": 15,
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "todoist": {
                "styleOverride": {
                    "task": {
                        "text": {
                            "color": fgBase
                        },
                        "check": {
                            "hoverColor": fgBase
                        }
                    }
                }
            },
            "prayerTimes": {
                "styleOverride": {
                    "row": {
                        "name": {
                            "color": faded(fgBase, 0.75)
                        },
                        "time": {
                            "color": faded(fgBase, 0.75)
                        }
                    },
                    "timerLabel": {
                        "color": fgBase
                    }
                }
            },
            "flip": {
                "duration": 300,
                "button": {
                    "size": 20,
                    "anchors": {
                        "bottomMargin": 10
                    }
                }
            }
        }
    })

    readonly property var soundMenu: ({
        "spacing": 5,
        "padding": 5,
        "background": {
            "color": bgBase,
            "radius": 14,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "section": {
            "color": bgBase,
            "radius": 10,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "anchors": {
                    "topMargin": 4,
                    "leftMargin": 10
                },
                "color": fgBase
            },
            "slider": {
                "anchors": {
                    "bottomMargin": 10,
                    "leftMargin": 10
                },
                "width": 180
            },
            "content": {
                "anchors": {
                    "topMargin": 4,
                    "leftMargin": 10,
                    "rightMargin": 10,
                    "bottomMargin": 10
                },
                "spacing": 6
            }
        },
        "slider": {
            "radius": 2,
            "background": {
                "color": Qt.rgba(bgSecondary.r, bgSecondary.g, bgSecondary.b, 0.1)
            },
            "bar": {
                "color": fgBase
            },
        },
    })

    readonly property var systray: ({
        "spacing": 10,
        "iconSize": 12,
        "tooltip": {
            "delay": 400,
            "timeout": 5000
        }
    })

    readonly property var trayMenu: ({
        "menuPadding": 0,
        "anchor": {
            "margins": {
                "top": 15
            }
        },
        "background": {
            "color": bgBase,
            "border": { "width": 1, "color": fgBase }
        },
        "item": {
            "rowHeight": 26,
            "horizontalPadding": 8,
            "spacing": 0,
            "iconSize": 12,
            "enabledOpacity": 1,
            "disabledOpacity": 0.4,
            "normalTextColor": fgBase,
            "hoverColor": fgBase,
            "hoverTextColor": bgBase,
            "label": {
                "font": { "family": fontFamily}
            },
            "chevron": {
                "font": { "family": fontFamily}
            }
        },
        "separator": {
            "rowHeight": 9,
            "horizontalMargin": 5,
            "line": {
                "color": fgBase,
                "height": 1
            }
        },
    })

    // In-window right-click menus (StyledContextMenu). Same look as trayMenu.
    readonly property var contextMenu: ({
        "menuPadding": 0,
        "spacing": 2,
        "background": {
            "color": bgBase,
            "radius": 0,
            "border": { "width": 1, "color": fgBase }
        },
        "item": {
            "rowHeight": 26,
            "horizontalPadding": 8,
            "spacing": 6,
            "iconSize": 12,
            "enabledOpacity": 1,
            "disabledOpacity": 0.4,
            "normalTextColor": fgBase,
            "hoverColor": fgBase,
            "hoverTextColor": bgBase,
            "label": {
                "font": { "family": fontFamily, "pixelSize": pixelSize }
            }
        },
        "separator": {
            "rowHeight": 9,
            "horizontalMargin": 5,
            "line": {
                "color": fgBase,
                "height": 1
            }
        },
    })

    readonly property var prayerTimes: ({
        "color": "transparent",
        "radius": 0,
        "rowSpacing": 5,
        "pixelSize": 13,
        "date": {
            "font": {
                "family": "Pixel Code Regular",
                "bold": false,
            },
            "color": fgBase
        },
        "row": {
            "name": {
                "font": {
                    "family": "Pixel Code Regular",
                    "bold": false,
                },
                "color": fgSecondary
            },
            "time": {
                "font": {
                    "family": "Pixel Code Regular",
                    "bold": false,
                },
                "color": fgSecondary
            },
            "active": {
                "name": {
                    "font": {
                        "family": "Pixel Code Regular",
                        "bold": true,
                    },
                    "color": fgBase
                },
                "time": {
                    "font": {
                        "family": "Pixel Code Regular",
                        "bold": true,
                    },
                    "color": fgBase
                }
            }
        },
        "empty": {
            "text": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                },
                "color": faded(fgBase, 0.45)
            }
        },
        "error": {
            "text": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                },
                "color": "#e54545"
            }
        },
        "timer": {
            "topMargin": 5,
            "font": {
                "family": "Pixel Code Regular",
                "pixelSize": 22,
                "bold": true
            },
            "color": fgBase
        },
        "timerLabel": {
            "font": {
                "family": "Pixel Code Regular",
                "pixelSize": 12,
                "bold": false
            },
            "color": fgSecondary
        }
    })

    readonly property var todoist: ({
        "color": "transparent",
        "radius": 0,
        "rowSpacing": 10,
        "taskMaxWidth": 320,
        "task": {
            "text": {
                "font": {
                    "family": "CozetteVector",
                    "bold": false,
                    "pixelSize": 19
                },
                "color": fgSecondary,
            },
            "check": {
                "font": {
                    "family": fontFamily,
                    "bold": false,
                    "pixelSize": 14
                },
                "hoverColor": bgBase
            }
        },
        "empty": {
            "text": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                },
                "color": faded(fgBase, 0.45)
            }
        },
        "error": {
            "text": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                },
                "color": "#e54545"
            }
        },
        "priority": {
            "p1": "#e54545",
            "p2": "#e6a032",
            "p3": "#5b8fd4",
            "p4": faded(fgBase, 0.22)
        }
    })

    readonly property var wallpaper: ({
        "tasks": {
            "widthPadding": 30,
            "heightPadding": 65,
            "color": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.70),
            "radius": 10,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "anchors": {
                "topMargin": 50,
                "leftMargin": 15
            },
            "header": {
                "text": "TO DO:",
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 22,
                    "bold": false
                },
                "color": fgBase,
                "anchors": {
                    "topMargin": 10,
                    "leftMargin": 15
                }
            },
            "todoist": {
                "anchors": {
                    "verticalCenterOffset": 18
                },
                "styleOverride": {
                    "rowSpacing": 20,
                    "taskMaxWidth": 300,
                    "task": {
                        "text": {
                            "font": {
                                "pixelSize": 22,
                                "family": "Silkscreen",
                            },
                            "color": fgBase
                        },
                        "check": {
                            "font": {
                                "pixelSize": 20
                            },
                        }
                    }
                }
            }
        },
        "clock": {
            "color": "transparent",
            "radius": 0,
            "text": {
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 200,
                    "bold": false
                },
                "color": fgBase
            },
            "shadow": {
                "color": Qt.rgba(0, 0, 0, 1),
                "opacity": 0.65,
                "blur": 0.55,
                "horizontalOffset": 0,
                "verticalOffset": 4
            }
        },
        "media": {
            "width": 800,
            "height": 300,
            "color": "transparent",
            "controls": {
                "spacing": 40,
                "bottomOffset": 40
            },
            "titleMaxLength": 75,
            "artistMaxLength": 75,
            "anchors": {
                "bottomMargin": 60,
                "rightMargin": 60
            },
            "text": {
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 15,
                    "bold": false
                },
                "color": fgBase
            },
            "button": {
                "size": 45,
                "radius": 25,
                "normalColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.0),
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
                "pressedColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.2),
                "iconSize": 16,
                "iconColor": fgBase,
                "iconHoverColor": fgBase,
                "iconPressedColor": fgBase,
                "shadow": {
                    "color": Qt.rgba(0, 0, 0, 1),
                    "opacity": 0.65,
                    "blur": 0.55,
                    "horizontalOffset": 0,
                    "verticalOffset": 4,
                    "pressedVerticalOffset": 1
                }
            },
            "cava": {
                "barCount": 70,
                "barColor": Qt.rgba(bgSecondary.r, bgSecondary.g, bgSecondary.b, 0.75),
                "confPath": "wallpaper.conf",
                "bars": {
                    "spacing": 1
                }
            },
            "slider": {
                "radius": 2,
                "background": {
                    "color": fgBase
                },
                "bar": {
                    "color": bgBase
                },
                "handle": {
                    "color": fgBase
                }
            },
            "seekSlider": {
                "implicitHeight": 6
            },
        },
        "lyrics": {
            "height": 150,
            "padding": 0,
            "anchors": {
                "topMargin": 60,
                "rightMargin": 60
            },
            "text": {
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 22,
                    "bold": false
                },
                "color": fgBase
            },
            "inactiveColor": faded(fgBase, 0.75),
            "background": {
                "color": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.75),
                "radius": 10,
                "visible": true,
                "opacity": 1,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            }
        }
    })

    readonly property var keyboard: ({
        "halfGap": 300,
        "keySize": 70,
        "keyGap": 5,
        "splay": 0,
        "key": {
            "radius": 5,
            "color": bgBase,
            "pressedColor": fgBase,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 22,
                    "bold": false
                },
                "color": fgBase,
                "pressedColor": fgSecondary,
                "pressedBold": false
            },
            "hold": {
                "font": {
                    "family": "silkscreen",
                    "pixelSize": 15,
                    "bold": false
                },
                "color": fgBase,
                "pressedColor": faded(fgSecondary, 0.75)
            },
            "icon": {
                "font": {
                    "family": "FiraCode Nerd Font Mono",
                    "pixelSize": 32,
                    "bold": false
                },
                "holdPixelSize": 26
            }
        }
    })

    readonly property var wallpaperGallery: ({
        "windowWidth": 1800,
        "windowHeight": 1000,
        "sidebarWidth": 250,
        "previewWidth": 360,
        "headerHeight": 28,
        "thumbMin": 160,
        "padding": 5,
        "spacing": 5,
        "background": {
            "color": bgBase,
            "radius": 14,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "title": {
            "color": "transparent",
            "text": {
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 16,
                    "bold": false
                },
                "color": fgBase
            }
        },
        "search": {
            "color": bgBase,
            "radius": 5,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase,
                "placeholder": faded(fgBase, 0.45)
            }
        },
        "sidebar": {
            "color": bgBase,
            "radius": 10,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "folder": {
            "height": 22,
            "indent": 12,
            "radius": 5,
            "normalColor": "transparent",
            "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.12),
            "selectedColor": fgBase,
            "text": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase,
                "selectedColor": bgBase
            },
            "count": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase,
                "selectedColor": bgBase
            }
        },
        "grid": {
            "color": bgBase,
            "radius": 10,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "thumb": {
            "color": bgBase,
            "radius": 5,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "selectedBorder": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase
            },
            "badge": {
                "color": bgBase,
                "radius": 5,
                "text": {
                    "font": {
                        "family": fontFamily,
                        "pixelSize": pixelSize
                    },
                    "color": fgBase
                }
            }
        },
        "preview": {
            "color": bgBase,
            "radius": 10,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "frame": {
                "color": bgBase,
                "radius": 5,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "text": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase
            },
            "muted": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase
            }
        },
        "chip": {
            "height": 20,
            "horizontalPadding": 8,
            "radius": 5,
            "normalColor": bgBase,
            "hoverColor": Qt.rgba(
                bgBase.r * 0.8 + fgBase.r * 0.2,
                bgBase.g * 0.8 + fgBase.g * 0.2,
                bgBase.b * 0.8 + fgBase.b * 0.2,
                1
            ),
            "selectedColor": fgBase,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase,
                "selectedColor": bgBase
            }
        },
        "slider": {
            "radius": 2,
            "background": {
                "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1)
            },
            "bar": {
                "color": fgBase
            },
            "handle": {
                "color": fgBase
            }
        },
        "button": {
            "height": 24,
            "radius": 5,
            "normalColor": bgBase,
            "hoverColor": Qt.rgba(
                bgBase.r * 0.8 + fgBase.r * 0.2,
                bgBase.g * 0.8 + fgBase.g * 0.2,
                bgBase.b * 0.8 + fgBase.b * 0.2,
                1
            ),
            "pressedColor": fgBase,
            "border": {
                "width": 1,
                "color": fgBase
            },
            "text": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "color": fgBase,
                "pressedColor": bgBase
            }
        }
    })

    readonly property var mpdClient: ({
        "windowWidth": 1800,
        "windowHeight": 1000,
        "padding": 5,
        "spacing": 5,
        "background": {
            "color": bgBase,
            "radius": 14,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "nav": {
            "width": 140,
            "padding": 8,
            "spacing": 4,
            "headerHeight": 24,
            "header": {
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 12,
                    "bold": false
                }
            },
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "item": {
                "height": 28,
                "radius": 5,
                "padding": 10,
                "normalColor": "transparent",
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.08),
                "selectedColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.16),
                "border": {
                    "width": 0,
                    "color": "transparent"
                },
                "text": {
                    "font": {
                        "family": "Silkscreen",
                        "pixelSize": 12,
                        "bold": false
                    },
                    "color": fgBase,
                    "selectedColor": fgBase
                }
            }
        },
        "info": {
            "width": 280,
            "padding": 10,
            "spacing": 8,
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "cover": {
                "radius": 8,
                "placeholder": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "label": {
                "color": faded(fgBase, 0.55),
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize,
                    "bold": false
                }
            },
            "value": {
                "color": fgBase,
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize,
                    "bold": false
                }
            },
            "name": {
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 12,
                    "bold": false
                }
            },
            "muted": {
                "color": faded(fgBase, 0.45),
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                }
            }
        },
        "content": {
            "padding": 8,
            "spacing": 4,
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "search": {
                "height": 26,
                "padding": 8,
                "color": fgBase,
                "placeholderColor": faded(fgBase, 0.45),
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "background": {
                    "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.06),
                    "radius": 5,
                    "border": {
                        "width": 1,
                        "color": fgBase
                    }
                }
            },
            "list": {
                "spacing": 2,
                "headerHeight": 24,
                "header": {
                    "color": fgBase,
                    "font": {
                        "family": "Silkscreen",
                        "pixelSize": 12,
                        "bold": false
                    }
                },
                "muted": {
                    "color": faded(fgBase, 0.45),
                    "font": {
                        "family": fontFamily,
                        "pixelSize": pixelSize
                    }
                },
                "column": {
                    "color": "transparent",
                    "radius": 8,
                    "border": {
                        "width": 1,
                        "color": fgBase
                    }
                },
                "item": {
                    "height": 26,
                    "radius": 5,
                    "padding": 8,
                    "normalColor": "transparent",
                    "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.08),
                    "selectedColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.16),
                    "border": {
                        "width": 0,
                        "color": "transparent"
                    },
                    "text": {
                        "font": {
                            "family": fontFamily,
                            "pixelSize": pixelSize,
                            "bold": false
                        },
                        "color": fgBase,
                        "selectedColor": fgBase
                    }
                }
            }
        },
        "playerBar": {
            // height = cover.height + padding * 2
            "height": 120,
            "padding": 12,
            "spacing": 12,
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "cover": {
                "width": 96,
                "height": 96,
                "radius": 5,
                "border": {
                    "width": 1,
                    "color": fgBase
                },
                "mask": {
                    "color": fgBase
                },
                "placeholder": {
                    "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1)
                }
            },
            "controls": {
                "spacing": 40
            },
            "toggle": {
                "size": 28,
                "radius": 14,
                "iconSize": 18,
                "spacing": 20,
                "normalColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.0),
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
                "pressedColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.2),
                "offColor": faded(fgBase, 0.55),
                "onColor": fgBase,
                "shadow": {
                    "color": Qt.rgba(0, 0, 0, 1),
                    "opacity": 0.35,
                    "blur": 0.4,
                    "horizontalOffset": 0,
                    "verticalOffset": 2,
                    "pressedVerticalOffset": 1
                }
            },
            "text": {
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 12,
                    "bold": false
                },
                "color": fgBase,
                "spacing": 2,
                "bottomMargin": 5
            },
            "time": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize,
                    "bold": false
                },
                "color": fgBase
            },
            "meta": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize,
                    "bold": false
                },
                "color": faded(fgBase, 0.7),
                "spacing": " · ",
                "rightMargin": 12,
                "maxChars": 18
            },
            "lyrics": {
                "font": {
                    "family": fontFamily,
                    "pixelSize": 11,
                    "bold": false
                },
                "color": fgBase,
                "topMargin": 10,
                "rightMargin": 32,
                // queueToggle.size; media row: 28+20+45+40+45+40+45+20+28
                "minHeight": 26,
                "minWidth": 311,
                "radius": 6,
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1)
            },
            "queueToggle": {
                "size": 26,
                "color": faded(fgBase, 0.55),
                "activeColor": fgBase,
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
                "radius": 6,
                "font": {
                    "family": fontFamily,
                    "pixelSize": 24
                }
            },
            "easyeffects": {
                "height": 26,
                "margin": 16,
                "padding": 8,
                "radius": 6,
                "maxWidth": 120,
                "color": faded(fgBase, 0.7),
                "activeColor": fgBase,
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "menu": {
                    "width": 140,
                    "padding": 4,
                    "spacing": 2,
                    "itemHeight": 24,
                    "radius": 8,
                    "background": bgBase,
                    "border": {
                        "width": 1,
                        "color": fgBase
                    },
                    "itemHoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
                    "itemActiveColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.16)
                }
            },
            "button": {
                "size": 45,
                "radius": 25,
                "normalColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.0),
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1),
                "pressedColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.2),
                "iconSize": 16,
                "iconColor": fgBase,
                "iconHoverColor": fgBase,
                "iconPressedColor": fgBase,
                "shadow": {
                    "color": Qt.rgba(0, 0, 0, 1),
                    "opacity": 0.55,
                    "blur": 0.5,
                    "horizontalOffset": 0,
                    "verticalOffset": 3,
                    "pressedVerticalOffset": 1
                }
            },
            "slider": {
                "radius": 2,
                "background": {
                    "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.1)
                },
                "bar": {
                    "color": fgBase
                },
                "handle": {
                    "color": fgBase
                }
            },
            "volumeSlider": {
                "implicitWidth": 6
            },
            "seekSlider": {
                "implicitHeight": 6
            }
        },
        "queue": {
            "widthRatio": 0.3,
            "height": 280,
            "padding": 8,
            "spacing": 2,
            "headerHeight": 22,
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "header": {
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 12,
                    "bold": false
                }
            },
            "item": {
                "height": 36,
                "radius": 5,
                "padding": 8,
                "normalColor": "transparent",
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.08),
                "currentColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.16),
                "text": {
                    "color": fgBase,
                    "currentColor": fgBase,
                    "font": {
                        "family": "Silkscreen",
                        "pixelSize": 12,
                        "bold": false
                    }
                },
                "muted": {
                    "color": faded(fgBase, 0.55),
                    "font": {
                        "family": fontFamily,
                        "pixelSize": pixelSize
                    }
                }
            },
            "remove": {
                "size": 28,
                "color": faded(fgBase, 0.7),
                "activeColor": fgBase,
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.15),
                "font": {
                    "family": fontFamily,
                    "pixelSize": 20
                }
            },
            "clear": {
                "height": 22,
                "padding": 8,
                "radius": 5,
                "color": faded(fgBase, 0.7),
                "activeColor": fgBase,
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.12),
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                }
            }
        },
        "lyricsPanel": {
            "widthRatio": 0.32,
            "height": 280,
            "padding": 8,
            "spacing": 2,
            "headerHeight": 22,
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "header": {
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 12,
                    "bold": false
                }
            },
            "item": {
                "height": 28,
                "radius": 5,
                "padding": 8,
                "normalColor": "transparent",
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.08),
                "currentColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.12),
                "text": {
                    "color": faded(fgBase, 0.55),
                    "activeColor": fgBase,
                    "activeBold": false,
                    "font": {
                        "family": fontFamily,
                        "pixelSize": pixelSize,
                        "bold": false
                    }
                }
            }
        },
        "prompt": {
            "width": 360,
            "padding": 16,
            "spacing": 10,
            "scrim": {
                "color": Qt.rgba(0, 0, 0, 0.45)
            },
            "background": {
                "color": bgBase,
                "radius": 10,
                "border": {
                    "width": 1,
                    "color": fgBase
                }
            },
            "title": {
                "color": fgBase,
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 12
                }
            },
            "input": {
                "color": fgBase,
                "placeholderColor": faded(fgBase, 0.45),
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                },
                "background": {
                    "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.06),
                    "radius": 5,
                    "border": {
                        "width": 1,
                        "color": fgBase
                    }
                }
            },
            "button": {
                "height": 28,
                "radius": 5,
                "normalColor": "transparent",
                "hoverColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.12),
                "activeColor": fgBase,
                "textColor": fgBase,
                "activeTextColor": bgBase,
                "border": {
                    "width": 1,
                    "color": fgBase
                },
                "font": {
                    "family": fontFamily,
                    "pixelSize": pixelSize
                }
            }
        }
    })
}
