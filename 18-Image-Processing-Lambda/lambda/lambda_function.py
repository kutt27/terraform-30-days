import json
import boto3
import os
import logging
import base64
from urllib.parse import unquote_plus
from io import BytesIO
from PIL import Image, ImageDraw, ImageFont
from PIL.ExifTags import TAGS
import uuid

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')

# Supported formats
SUPPORTED_FORMATS = ['JPEG', 'PNG', 'WEBP', 'BMP', 'TIFF']
DEFAULT_QUALITY = 85
MAX_DIMENSION = 4096

# Watermark settings
WATERMARK_TEXT = os.environ.get('WATERMARK_TEXT', 'Image Processor')
WATERMARK_OPACITY = int(os.environ.get('WATERMARK_OPACITY', '128'))
WATERMARK_ENABLED = os.environ.get('WATERMARK_ENABLED', 'true').lower() == 'true'

def lambda_handler(event, context):
    """
    Lambda function to process images uploaded to S3.
    Supports compression, format conversion, watermarking, and EXIF extraction.
    Can be triggered by S3 events or API Gateway.
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")

        # Check if this is an API Gateway request
        if 'httpMethod' in event or 'requestContext' in event:
            return handle_api_request(event, context)

        # Handle S3 trigger event
        return handle_s3_event(event, context)

    except Exception as e:
        logger.error(f"Error processing image: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': str(e)})
        }


def get_cors_headers():
    """Return CORS headers for API Gateway responses."""
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
    }


def handle_api_request(event, context):
    """Handle API Gateway requests for direct image upload."""
    http_method = event.get('httpMethod', event.get('requestContext', {}).get('http', {}).get('method'))

    # Handle OPTIONS for CORS
    if http_method == 'OPTIONS':
        return {'statusCode': 200, 'headers': get_cors_headers(), 'body': ''}

    if http_method == 'POST':
        body = event.get('body', '')
        is_base64 = event.get('isBase64Encoded', False)

        if is_base64:
            image_data = base64.b64decode(body)
        else:
            # Try to parse JSON body
            try:
                json_body = json.loads(body)
                image_data = base64.b64decode(json_body.get('image', ''))
            except:
                return {
                    'statusCode': 400,
                    'headers': get_cors_headers(),
                    'body': json.dumps({'error': 'Invalid request body'})
                }

        # Generate unique filename
        filename = f"api-upload-{uuid.uuid4()}.jpg"

        # Upload to source bucket
        upload_bucket = os.environ.get('UPLOAD_BUCKET')
        if upload_bucket:
            s3_client.put_object(Bucket=upload_bucket, Key=filename, Body=image_data)
            logger.info(f"Uploaded via API: {filename}")

        # Process image directly
        processed_images = process_image(image_data, filename)
        processed_bucket = os.environ['PROCESSED_BUCKET']

        results = []
        for processed_image in processed_images:
            s3_client.put_object(
                Bucket=processed_bucket,
                Key=processed_image['key'],
                Body=processed_image['data'],
                ContentType=processed_image['content_type'],
                Metadata={
                    'original-key': filename,
                    'processed-by': 'lambda-image-processor',
                    'exif-data': json.dumps(processed_image.get('exif', {}))[:1024]
                }
            )
            results.append({
                'key': processed_image['key'],
                'format': processed_image['format'],
                'exif': processed_image.get('exif', {})
            })

        # Send SNS notification
        send_sns_notification(filename, results)

        return {
            'statusCode': 200,
            'headers': get_cors_headers(),
            'body': json.dumps({
                'message': 'Image processed successfully',
                'original_filename': filename,
                'processed_images': results
            })
        }

    return {
        'statusCode': 405,
        'headers': get_cors_headers(),
        'body': json.dumps({'error': 'Method not allowed'})
    }


def handle_s3_event(event, context):
    """Handle S3 trigger events."""
    processed_count = 0

    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])

        logger.info(f"Processing image: {key} from bucket: {bucket}")

        # Download the image from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()

        # Process the image
        processed_images = process_image(image_data, key)

        # Upload processed images to the processed bucket
        processed_bucket = os.environ['PROCESSED_BUCKET']

        results = []
        for processed_image in processed_images:
            output_key = processed_image['key']
            output_data = processed_image['data']
            content_type = processed_image['content_type']

            logger.info(f"Uploading processed image: {output_key}")

            s3_client.put_object(
                Bucket=processed_bucket,
                Key=output_key,
                Body=output_data,
                ContentType=content_type,
                Metadata={
                    'original-key': key,
                    'processed-by': 'lambda-image-processor',
                    'exif-data': json.dumps(processed_image.get('exif', {}))[:1024]
                }
            )
            results.append({'key': output_key, 'format': processed_image['format']})

        processed_count = len(processed_images)
        logger.info(f"Successfully processed {processed_count} variants of {key}")

        # Send SNS notification
        send_sns_notification(key, results)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Image processed successfully',
            'processed_images': processed_count
        })
    }


def send_sns_notification(original_key, processed_images):
    """Send SNS notification when processing completes."""
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
    if not sns_topic_arn:
        logger.info("SNS_TOPIC_ARN not configured, skipping notification")
        return

    try:
        message = {
            'event': 'image_processed',
            'original_key': original_key,
            'processed_count': len(processed_images),
            'processed_images': [img['key'] for img in processed_images]
        }

        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject=f"Image Processed: {original_key}",
            Message=json.dumps(message, indent=2)
        )
        logger.info(f"SNS notification sent for {original_key}")
    except Exception as e:
        logger.error(f"Failed to send SNS notification: {str(e)}")


def extract_exif_data(image):
    """Extract EXIF metadata from an image."""
    exif_data = {}
    try:
        raw_exif = image._getexif()
        if raw_exif:
            for tag_id, value in raw_exif.items():
                tag = TAGS.get(tag_id, tag_id)
                # Convert bytes to string for JSON serialization
                if isinstance(value, bytes):
                    try:
                        value = value.decode('utf-8', errors='ignore')
                    except:
                        value = str(value)
                # Skip large or complex data types
                if isinstance(value, (str, int, float)):
                    exif_data[tag] = value
            logger.info(f"Extracted EXIF data: {len(exif_data)} fields")
    except Exception as e:
        logger.warning(f"Could not extract EXIF data: {str(e)}")
    return exif_data


def add_watermark(image, text=None):
    """Add a watermark to the image."""
    if not WATERMARK_ENABLED:
        return image

    text = text or WATERMARK_TEXT

    try:
        # Create a copy to avoid modifying original
        watermarked = image.copy()
        draw = ImageDraw.Draw(watermarked)

        width, height = watermarked.size

        # Calculate font size based on image dimensions
        font_size = max(20, min(width, height) // 20)

        # Try to use default font
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", font_size)
        except:
            font = ImageFont.load_default()

        # Get text bounding box
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]

        # Position in bottom-right corner with padding
        padding = 20
        x = width - text_width - padding
        y = height - text_height - padding

        # Draw semi-transparent watermark
        # Create overlay for transparency effect
        draw.text((x+2, y+2), text, font=font, fill=(0, 0, 0, WATERMARK_OPACITY))  # Shadow
        draw.text((x, y), text, font=font, fill=(255, 255, 255, WATERMARK_OPACITY))  # Main text

        logger.info(f"Added watermark: {text}")
        return watermarked

    except Exception as e:
        logger.warning(f"Could not add watermark: {str(e)}")
        return image


def process_image(image_data, original_key):
    """
    Process the image: create compressed versions, convert formats,
    add watermarks, and extract EXIF data.

    Args:
        image_data: Raw image data
        original_key: Original S3 key

    Returns:
        List of processed image dictionaries with EXIF data
    """
    processed_images = []

    try:
        # Open the image
        original_image = Image.open(BytesIO(image_data))

        # Extract EXIF data before any processing
        exif_data = extract_exif_data(original_image)

        image = original_image.copy()

        # Convert RGBA to RGB for JPEG compatibility
        if image.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', image.size, (255, 255, 255))
            if image.mode == 'P':
                image = image.convert('RGBA')
            background.paste(image, mask=image.split()[-1] if image.mode in ('RGBA', 'LA') else None)
            image = background
        elif image.mode != 'RGB':
            image = image.convert('RGB')

        # Get original format and dimensions
        original_format = original_image.format or 'JPEG'
        width, height = image.size

        logger.info(f"Original image: {width}x{height}, format: {original_format}")

        # Resize if image is too large
        if width > MAX_DIMENSION or height > MAX_DIMENSION:
            ratio = min(MAX_DIMENSION / width, MAX_DIMENSION / height)
            new_width = int(width * ratio)
            new_height = int(height * ratio)
            image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
            logger.info(f"Resized to: {new_width}x{new_height}")

        # Add watermark
        image = add_watermark(image)

        # Generate base filename
        base_name = os.path.splitext(original_key)[0]
        unique_id = str(uuid.uuid4())[:8]

        # Create multiple variants
        variants = [
            {'format': 'JPEG', 'quality': 85, 'suffix': 'compressed'},
            {'format': 'JPEG', 'quality': 60, 'suffix': 'low'},
            {'format': 'WEBP', 'quality': 85, 'suffix': 'webp'},
            {'format': 'PNG', 'quality': None, 'suffix': 'png'}
        ]

        for variant in variants:
            output = BytesIO()
            save_format = variant['format']

            if variant['quality']:
                image.save(output, format=save_format, quality=variant['quality'], optimize=True)
            else:
                image.save(output, format=save_format, optimize=True)

            output.seek(0)

            # Generate output key
            extension = save_format.lower()
            if extension == 'jpeg':
                extension = 'jpg'

            output_key = f"{base_name}_{variant['suffix']}_{unique_id}.{extension}"

            # Determine content type
            content_type_map = {
                'JPEG': 'image/jpeg',
                'PNG': 'image/png',
                'WEBP': 'image/webp'
            }
            content_type = content_type_map.get(save_format, 'image/jpeg')

            processed_images.append({
                'key': output_key,
                'data': output.getvalue(),
                'content_type': content_type,
                'format': save_format,
                'quality': variant['quality'],
                'exif': exif_data
            })

            logger.info(f"Created variant: {output_key} ({save_format}, quality: {variant['quality']})")

        # Create thumbnail (without watermark for cleaner look)
        thumbnail = image.copy()
        thumbnail.thumbnail((300, 300), Image.Resampling.LANCZOS)
        thumb_output = BytesIO()
        thumbnail.save(thumb_output, format='JPEG', quality=80, optimize=True)
        thumb_output.seek(0)

        processed_images.append({
            'key': f"{base_name}_thumbnail_{unique_id}.jpg",
            'data': thumb_output.getvalue(),
            'content_type': 'image/jpeg',
            'format': 'JPEG',
            'quality': 80,
            'exif': exif_data
        })

        logger.info(f"Created thumbnail: {base_name}_thumbnail_{unique_id}.jpg")

        return processed_images

    except Exception as e:
        logger.error(f"Error in process_image: {str(e)}", exc_info=True)
        raise
