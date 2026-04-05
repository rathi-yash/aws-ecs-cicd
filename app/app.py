from flask import Flask
app = Flask(__name_)

@app.route("/")
def home():
    return "<h1>Hello form ECS! Deployed via Github Actions + Terraform</h1>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)