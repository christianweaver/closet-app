//
//  TagOptions.swift
//  ClosetApp
//
//  Created by Christian Weaver on 11/26/26.
//

import Foundation

/// The tag values the editor offers.
/// Keep in sync with the backend: app/ml/colors.py (color names) and
/// STYLE_TERMS in app/ml/tagger.py.
enum TagOptions {
    static let colors = [
        "black", "white", "gray", "navy", "blue", "light blue",
        "red", "burgundy", "pink", "orange", "yellow",
        "olive", "green", "brown", "beige", "purple",
    ]

    static let styles = [
        "casual", "streetwear", "formal", "business casual",
        "athletic", "minimal", "vintage", "preppy",
    ]
}
