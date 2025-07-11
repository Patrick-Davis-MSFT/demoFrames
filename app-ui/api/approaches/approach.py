from typing import Any


class Approach:
    def run(self, q: str, overrides: dict[str, Any]) -> Any:
        raise NotImplementedError

    def save(self, q: str, overrides: dict[str, Any]) -> Any:
        raise NotImplementedError
    
    def get(self, q: str, overrides: dict[str, Any]) -> Any:
        raise NotImplementedError
    
    def post (self, q: str, overrides: dict[str, Any]) -> Any:
        raise NotImplementedError
    
    def put (self, q: str, overrides: dict[str, Any]) -> Any:
        raise NotImplementedError
    
    def delete (self, q: str, overrides: dict[str, Any]) -> Any:
        raise NotImplementedError
