import os
import json
from google.cloud import storage
from google.cloud import vision
import tempfile
import fitz  # PyMuPDF

def process_pdf(event, context):
    """Cloud Function triggered by a new file in the input bucket.
    Args:
        event (dict): The Cloud Functions event metadata.
        context (google.cloud.functions.Context): The Cloud Functions event context.
    """
    file_name = event['name']
    bucket_name = event['bucket']
    output_bucket = os.environ.get('OUTPUT_BUCKET')
    invoice_bucket = os.environ.get('INVOICE_BUCKET')
    company_bucket = os.environ.get('COMPANY_BUCKET')

    # Initialize clients
    storage_client = storage.Client()
    vision_client = vision.ImageAnnotatorClient()

    # Get the input bucket and file
    input_bucket = storage_client.bucket(bucket_name)
    pdf_blob = input_bucket.blob(file_name)

    # Process PDF and extract text
    with tempfile.NamedTemporaryFile(suffix='.pdf') as temp_pdf:
        pdf_blob.download_to_filename(temp_pdf.name)
        pdf_document = fitz.open(temp_pdf.name)
        
        results = []
        full_text = ""
        for page_num in range(pdf_document.page_count):
            page = pdf_document[page_num]
            
            pix = page.get_pixmap()
            with tempfile.NamedTemporaryFile(suffix='.png') as temp_image:
                pix.save(temp_image.name)
                
                with open(temp_image.name, 'rb') as image_file:
                    content = image_file.read()
                
                image = vision.Image(content=content)
                response = vision_client.text_detection(image=image)
                texts = response.text_annotations
                
                if texts:
                    page_text = texts[0].description
                    full_text += page_text.lower()
                    results.append({
                        'page': page_num + 1,
                        'text': page_text
                    })

        # Create JSON output
        output = {
            'file_name': file_name,
            'total_pages': pdf_document.page_count,
            'pages': results
        }

        # Determine document type and save to appropriate bucket
        json_content = json.dumps(output, indent=2)
        
        # Save to general output bucket
        output_bucket_client = storage_client.bucket(output_bucket)
        output_blob = output_bucket_client.blob(f"{os.path.splitext(file_name)[0]}.json")
        output_blob.upload_from_string(json_content, content_type='application/json')

        # Save to invoice bucket if it contains "invoice"
        if 'invoice' in full_text:
            invoice_bucket_client = storage_client.bucket(invoice_bucket)
            invoice_blob = invoice_bucket_client.blob(f"{os.path.splitext(file_name)[0]}.json")
            invoice_blob.upload_from_string(json_content, content_type='application/json')

        # Save to company bucket if it contains "betterme"
        if 'betterme' in full_text:
            company_bucket_client = storage_client.bucket(company_bucket)
            company_blob = company_bucket_client.blob(f"{os.path.splitext(file_name)[0]}.json")
            company_blob.upload_from_string(json_content, content_type='application/json')

        return f"Successfully processed {file_name}"
