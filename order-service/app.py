from flask import Flask, request, jsonify
import mysql.connector
import os

app = Flask(__name__)

# Standard database connection helper
def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv('DB_HOST', 'db'),
        user=os.getenv('DB_USER', 'root'),
        password=os.getenv('DB_PASSWORD', 'rootpassword'),
        database=os.getenv('DB_NAME', 'cloudmart')
    )

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/orders', methods=['POST'])
def create_order():
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # In a real app, we'd verify the user and product exist first!
        # For now, we'll insert the record directly into the 'orders' table
        query = "INSERT INTO orders (user_id, product_id, quantity, total_price, status) VALUES (%s, %s, %s, %s, %s)"
        values = (data['user_id'], data['product_id'], data['quantity'], data['total_price'], 'pending')
        
        cursor.execute(query, values)
        conn.commit()
        
        return jsonify({
            "message": "Order placed!", 
            "order_id": cursor.lastrowid
        }), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
