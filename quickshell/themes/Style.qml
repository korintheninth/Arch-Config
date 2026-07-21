// theme/Styles.qml
pragma Singleton
import "../services"
import QtQuick
import Quickshell

Singleton {
    readonly property color bgBase: Colors.color1
    readonly property color bgSecondary: Colors.color2
    readonly property color fgBase: Colors.color6
    readonly property color fgSecondary: Colors.color5
    readonly property string fontFamily: "Departure Mono"
    readonly property double pixelSize: 11

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
        }
    })

    readonly property var mediaMenu: ({
        "menuWidth": 601,
        "menuHeight": 225,
        "controlsSpacing": 20,
        "controlsBottomOffset": 35,
        "cavaColor": fgBase,
        "button": {
            "size": 50,
            "radius": 25,
            "normalColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.2),
            "hoverColor": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.5),
            "pressedColor": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.2),
            "iconSize": 16,
            "iconColor": fgBase,
            "iconHoverColor": bgBase,
            "iconPressedColor": fgBase,
        },
        "background": {
            "color": bgBase,
            "radius": 0,
            "border": {
                "width": 1,
                "color": fgBase,
            },
        },
        "text": {
            "font": {
                "family": "Pixel Code",
                "pixelSize": 15,
                "bold": false
            },
            "color": fgBase
        },
        "cover": {
            "width": 96,
            "height": 96,
            "coverRadius": 0,
            "coverBorderWidth": 1,
            "coverBorderColor": fgBase,
            "anchors": {
                "leftMargin": 30,
                "topMargin": 15
            },
            "mask": {
                "color": fgBase
            }
        },
        "cava": {
            "width": 601,
            "height": 65,
            "bars": {
                "anchors": {
                    "bottomMargin": 0
                }
            },
            "barCount": 70,
            "barColor": Qt.rgba(fgSecondary.r, fgSecondary.g, fgSecondary.b, 0.8),
            "confPath": "wallpaper.conf"
        },
        "slider": {
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
        "volumeSlider": {
            "implicitWidth": 6,
            "implicitHeight": 96,
            "anchors": {
                "leftMargin": 15,
                "topMargin": 20
            }
        },
        "seekSlider": {
            "implicitWidth": 550,
            "implicitHeight": 6,
            "anchors": {
                "bottomMargin": 65
            }
        },
        "ytmusic": {
            "width": 36,
            "height": 36,
            "anchors": {
                "bottomMargin": 10,
                "rightMargin": 10
            },
            "background": {
                "visible": false
            },
            "icon": {
                "width": 32,
                "height": 32
            }
        },
        "lyrics": {
            "height": 96,
            "spacing": 5,
            "inactiveColor": fgSecondary,
            "background": {
                "anchors": {
                    "horizontalCenterOffset": 63,
                    "verticalCenterOffset": -50
                },
                "color": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.75),
                "radius": 0,
                "visible": true,
                "height": 96,
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

    readonly property var workspaces: ({
        "buttonWidth": 14,
        "spacing": 0,
        "background": {
            "color": "transparent",
            "radius": 0
        },
        "button": {
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
        "enabled": true,
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
            "color": fgBase
        },
        "text": {
            "font": {
                "family": fontFamily,
                "bold": false
            },
            "color": fgBase
        },
        "mutedIcon": "󰝟" ,
        "wiredIcons": ["", " ", ""],
        "bluetoothIcons": [" ", " ", " "]
    })

    readonly property var battery: ({
        "color": "transparent",
        "radius": 0,
        "icon": {
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
        "criticalColor": "#e54545",
        "chargingIcons": [" ", " ", " ", " ", " "],
        "dischargingIcons": ["", "", "", "", ""]
    })

    readonly property var updates: ({
        "color": "transparent",
        "radius": 0,
        "icon": {
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
        "iconGlyph": "",
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
        "temps": {
            "color": bgSecondary,
            "width": 250,
            "height": 25,
            "border": {
                "width": 2,
                "color": bgBase
            },
            "text": {
                "anchors": {
                    "topMargin": 5,
                    "leftMargin": 10
                },
            },
            "baseColor": fgBase,
            "warningColor": "#e6c200",
            "criticalColor": "#e54545",
            "warningThreshold": 80,
            "criticalThreshold": 90
        },
        "bars": {
            "color": bgSecondary,
            "height": 45,
            "width": 250,
            "border": {
                "width": 2,
                "color": bgBase
            },
            "text": {
                "anchors": {
                    "topMargin": 4,
                    "leftMargin": 10
                },
                "color": fgBase
            },
            "bar": {
                "width": 230,
                "height": 15,
                "leftMargin": 5,
                "anchors": {
                    "bottomMargin": 7,
                    "leftMargin": 10,
                    "topMargin": 5,
                },
                "label": {
                    "color": fgBase
                },
                "color": fgSecondary,
                "barColor": bgBase
            },
            "withProcessesHeight": 105,
            "processes": {
                "list": {
                    "anchors": {
                        "topMargin": 5,
                        "leftMargin": 10,
                        "rightMargin": 10,
                        "bottomMargin": 4
                    }
                },
                "row": {
                    "height": 18,
                    "name": {
                        "color": fgBase
                    },
                    "pid": {
                        "color": fgSecondary
                    },
                    "usage": {
                        "color": fgBase
                    }
                }
            }

        },
        "powerProfiles": {
            "color": bgSecondary,
            "height": 45,
            "width": 250,
            "border": {
                "width": 2,
                "color": bgBase
            },
            "text": {
                "color": fgBase,
                "anchors": {
                    "topMargin": 3,
                    "leftMargin": 10
                }
            },
            "buttonRow": {
                "height": 20,
                "width": 250,
                "buttonWidth": 75,
                "buttonHeight": 20,
                "anchors":{
                    "bottomMargin": 5,
                },
                "button": {
                    "text": {
                        "color": bgBase,
                        "font":{
                            "family": "Scientifica",
                            "pixelSize": "16"
                        } 
                    },
                    "icon": {
                        "radius": 5,
                        "checkedColor": fgSecondary,
                        "normalColor": bgSecondary,
                        "border": {
                            "color": bgBase,
                            "width": 2,
                        },
                    },
                },
            },
        }
    })


    readonly property var centerMenu: ({
        "panelWidth": 250,
        "panelHeight": 250,
        "background": {
            "color": bgBase,
            "border": {
                "width": 1,
                "color": fgBase
            }
        },
        "notifications": {
            "color": bgSecondary,
            "border": {
                "width": 2,
                "color": bgBase
            },
            "header": {
                "text": {
                    "color": fgSecondary,
                    "font": {
                        "family": fontFamily,
                    }
                },
                "clear": {
                    "color": fgBase,
                    "hoverColor": bgBase,
                    "hoverTextColor": bgSecondary
                }
            },
            "item": {
                "color": bgSecondary,
                "border": {
                    "width": 1,
                    "color": bgBase
                },
                "accentWidth": 3,
                "padding": {
                    "top": 6,
                    "left": 12,
                    "right": 16,
                    "bottom": 6
                },
                "dismiss": {
                    "normalColor": fgBase,
                    "hoverColor": "#e54545",
                    "font": {
                        "family": fontFamily,
                        "pixelSize": 12
                    }
                },
                "actionsRow": {
                    "spacing": 4
                },
                "action": {
                    "height": 18,
                    "horizontalPadding": 6,
                    "normalColor": bgBase,
                    "hoverColor": fgBase,
                    "border": {
                        "width": 1,
                        "color": bgBase
                    },
                    "text": {
                        "normalColor": fgBase,
                        "hoverColor": bgSecondary,
                        "font": {
                            "family": fontFamily,
                            "pixelSize": 9
                        }
                    }
                },
                "appName": {
                    "color": bgBase,
                    "font": {
                        "family": fontFamily,
                        "pixelSize": 10
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
                    "normal": bgBase,
                    "critical": "#e54545"
                }
            },
            "empty": {
                "color": fgBase,
                "opacity": 0.45
            }
        },
        "placeholder": {
            "color": bgSecondary,
            "border": {
                "width": 2,
                "color": bgBase
            }
        },
        "calendar": {
            "color": bgSecondary,
            "border": {
                "width": 2,
                "color": bgBase
            },
            "buttonWidth": 70,
            "buttonHeight": 30,
            "text": {
                "color": fgBase,
                "font": {
                    "family": fontFamily
                }
            },
            "navButton": {
                "color": fgBase,
                "hoverColor": bgBase,
                "hoverTextColor": bgSecondary
            },
            "selected": {
                "color": bgBase,
                "textColor": bgSecondary
            },
            "today": {
                "borderColor": fgBase,
                "borderWidth": 2
            },
            "outOfMonth": {
                "opacity": 0.35
            },
            "dayOfWeek": {
                "font": {
                    "family": "Silkscreen",
                    "pixelSize": 14
                },
                "color": fgBase
            },
            "taskDueTextColor": bgSecondary
        }
    })

    readonly property var soundMenu: ({
        "text": {
            "color": bgBase
        },
        "background": {
            "color": "transparent"
        },
        "section": {
            "color": bgSecondary,
            "border": {
                "width": 2,
                "color": bgBase
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
            "background": {
                "color": fgSecondary
            },
            "bar": {
                "color": bgBase
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

    readonly property var prayerTimes: ({
        "color": "transparent",
        "radius": 0,
        "rowSpacing": 5,
        "maxWidth": 230,
        "pixelSize": 11,
        "date": {
            "font": {
                "family": fontFamily,
                "bold": false,
            },
            "color": fgBase
        },
        "row": {
            "name": {
                "font": {
                    "family": fontFamily,
                    "bold": false,
                },
                "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.55)
            },
            "time": {
                "font": {
                    "family": fontFamily,
                    "bold": false,
                },
                "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.55)
            },
            "active": {
                "name": {
                    "font": {
                        "family": fontFamily,
                        "bold": true,
                    },
                    "color": fgBase
                },
                "time": {
                    "font": {
                        "family": fontFamily,
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
                "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.45)
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
                    "family": fontFamily,
                    "bold": false
                },
                "color": fgBase
            },
            "due": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                },
                "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.55)
            },
            "check": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                },
                "hoverColor": bgBase,
                "normalColor": fgBase,
                "doneColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.35)
            }
        },
        "empty": {
            "text": {
                "font": {
                    "family": fontFamily,
                    "bold": false
                },
                "color": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.45)
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
            "p4": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.22)
        }
    })

    readonly property var wallpaper: ({
        "tasks": {
            "widthPadding": 30,
            "heightPadding": 65,
            "color": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.70),
            "radius": 10,
            "anchors": {
                "topMargin": 50,
                "leftMargin": 50
            },
            "header": {
                "text": "Today's Tasks:",
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
                                "family": "Silkscreen"
                            }
                        },
                        "check": {
                            "font": {
                                "pixelSize": 20
                            }
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
            }
        },
        "media": {
            "width": 800,
            "height": 300,
            "color": "transparent",
            "controlsSpacing": 20,
            "controlsBottomOffset": 35,
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
                "size": 50,
                "radius": 25,
                "normalColor": Qt.rgba(fgBase.r, fgBase.g, fgBase.b, 0.2),
                "hoverColor": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.5),
                "pressedColor": Qt.rgba(bgBase.r, bgBase.g, bgBase.b, 0.2),
                "iconSize": 16,
                "iconColor": fgBase,
                "iconHoverColor": bgBase,
                "iconPressedColor": fgBase
            },
            "cava": {
                "barCount": 70,
                "barColor": Qt.rgba(bgSecondary.r, bgSecondary.g, bgSecondary.b, 0.6),
                "confPath": "wallpaper.conf",
                "bars": {
                    "spacing": 1
                }
            },
            "slider": {
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
            "height": 200,
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
            "inactiveColor": fgSecondary,
        }
    })
}
