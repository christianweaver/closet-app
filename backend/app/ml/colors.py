import colorsys
from collections import defaultdict

import numpy as np
from PIL import Image
from sklearn.cluster import KMeans

N_CLUSTERS = 6
MIN_ALPHA = 250     # only fully opaque pixels; cutout edges are blended with the background
MIN_SHARE = 0.08    # a color must cover at least 8% of the item
MAX_COLORS = 3


def color_name(rgb: tuple[float, float, float]) -> str:
    """Name a color using hue / saturation / brightness rules instead of RGB distance."""
    r, g, b = (float(c) / 255 for c in rgb)
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    hue = h * 360

    if v < 0.20:                       # too dark to judge hue reliably
        return "black"
    if s < 0.18:                       # barely colorful → a neutral
        if v > 0.70:
            return "white"
        if v < 0.35:
            return "black"
        return "gray"
    if 190 <= hue < 255:               # blues
        if v < 0.40:
            return "navy"
        if v > 0.75 and s < 0.45:
            return "light blue"
        return "blue"
    if hue < 15 or hue >= 340:         # reds
        if v < 0.45:
            return "burgundy"
        if v > 0.75 and s < 0.45:
            return "pink"
        return "red"
    if hue < 45:                       # oranges and browns
        if v < 0.55:
            return "brown"
        if s < 0.45:
            return "beige"
        return "orange"
    if hue < 70:                       # yellows
        return "olive" if v < 0.55 else "yellow"
    if hue < 190:                      # greens
        return "olive" if v < 0.45 else "green"
    if hue < 290:
        return "purple"
    return "pink"


def color_clusters(image: Image.Image) -> list[tuple[tuple[float, float, float], float]]:
    """k-means over the opaque pixels. Returns (rgb_center, share), biggest first."""
    small = image.copy()
    small.thumbnail((128, 128))

    pixels = np.asarray(small).reshape(-1, 4)
    opaque = pixels[pixels[:, 3] >= MIN_ALPHA][:, :3].astype(np.float32)
    if len(opaque) < N_CLUSTERS:
        return []

    kmeans = KMeans(n_clusters=N_CLUSTERS, n_init=10, random_state=0).fit(opaque)
    shares = np.bincount(kmeans.labels_, minlength=N_CLUSTERS) / len(opaque)
    return [
        (tuple(kmeans.cluster_centers_[i]), float(shares[i]))
        for i in np.argsort(-shares)
    ]


def color_breakdown(image: Image.Image) -> list[tuple[str, float]]:
    """Color names with their combined share of the item, biggest first."""
    totals: dict[str, float] = defaultdict(float)
    for rgb, share in color_clusters(image):
        totals[color_name(rgb)] += share
    ranked = sorted(totals.items(), key=lambda kv: -kv[1])
    return [(name, share) for name, share in ranked if share >= MIN_SHARE]


def dominant_colors(image: Image.Image) -> list[str]:
    return [name for name, _ in color_breakdown(image)[:MAX_COLORS]]