import boto3
import os
import random
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
table = dynamodb.Table(table_name)

def generate_show_data():
    show_id = str(uuid.uuid4())
    tour_id = str(uuid.uuid4())
    year = datetime.now().year
    # SK using synthetic key: TOUR#{tour_id}#{year}
    return {
        'PK': f'SHOW#{show_id}',
        'SK': f'TOUR#{tour_id}#{year}',
        'ShowName': f'Show {random.randint(1, 100)}',
        'Date': datetime.now().isoformat(),
        'Venue': f'Venue {random.randint(1, 10)}'
    }

def generate_order_data():
    user_id = str(uuid.uuid4())
    order_id = str(uuid.uuid4())
    show_id = str(uuid.uuid4())
    return {
        'PK': f'USER#{user_id}',
        'SK': f'ORDER#{order_id}',
        'Details': {
            'Amount': str(random.randint(50, 500)),
            'Status': random.choice(['CONFIRMED', 'PENDING', 'CANCELLED']),
            'ShowID': show_id
        }
    }

def lambda_handler(event, context):
    # Generate random data without needing input
    
    # Randomly decide to generate a Show or an Order, or both.
    # Let's generate one of each to ensure data variety in each run.
    
    show_item = generate_show_data()
    table.put_item(Item=show_item)
    print(f"Inserted Show: {show_item}")

    order_item = generate_order_data()
    table.put_item(Item=order_item)
    print(f"Inserted Order: {order_item}")

    return {
        'statusCode': 200,
        'body': 'Successfully inserted random data into DynamoDB'
    }
