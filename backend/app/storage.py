import logging
import os

import boto3
from botocore.client import Config
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

S3_BUCKET = os.environ["S3_BUCKET"]
UPLOAD_URL_EXPIRES_SECONDS = 15 * 60


def _make_client(endpoint_url: str):
    return boto3.client(
        "s3",
        endpoint_url=endpoint_url,
        aws_access_key_id=os.environ["S3_ACCESS_KEY"],
        aws_secret_access_key=os.environ["S3_SECRET_KEY"],
        region_name=os.environ.get("S3_REGION", "us-east-1"),
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )


# The API's own connection to storage (inside Docker).
_internal = _make_client(os.environ["S3_ENDPOINT"])
# Used ONLY to sign URLs for clients outside Docker.
_public = _make_client(os.environ["S3_PUBLIC_ENDPOINT"])


def ensure_bucket() -> None:
    """Create the bucket if it doesn't exist (safe to call on every startup)."""
    try:
        _internal.head_bucket(Bucket=S3_BUCKET)
    except ClientError:
        logger.info("Bucket %s not found; creating it", S3_BUCKET)
        _internal.create_bucket(Bucket=S3_BUCKET)


def presigned_upload_url(key: str, content_type: str) -> str:
    return _public.generate_presigned_url(
        "put_object",
        Params={"Bucket": S3_BUCKET, "Key": key, "ContentType": content_type},
        ExpiresIn=UPLOAD_URL_EXPIRES_SECONDS,
    )


def download_bytes(key: str) -> bytes:
    obj = _internal.get_object(Bucket=S3_BUCKET, Key=key)
    return obj["Body"].read()


def delete_object(key: str) -> None:
    _internal.delete_object(Bucket=S3_BUCKET, Key=key)

def object_exists(key: str) -> bool:
    try:
        _internal.head_object(Bucket=S3_BUCKET, Key=key)
        return True
    except ClientError as exc:
        if exc.response["Error"]["Code"] in ("404", "NoSuchKey", "NotFound"):
            return False
        raise