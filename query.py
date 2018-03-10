from google.cloud import bigquery
import collections

def sync_query(query, project='mlab-sandbox'):
    client = bigquery.Client(project='mlab-sandbox')
    job = client.query(query)

    results = collections.defaultdict(list)
    for row in job.result(timeout=300):
        for key in row.keys():
            results[key].append(row.get(key))

    return results
