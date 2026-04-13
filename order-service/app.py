from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import os
import traceback
import time

app = Flask(__name__)
# Enable CORS so the Frontend (8080) can talk to this API (5002)
CORS(app)

# Database configuration from Environment Variables
DB_HOST = os.getenv('DB_HOST', 'db')
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'rootpassword')
DB_NAME = os.getenv('DB_DATABASE', 'cloudmart')

def get_db_connection():
    """Connects to MySQL with a simple retry logic to handle startup delays."""
    connection = None
    try:
        connection = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            port=3306,
            # This handles MySQL 8.0's new authentication method
            auth_plugin='mysql_native_password'
        )
    except Error as e:
        print(f"!!! DATABASE CONNECTION ERROR !!!")
        print(e)
    return connection

@app.route('/orders', methods=['POST'])
def create_order():
    try:
        # 1. Get the data from the request
        data = request.json
        print(f"DEBUG: Received Order Request: {data}")
        
        user_id = data.get('user_id')
        product_id = data.get('product_id')
        quantity = data.get('quantity', 1)
        total_price = data.get('total_price', 0.0)

        # 2. Validate
        if not user_id or not product_id:
            return jsonify({"error": "Missing user_id or product_id"}), 400

        # 3. Connect to DB
        conn = get_db_connection()
        if conn is None:
            return jsonify({"error": "Service temporarily unable to connect to database"}), 500

        # 4. Insert Order
        cursor = conn.cursor()
        query = "INSERT INTO orders (user_id, product_id, quantity, total_price) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (user_id, product_id, quantity, total_price))
        
        conn.commit()
        order_id = cursor.lastrowid
        
        cursor.close()
        conn.close()
        
        print(f"SUCCESS: Order #{order_id} created in database.")
        return jsonify({
            "message": "Order placed successfully!",
            "order_id": order_id
        }), 201

    except Exception as e:
        # THIS IS THE CURE FOR SILENT 500 ERRORS
        print("!!! CRITICAL EXCEPTION IN /ORDERS ROUTE !!!")
        print(traceback.format_exc()) 
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    # host='0.0.0.0' makes the service reachable inside the Docker network
    app.run(host='0.0.0.0', port=5002, debug=True)
