.pragma library

function apply(target, styleData) {
    if (!target || !styleData) return;

    for (let key in styleData) {
        let value = styleData[key];
        
        // Check if the property is a nested object (like 'border' or 'font')
        if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
            // Check if the target actually has this nested object (e.g., target.border)
            if (target[key] !== undefined) {
                // Recursively apply the nested properties
                apply(target[key], value);
            }
        } else if (target[key] !== undefined) {
            // Apply flat properties only when the target already has them
            target[key] = Qt.binding(function() { return styleData[key]; });
        }
    }
}