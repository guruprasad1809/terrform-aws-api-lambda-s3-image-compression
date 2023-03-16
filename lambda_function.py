# Code to get image from S3 and compress it 
# PIL is added as a Layer

import base64
import boto3
from PIL import Image

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = event ["pathParameters"]["bucket"]  #
    file_name = event ["queryStringParameters"]["file"]  #
    
    # Create a temp folder for downloading the image
    filepath = '/tmp/' + file_name
    
    # Download Image
    fileObj = s3.download_file(bucket_name, file_name , filepath)
    img = Image.open(filepath)
    img.save("/tmp/img.jpg", quality=10)   # Compress Image
    
    # Convert Jpg into byte to be able to send in response
    with open('/tmp/img.jpg', "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode("utf-8")

    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/jpg",
            "Content-Disposition": "attachment; filename={}".format(file_name)
        },
        "body":encoded_string,
        "isBase64Encoded": True
    }
