from flask import Flask, jsonify, Response  # Add Response here
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST # Add this line
from flask_cors import CORS
import mysql.connector
import os
# 1. Import the exporter
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
CORS(app)

# 2. Initialize metrics
metrics = PrometheusMetrics(app, path=None) # We set path to None to handle it manually

@app.route('/metrics')
def metrics_endpoint():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

# Static information as metric
metrics.info('app_info', 'Product Service info', version='1.0.0')

def get_db():
    return mysql.connector.connect(
        host=os.environ.get('DB_HOST', 'db'),
        user=os.environ.get('DB_USER', 'root'),
        password=os.environ.get('DB_PASSWORD', 'password'),
        database=os.environ.get('DB_NAME', 'cloudmart')
    )

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/products')
def get_products():
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM products")
        products = cursor.fetchall()
        return jsonify(products), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/products/<int:id>')
def get_product(id):
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM products WHERE id = %s", (id,))
        product = cursor.fetchone()
        if not product:
            return jsonify({"error": "Product not found"}), 404
        return jsonify(product), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
