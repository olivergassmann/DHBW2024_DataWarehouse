import sys
import psycopg2
from numpy import ndarray
from sentence_transformers import SentenceTransformer

if len(sys.argv) != 2:
    print("Usage: python3 rag_retrieval.py <query>")
    exit()

query = sys.argv[1]

# Embed query
print("Calculate embedding for query...")
model = SentenceTransformer('sentence-transformers/allenai-specter')
query_vector: ndarray = model.encode(query)
print("Embedding finished.")

print("Querying Database for similar documents...")
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
                            SELECT title
                            FROM articles
                            ORDER BY embedding <-> %s::VECTOR
                            LIMIT 5;
                        ''', (query_vector.tolist(),))
            results = cursor.fetchall()
except Exception as e:
    print(f"An database error occurred: {e}")
    exit(-1)
finally:
    connection.close()

print("Retrieved documents:")
for result in results:
    print(result[0])