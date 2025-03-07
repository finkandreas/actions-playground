import firecrest as fc
import os

client_id = os.environ.get("INPUT_FIRECREST_CLIENT_ID", "")
client_secret = os.environ.get("INPUT_FIRECREST_CLIENT_SECRET", "")
if client_id == "" or client_secret == "":
    print("The client-id or client-secret is empty. Please provide the firecrest credentials")
    exit(1)

url = os.environ['INPUT_FIRECREST_URL']
auth_url = os.environ['INPUT_FIRECREST_TOKEN_URL']

client =  fc.v1.Firecrest(firecrest_url=url, authorization=fc.ClientCredentialsAuth(client_id, client_secret, auth_url, min_token_validity=60))

print(client.all_systems())
