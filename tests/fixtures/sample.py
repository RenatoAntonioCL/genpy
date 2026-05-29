# Fixture para tests de resolver.sh
# NO modificar: las líneas son parte del contrato de los tests.

import os
import sys
from typing import Optional


def get_config(key: str) -> Optional[str]:
    return os.getenv(key)


async def fetch_data(url: str) -> dict:
    return {"url": url, "data": None}


@staticmethod
def decorated_func():
    pass


class ItemService:
    def __init__(self, db):
        self.db = db

    def create_item(self, name: str) -> dict:
        return {"name": name}

    async def delete_item(self, item_id: int) -> bool:
        return True

    def _private_helper(self):
        x = 1
        y = 2
        return x + y


class Config:
    DEBUG = False
    VERSION = "1.0"
