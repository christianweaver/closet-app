import logging
import time
from dataclasses import dataclass, field

import open_clip
import torch
from PIL import Image

from app.models import Category

logger = logging.getLogger(__name__)

MODEL_NAME = "ViT-B-32"
PRETRAINED = "laion2b_s34b_b79k"

TEMPLATES = ["a photo of {}.", "a product photo of {}."]

CATEGORY_TERMS: dict[Category, list[str]] = {
    "top": ["a t-shirt", "a shirt", "a sweater", "a hoodie", "a blouse", "a tank top"],
    "bottom": ["a pair of pants", "a pair of jeans", "a pair of shorts", "a skirt", "a pair of sweatpants"],
    "shoes": ["a pair of sneakers", "a pair of boots", "a pair of dress shoes", "a pair of sandals"],
    "outerwear": ["a jacket", "a coat", "a puffer jacket", "a denim jacket"],
    "accessory": ["a hat", "a bag", "a belt", "a scarf", "a pair of sunglasses", "a watch"],
}

STYLE_TERMS: dict[str, list[str]] = {
    "casual": ["casual clothing"],
    "streetwear": ["streetwear", "urban streetwear clothing"],
    "formal": ["formal clothing", "formal wear"],
    "business casual": ["business casual clothing"],
    "athletic": ["athletic sportswear", "gym clothing"],
    "minimal": ["minimalist clothing"],
    "vintage": ["vintage clothing", "retro clothing"],
    "preppy": ["preppy clothing"],
}

CATEGORY_MIN_CONFIDENCE = 0.40  # below this, leave category unknown and let the user decide
STYLE_MIN_PROBABILITY = 0.20
MAX_STYLES = 2


@dataclass
class TagResult:
    category: Category | None
    category_confidence: float
    style_tags: list[str]
    embedding: list[float]
    category_probs: dict[str, float] = field(default_factory=dict)


class ClipModel:
    def __init__(self) -> None:
        model, _, preprocess = open_clip.create_model_and_transforms(
            MODEL_NAME, pretrained=PRETRAINED
        )
        model.eval()
        self.model = model
        self.preprocess = preprocess
        self.tokenizer = open_clip.get_tokenizer(MODEL_NAME)
        self.logit_scale = model.logit_scale.exp().item()

        # Computed once: one averaged text embedding per label.
        self.category_names, self.category_embs = self._label_embeddings(CATEGORY_TERMS)
        self.style_names, self.style_embs = self._label_embeddings(STYLE_TERMS)

    @torch.no_grad()
    def embed_image(self, image: Image.Image) -> torch.Tensor:
        """Return a normalized 512-number embedding for one RGB image."""
        batch = self.preprocess(image).unsqueeze(0)    # [1, 3, 224, 224]
        features = self.model.encode_image(batch)      # [1, 512]
        features = features / features.norm(dim=-1, keepdim=True)
        return features[0]                             # [512]

    @torch.no_grad()
    def embed_texts(self, texts: list[str]) -> torch.Tensor:
        """Return normalized embeddings, shape [len(texts), 512]."""
        features = self.model.encode_text(self.tokenizer(texts))
        return features / features.norm(dim=-1, keepdim=True)

    @torch.no_grad()
    def _label_embeddings(self, terms_by_label: dict[str, list[str]]) -> tuple[list[str], torch.Tensor]:
        names: list[str] = []
        rows: list[torch.Tensor] = []
        for label, terms in terms_by_label.items():
            prompts = [template.format(term) for term in terms for template in TEMPLATES]
            mean = self.embed_texts(prompts).mean(dim=0)   # average all prompts for this label
            rows.append(mean / mean.norm())                # re-normalize to length 1
            names.append(label)
        return names, torch.stack(rows)                    # [num_labels, 512]

    @torch.no_grad()
    def tag(self, image: Image.Image) -> TagResult:
        """Tag one RGB image (already placed on a white background)."""
        emb = self.embed_image(image)                                          # [512]

        category_probs = (self.logit_scale * self.category_embs @ emb).softmax(dim=0)
        best = int(category_probs.argmax())
        confidence = float(category_probs[best])
        category = self.category_names[best] if confidence >= CATEGORY_MIN_CONFIDENCE else None

        style_probs = (self.logit_scale * self.style_embs @ emb).softmax(dim=0)
        ranked = sorted(zip(self.style_names, style_probs.tolist()), key=lambda pair: -pair[1])
        styles = [name for name, p in ranked[:MAX_STYLES] if p >= STYLE_MIN_PROBABILITY]
        if not styles:
            styles = [ranked[0][0]]   # always suggest at least one style

        return TagResult(
            category=category,
            category_confidence=confidence,
            style_tags=styles,
            embedding=emb.tolist(),
            category_probs=dict(zip(self.category_names, category_probs.tolist())),
        )


_model: ClipModel | None = None


def load_model() -> None:
    global _model
    start = time.perf_counter()
    _model = ClipModel()
    logger.info("Loaded CLIP %s (%s) in %.1fs", MODEL_NAME, PRETRAINED, time.perf_counter() - start)


def get_model() -> ClipModel:
    if _model is None:
        raise RuntimeError("CLIP model not loaded; load_model() must run at startup")
    return _model