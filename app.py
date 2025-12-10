from flask import Flask, request, jsonify
from sqlalchemy import create_engine, Column, Integer, String, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import boto3
import pymysql

app = Flask(__name__)

# --- DB CONFIG (via variables d'environnement) ---
DB_USER = os.environ.get('DB_USER', 'appadmin')
DB_PASS = os.environ.get('DB_PASS', '')
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_NAME = os.environ.get('DB_NAME', 'appdb')

SQLALCHEMY_DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}/{DB_NAME}"

engine = create_engine(SQLALCHEMY_DATABASE_URL, pool_recycle=280)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ------------------------
#       MODEL
# ------------------------
class Task(Base):
    __tablename__ = 'tasks'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200))
    description = Column(Text)

Base.metadata.create_all(bind=engine)

# ------------------------
#         S3
# ------------------------
s3 = boto3.client("s3")
BUCKET = os.environ.get("S3_BUCKET")

# ------------------------
#         ROUTES
# ------------------------

@app.route("/")
def root():
    return jsonify({"status": "ok", "service": "task-manager"})

# --- CRUD TASKS ---
@app.route("/tasks", methods=["GET", "POST"])
def tasks():
    db = SessionLocal()
    if request.method == "POST":
        data = request.json
        new_task = Task(title=data.get("title"), description=data.get("description"))
        db.add(new_task)
        db.commit()
        db.refresh(new_task)
        return jsonify({"id": new_task.id}), 201

    items = db.query(Task).all()
    return jsonify([
        {"id": t.id, "title": t.title, "description": t.description}
        for t in items
    ])


@app.route("/tasks/<int:task_id>", methods=["GET", "PUT", "DELETE"])
def task_item(task_id):
    db = SessionLocal()
    task = db.query(Task).filter(Task.id == task_id).first()

    if not task:
        return jsonify({"error": "Task not found"}), 404

    if request.method == "GET":
        return jsonify({"id": task.id, "title": task.title, "description": task.description})

    if request.method == "PUT":
        data = request.json
        task.title = data.get("title", task.title)
        task.description = data.get("description", task.description)
        db.commit()
        return jsonify({"id": task.id})

    if request.method == "DELETE":
        db.delete(task)
        db.commit()
        return jsonify({"status": "deleted"})


# --- PRESIGNED UPLOAD URL ---
@app.route("/upload-url", methods=["POST"])
def upload_url():
    key = request.json.get("key")
    if not key:
        return jsonify({"error": "Missing key"}), 400

    url = s3.generate_presigned_url(
        "put_object",
        Params={"Bucket": BUCKET, "Key": key},
        ExpiresIn=3600
    )
    return jsonify({"upload_url": url})


# --- PRESIGNED DOWNLOAD URL ---
@app.route("/download-url", methods=["POST"])
def download_url():
    key = request.json.get("key")
    if not key:
        return jsonify({"error": "Missing key"}), 400

    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": BUCKET, "Key": key},
        ExpiresIn=3600
    )
    return jsonify({"download_url": url})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
