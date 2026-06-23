from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({"service": "redemption", "status": "ok"})

@app.route('/health/ready')
def ready():
    return jsonify({"ready": True})

@app.route('/health/live')
def live():
    return jsonify({"live": True})

@app.route('/health/startup')
def startup():
    return jsonify({"startup": True})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
