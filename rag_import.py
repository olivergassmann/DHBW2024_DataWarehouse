import os
import fitz
from numpy import ndarray
from sentence_transformers import SentenceTransformer
import psycopg2

document_titles = []
documents = []

# First, get all document titles and paths
for filename in os.listdir('./arxiv_pdfs'):
    if filename.endswith(".pdf"):
        pdf_path = os.path.join('./arxiv_pdfs', filename)
        document_titles.append([filename, pdf_path])
   
# Then, read all the pdf's first page contents into another list     
for filename, pdf_path in document_titles:
    print(f"Reading {filename}")

    # Open pdf with pdf reader
    with fitz.open(pdf_path) as pdf:
        first_page = pdf.load_page(0)
        # Extract text from the first page
        page_text = first_page.get_text("text")
        if not page_text:
            print("Error reading file: First page contains no extractable content. Skipping...")
            document_titles.remove([filename, pdf_path])
            continue
        documents.append(page_text)

print('Start embedding process...')

model = SentenceTransformer('sentence-transformers/allenai-specter')
# SentenceTransformer can encode multiple inputs at once if a List of strings is provided as input parameter.
embeddings: ndarray = model.encode(documents, show_progress_bar = True)

print('Embedding process finished.')
print(embeddings)

# Merge the document titles with their corresponding embeddings
merged_results = [{"title": title[0], "embedding": embedding} for title, embedding in zip(document_titles, embeddings)]

print('Merged document titles with embeddings:')
for result in merged_results:
    print(result)

print('Saving merged results (documents with embeddings) to database...')

# Establish database connection
connection = psycopg2.connect(
    dbname="postgres",
    user="postgres",
    password="postgres",
    host="db",
    port="5432"
)

try:
    with connection:
        with connection.cursor() as cursor:
            # Create table for the articles if it does not already exist
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS articles (
                    id SERIAL PRIMARY KEY,
                    title TEXT NOT NULL,
                    embedding VECTOR NOT NULL
                )
            ''')
            
            # Insert merged results into the table
            for result in merged_results:
                cursor.execute('''
                    INSERT INTO articles (title, embedding)
                    VALUES (%s, %s)
                ''', (result['title'], result['embedding'].tolist()))
except Exception as e:
    print(f"An database error occurred: {e}")
finally:
    connection.close()

print('Results saved to database successfully.')
