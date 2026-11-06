import os

from flask import Flask

from api.item_routes import item_api
from repository.item_repository import ItemRepository
from services.item_service import ItemService


def create_app(repository=None):
    app = Flask(__name__)
    service = ItemService(repository or ItemRepository())
    app.register_blueprint(item_api(service), url_prefix="/api/v1/items")
    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))