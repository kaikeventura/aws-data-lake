import json
import boto3
import os
from datetime import datetime
from boto3.dynamodb.types import TypeDeserializer

firehose = boto3.client('firehose')
deserializer = TypeDeserializer()

def deserialize_dynamodb_item(item):
    return {k: deserializer.deserialize(v) for k, v in item.items()}

def lambda_handler(event, context):
    firehose_name = os.environ['FIREHOSE_NAME']
    records = []
    
    for record in event['Records']:
        if record['eventName'] in ['INSERT', 'MODIFY']:
            new_image = record['dynamodb'].get('NewImage', {})
            sk = deserializer.deserialize(new_image.get('SK', {'S': ''}))
            
            if sk.startswith('ORDER#'):
                clean_item = deserialize_dynamodb_item(new_image)
                clean_item['evento_tipo'] = 'venda_ingresso'
                clean_item['ingestion_at'] = datetime.utcnow().isoformat()
                
                records.append({
                    'Data': json.dumps(clean_item) + '\n'
                })
    
    if records:
        firehose.put_record_batch(
            DeliveryStreamName=firehose_name,
            Records=records
        )
    
    return {'statusCode': 200, 'body': f'Processed {len(records)} records'}
