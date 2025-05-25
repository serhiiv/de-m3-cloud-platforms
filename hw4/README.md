# Recognizes a PDF image and saves it in JSON format

PoC for an application that recognizes PDF images and saves them to GCP Storage in JSON format.

Develop a Python application that will take a PDF from the GCP Storage, send it to your Cloud AI Service, which can OCR the PDF, get the result in JSON, and put the JSON in the GCP Storage.

Use draw.io to create the solution's architecture. 

As described in the diagram, use Terraform to create infrastructure in Cloud GCP. 