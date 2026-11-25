import io

from PIL import Image, ImageOps


def load_image(data: bytes) -> Image.Image:
    """Open image bytes, fix phone rotation, and return RGBA (with transparency)."""
    image = Image.open(io.BytesIO(data))
    image = ImageOps.exif_transpose(image)
    return image.convert("RGBA")


def on_white(image: Image.Image) -> Image.Image:
    """Paste an RGBA image onto a white background and return plain RGB."""
    background = Image.new("RGBA", image.size, (255, 255, 255, 255))
    return Image.alpha_composite(background, image).convert("RGB")