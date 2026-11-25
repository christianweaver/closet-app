import logging
import time

import open_clip
import torch
from PIL import Image

logger = logging.getLogger(__name__)

MODEL_NAME = "ViT-B-32"
PRETRAINED = "laion2b_s34b_b79k"


class ClipModel:
    def __init__(self) -> None:
        model, _, preprocess = open_clip.create_model_and_transforms(
            MODEL_NAME, pretrained=PRETRAINED
        )
        model.eval()
        self.model = model
        self.preprocess = preprocess
        self.tokenizer = open_clip.get_tokenizer(MODEL_NAME)

    @torch.no_grad()
    def embed_image(self, image: Image.Image) -> torch.Tensor:
        """Return a normalized 512-number embedding for one image."""
        batch = self.preprocess(image).unsqueeze(0)    # [3, 224, 224] → [1, 3, 224, 224]
        features = self.model.encode_image(batch)      # [1, 512]
        features = features / features.norm(dim=-1, keepdim=True)
        return features[0]                             # [512]

    @torch.no_grad()
    def embed_texts(self, texts: list[str]) -> torch.Tensor:
        """Return one normalized embedding per text, shape [len(texts), 512]."""
        tokens = self.tokenizer(texts)
        features = self.model.encode_text(tokens)
        return features / features.norm(dim=-1, keepdim=True)


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